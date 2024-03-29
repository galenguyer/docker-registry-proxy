REGISTRY_URL="${REGISTRY:-registry}"

cat > /etc/nginx/nginx.conf << EOF
# run nginx as the www-data user
user www-data;

# set the number of workers equal to the cpu count
worker_processes auto;

# set the maximum number of simultaneous connections
# since this is a proxy server, this is set higher than default
events {
  worker_connections 2048;
}


http {
  upstream docker-registry {
    server $REGISTRY_URL:5000;
  }

  map \$upstream_http_docker_distribution_api_version \$docker_distribution_api_version {
    '' 'registry/2.0';
  }

  server {
    listen 8080;
    server_name _;

    error_page 588 = @pushrequests;

    if (\$request_method = 'POST') {
      return 588;
    }

    if (\$request_method = 'DELETE') {
      return 588;
    }

    ## If \$docker_distribution_api_version is empty, the header is not added.
    ## See the map directive above where this variable is defined.
    add_header 'Docker-Distribution-Api-Version' \$docker_distribution_api_version always;

    location / {
      proxy_set_header  Host              \$http_host;   # required for docker client's sake
      proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
      proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
      proxy_set_header  X-Forwarded-Proto https;
      client_max_body_size 800M; # avoid HTTP 413 for large image uploads
      chunked_transfer_encoding on; # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
      proxy_pass http://docker-registry;
    }

    location @pushrequests {
      auth_basic "Restricted";
      auth_basic_user_file /auth/.htpasswd;
      proxy_set_header  Host              \$http_host;   # required for docker client's sake
      proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
      proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
      proxy_set_header  X-Forwarded-Proto https;
      client_max_body_size 800M; # avoid HTTP 413 for large image uploads
      chunked_transfer_encoding on; # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
      proxy_pass http://docker-registry;
    }
  }
}
EOF

/usr/sbin/nginx -g "daemon off;"

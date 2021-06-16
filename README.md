# docker-registry-proxy
Provides an easy way to have user authentication in front of a docker registry.

Importantly, it does not restrict what namespaces a user can push to, just requires that
a user have a password before being able to push anywhere in the registry.

In order for this to work, any clients that wish to push must be running my modified fork of dockerd,
avaiable by building [my fork of moby](https://github.com/galenguer/moby).

Before running, make sure to make the local auth folder. To add a user, run `docker-compose run proxy add-user [username]`
and you will get a password prompt. To remove a user, remove their line from the password file.

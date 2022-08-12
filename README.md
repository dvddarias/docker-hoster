# Hoster

## Mount hosts file directyly
A simple "etc/hosts" file injection tool to resolve names of local Docker containers on the host.

hoster is intended to run in a Docker container:

    docker run -d \
        --mount type=bind,source=/var/run/docker.sock,target=/tmp/docker.sock \
        --mount type=bind,source=/etc/hosts,target=/tmp/hosts \
        dvdarias/docker-hoster

## Mount directory containing hosts file
In some cases there is a problem while rewriting hosts file. This can be prevent with mapping/mounting complete directory and point to the hosts file with environment variable.

    docker run -d \
        -e HOST_PATH=/tmp/etc/hosts -e SOCK_PATH=tmp/docker.sock \
        --mount type=bind,source=/etc,target=/tmp/etc \
        --mount type=bind,source=/var/run/docker.sock,target=/tmp/docker.sock \
        dvdarias/docker-hoster


The `docker.sock` is mounted to allow hoster to listen for Docker events and automatically register containers IP.

Hoster inserts into the host's `/etc/hosts` file an entry per running container and keeps the file updated with any started/stoped container.

## Container Registration

Hoster provides by default the entries `<container name>, <hostname>, <container id>` for each container and the aliases for each network. Containers are automatically registered when they start, and removed when they die.

For example, the following container would be available via DNS as `myname`, `myhostname`, `et54rfgt567` and `myserver.com`:

    docker run -d \
        --name myname \
        --hostname myhostname \
        --network somenetwork --network-alias "myserver.com" \
        mycontainer

If you need more features like **systemd interation** and **dns forwarding** please check [resolvable](https://hub.docker.com/r/mgood/resolvable/)

Any contribution is, of course, welcome. :)

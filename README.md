# Hoster

A simple "etc/hosts" file injection tool to resolve names of local Docker containers on the host.

hoster is intended to run in a Docker container:

	docker run -d \
		-v /var/run/docker.sock:/tmp/docker.sock \
    -v /etc/hosts:/tmp/hosts \
		dvdarias/docker-hoster

The `docker.sock` is mounted to allow hoster to listen for Docker events and automatically register containers IP.

Hoster inserts into the host's `/etc/hosts` file an entry per running container and keeps the file updated with any started/stoped container.

## Container Registration

Hoster provides by default the entry `<name>.local` for each container. Also you can set a label `hoster.domains` with a list of space separated domains to include as container aliases. Containers are automatically registered when they start, and removed when they die.

For example, the following container would be available via DNS as `myname.local`, `myserver.com` and `www.myserver.com`:

	docker run -d \
		--name myname \
		--label hoster.domains="myserver.com www.myserver.com" \
		mycontainer

If you need more features like **systemd interation** and **dns forwarding** please check [resolvable](https://hub.docker.com/r/mgood/resolvable/)

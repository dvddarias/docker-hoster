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

Hoster provides by default the entries `<container name>, <hostname>, <container id>` for each container and the aliases for each network. Containers are automatically registered when they start, and removed when they die.

For example, the following container would be available via DNS as `myname`, `myhostname`, `et54rfgt567` and `myserver.com`:

    docker run -d \
        --name myname \
        --hostname myhostname \
        --network somenetwork --network-alias "myserver.com" \
        mycontainer

If you need more features like **systemd interation** and **dns forwarding** please check [resolvable](https://hub.docker.com/r/mgood/resolvable/)

## Windows Host implementation

If windows is your host machine OS, then you may have problems configuring the network and accessing containers.

To solve problems, you need to manually create a network for the docker.

Example of creating a network:

```bash
docker network create --subnet=172.25.0.0/16 dev-test
```

You must select a subnet to forward all requests to this subnet to the docker’s Hyper-V virtual machine.

You can add a route for the subnet this way:

```bash
route /P add 172.25.0.0 MASK 255.255.0.0 10.0.75.2
```

Where 10.0.75.2 is your main docker VM ip.

Next, in the `docker-compose.yml` file, you need to add your network as a external and set up aliases for the containers:

```yaml
version: '3'
services:
  nginx:
    image: 'nginx:latest'
    container_name: nginx-test
    volumes:
      - './.docker/nginx/conf:/etc/nginx/conf.d'
      - '.:/var/www/app'
      - './.docker/nginx/logs:/var/log/nginx'
    networks:
        development:
            aliases:
                - mydomain.test
networks:
  development:
    external:
      name: dev-test
```

Wor windows run container like this:

```bash
docker run -d --restart=always --name docker-hoster -v /var/run/docker.sock:/tmp/docker.sock -v /c/Windows/System32/drivers/etc/hosts:/tmp/hosts dvdarias/docker-hoster
```

You can use the `--restart=always` flag to automatically turn it on with docker restart.

## Network and Domain filtering

You can run container with additional service parameters for enable network and domain filtering (for clearing data in your hosts file).

Add in the end os run command:

```
... python -u hoster.py --networks <network-name-1> <network-name-N> --masks <mask-1> <mask-N>
```

You can add networks by name and domain masks as substring of domain.

For test example:

```bash
docker run -it --rm --name docker-hoster -v /var/run/docker.sock:/tmp/docker.sock -v /c/Windows/System32/drivers/etc/hosts:/tmp/hosts dvdarias/docker-hoster python -u hoster.py --networks dev-test dev-test2 --masks .test .local
```

And if `docker-compose up` for previous config, you will see next in your hosts:

```
#-----------Docker-Hoster-Domains----------
172.25.0.2    webpack.test
#-----Do-not-add-hosts-after-this-line-----
```

---

Any contribution is, of course, welcome. :)

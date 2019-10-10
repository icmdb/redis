# icmdb/redis

This project is used to build a configurable redis image based on official's.

## Reference

* [Get Docker Engine - Community for Ubuntu - Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* [Install Docker Compose - Docker](https://docs.docker.com/compose/install/)
* [redis.conf - redis.io](http://download.redis.io/redis-stable/redis.conf)
* [redis - DockerHub](https://hub.docker.com/_/redis)
* [ngbdf/redis-manager - GitHub](https://github.com/ngbdf/redis-manager)
* [z-song/redis-manager - GitHub](https://github.com/z-song/redis-manager)

## Quick Start

* `docker run`

```bash
docker run -d \
    --name=redis \
    --hostname=redis \
    -e REDIS_REQUIREPASS=Redis@Pass0rd \
    -e REDIS_RENAME_COMMAND_CONFIG=renamedconfig \
    -p 6379:6379 \
    icmdb/redis 
```

* `docker-compose.yml`

```bash
version: "3"
services:
  redis:
    container_name: redis
    hostname: redis
    image: icmdb/redis
    environment:
     - REDIS_DEBUG=
     - REDIS_DELAY=1
     - REDIS_PORT=6379
     - REDIS_REQUIREPASS=Redis@Pass0rd
     - REDIS_RENAME_COMMAND_CONFIG=renamedconfig
    ports:
     - 6379:6379
    restart: always
```

## Todo List

* [x] Managemnt
* [ ] Monit
* [ ] Configfile 
* [ ] Yaml for k8s
* [ ] Helm Charts
* [ ] Sential 


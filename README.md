# icmdb/redis

## Quick Start

* `docker run`

```bash
# By docker run
docker run -d \
    --name=redis \
    --hostname=redis \
    -e REDIS_REQUIREPASS=123654  \
    -e REDIS_RENAME_COMMAND_CONFIG=renamedconfig \
    -p 6379:6379 \
    icmdb/redis 
```

or

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
     - REDIS_REQUIREPASS=123654
     - REDIS_RENAME_COMMAND_CONFIG=renamedconfig
    ports:
     - 6379:6379
    restart: always
```


## Todo

* Sential 
* Monit


#!/bin/bash
#

#set -xue
set -xe

REDIS_DEBUG=""
REDIS_PORT="${REDIS_PORT}"
REDIS_REQUIREPASS="${REDIS_REQUIREPASS}"
REDIS_RENAME_COMMAND_CONFIG="${REDIS_RENAME_COMMAND_CONFIG}"

if [ ! -z "${REDIS_PORT}" ]; then
    sed -i "s#^port.*#port '"${REDIS_PORT}"'#g" /redis/redis.conf
fi

if [ ! -z "${REDIS_REQUIREPASS}" ]; then
    echo "requirepass '${REDIS_REQUIREPASS}'" >> /redis/redis.conf
fi

if [ ! -z "${REDIS_RENAME_COMMAND_CONFIG}" ]; then
    echo "rename-command CONFIG '${REDIS_RENAME_COMMAND_CONFIG}'" >> /redis/redis.conf
fi

if [ ! -z "${REDIS_DEBUG}" ]; then
    cat /redis/redis.conf
fi

[ -w /proc/sys/net/core/somaxconn ] && echo 1024  > /proc/sys/net/core/somaxconn
[ -w /sys/kernel/mm/transparent_hugepage/enabled ] && echo never > /sys/kernel/mm/transparent_hugepage/enabled

chown -R redis:redis /data

exec gosu redis redis-server /redis/redis.conf

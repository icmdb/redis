#!/bin/bash
#
set +xue

REDIS_DEBUG="${REDIS_DEBUG}"
REDIS_DELAY="${REDIS_DELAY}"
REDIS_PORT="${REDIS_PORT}"
REDIS_REQUIREPASS="${REDIS_REQUIREPASS}"
REDIS_RENAME_COMMAND_CONFIG="${REDIS_RENAME_COMMAND_CONFIG}"


[ ! -z "${REDIS_DEBUG}" ] && set -xe

if [ ! -z "${REDIS_DELAY}" ]; then
    echo ""
    echo "Redis Server will start in ${REDIS_DELAY} seconds..."
    echo ""
    sleep ${REDIS_DELAY}
fi

if [ ! -z "${REDIS_PORT}" ]; then
    sed -i "s#^port.*#port "${REDIS_PORT}"#g" /redis/redis.conf
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
chown -R redis:redis /redis/redis.conf

exec gosu redis redis-server /redis/redis.conf

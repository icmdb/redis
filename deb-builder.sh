#!/bin/bash
#
#################################################################
#      This script is used to buid a customize deb package.     #
#################################################################
#

# This is a demo, tested on Ubuntu 18.04.4

PS4='+ $(date +"%F %T%z") ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -e

DATETIME="$(date +%Y%m%d%H%M%S)"

PKG_COMMON_NAME="redis"
PKG="${PKG:=hi-redis}"
PKG_VER="6.0.5"

DEB_PKGS_DIR="${HOME}/pkgs"
DEB_FILE_DIR="${HOME}/debs"

mkdir -p ${DEB_PKGS_DIR}
mkdir -p ${DEB_FILE_DIR}

rm   -rf ${DEB_PKGS_DIR}/${PKG}/*

mkdir -p ${DEB_PKGS_DIR}/${PKG}
mkdir -p ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/bin
mkdir -p ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc
mkdir -p ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/data
mkdir -p ${DEB_PKGS_DIR}/${PKG}/lib/systemd/system/
mkdir -p ${DEB_PKGS_DIR}/${PKG}/etc/logrotate.d/
mkdir -p ${DEB_PKGS_DIR}/${PKG}/var/log/${PKG}
mkdir -p ${DEB_PKGS_DIR}/${PKG}/DEBIAN/

touch    ${DEB_PKGS_DIR}/${PKG}/DEBIAN/{control,preinst,postinst,prerm,postrm}
chmod +x ${DEB_PKGS_DIR}/${PKG}/DEBIAN/{control,preinst,postinst,prerm,postrm}


makebin() {
    REDIS_VER=6.0.5
    REDIS_TAR=redis-${REDIS_VER}.tar.gz
    REDIS_URL=http://download.redis.io/releases/${REDIS_TAR}

    apt-get update && apt-get -y install \
        tree \
        wget \
        curl \
        gcc \
        make \
        vim 

       wget -c -P /tmp/ ${REDIS_URL} \
    && tar -C /tmp/ -xvf /tmp/${REDIS_TAR} \
    && cd /tmp/redis-${REDIS_VER} \
    && make MALLOC=libc CFLAGS="-march=native" PREFIX=${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG} install

    echo -e "# Gernerate at $(date +%F_%T%z) by Youqing Han\n#\n# http://download.redis.io/redis-stable/redis.conf\n# https://redis.io/topics/admin\n#" > ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf.default
    curl -sL http://download.redis.io/redis-stable/redis.conf >> ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf.default
    grep -v '^\s*$\|^\s*#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf.default > ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf

    # Customize config
    sed -i                                's#^bind.*#bind 0.0.0.0#g' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i                      's#^tcp-backlog.*#tcp-backlog 2048#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i                                   's#^port.*#port 6380#g' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i        's#^pidfile.*#pidfile /var/run/'${PKG}'/6380.pid#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i               's#^dbfilename.*#dbfilename dump-6380.rdb#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i 's#^appendfilename.*#appendfilename appendonly-6380.aof#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i 's#^logfile.*#logfile /var/log/'${PKG}/${PKG}'-6380.log#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i                  's#^dir.*#dir /usr/local/'${PKG}'/data#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i                         's#^loglevel.*#loglevel warning#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    sed -i                           's#^daemonize.*#daemonize yes#' ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf
    
    cat >> ${DEB_PKGS_DIR}/${PKG}/usr/local/${PKG}/etc/redis.conf <<EOF
# addtional config $(date +%F_%T%z) by Youqing Han
rename-command CONFIG ""
requirepass $(date +%s|base64)
maxclients 2048
maxmemory 4g
maxmemory-policy allkeys-lru
maxmemory-samples 100
slowlog-log-slower-than 10000
#slaveof x.x.x.x
#masterauth $(date +%s|base64)
EOF
}
makeservice() {
    cat > ${DEB_PKGS_DIR}/${PKG}/lib/systemd/system/${PKG}.service <<EOF
[Unit]
Description=Customized ${PKG_COMMON_NAME} based on version ${PKG_VER}.
After=network.target
Documentation=http://redis.io/documentation

[Service]
Type=forking
ExecStart=/usr/local/${PKG}/bin/redis-server /usr/local/${PKG}/etc/redis.conf
ExecStop=/bin/kill -s TERM \$MAINPID
PIDFile=/var/run/${PKG}/6380.pid
TimeoutStopSec=0
Restart=always
User=${PKG}
Group=${PKG}
RuntimeDirectory=${PKG}
RuntimeDirectoryMode=2755

UMask=007
PrivateTmp=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWriteDirectories=-/var/lib/${PKG}
ReadWriteDirectories=-/var/log/${PKG}
ReadWriteDirectories=-/var/run/${PKG}
ReadWriteDirectories=-/usr/local/${PKG}/data/

NoNewPrivileges=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
MemoryDenyWriteExecute=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# redis-server can write to its own config file when in cluster mode so we
# permit writing there by default. If you are not using this feature, it is
# recommended that you replace the following lines with "ProtectSystem=full".
ProtectSystem=true
ReadWriteDirectories=-/usr/local/${PKG}/etc/

[Install]
WantedBy=multi-user.target
EOF
}
logrotate() {
    cat > ${DEB_PKGS_DIR}/${PKG}/etc/logrotate.d/${PKG} <<EOF
/var/log/${PKG}.log {
	daily
	rotate 15
	compress
	delaycompress
	missingok
	notifempty
	create 644 root root
}
EOF
}
preinst() {
    cat > ${DEB_PKGS_DIR}/${PKG}/DEBIAN/preinst <<EOF
#!/bin/bash
# Do something pre-install
echo -e "\n=> Create user for ${PKG}"
grep ${PKG} /etc/group  || groupadd ${PKG};
grep ${PKG} /etc/passwd || useradd -d /usr/local/${PKG}/data -s /sbin/nologin -M -g ${PKG} ${PKG};

echo -e "\n=> Create directories for ${PKG}"
mkdir -pv /var/log/${PKG}/
mkdir -pv /usr/local/${PKG}/data

echo -e "\n=> Change directories owner to ${PKG}"
chown -R ${PKG}:${PKG} /var/log/${PKG}/
chown -R ${PKG}:${PKG} /usr/local/${PKG}/data
chown -R ${PKG}:${PKG} /usr/local/${PKG}/etc

exit 0
EOF
}
postinst() {
    cat > ${DEB_PKGS_DIR}/${PKG}/DEBIAN/postinst <<EOF
#!/bin/bash
# Do something post-install.

echo -e "\n=> Setting TCP backlog for ${PKG}"
echo 2048 > /proc/sys/net/core/somaxconn

echo -e "\n=> Disable Transparent Huge Pages (THP) for ${PKG} which will create latency and memory usage issues"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
grep '# THP' /etc/rc.local||sed -i '/^exit/i# THP disabled for ${PKG}\necho never > /sys/kernel/mm/transparent_hugepage/enabled' /etc/rc.local

echo -e "\n=> Setting overcommit_memory for ${PKG}"
grep '^vm.overcommit_memory' /etc/sysctl.conf||echo -e '# ${PKG}\nvm.overcommit_memory = 1' >> /etc/sysctl.conf;
sysctl -p

echo -e "\n=> Start and bootstrap for ${PKG}"
systemctl daemon-reload
systemctl enable ${PKG}
systemctl start  ${PKG}

exit 0
EOF
}
prerm() {
    cat ${DEB_PKGS_DIR}/${PKG}/DEBIAN/prerm <<EOF
#!/bin/bash
# Do something pre-rm.

echo -e "\n=> Stop and remove bootstrap for ${PKG}"
systemctl stop    ${PKG}
systemctl disable ${PKG}
systemctl daemon-reload

exit 0
EOF
}
postrm() {
    cat ${DEB_PKGS_DIR}/${PKG}/DEBIAN/postrm <<EOF
#!/bin/bash
# Do something post-rm.

exit 0
EOF
}
control() {
    cat > ${DEB_PKGS_DIR}/${PKG}/DEBIAN/control <<EOF
Package: ${PKG}
Version: ${PKG_VER}-${DATETIME}
Section: ${PKG} builded by Youqing.
Priority: optional
Depends: curl,wget
Suggests: curl,wget
Architecture: amd64
Installed-Size: $(du -sh ${DEB_PKGS_DIR}/${PKG}|awk '{print $1}')
Maintainer: Youqing Han
Provides: Youqing
Description: This is a customized deb package based on ${PKG_COMMON_NAME}-${PKG_VER}.
EOF
}

main() {
    makebin
    makeservice
    logrotate
    preinst
    prerm
    postinst
    postrm
    control

    package="$(grep '^Package:' ${DEB_PKGS_DIR}/${PKG}/DEBIAN/control|awk '{print $NF}')"
    version="$(grep '^Version:' ${DEB_PKGS_DIR}/${PKG}/DEBIAN/control|awk '{print $NF}')"
    arch="$(grep '^Architecture:' ${DEB_PKGS_DIR}/${PKG}/DEBIAN/control|awk '{print $NF}')"

    rm -rf ${DEB_FILE_DIR}/*
    time dpkg -b ${DEB_PKGS_DIR}/${PKG} ${DEB_FILE_DIR}/${package}-${version}.${arch}.deb
}

main

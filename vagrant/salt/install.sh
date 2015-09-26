#!/bin/sh

#
# The Perfect Cluster: Moodle
#
# @author Luke Carrier <luke.carrier@floream.com>
# @copyright 2015 Floream Limited
#

eval set -- "$(getopt -o "air:" --long "master:,minion:,root:" -- "$@")"
while true; do
    case "$1" in
        -a|--master) install_master="$2" ; shift 2 ;;
        -i|--minion) install_minion="$2" ; shift 2 ;;
        -r|--root  ) root="$2"           ; shift 2 ;;
        *          ) break               ;         ;;
    esac
done

echo "installing saltstack GPG key..."
rpm --import https://repo.saltstack.com/yum/rhel7/SALTSTACK-GPG-KEY.pub

echo "installing saltstack yum repository..."
echo '[saltstack-repo]
name=SaltStack repo for RHEL/CentOS $releasever
baseurl=https://repo.saltstack.com/yum/rhel$releasever
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/rhel$releasever/SALTSTACK-GPG-KEY.pub' > /etc/yum.repos.d/saltstack.repo

if [ -n "$install_master" ]; then
    echo "installing Salt master..."
    yum install -y salt-master >/dev/null

    echo "temporarily starting master to create configuration directories..."
    systemctl start salt-master
    sleep 2
    systemctl stop salt-master

    echo "installing configuration..."
    cp "${root}/master" /etc/salt/master
    cp "${root}/master.pem" "${root}/master.pub" /etc/salt/pki/master

    minions=($(echo $install_master | tr "," " "))
    for minion in "${minions[@]}"; do
        echo "preseeding master with minion key ${minion}..."
        cp "${root}/minions/${minion}.pub" "/etc/salt/pki/master/minions/${minion}"
    done

    echo "enabling and starting master daemon..."
    systemctl enable salt-master 2>/dev/null
    systemctl start salt-master
fi

if [ -n "$install_minion" ]; then
    echo "installing Salt minion..."
    yum install -y salt-minion >/dev/null

    echo "temporarily starting minion to create configuration directories..."
    systemctl start salt-minion
    sleep 2
    systemctl stop salt-minion

    echo "installing minion configuration and keys..."
    cp "${root}/minions/${install_minion}" /etc/salt/minion
    cp "${root}/minions/${install_minion}.pem" /etc/salt/pki/minion/minion.pem
    cp "${root}/minions/${install_minion}.pub" /etc/salt/pki/minion/minion.pub

    echo "preseeding minion with master key..."
    cp "${root}/master.pub" /etc/salt/pki/minion/minion_master.pub

    echo "enabling and starting minion daemon..."
    systemctl enable salt-minion 2>/dev/null
    systemctl start salt-minion
fi

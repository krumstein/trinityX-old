#!/bin/bash

######################################################################
# Trinity X
# Copyright (c) 2016  ClusterVision B.V.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License (included with the sources) for more
# details.
######################################################################


# trinityX
# Standard node post-installation script
# This should include all the most common tasks that have to be performed after
# a completely standard CentOS minimal installation.


display_var STDCFG_{SSHROOT,CTRL_GATEWAY} TRIX_{ROOT,CTRL_IP} POST_FILEDIR


if flag_is_set STDCFG_SSHROOT ; then
    echo_info "Allowing SSH login as root"
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
else
    echo_info "SSH login as root disabled"
fi


#---------------------------------------

echo_info "Copying the root's SSH public key, if it exists"

if [[ -r "${TRIX_ROOT}/root/.ssh/id_ed25519.pub" ]] ; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    append_line /root/.ssh/authorized_keys "$(cat "${TRIX_ROOT}/root/.ssh/id_ed25519.pub")"
    chmod 600 /root/.ssh/authorized_keys
fi


echo_info 'Creating the SSH host key pairs'

[[ -e /etc/ssh/ssh_host_rsa_key ]] || \
    ssh-keygen -t rsa -b 4096 -N "" -f /etc/ssh/ssh_host_rsa_key
[[ -e /etc/ssh/ssh_host_ecdsa_key ]] || \
    ssh-keygen -t ecdsa -b 521 -N "" -f /etc/ssh/ssh_host_ecdsa_key
[[ -e /etc/ssh/ssh_host_ed25519_key ]] || \
    ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key


echo_info "Generating the root's private SSH keys"

[[ -e /root/.ssh/id_rsa ]] || \
    ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
[[ -e /root/.ssh/id_ecdsa ]] || \
    ssh-keygen -t ecdsa -b 521 -N "" -f /root/.ssh/id_ecdsa
[[ -e /root/.ssh/id_ed25519 ]] || \
    ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519


echo_info 'Disabling host key check between nodes'

if ! grep -q -- "---  TrinityX ---" /etc/ssh/ssh_config ; then
    cat "${POST_FILEDIR}/ssh_config_extra" >> /etc/ssh/ssh_config
fi


if flag_is_set STDCFG_SSHROOT ; then
    echo_info 'Allowing password-less SSH as root between nodes'
    append_line /root/.ssh/authorized_keys "$(cat /root/.ssh/id_ed25519.pub)"
fi


#---------------------------------------

echo_info "Disabling SELinux"

sed -i 's/\(^SELINUX=\).*/\1disabled/g' /etc/sysconfig/selinux /etc/selinux/config
setenforce 0


#---------------------------------------

echo_info "Disabling firewalld"

systemctl disable firewalld.service


#---------------------------------------

echo_info 'Setting up the controller as DNS server'

cat > /etc/resolv.conf << EOF
# This file was automatically generated by the Trinity X installer

search cluster ipmi
nameserver $TRIX_CTRL_IP
EOF


if flag_is_set STDCFG_CTRL_GATEWAY ; then
    echo_info 'Setting up the controller as default gateway'
    append_line /etc/sysconfig/network "GATEWAY=$TRIX_CTRL_IP"
fi


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


# Run yum update. It's really that simple.

echo_info 'Running yum update'

yum -y update

if flag_is_unset POST_CHROOT ; then
    echo_info 'Restarting some services after the update'

    systemctl daemon-reexec
    systemctl restart dbus polkit sshd systemd-logind
fi


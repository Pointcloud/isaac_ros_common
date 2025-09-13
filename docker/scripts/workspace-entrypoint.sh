#!/bin/bash
#
# Copyright (c) 2021, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

echo "Creating non-root container '${USERNAME}' for host user uid=${HOST_USER_UID}:gid=${HOST_USER_GID}"

if [ ! $(getent group ${HOST_USER_GID}) ]; then
  groupadd --gid ${HOST_USER_GID} ${USERNAME} &>/dev/null
else
  CONFLICTING_GROUP_NAME=`getent group ${HOST_USER_GID} | cut -d: -f1`
  groupmod -o --gid ${HOST_USER_GID} -n ${USERNAME} ${CONFLICTING_GROUP_NAME}
fi

if [ ! $(getent passwd ${HOST_USER_UID}) ]; then
  useradd --no-log-init --uid ${HOST_USER_UID} --gid ${HOST_USER_GID} -m ${USERNAME} &>/dev/null
else
  CONFLICTING_USER_NAME=`getent passwd ${HOST_USER_UID} | cut -d: -f1`
  usermod -l ${USERNAME} -u ${HOST_USER_UID} -m -d /home/${USERNAME} ${CONFLICTING_USER_NAME} &>/dev/null
  mkdir -p /home/${USERNAME}
  # Wipe files that may create issues for users with large uid numbers.
  rm -f /var/log/lastlog /var/log/faillog
fi

# Update 'admin' user
chown ${USERNAME}:${USERNAME} /home/${USERNAME}
echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME}
chmod 0440 /etc/sudoers.d/${USERNAME}
adduser ${USERNAME} video >/dev/null
adduser ${USERNAME} plugdev >/dev/null
adduser ${USERNAME} sudo  >/dev/null

# If jtop present, give the user access
if [ -S /run/jtop.sock ]; then
  JETSON_STATS_GID="$(stat -c %g /run/jtop.sock)"
  addgroup --gid ${JETSON_STATS_GID} jtop >/dev/null
  adduser ${USERNAME} jtop >/dev/null
fi

# Run all entrypoint additions
shopt -s nullglob
for addition in /usr/local/bin/scripts/entrypoint_additions/*.sh; do
  if [[ "${addition}" =~ ".user." ]]; then
    echo "Running entryrypoint extension: ${addition} as user ${USERNAME}"
    gosu ${USERNAME} ${addition}
  else
    echo "Sourcing entryrypoint extension: ${addition}"
    source ${addition}
  fi
done

# Setup colored prompt and terminal preferences
echo 'export PS1="\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/${USERNAME}/.bashrc
echo 'export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=1;31:sg=1;31:tw=1;34:ow=1;34:"' >> /home/${USERNAME}/.bashrc
echo 'alias ls="ls --color=auto"' >> /home/${USERNAME}/.bashrc
echo 'alias grep="grep --color=auto"' >> /home/${USERNAME}/.bashrc
chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

# Restart udev daemon
service udev restart

exec gosu ${USERNAME} "$@"

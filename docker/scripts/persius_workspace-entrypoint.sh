#!/bin/bash
#
# Copyright (c) 2021, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.

# Build ROS dependency
echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
echo "source /workspaces/zed/install/setup.bash" >> ~/.bashrc
source /opt/ros/${ROS_DISTRO}/setup.bash
source /workspaces/zed/install/setup.bash

#Rob adding to update root access to ros
echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc
echo "source /workspaces/zed/install/setup.bash" >> ~/.bashrc
echo 'export PATH=$PATH:/opt/ros/humble/install/bin:/opt/nvidia/tao:/usr/local/cuda/bin' >> /root/.bashrc

sudo apt-get update

# commenting out temporarily until I fix the permissions issue with admin/root
# rosdep update

# Restart udev daemon
sudo service udev restart

$@
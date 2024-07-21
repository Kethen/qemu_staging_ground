#!/bin/bash
#export DISPLAY=""
#export WAYLAND_DISPLAY=""
export LD_PRELOAD=""
export > env_list
bash boot_podman_stage_2.sh 2>&1 | tee log

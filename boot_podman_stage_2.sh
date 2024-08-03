#!/bin/bash

set -xe
IMAGE_NAME="qemu"

if ! podman image $IMAGE_NAME
then
	podman image build -t $IMAGE_NAME -f Dockerfile
fi

XORG=""
if [ "$DISPLAY" != "" ] && [ -d /tmp/.X11-unix ]
then
        XORG="--tmpfs /tmp/.X11-unix"
        if [ -n "$(ls /tmp/.X11-unix/)" ]
        then
                for f in /tmp/.X11-unix/*
                do
                        XORG="$XORG -v $f:$f"
                done
        fi
        XORG="$XORG --env DISPLAY=$DISPLAY"
        if [ -e $HOME/.Xauthority ]
        then
                XORG="$XORG -v $HOME/.Xauthority:/home_dir/.Xauthority"
        fi
fi

WAYLAND=""
if [ "$WAYLAND_DISPLAY" != "" ] && [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]
then
        WAYLAND="-v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        WAYLAND="$WAYLAND --env WAYLAND_DISPLAY=$WAYLAND_DISPLAY --env XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
fi

PULSE=""
if [ -z "$PULSE_SERVER" ]
then
        if [ -S "$XDG_RUNTIME_DIR/pulse/native" ]
        then
                PULSE="-v $XDG_RUNTIME_DIR/pulse/native:/tmp/pulse_socket"
                PULSE="$PULSE --env PULSE_SERVER=/tmp/pulse_socket"
        fi
else
        if [ -S "$PULSE_SERVER" ]
        then
                PULSE="-v $PULSE_SERVER:/tmp/pulse_socket"
                PULSE="$PULSE --env PULSE_SERVER=/tmp/pulse_socket"
        else
                PULSE="--env PULSE_SERVER=$PULSE_SERVER"
        fi
fi

PIPEWIRE=""
if [ -n "$PIPEWIRE_REMOTE" ]
then
        pipewire_socket_name="$PIPEWIRE_REMOTE"
else
        pipewire_socket_name="pipewire-0"
fi

if [ -n "$PIPEWIRE_RUNTIME_DIR" ]
then
        pipewire_runtime_dir="$PIPEWIRE_RUNTIME_DIR"
else
        pipewire_runtime_dir="$XDG_RUNTIME_DIR"
fi

pipewire_socket_path="$pipewire_runtime_dir"/"$pipewire_socket_name"
echo $pipewire_socket_path
if [ -e "$pipewire_socket_path" ]
then
	PIPEWIRE="$PIPEWIRE -v $pipewire_socket_path:/tmp/pipewire_socket"
	PIPEWIRE="$PIPEWIRE --env PIPEWIRE_RUNTIME_DIR=/tmp"
	PIPEWIRE="$PIPEWIRE --env PIPEWIRE_REMOTE=pipewire_socket"
fi

DRI=""
if [ -d /dev/dri ]
then
        DRI="-v /dev/dri:/dev/dri"
        for f in $(ls /dev | grep -E "^nvi")
        do
                DRI="$DRI -v /dev/$f:/dev/$f"
        done
fi
if [ -d /dev/udmabuf ]
then
	DRI="$DRI -v /dev/udmabuf /dev/udmabuf"
fi

INPUT=""
if [ -d /dev/input ]
then
	INPUT="-v /proc/bus/input:/proc/bus/input -v /dev/input:/dev/input"
fi
if ls /dev/hidraw*
then
	for f in /dev/hidraw*
	do
		INPUT="$INPUT -v $f:$f"
	done
fi

KVM=""
if [ -e /dev/kvm ]
then
	KVM="-v /dev/kvm:/dev/kvm"
fi

podman run \
	--rm -it \
	--security-opt label=disable \
	--security-opt seccomp=unconfined \
	--ipc host \
	--net host \
	-v ./:/work_dir \
	-w /work_dir \
	--entrypoint /bin/bash \
	$XORG \
	$WAYLAND \
	$PULSE \
	$PIPEWIRE \
	$DRI \
	$INPUT \
	$KVM \
	$IMAGE_NAME \
	boot_stage_2.sh


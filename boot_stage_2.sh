#!/bin/bash
#PLATFORM="-cpu Skylake-Client-v4"
PLATFORM="-cpu host"
PLATFORM="$PLATFORM -enable-kvm -smp sockets=1,cores=4,threads=1 -m 4G -M q35,i8042=off"
PLATFORM="$PLATFORM -global ICH9-LPC.disable_s3=1 -global ICH9-LPC.disable_s4=1"
PLATFORM="$PLATFORM -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off"

NETWORK="-netdev user,id=eth0"
NETWORK="$NETWORK -device virtio-net,netdev=eth0"

STORAGE="-drive if=none,id=maindisk,format=raw,file=maindisk.img,discard=unmap -object iothread,id=iomaindisk -device virtio-blk,iothread=iomaindisk,drive=maindisk"
#STORAGE="-drive if=virtio,id=maindisk,format=raw,file=maindisk.img,discard=unmap"

USB="-device qemu-xhci"

INPUT="-device virtio-keyboard-pci"
INPUT="$INPUT -device virtio-multitouch-pci"
#INPUT="$INPUT -device usb-mouse"
#INPUT="$INPUT -device usb-tablet"
if false
then
	while read -r LINE; do
		DEVICES=$(echo $LINE | sed 's/^H: Handlers=//' | sed -E 's/js[0-9]+//g')
		for d in $DEVICES
		do
			if [ -n "$(echo $d | grep event)" ]
			then
				INPUT="$INPUT -device virtio-input-host-pci,evdev=/dev/input/$d"
			fi
		done
	done <<< $(cat /proc/bus/input/devices | grep -E 'js[0-9]+' | grep -v mouse | grep -v kbd)
else
	DEVICE_NAME=""
	while read -r LINE; do
		if [ -n "$(echo $LINE | grep 'N: Name=')" ]
		then
			DEVICE_NAME=$(echo $LINE | sed -E 's/N: Name="(.+)"/\1/')
			continue
		fi

		if [ -n "$(echo $LINE | grep 'H: Handlers=')" ]
		then
			if [ -n "$(echo $DEVICE_NAME | grep -E 'Microsoft X-Box 360 pad [0-9]+')" ]
			then
				DEVICES=$(echo $LINE | sed 's/^H: Handlers=//' | sed -E 's/js[0-9]+//g')
				for d in $DEVICES
				do
					INPUT="$INPUT -device virtio-input-host-pci,evdev=/dev/input/$d"
				done

			fi
			continue
		fi
	done <<< $(cat /proc/bus/input/devices)
fi

#AUDIO="-audiodev pa,id=aud,server=$PULSE_SERVER"
#AUDIO="-audiodev alsa,id=aud"
AUDIO="-audiodev pipewire,id=aud"
AUDIO="$AUDIO -device ich9-intel-hda -device hda-micro,audiodev=aud"
#AUDIO="$AUDIO -device usb-audio,audiodev=aud"

#DISP="-display sdl,gl=on"
DISP="-display gtk,gl=on,full-screen=on"
#DISP="-display gtk,gl=es,full-screen=on"
DISP="$DISP -vga none -device virtio-vga-gl,xres=1280,yres=800"

MISC="-nodefaults"
MISC="$MISC -name bliss,debug-threads=on"

QEMU="qemu-kvm"
QEMU="./qemu/build/qemu-system-x86_64"

export vblank_mode=0

#$QEMU $PLATFORM $NETWORK $STORAGE $USB $INPUT $AUDIO $DISP $MISC -cdrom Fedora-Workstation-Live-x86_64-40-1.14.iso -boot d -L /usr/share/seabios -L /usr/share/ipxe/qemu -L /usr/share/qemu -L /usr/share/seavgabios
$QEMU $PLATFORM $NETWORK $STORAGE $USB $INPUT $AUDIO $DISP $MISC -kernel kernel -append 'SRC=/bliss14 DATA=userdata CODEC2_LEVEL=0 FFMPEG_OMX_CODEC=1 VIRT_WIFI=1 OMX_NO_YUV420=1' -initrd initrd.img -L /usr/share/seabios -L /usr/share/ipxe/qemu -L /usr/share/qemu -L /usr/share/seavgabios

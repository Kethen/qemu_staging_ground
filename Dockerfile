FROM fedora:41
RUN dnf install -y qemu-kvm
RUN dnf install -y clang gcc make git SDL2-devel pulseaudio-libs-devel alsa-lib-devel libnfs-devel ncurses-devel spice-protocol spice-server-devel libjpeg-devel brlapi-devel glusterfs-api-devel gtk3-devel vte291-devel gettext bzip2-devel libtasn1-devel libcacard-devel virglrenderer-devel capstone-devel libudev-devel pam-devel liburing-devel libzstd-devel hostname daxctl-devel fuse-devel pipewire-jack-audio-connection-kit-devel fuse3-devel SDL2_image-devel pipewire-devel keyutils-libs-devel libxdp-devel glibc-static glib2-static zlib-static pcre2-static pcre-static ninja-build flex bison bzip2 libslirp-devel rutabaga-gfx-ffi-devel weston gfxstream-devel



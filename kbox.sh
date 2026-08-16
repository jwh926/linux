#!/usr/bin/env bash
#
# Build this kernel tree inside an Apple `container` VM.
# The VM is arm64, so this is a native build -- no cross compiler.
#
#   ./kbox.sh                 argument-less default: Image/bzImage modules
#   ./kbox.sh defconfig
#   ./kbox.sh menuconfig
#   ./kbox.sh Image
#   ./kbox.sh clean
#   ./kbox.sh shell           interactive shell in the build environment
#
# Target architecture:
#   ./kbox.sh -a x86_64 defconfig     cross-compile for x86_64
#   ./kbox.sh --arch arm64 Image
# Without -a/--arch the host architecture is detected and the build is
# native. Objects land in /build/<arch>/ so architectures don't collide.
#
# Everything is out-of-tree: objects live on a `container volume` (VM-local
# ext4, persistent across runs), not on virtiofs -- compiles aren't throttled
# by host round-trips, and the source tree stays clean. The cost: artifacts
# are only reachable through the container, e.g.
#   ./kbox.sh shell -c 'cp /build/arm64/arch/arm64/boot/Image /src/'
#
# Overridable:  CPUS=10 JOBS=10 MEM=8g VOL=kbox-build ./kbox.sh Image
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VOL="${VOL:-kbox-build}"
VOLSIZE="${VOLSIZE:-64G}"
IMAGE="${IMAGE:-kbox}"
CPUS="${CPUS:-4}"
MEM="${MEM:-4g}"
JOBS="${JOBS:-$CPUS}"

usage() {
	cat <<EOF
Usage: ./kbox.sh [-a <arch>] [make targets...]
       ./kbox.sh shell [command...]

Builds this kernel tree inside an Apple \`container\` VM.
With no targets, builds the kernel image and modules.

Options:
  -a, --arch <arch>   Target architecture: arm64 or x86_64
                      (default: host architecture, native build)
  -h, --help          Show this help

Common targets:
  defconfig           Initialize .config
  menuconfig          Edit .config (needs a TTY)
  Image / bzImage     Kernel image only (arm64 / x86_64)
  fs/ext4/            Compile a single directory
  clean               Remove objects, keep .config
  mrproper            Remove everything including .config

Environment overrides (current defaults):
  CPUS=$CPUS JOBS=$JOBS MEM=$MEM IMAGE=$IMAGE
  VOL=$VOL VOLSIZE=$VOLSIZE  (build-output volume, objects in /build/<arch>)

Examples:
  ./kbox.sh defconfig && ./kbox.sh
  ./kbox.sh -a x86_64 defconfig && ./kbox.sh -a x86_64
  CPUS=10 JOBS=10 MEM=8g ./kbox.sh Image
EOF
}

# Pull -a/--arch out of the arguments; everything else passes through to make.
arch=""
args=()
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-a | --arch)
		[ $# -ge 2 ] || { echo "kbox: $1 requires an argument" >&2; exit 1; }
		arch="$2"
		shift 2
		;;
	--arch=*)
		arch="${1#--arch=}"
		shift
		;;
	*)
		args+=("$1")
		shift
		;;
	esac
done
set -- ${args[@]+"${args[@]}"}

# The VM's architecture matches the host, so native vs cross is decided by
# comparing the requested arch against `uname -m`.
host_arch="$(uname -m)"
case "$host_arch" in
arm64 | aarch64) host_arch=arm64 ;;
x86_64 | amd64) host_arch=x86_64 ;;
esac

arch="${arch:-$host_arch}"
case "$arch" in
arm64 | aarch64)
	arch=arm64
	default_image=Image
	cross_prefix=aarch64-linux-gnu-
	;;
x86_64 | amd64 | x86)
	arch=x86_64
	default_image=bzImage
	cross_prefix=x86_64-linux-gnu-
	;;
*)
	echo "kbox: unsupported arch '$arch' (supported: arm64, x86_64)" >&2
	exit 1
	;;
esac

cross=""
if [ "$arch" != "$host_arch" ]; then
	cross="$cross_prefix"
fi

OUT="/build/$arch"

if ! container volume inspect "$VOL" >/dev/null 2>&1; then
	printf '==> creating build volume "%s" (%s, sparse; first run only)\n' "$VOL" "$VOLSIZE" >&2
	container volume create -s "$VOLSIZE" "$VOL"
fi

if ! container image inspect "$IMAGE" >/dev/null 2>&1; then
	printf '==> building toolchain image "%s" (first run only)\n' "$IMAGE" >&2
	container build -t "$IMAGE" -f "$SRC/.kbox/Dockerfile" "$SRC/.kbox"
fi

# menuconfig and `shell` need a TTY; a piped/CI build must not ask for one.
tty=()
if [ -t 0 ] && [ -t 1 ]; then
	tty=(-it)
fi

if [ "${1-}" = shell ]; then
	shift
	set -- bash "$@"
else
	if [ $# -eq 0 ]; then
		set -- "$default_image" modules
	fi
	set -- make -C /src O="$OUT" -j"$JOBS" \
		ARCH="$arch" ${cross:+CROSS_COMPILE="$cross"} "$@"
fi

# bash 3.2 (the macOS default) treats "${tty[@]}" on an empty array as unset
# under `set -u`, so guard the expansion.
exec container run --rm ${tty[@]+"${tty[@]}"} \
	--cpus "$CPUS" --memory "$MEM" \
	-v "$SRC:/src" \
	-v "$VOL:/build" \
	"$IMAGE" "$@"

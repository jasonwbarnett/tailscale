#!/usr/bin/env sh
#
# Runs `go build` with flags configured for binary distribution. All
# it does differently from `go build` is burn git commit and version
# information into the binaries, so that we can track down user
# issues.
#
# If you're packaging Tailscale for a distro, please consider using
# this script, or executing equivalent commands in your
# distro-specific build system.

set -eu

go="go"
if [ -n "${TS_USE_TOOLCHAIN:-}" ]; then
	go="./tool/go"
fi

eval `CGO_ENABLED=0 GOOS=$($go env GOHOSTOS) GOARCH=$($go env GOHOSTARCH) $go run ./cmd/mkversion`


VERSION_LONG="${VERSION_SHORT}-udm-pro"

tags=""
ldflags="-X tailscale.com/version.longStamp=${VERSION_LONG} -X tailscale.com/version.shortStamp=${VERSION_SHORT}"

# build_dist.sh arguments must precede go build arguments.
while [ "$#" -gt 1 ]; do
	case "$1" in
	--extra-small)
		shift
		ldflags="$ldflags -w -s"
		tags="${tags:+$tags,}ts_omit_aws,ts_omit_bird,ts_omit_tap,ts_omit_kube"
		;;
	--box)
		shift
		tags="${tags:+$tags,}ts_include_cli"
		;;
	*)
		break
		;;
	esac
done

GOARCH=arm64 GOOS=linux $go build ${tags:+-tags=$tags} -ldflags "$ldflags" tailscale.com/cmd/tailscale
GOARCH=arm64 GOOS=linux $go build ${tags:+-tags=$tags} -ldflags "$ldflags" tailscale.com/cmd/tailscaled

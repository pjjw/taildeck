#!/usr/bin/env bash

set -ex

TS_VER=1.22.0
TS_ROOT="${HOME}/.local/share/tailscale"
TS_PATH="${TS_ROOT}/tailscale_${TS_VER}_amd64"

mkdir -p ${TS_ROOT}
cd ${TS_ROOT}

if [ ! -d "${TS_PATH}" ]; then
    curl -o tailscale_1.22.0_amd64.tgz https://pkgs.tailscale.com/stable/tailscale_1.22.0_amd64.tgz
    tar zxf tailscale_1.22.0_amd64.tgz
fi

sudo systemctl stop tailscaled.service ||:
sudo systemd-run \
    --service-type=notify \
    --description="Tailscale node agent" \
    -u tailscaled.service \
    -p ExecStartPre="${HOME}/.local/share/tailscale/tailscale_1.22.0_amd64/tailscaled --cleanup" \
    -p ExecStopPost="${HOME}/.local/share/tailscale/tailscale_1.22.0_amd64/tailscaled --cleanup" \
    -p Restart=on-failure \
    -p RuntimeDirectory=tailscale \
    -p RuntimeDirectoryMode=0755 \
    -p StateDirectory=tailscale \
    -p StateDirectoryMode=0700 \
    -p CacheDirectory=tailscale \
    -p CacheDirectoryMode=0750 \
    "${HOME}/.local/share/tailscale/tailscale_1.22.0_amd64/tailscaled" \
    "--state=/var/lib/tailscale/tailscaled.state" \
    "--socket=/run/tailscale/tailscaled.sock"

sudo ${TS_PATH}/tailscale up
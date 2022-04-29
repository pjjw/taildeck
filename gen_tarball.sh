#!/usr/bin/env nix-shell
#! nix-shell -p curl -p jq -p nix -i bash

set -euo pipefail

version="$(curl https://pkgs.tailscale.com/stable/?mode=json | jq .Tarballs.amd64 -r)"
url="https://pkgs.tailscale.com/stable/${version}"
shasum="$(nix-prefetch-url "${url}")"

rm -f tarball.nix
echo "{
  version = \"$(echo ${version} | cut -d_ -f2)\";
  tarball = builtins.fetchurl {
    url = \"${url}\";
    sha256 = \"${shasum}\";
  };
}" >> tarball.nix

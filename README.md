# taildeck

A bunch of hacks to install Tailscale on a steam deck

## Building

```
nix build .#image
```

## Updating

```
./gen_tarball.sh
```

## Installing

If you have a steam deck, try this and see if it works:

```
mkdir -p ~/.local/share/tailscale/steamos
sudo mkdir -p /etc/extensions
curl -o ~/.local/share/tailscale/steamos/tailscale_sysext_1.24.2.raw https://xena.greedo.xeserv.us/pkg/ts-sysext/tailscale_sysext_1.24.2.raw
sudo ln -s ~/.local/share/tailscale/steamos/tailscale_sysext_1.24.2.raw /etc/extensions/tailscale.raw
sudo systemd-sysext merge
sudo systemctl enable --now tailscaled.service
sudo tailscale up --qr
```

If you see what I'm doing wrong, please [let me
know](https://pony.social/@cadey).

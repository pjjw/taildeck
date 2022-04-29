{
  description = "A basic Go web server setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              go = prev.go_1_18;
              buildGoModule = prev.buildGo118Module;
            })
          ];
        };
        version = builtins.substring 0 8 self.lastModifiedDate;
      in {
        packages = rec {
          imagebuilder = pkgs.buildGoModule {
            pname = "taildeck-imagebuilder";
            inherit version;
            src = ./.;

                        vendorSha256 =
              "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
          };

          tsTarball = builtins.fetchurl {
            url = "https://pkgs.tailscale.com/stable/tailscale_1.24.2_amd64.tgz";
            sha256 = "1b697g694vigzmv5q48l1d3pjc9l5gwzazggnfi7z9prb9cvlnx2";
          };

          image = pkgs.stdenv.mkDerivation {
            pname = "tailscale-image";
            version = "1.24.2";
            buildInputs = with pkgs; [ squashfsTools imagebuilder ];
            phases = "installPhase";

            installPhase = ''
              mkdir -p $out
              taildeck --out $out --tarball ${tsTarball}
            '';
          };
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ go gopls gotools go-tools squashfsTools ];
        };
      });
}

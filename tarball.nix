{
  version = "1.24.2";
  tarball = builtins.fetchurl {
    url = "https://pkgs.tailscale.com/stable/tailscale_1.24.2_amd64.tgz";
    sha256 = "1b697g694vigzmv5q48l1d3pjc9l5gwzazggnfi7z9prb9cvlnx2";
  };
}

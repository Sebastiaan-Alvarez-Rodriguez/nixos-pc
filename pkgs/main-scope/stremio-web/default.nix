{ pkgs ? import <nixpkgs> {} }:

pkgs.buildNpmPackage rec {
  pname = "stremio-web";
  version = "5.0.0-beta.26";

  src = pkgs.fetchFromGitHub {
    owner = "Stremio";
    repo = "stremio-web";
    rev = "v${version}";
    hash = "sha256-UQX54ngv5LYtumD3CMCHfvCVoslwvHP7Q+RLWw/qaGs="; # Temporary placeholder
  };

  npmDepsHash = "sha256-Pe8HI5ruDZ/RAR26JrSt0Gl84dV4icviqvjuGbu05aI="; # Will be filled after build failure

  installPhase = ''
    mkdir -p $out
    cp -r dist/* $out/
  '';

  meta = with pkgs.lib; {
    description = "Stremio Web UI (self-hostable)";
    homepage = "https://github.com/Stremio/stremio-web";
    license = licenses.gpl2;
    platforms = platforms.all;
  };
}

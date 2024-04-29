{ lib, stdenv, fetchFromGitHub }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "spotify-adblock";
  version = "1.0.2";
  src = pkgs.fetchFromGitHub {
    owner = "abba23";
    repo = "spotify-adblock";
    rev = "v${version}";
    sha256 = "YGD3ymBZ2yT3vrcPRS9YXcljGNczJ1vCvAXz/k16r9Y=";
  };

  cargoSha256 = "bYqkCooBfGeHZHl2/9Om+0qbudyOCzpvwMhy8QCsPRE=";
}

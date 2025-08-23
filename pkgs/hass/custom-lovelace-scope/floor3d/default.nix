{ lib, stdenvNoCC, fetchurl }: stdenvNoCC.mkDerivation rec {
  pname = "floor3d-card";
  version = "1.5.3";

  # src = fetchFromGitHub {
  #   owner = "adizanni";
  #   repo = "floor3d-card";
  #   rev = "v${version}";
  #   hash = lib.fakeHash;
  # };
  # NOTE: has a yarn.lock... Need to make package-lock.json to build from source

  src = fetchurl {
    url = "https://github.com/adizanni/floor3d-card/releases/download/v.1.5.3/floor3d-card.js";
    hash = "sha256-Cl56wDo1ubHMm8+07OUOwdnt/uYj9VQHgERYJ8LKBds=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    cp $src $out/floor3d-card.js
  '';

  meta = {
    description = "Custom card to render 3d floorplans.";
    homepage = "https://github.com/adizanni/floor3d-card";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}

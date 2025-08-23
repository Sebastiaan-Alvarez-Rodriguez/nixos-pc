{ lib, stdenvNoCC, fetchurl }: stdenvNoCC.mkDerivation rec {
  pname = "house-model";
  version = "1.0.0";

  src = ./model.glb;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    cp $src $out/model.glb
  '';

  meta = {
    description = "sweethome3d model";
    platforms = lib.platforms.all;
  };
}

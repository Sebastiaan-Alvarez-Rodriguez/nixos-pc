{ lib, stdenvNoCC, fetchurl }: stdenvNoCC.mkDerivation rec {
  pname = "house-model";
  version = "1.0.0";

  src = ./model.glb;
  # NOTE: created like so:
  # 1. construct house in sweet home 3d application (tip: import floor plan as 2d background image, then add outer walls, then inner walls, then furniture, repeat for every floor)
  # 2. set 3d viewer to a nice angle
  # 3. export as obj file
  #
  # ```
  # nix-shell -p nodejs
  # mkdir node_modules
  # npm install obj2gltf
  # ./node_modules/obj2gltf/bin/obj2gltf.js --checkTransparency -i main.obj -o main.glb
  # ```

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

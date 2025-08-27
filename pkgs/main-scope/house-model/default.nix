{ lib, stdenvNoCC, fetchurl }: stdenvNoCC.mkDerivation rec {
  pname = "house-model";
  version = "1.0.0";

  src = ./model.glb;
  # Create a model like so:
  # 0. install plugin for sweet home 3d: https://github.com/adizanni/ExportToHASS (read instructions there on how to do that)
  # 1. construct house in sweet home 3d application (tip: import floor plan as 2d background image, then add outer walls, then inner walls, then furniture, repeat for every floor)
  #    > **NOTE**: Do set object IDs by filling in furniture names. The object IDs can be found in step 4 by searching `home.json` from the zipfile.
  #    > **NOTE**: When building the model, every time you remove furniture, somehow the name --> object_id conversion does not work for all furniture which is a 'light' and exists at the moment of 1 furniture removal.
  #      All furniture added after this one removal seems to work fine again. You can cut and paste all furniture to rectify all furniture object ids again.
  # 2. set 3d viewer to a nice angle
  # 3. tools > Export obj to HASS
  # 4. Unpack the produced zipfile, and then convert the contained obj file to 'glb' format for improved performance
  # ```
  # nix-shell -p nodejs
  # mkdir node_modules
  # npm install obj2gltf
  # ./node_modules/obj2gltf/bin/obj2gltf.js --checkTransparency -i model.obj -o model.glb
  # ```
  # NOTE: better use this plugin, because then the rendered model has a level selector in the top left corner (otherwise not).
  # 
  # NOTE: Previously created like so:
  # 1. construct house in sweet home 3d application (tip: import floor plan as 2d background image, then add outer walls, then inner walls, then furniture, repeat for every floor)
  # 2. set 3d viewer to a nice angle
  # 3. 3D View > export to obj format
  # 4. like step 4 above (converting obj file to 'glb' format)

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

{ lib, pkgs, ... }: let
  # custom-pkgs = import "${self}/pkgs" {
  #   pkgs = import inputs.nixpkgs { inherit system; };
  # };
  # custom-pkgs = nixpkgs.extend (self: super: {
  #   custom-pkgs = import "${self}/pkgs" {
  #     pkgs = import nixpkgs {
  #       inherit system;
  #       # seb: TODO define overlays again here?
  #     };
  #   };
  # });
in {
  # custompkgs = lib.recurseIntoAttrs (pkgs.callPackage "${self}/pkgs" { inherit lib pkgs; });
  custompkgs = lib.recurseIntoAttrs (pkgs.callPackage ../pkgs { inherit lib pkgs; });
}
  # import "${self}/pkgs" {
  #   pkgs = import nixpkgs {
  #     inherit system;
  #     # seb: TODO define overlays again here?
  #   };
  # };
  # lib.filterPackages system (lib.flattenTree custom-pkgs)

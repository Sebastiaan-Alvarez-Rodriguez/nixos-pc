{ inputs, config, lib, pkgs, system, ...}: let
  username = "rdn";
in {
  imports = [ ../rdn/rdn-headless.nix ../rdn/default.nix ];

  home.packages = with pkgs; [ stremio ];

  services.kanshi.settings = [
    {
      profile.name = "undocked";
      profile.outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          mode = "2560x1440@60Hz";
          position = "0,0";
        }
      ];
    }
  ];
}

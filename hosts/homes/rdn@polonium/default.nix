{ inputs, config, lib, pkgs, system, ...}: let
  username = "rdn";
in {
  imports = [ ../rdn/rdn-headless.nix ];

  home.packages = with pkgs; [
    chromium
    drawio
    droidcam
    galculator
    gamemode
    gparted
    hotspot
    # logiops
    nheko
    proton-caller
    qbittorrent
    tdesktop
    teams-for-linux
    teamspeak_client
    tor-browser-bundle-bin
    vlc
  ];

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

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
    proton-caller
    rustdesk-flutter
    qbittorrent
    stremio
    tdesktop
    teams-for-linux
    teamspeak3
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

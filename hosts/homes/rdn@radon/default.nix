{ inputs, config, lib, pkgs, system, ...}: let
  username = "rdn";
in {
  imports = [ ../rdn/rdn-headless.nix ];

  home.packages = with pkgs; [
    adbfs-rootless
    android-studio
    chromium
    drawio
    droidcam
    galculator
    gamemode
    gparted
    hotspot
    jetbrains.idea-community
    # logiops
    nheko
    proton-caller
    qbittorrent
    tdesktop
    teams-for-linux
    teamspeak_client
    teamviewer
    tor-browser-bundle-bin
    virt-manager # ui manager for vm's
    vlc
  ];

  services.kanshi.settings = [
    {
      profile.name = "home";
      profile.outputs = [
        {
          criteria = "DP-1";
          status = "enable";
          mode = "2560x1440@144Hz";
          position = "0,0";
        }
        {
          criteria = "DP-2";
          status = "enable";
          mode = "1920x1080@144Hz";
          position = "2560,200";
        }
      ];
    }
  ];
}

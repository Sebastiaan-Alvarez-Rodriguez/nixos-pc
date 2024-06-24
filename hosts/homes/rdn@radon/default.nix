{ inputs, config, lib, pkgs, ...}: let
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
    river # seb: TODO move to river pkg.
    tdesktop
    # inputs.nixpkgs.outputs.legacyPackages.x86_64-linux.tdesktop # seb: TODO why can this not be found?
    teams-for-linux
    teamspeak_client
    teamviewer
    # tor-browser-bundle-bin # seb: TODO why can this not be found?
    virt-manager # ui manager for vm's
    vlc
  ];



  programs.foot.settings.main.monitor-scale = "eDP-1:1, 27GL850:1.7, G2460:1.6, QROM8HA000914:1.5";

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

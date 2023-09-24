{ inputs, config, lib, pkgs, ...}: let
  username = "rdn";
in {
  imports = [ ./rdn-headless.nix ../graphical.nix ];

  home.packages = let
    pkgs_2205 = inputs.nixpkgs_2205.outputs.legacyPackages.x86_64-linux;
  in with pkgs; [
    pkgs_2205.remmina
    drawio
    droidcam
    galculator
    jetbrains.idea-community
    nheko
    qbittorrent
    # sublime4 # removed because of openssl 1.1.0 dependency
    tdesktop
    tidal-hifi
    teams
    teamspeak_client
    tor-browser-bundle-bin
    virt-manager # ui manager for vm's
    vlc
  ];

  accounts.email = {
    accounts.gmail = {
      address = "sebastiaanalva@gmail.com";
      gpg = {
        key = null;
        signByDefault = true;
      };

      smtp.tls.useStartTls = true;

      primary = true;
      flavor = "gmail.com";
    };
  };

  programs.swaybg-dynamic.images = ../../res/background;
  programs.swaybg-dynamic.selection = "random-boot";
  programs.swaybg-dynamic.interval = "10s";

  programs.foot.settings.main.monitor-scale = "eDP-1:1, 27GL850:1.7, G2460:1.6, QROM8HA000914:1.5";

  services.kanshi.profiles = {
    undocked = {
      outputs = [
        {
          criteria = "eDP-1";
          status = "enable";
          mode = "2560x1440@60Hz";
          position = "0,0";
        }
      ];
    };
  };
  programs.thunderbird.profiles."${username}" = {
    isDefault = true;
    withExternalGnupg = false;
  };
}
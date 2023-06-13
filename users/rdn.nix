{ inputs, config, lib, pkgs, ...}: let
  username = "rdn";
in {
  imports = [ ./graphical.nix ];

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
    teams
    teamspeak_client
    tor-browser-bundle-bin
    virt-manager # ui manager for vm's
    vlc
  ];
  home.username = username;
  home.homeDirectory = "/home/${username}";

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

  programs.swaybg.image = ../res/background/neon_rain_3840x2160.jpg;

  programs.git.userName = "Sebastiaan-Alvarez-Rodriguez";
  programs.git.userEmail = "sebastiaanalva@gmail.com";

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

  programs.ssh.matchBlocks = {
    "github.com" = {
      user = "Sebastiaan-Alvarez-Rodriguez";
      identityFile = "~/.ssh/github.rsa";
      identitiesOnly = true;
    };
    "cobra" = {
      user = "sebastiaan";
      hostname = "pythons.space";
      identityFile = "~/.ssh/cobra_sebastiaan.rsa";
      identitiesOnly = true;
    };
  };
}
{ inputs, config, lib, pkgs, spicetify-nix, ...}: let
  username = "rdn";
  spicetify-nix = inputs.spicetify-nix.outputs.packages.x86_64-linux;
  spicePkgs = inputs.spicetify-nix.outputs.packages.${pkgs.system}.default;
in {
  imports = [ inputs.spicetify-nix.outputs.homeManagerModule ./rdn-headless.nix ../graphical.nix ];

  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    # theme = spicePkgs.themes.SpotifyNoPremium; //Same as default spotify but without ads and anything related to getting premium
    enabledExtensions = with spicePkgs.extensions; [adblock];
    
  };
  home.packages = let
    pkgs_2205 = inputs.nixpkgs_2205.outputs.legacyPackages.x86_64-linux;
  in with pkgs; [
    pkgs_2205.remmina
    adbfs-rootless
    android-studio
    drawio
    droidcam
    galculator
    gamemode
    jetbrains.idea-community
    logiops
    nheko
    proton-caller
    qbittorrent
    # spicetify-cli
    # spotify
    tdesktop
    teams-for-linux
    teamspeak_client
    teamviewer
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

  programs.thunderbird.profiles."${username}" = {
    isDefault = true;
    withExternalGnupg = false;
  };

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
}

{ lib, ... }: {
  imports = [
    ./bat
    ./bitwarden
    ./bluetooth
    ./editor
    ./firefox
    ./gdb
    ./gpg
    ./gm
    ./gtk
    ./librewolf
    ./mail
    ./mpv
    ./nix
    ./nix-index
    ./nm-applet
    ./packages
    ./power-alert
    ./spotify
    ./ssh
    ./terminal
    ./wm
    ./xdg
    ./zathura
    ./zen-browser
  ];

  home.stateVersion = lib.mkForce "24.05";
}

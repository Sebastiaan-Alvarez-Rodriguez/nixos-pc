{ lib, ... }: {
  imports = [
    ./bat
    ./bitwarden
    ./bluetooth
    ./browser
    ./editor
    ./gdb
    ./gpg
    ./gm
    ./gtk
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
  ];

  home.stateVersion = lib.mkForce "24.05";
}

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
    ./power-alert
    ./spotify
    ./ssh
    ./stylix
    ./terminal
    ./wm
    ./xdg
    ./zathura
  ];

  home.stateVersion = lib.mkForce "24.05";
}

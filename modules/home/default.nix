{ ... }: {
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

  home.stateVersion = "24.05";

  # # Start services automatically # seb: NOTE commented below line.
  # systemd.user.startServices = "sd-switch";
}

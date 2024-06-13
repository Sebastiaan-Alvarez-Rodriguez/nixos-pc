{ ... }: {
  imports = [ # seb: TODO check all items in this list.
    ./bat
    ./bitwarden
    ./bluetooth
    ./firefox
    ./gdb
    ./gpg
    ./gm
    ./gtk
    ./mail
    ./mpv
    ./nix
    ./nix-index
    ./nixpkgs
    ./nm-applet
    ./packages
    ./pager
    ./power-alert
    ./secrets
    ./spotify
    ./ssh
    ./terminal
    ./udiskie
    ./vim
    ./wget
    ./wm
    ./xdg
    ./zathura
  ];

  home.stateVersion = "24.05";

  # # Start services automatically # seb remove
  # systemd.user.startServices = "sd-switch";
}

{ ... }: {
  imports = [
    ./bat
    ./bitwarden
    ./bluetooth
    ./firefox
    ./gdb
    ./gpg
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
    ./ssh
    ./tmux
    ./udiskie
    ./vim
    ./wget
    ./wm
    ./x
    ./xdg
    ./zathura
    ./zsh
  ];

  home.stateVersion = "24.05";

  # # Start services automatically # seb remove
  # systemd.user.startServices = "sd-switch";
}

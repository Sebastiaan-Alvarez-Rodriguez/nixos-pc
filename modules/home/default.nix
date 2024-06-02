{ ... }:
{
  imports = [
    ./bat
    ./bitwarden
    ./bluetooth
    ./documentation
    ./feh
    ./firefox
    ./flameshot
    ./fzf
    ./gammastep
    ./gdb
    ./gpg
    ./gtk
    ./htop
    ./jq
    ./keyboard
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
    ./terminal
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

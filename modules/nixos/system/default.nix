# System-related modules
{ ... }:  {
  imports = [
    ./boot
    ./docker
    ./gm
    ./nix
    ./packages
    ./podman
    ./polkit
    ./printing
  ];
}

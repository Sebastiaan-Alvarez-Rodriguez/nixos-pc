# System-related modules
{ ... }:  {
  imports = [
    ./boot
    ./docker
    ./nix
    ./packages
    ./podman
    ./polkit
    ./printing
  ];
}

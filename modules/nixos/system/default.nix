# System-related modules
{ ... }:

{
  imports = [
    ./boot
    ./docker
    ./documentation
    ./language
    ./nix
    ./packages
    ./podman
    ./polkit
    # ./printing # seb: use once needed
    ./users
  ];
}

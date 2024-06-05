# System-related modules
{ ... }:  {
  imports = [
    ./boot # seb TODO: get below modules in shape.
    ./docker # seb TODO: get below modules in shape.
    ./documentation # seb TODO: get below modules in shape.
    ./nix
    ./packages
    ./podman # seb TODO: get below modules in shape.
    ./polkit # seb TODO: get below modules in shape.
    ./printing
    ./users # seb TODO: get below modules in shape.
  ];
}

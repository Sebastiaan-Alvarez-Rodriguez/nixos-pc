# Hardware-related modules
{ ... }: {
  imports = [
    ./bluetooth
    ./firmware
    ./graphics
    ./networking
    ./sound
    ./upower
  ];
}

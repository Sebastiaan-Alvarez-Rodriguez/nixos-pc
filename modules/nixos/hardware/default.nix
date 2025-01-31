# Hardware-related modules
{ ... }: {
  imports = [
    ./bluetooth
    ./fancontrol
    ./firmware
    ./graphics
    ./networking
    ./sound
    ./upower
  ];
}

# Configuration that spans accross system and home, or are almagations of modules
{ ... }: {
  imports = [
    ./bluetooth
    ./gtk
    ./laptop
    ./wm
    ./x
  ];
}

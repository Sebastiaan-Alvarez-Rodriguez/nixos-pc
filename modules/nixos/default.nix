# Common modules
{ lib, ... }: {
  imports = [
    ./hardware
    ./home
    ./profiles
    ./programs
    ./services
    # ./../../secrets # seb TODO: Enable once done configuring basics.
    ./system
  ];
}

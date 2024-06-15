# Common modules
{ lib, ... }: {
  imports = [
    ./hardware
    ./home
    ./profiles
    ./programs
    ./services
    ./../../secrets
    ./system
  ];
}

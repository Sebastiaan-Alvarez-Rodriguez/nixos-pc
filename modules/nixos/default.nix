# Common modules
{ lib, system, ... }: {
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

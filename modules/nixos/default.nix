# Common modules
{ lib, ... }: {
  imports = [
    ./hardware
    ./home
    ./programs
    ./services
    ./../../secrets
    ./system
  ];
}

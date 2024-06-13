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

  options.my = with lib; { # seb: TODO remove this stuff, I don't want it. (multi-user support where are you)
    user = {
      name = mkOption {
        type = types.str;
        description = "my username";
      };

      home = {
        enable = my.mkDisableOption "home-manager configuration";
      };
    };
  };
}

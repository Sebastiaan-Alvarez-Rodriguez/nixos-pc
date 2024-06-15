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
  options.my = with lib; { # seb TODO: remove me
    user = {
      name = mkOption {
        type = types.str;
        default = "ambroisie";
        example = "alice";
        description = "my username";
      };

      home = {
        enable = my.mkDisableOption "home-manager configuration";
      };
    };
  };
}

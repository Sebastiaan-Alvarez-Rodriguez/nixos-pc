{ config, lib, pkgs, ... }: let
  cfg = config.my.home.bitwarden;
in {
  options.my.home.bitwarden = with lib; {
    enable = mkEnableOption "bitwarden configuration";
    pinentry = mkPackageOption pkgs "pinentry" { default = [ "pinentry-tty" ]; };
    mail = mkOption {
      type = types.str;
      example = "a@b.com";
    }
  };

  config = lib.mkIf cfg.enable {
    programs.rbw = {
      enable = true;

      settings = {
        email = cfg.mail;
        inherit (cfg) pinentry;
      };
    };
  };
}

{ config, lib, pkgs, ... }: let
  cfg = config.my.home.gpg;
in {
  options.my.home.gpg = with lib; {
    enable = mkEnableOption "gpg configuration";
    pinentry = mkPackageOption pkgs "pinentry" { default = [ "pinentry-tty" ]; };
  };

  config = lib.mkIf cfg.enable {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true; # One agent to rule them all
      pinentryPackage = cfg.pinentry;
      extraConfig = ''
        allow-loopback-pinentry
      '';
    };

    home.shellAliases = {
      # Sometime `gpg-agent` errors out...
      reset-agent = "gpg-connect-agent updatestartuptty /bye";
    };
  };
}

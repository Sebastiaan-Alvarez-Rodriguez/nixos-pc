{ config, lib, pkgs, ... }: let
  cfg = config.my.home.bitwarden;
in {
  options.my.home.bitwarden = with lib; {
    enable = mkEnableOption "bitwarden configuration";
    pinentry = mkPackageOption pkgs "pinentry" { default = [ "pinentry-tty" ]; };
    mail = mkOption {
      type = types.str;
      example = "a@b.com";
      description = "The email address to use as the account name when logging into the Bitwarden server.";
    };
    base_url = mkOption {
      type = types.str;
      example = "my.domainname.com";
      description = "Domainname for bitwarden server. Set to 'official' server at 'https://api.bitwarden.com/' if you won't host your own server.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.rbw = {
      enable = true;
      settings = {
        email = cfg.mail;
        base_url =  cfg.base_url;
        sync_interval = 1800; # sync after 1800 seconds.
        # lock_timeout = 36000; # keep master keys in memory for the entire session.
        inherit (cfg) pinentry;
      };
    };
  };
}

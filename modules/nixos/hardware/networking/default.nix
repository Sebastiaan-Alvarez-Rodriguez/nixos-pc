{ config, lib, ... }: let
  cfg = config.my.hardware.networking;
in {
  options.my.hardware.networking = with lib; {
    enable = mkEnableOption "networking configuration";

    hostname = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Name of host";
    };

    domain = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Domain name this server hosts for.";
      example = "test.com";
    };

    block-trackers = mkEnableOption "block common trackers";

    wireless.enable = mkEnableOption "wireless configuration";
  };

  config = lib.mkIf cfg.enable {
    networking = lib.mkMerge [
      {
        useDHCP = false; # Deprecated. Explicitly set to false here, to mimic future standard behavior.
        hostName = lib.mkIf (cfg.hostname != null) cfg.hostname;
        domain = lib.mkIf (cfg.domain != null) cfg.domain;
        networkmanager.enable = lib.mkIf cfg.wireless.enable true;
      }
      (lib.mkIf cfg.block-trackers { # seb TODO: to setup this stuff professionally, use: https://github.com/StevenBlack/hosts
        extraHosts = ''
          0.0.0.0 connect.facebook.net
          0.0.0.0 datadome.co
          0.0.0.0 usage.trackjs.com
          0.0.0.0 googletagmanager.com
          0.0.0.0 firebaselogging-pa.googleapis.com
          0.0.0.0 redshell.io
          0.0.0.0 api.redshell.io
          0.0.0.0 treasuredata.com
          0.0.0.0 api.treasuredata.com
          0.0.0.0 in.treasuredata.com
          0.0.0.0 cdn.rdshll.com
          0.0.0.0 t.redshell.io
          0.0.0.0 innervate.us
        '';
      })
      (lib.mkIf cfg.wireless.enable {
        networkmanager.enable = true;
      })
    ];
  };
}

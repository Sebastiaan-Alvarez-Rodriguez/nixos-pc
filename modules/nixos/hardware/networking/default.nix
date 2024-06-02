{ config, lib, ... }:
let
  cfg = config.my.hardware.networking;
in
{
  options.my.hardware.networking = with lib; {
    enable = mkEnableOption "networking configuration";

    hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of host";
    };

    block-trackers = lib.mkDisableOption "block common trackers";

    wireless = {
      enable = mkEnableOption "wireless configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = lib.mkMerge [
    {
      networkmanager.enable = true;
      useDHCP = false; # Deprecated. Explicitly set to false here, to mimic future standard behavior.
      hostname = lib.mkIf cfg.hostname cfg.hostname;
    }
    (lib.mkIf cfg.block-trackers {
      extraHosts = ''
        0.0.0.0  connect.facebook.net
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
      networkmanager.enable = cfg.wireless;
    })
  ];
}

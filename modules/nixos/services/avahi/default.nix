# A m-DNS server, which allows applications to advertise servicesy other LAN clients 
{ config, lib, ... }: let
  cfg = config.my.services.avahi;
in {
  options.my.services.avahi = with lib; {
    enable = mkEnableOption "avahi mDNS";
    host = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Hostname part used in advertisements (<hostname>.<domain>)";
      example = "h";
    };
    domain = mkOption {
      type = types.str;
      default = "local";
      description = "Domainname part used in advertisements (<hostname>.<domain>)";
      example = "mijn.place";
    };

    allow-interfaces = mkOption {
      type = with types; nullOr (listOf str);
      default = null;
      description = "List of network interfaces that should be used by avahi to advertise. If `null`, all local interfaces except loopback and point-to-point will be used.";
    };
  };
    
  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = true;
        # nssmdns = true;
        publish.enable = true; # otherwise services cannot publish themselves
        publish.userServices = true;

        hostName = cfg.host;
        domainName = cfg.domain;
        # hostName = config.my.hardware.networking.domain;
        # domainName = config.my.hardware.networking.domain;
        allowInterfaces = cfg.allow-interfaces;
        openFirewall = true; # NOTE: this opens 5353 udp. Ensure no WAN traffic can enter here.
      };
      dbus.enable = true; # for configuring new services through dbus
      # seb NOTE: dbus does not appear happy: https://github.com/eworm-de/pacredir/issues/1#issuecomment-1085017998
      # I could manually create a service config for snapserver and provide it here?
    };
  };
}

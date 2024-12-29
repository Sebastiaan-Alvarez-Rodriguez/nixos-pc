# A vnc server

# configure clients:
# The 'Server ID' field: enter <url>:port of signal server, e.g. hbbs.example.com:21116
# THe 'Key' field: enter the key found at /var/lib/private/rustdesk/id_ed25519.pub
# the other fields can be left blank.

{ config, lib, ... }: let
  cfg = config.my.services.rustdesk;
  domain-prefix = "desk";
  signal-domain-prefix = "signal.${domain-prefix}";
  relay-domain-prefix = "relay.${domain-prefix}";
in {
  options.my.services.rustdesk = with lib; {
    enable = mkEnableOption "rustdesk remote support server";

    enforce-key = mkOption {
      type = types.bool;
      default = true;
      description = "If set, enforces use of set keys (for encrypted comms). Clients without the proper key cannot connect. This keeps random's well away from the server."
    };
    signal-port = mkOption {
      type = types.port;
      default = 21116;
      description = "Listen port for signal server";
    };
    relay-port = mkOption {
      type = types.port;
      default = 21117;
      description = "Listen port for relay server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.rustdesk-server = {
      enable = true;
      openFirewall = false; # we manually do this below
      signal = {
        enable = true; # servers/clients make themselves known on the signal server 
        relayHosts = [ "127.0.0.1:${builtins.toString cfg.relay-port}" ];
        extraArgs = ["-p" (builtins.toString cfg.signal-port) ] ++ lib.optionals cfg.enforce-key [  "-k" "_" ];
      };
      
      relay = {
        enable = true; # if server-client connections are not possible directly, a relay server is used to reroute traffic.
        extraArgs = ["-p" (builtins.toString cfg.relay-port) ] ++ lib.optionals cfg.enforce-key [  "-k" "_" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ 
      21115 # signal server (extra port for NAT tests)
      cfg.signal-port
      cfg.relay-port
      21118 # signal websocket
      21119 # relay websocket
    ];
    networking.firewall.allowedUDPPorts = [ cfg.signal-port ];

    # my.services.backup.paths = [ cfg.backup-path ]; seb TODO: backup of anything?
    # my.services.nginx.virtualHosts.${signal-domain-prefix} = {
    #   inherit (cfg) signal-port;
    #   useACMEHost = config.networking.domain;

    #   extraConfig = {
    #     extraConfig = ''
    #       proxy_buffering off;
    #       proxy_send_timeout 330s;
    #       proxy_read_timeout 330s;
    #     '';
    #     locations."/".proxyWebsockets = true;
    #   };
    # };
  };
}

# A vnc server

# configure clients:
# 'Server ID' field: enter url or ip address of signal server, e.g. hbbs.example.com
# 'Relay server' field: enter the same as in 'Server ID'
# 'Key' field: enter the key found at /var/lib/private/rustdesk/id_ed25519.pub
# All other fields can be left blank.

# if the machine is not supposed to be taken over, enable 'IP whitelist', with only '127.0.0.1' in the whitelist.
# if the machine should be taken over unattended, configure a 'permanent password'. Depending on the device type (android, windows, linux,...) ensure the application has all permissions to run in the background.

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
      description = "If set, enforces use of set keys (for encrypted comms). Clients without the proper key cannot connect. This keeps random's well away from the server.";
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
    private-keyfile = mkOption {
      type = types.str;
      description = "path to file containing secret-key to verify & encrypt connections to this rustdesk network. Only verified when `rustdesk.enforce-key` is set.";
    };
    public-keyfile = mkOption {
      type = types.str;
      description = "path to file containing public-key to join this rustdesk network. Only verified when `rustdesk.enforce-key` is set.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = config.users.users ? "rustdesk"; }
      { assertion = config.users.groups ? "rustdesk"; }
    ];
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

    networking.firewall = {
      allowedTCPPorts = [ 
        21115 # signal server (extra port for NAT tests)
        cfg.signal-port
        cfg.relay-port
        21118 # signal websocket
        21119 # relay websocket
      ];
      allowedUDPPorts = [ cfg.signal-port ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/private 0700 root root -"
      "d /var/lib/private/rustdesk 0750 rustdesk rustdesk -"
      "L+ /var/lib/rustdesk/id_ed25519 - - - - ${cfg.private-keyfile}"
      "L+ /var/lib/rustdesk/id_ed25519.pub - - - - ${cfg.public-keyfile}"
    ];

    # private: ?
    # public : -rw-r--r-- rustdesk rustdesk
  };
}

# declarative music assistant
# to use with snapcast, make snapcast listen for tcp requests, because [that is how music-assistant sends audio to it](https://github.com/SantiagoSotoC/music-assistant-server/blob/c6b2cb04414e192ba22c9ad00fcbcbc412a55cb8/music_assistant/providers/snapcast/__init__.py#L648)
#
# Configuration
# Configure snapcast:
# - goto advanced settings
# - enable existing snapserver
# - set ip to my.services.snapserver.json-rpc.tcp.bind_to_address
# - set control port to the configured my.services.snapserver.json-rpc.tcp.port
# 
# Intel
# interesting shairport cfg:
# https://github.com/OptimoSupreme/nixos-configs/blob/main/server/shairport-management-sync.nix
# it seems there may be an issue with external snapcast player - https://github.com/music-assistant/support-management/issues/3740

# note: `DEEZER` provider does not work because it needs you to have a non-free account.

{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.music-assistant;
  # unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  ip-host = "10.0.2.2";
  ip-local = "10.0.2.3";
  # container forwardport rules make these ports unusable on the host (rerouting traffic even before filtering to the container). Best to not use them elsewhere, and to not expose them to the wan.
  dnat-port-webui-mass = 65000;
  dnat-port-webui-snap = 65001;
  dnat-port-snap-conn = 65002;
in {
  options.my.services.music-assistant = with lib; {
    enable = mkEnableOption "music-assistant service";

    ports = {
      webui-mass = mkOption {
        type = types.port;
        default = 8095; # normally 8095
        description = "UI port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
      };
      webui-snapserver = mkOption {
        type = types.port;
        default = 9003; # normally 1780
        description = "UI port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
      };
      snapclient-connections = mkOption {
        type = types.port;
        default = 9001; # normally 1704
        description = "UI port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
      };
    };

    config-path = mkOption {
      type = types.str;
      default = "/var/lib/music-assistant/";
      description = "Location where '.music-assistant' config directory is located. Note: Ensure this directory exists on the host";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    providers = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Extra music assistant providers to load (see https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/mu/music-assistant/providers.nix)";
    };

    extra-settings = mkOption {
      type = with types; attrs;
      default = {};
      description = "Extra settings for the 'settings'.json of music assistant.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.ports.snapclient-connections != 1704; message = "Port 1704 must be used by the container for DNAT iptable forwarding. You cannot use this port on this host since the DNAT would reroute the packets to the container directly (to ipv4 instead of ipv6, too)"; }
    ];
    containers.mass = let
      hass-enabled = config.my.services.home-assistant.enable;
      jellyfin-enabled = config.my.services.jellyfin.enable;
    in {
      autoStart = true;
      ephemeral = true;
      bindMounts."/var/lib/private/music-assistant" = { hostPath = cfg.config-path; isReadOnly = false; }; # mirror config path on the host
      privateNetwork = true;
      hostAddress = ip-host;
      localAddress = ip-local;
      # extraFlags = [ "-U" ]; # seb NOTE: cannot drop root permissions for container because "Failed to set up special execution directory in /var/lib: Operation not permitted. Failed at step STATE_DIRECTORY"
      forwardPorts = [
        { # for web-ui of Music-assistant
          containerPort = 8095; # NOTE: must be 8095, since this is not configurable from nixos.
          hostPort = dnat-port-webui-mass;
          protocol = "tcp";
        }
        { # for web-ui of Snapserver
          containerPort = 1780; # NOTE: must be 1780, since this is not configurable from nixos.
          hostPort = dnat-port-webui-snap;
          protocol = "tcp";
        }
        { # for snapserver-to-snapclient communications (snapclient players register themselves here)
          containerPort = 1704; # NOTE: must be 1704, since this is not configurable from nixos.
          hostPort = dnat-port-snap-conn;
          protocol = "tcp";
        }
      ];

      config = { config, pkgs, ... }: {
        services.music-assistant = {
          enable = true;
          providers = cfg.providers ++ lib.optionals hass-enabled [ "hass" "hass_players" ] ++ lib.optional jellyfin-enabled "jellyfin";
          extraOptions = [ "--log-level" "DEBUG" ];
          package = pkgs.music-assistant;
        };

        environment.systemPackages = [ pkgs.nettools pkgs.dig ]; # for debugging

        networking.useHostResolvConf = lib.mkForce false; # otherwise it would use the hosts resolvconf, which will not work
        # (i.e. entries like 127.0.0.1 when having host-local dns will just error out on the container-local interface)

        networking.nameservers = [ ip-host "1.1.1.1" "9.9.9.9" "8.8.8.8" ];
        networking.firewall.allowedTCPPorts = [ 8095 1704 1780 ];
        system.stateVersion = "25.11";
      };
    };
    # below does NAT for container, i.e. container gets access to enp2s0=internet
    networking.nat.enable = true;
    networking.nat.internalInterfaces = [ "ve-mass" ];
    networking.nat.externalInterface = "enp2s0";

    services.home-assistant.extraComponents = [ "music_assistant" ];

    my.services.avahi.extra-service-files = {
      snapcast = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">Snapcast on %h</name>

          <service>
            <type>_snapcast._tcp</type>
            <port>${toString cfg.ports.snapclient-connections}</port>
          </service>

          <service>
            <type>_snapcast-stream._tcp</type>
            <port>${toString cfg.ports.snapclient-connections}</port>
          </service>
        </service-group>
      '';
    };
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.config-path ]; };

    my.services.nginx.streams = {
      "${toString cfg.ports.snapclient-connections}" = {
        destination = "[::ffff:${ip-host}]:${toString dnat-port-snap-conn}";
        type = "tcp";
        local-only = true;
      };
      "[::]:${toString cfg.ports.snapclient-connections}" = {
        destination = "[::ffff:${ip-host}]:${toString dnat-port-snap-conn}";
        type = "tcp";
        local-only = true;
      };
    };
    # ''
    #   server {
    #     listen ${toString cfg.ports.snapclient-connections};
    #     proxy_pass [::ffff:${ip-host}]:1704;
    #   }
    #   server {
    #     listen [::]:${toString cfg.ports.snapclient-connections};
    #     proxy_pass 
    #   }
    # ''; # seb TODO: make local-only configurable

    my.services.nginx.virtualHosts.ma = {
      port = cfg.ports.webui-mass;
      local-only = true;

      extraConfig.locations."/" = {
        proxyPass = "http://${ip-host}:${toString dnat-port-webui-mass}/";
        proxyWebsockets = true;
      };
    };
    my.services.nginx.virtualHosts.snapserver = {
      port = cfg.ports.webui-snapserver;
      local-only = true;
      extraConfig.locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://${ip-host}:${toString dnat-port-webui-snap}/";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.ports.snapclient-connections ];
  };
}

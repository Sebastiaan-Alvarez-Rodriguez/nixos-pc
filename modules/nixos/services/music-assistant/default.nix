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
    containers.music-assistant = let
      hass-enabled = config.my.services.home-assistant.enable;
      jellyfin-enabled = config.my.services.jellyfin.enable;
    in {
      autoStart = true;
      ephemeral = true;
      bindMounts."/var/lib/private/music-assistant" = { hostPath = cfg.config-path; isReadOnly = false; }; # mirror config path on the host
      privateNetwork = true;
      hostAddress = ip-host;
      localAddress = ip-local;
      forwardPorts = [
        { # for web-ui of Music-assistant
          containerPort = 8095; # NOTE: must be 8095, since this is not configurable from nixos.
          hostPort = cfg.ports.webui-mass;
          protocol = "tcp";
        }
        { # for web-ui of Snapserver
          containerPort = 1780; # NOTE: must be 1780, since this is not configurable from nixos.
          hostPort = cfg.ports.webui-snapserver;
          protocol = "tcp";
        }
        { # for snapserver-to-snapclient communications (snapclient players register themselves here)
          containerPort = 1704; # NOTE: must be 1704, since this is not configurable from nixos.
          hostPort = cfg.ports.snapclient-connections;
          protocol = "tcp";
        }
        # { # for mDNS, for service announcement of snapserver so that snapclient players know where to connect to snapserver.
        #   containerPort = 5353;
        #   hostPort = 5353;
        #   protocol = "udp";
        # }
      ];

      config = { config, pkgs, ... }: {
        # systemd.tmpfiles.rules = [ "d ${cfg.config-path} 700 mass mass -" ]; # create config dir in container
        services.music-assistant = {
          enable = true;
          providers = cfg.providers ++ lib.optionals hass-enabled [ "hass" "hass_players" ] ++ lib.optional jellyfin-enabled "jellyfin";
          # extraOptions = [ "--config" cfg.config-path "--log-level" "DEBUG" ];
          extraOptions = [ "--log-level" "DEBUG" ];
          package = pkgs.music-assistant;
        };

        # seb TODO: this does not stop entities binding on tcp6!
        networking.enableIPv6 = false;
        boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;

        environment.systemPackages = [ pkgs.nettools ]; # for debugging

        networking.firewall.allowedTCPPorts = [ 8095 1704 1780 ];
        system.stateVersion = "25.11";
      };
    };

    # services.music-assistant = {
    #   enable = true;
    #   providers = cfg.providers ++ lib.optionals config.my.services.home-assistant.enable [ "hass" "hass_players" ] ++ lib.optional config.my.services.jellyfin.enable "jellyfin";
    #   extraOptions = [ "--config" cfg.config-path "--log-level" "DEBUG" ];
    #   package = pkgs.music-assistant;
    # };
    # systemd.services.music-assistant = {
    #   path = let
    #     base = [ pkgs.lsof ] ++ lib.optionals (builtins.elem "spotify" cfg.providers) [ inputs.nixpkgs-unstable.legacyPackages.${system}.librespot-ma ]; # seb TODO: just use 'pkgs' once nixos 25.11 rolls out.
    #   in base ++ lib.optional (builtins.elem "snapcast" cfg.providers) config.services.snapserver.package;
    # };


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
        </service-group>
      '';
    };

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.config-path ]; };

    my.services.nginx.streamConfig = ''
      server {
        listen ${toString cfg.ports.snapclient-connections};
        proxy_pass ${ip-host}:${toString cfg.ports.snapclient-connections};
      }
    '';

    my.services.nginx.virtualHosts.ma = {
      port = cfg.ports.webui-mass;
      local-only = true;

      extraConfig.locations."/" = {
        proxyPass = "http://${ip-host}:${toString cfg.ports.webui-mass}/";
        proxyWebsockets = true;
      };
    };
    my.services.nginx.virtualHosts.snapserver = {
      port = cfg.ports.webui-snapserver;
      local-only = true;
      extraConfig.locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://${ip-host}:${toString cfg.ports.webui-snapserver}/";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.ports.snapclient-connections ];
  };
}

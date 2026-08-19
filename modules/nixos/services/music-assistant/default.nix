# declarative music assistant
# to use with snapcast, make snapcast listen for tcp requests, because [that is how music-assistant sends audio to it](https://github.com/SantiagoSotoC/music-assistant-server/blob/c6b2cb04414e192ba22c9ad00fcbcbc412a55cb8/music_assistant/providers/snapcast/__init__.py#L648)
#
# Configuration
# Configure snapcast - built-in server:
# Just add it, don't change anything, press ok.
# 
# Configure snapcast - external server:
# - goto advanced settings
# - enable existing snapserver
# - set ip to my.services.snapserver.json-rpc.tcp.bind_to_address
# - set control port to the configured my.services.snapserver.json-rpc.tcp.port
# 
# Configure spotify:
# - first go to settings > system > webserver and change from whatever ip address to the url you access with, e.g. ma.<host>
# - go to settings > music sources > add source > spotify
# - just authenticate (to ensure you stay within timeouts, first login to spotify in another tab, then click authenticate)
# - with playback authorization, pick the 'web' version. If you are not returned / timeouts etc, just copy the full spotify url and paste it into the input url box below the authorize button options
# - go to developer.spotify.com, log in with regular spotify credentials.
# - make a new project
# - copy the client id
# - paste in the last input box from spotify
# - save everything

{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.music-assistant;
in {
  options.my.services.music-assistant = with lib; {
    enable = mkEnableOption "music-assistant service";

    package = mkOption {
      type = types.package;
      default = pkgs.music-assistant;
      description = "package to use";
    };

    ports = {
      webui-mass = mkOption {
        type = types.port;
        default = 8095; # normally 8095
        description = "UI port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
      };
      webui-snapserver = mkOption {
        type = types.port;
        default = 1780; # normally 1780 (cannot change what the built-in snapserver of MA listens to)
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
      default = [ ];
      description = "Extra music assistant providers to load (see https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/mu/music-assistant/providers.nix)";
    };

    extra-settings = mkOption {
      type = with types; attrs;
      default = {};
      description = "Extra settings for the 'settings'.json of music assistant.";
    };
  };

  config = let
    hass-enabled = config.my.services.home-assistant.enable;
    jellyfin-enabled = config.my.services.jellyfin.enable;
    default-required-providers = []; #[ "sendspin" "local_audio" ]; # do not use it now, it crashes the build (especially local_audio)
  in lib.mkIf cfg.enable {
    # new setup: snapclient-connections (9001) -(nginx stream)-> 1704 (still has local-only protection) 
    # new setup: 80/443 -(nginx virtualhosts)-> 1780 (ma now has login. Stil could do local-only)
    # new setup: 80/443 -(nginx virtualhosts)-> 8095 (snap still is insecure, REQUIRE local-only (or not expose, we only use it to rename devices, which may be possible from MA as well now))

    services.music-assistant = {
      enable = true;
      providers = cfg.providers ++ default-required-providers ++ lib.optionals hass-enabled [ "hass" "hass_players" ] ++ lib.optional jellyfin-enabled "jellyfin";
      package = cfg.package;
    };
    services.home-assistant.extraComponents = [ "music_assistant" ];

    # send advertisements for music-assistant port.
    my.services.avahi.extra-service-files = {
      snapcast = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">Snapcast</name>

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
        destination = "[::ffff:127.0.0.1]:1704";
        type = "tcp";
        local-only = true;
      };
      "[::]:${toString cfg.ports.snapclient-connections}" = {
        destination = "[::ffff:127.0.0.1]:1704";
        type = "tcp";
        local-only = true;
      };
    };

    my.services.nginx.virtualHosts.ma = {
      port = cfg.ports.webui-mass;
      local-only = true;
      extraConfig.locations."/".proxyWebsockets = true;
    };
    my.services.nginx.virtualHosts.snapserver = {
      port = cfg.ports.webui-snapserver;
      local-only = true;
      extraConfig.locations."/" = {
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
    networking.firewall.allowedTCPPorts = [ cfg.ports.snapclient-connections ]; # must listen for snapcast devices
  };
}

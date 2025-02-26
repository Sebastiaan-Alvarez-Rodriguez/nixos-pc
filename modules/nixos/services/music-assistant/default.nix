# declarative MA
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.music-assistant;
in {
  options.my.services.music-assistant = with lib; {
    enable = mkEnableOption "music-assistant service";
    port = mkOption {
      type = types.port;
      default = 3345;
      description = "Port for music-assistant web interface (note: does not have authentication, keep on LAN)";
    };

    config-path = mkOption {
      type = types.str;
      default = "/var/lib/music-assistant/";
      description = "Location where '.music-assistant' config directory is located";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Restic backup routes to use for this data.";
    };

    providers = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Extra music assistant addons to load";
    };
  };

  config = lib.mkIf cfg.enable {
    services.music-assistant = {
      enable = true;
      providers = cfg.providers ++ lib.optionals config.my.services.home-assistant.enable [ "hass" "hass_players" ] ++ lib.optional config.my.services.jellyfin.enable "jellyfin";
      extraOptions = [ "--config" cfg.config-path ];
    };

    services.home-assistant.extraComponents = [ "music_assistant" ];
  
    systemd.tmpfiles.rules = [
      "d ${cfg.config-path} 0755 music-assistant music-assistant -"
    ];

    # seb: TODO is this enough of a backup?
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ "${cfg.config-path}/.musicassistant" ]; };

    # seb: NOTE there is no login system at all. We should not expose this thing to the internet... Perhaps we can generate the required configuration, and then skip the webui altogether (or local-bind it).
    my.services.nginx.virtualHosts.ma = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;

      extraConfig = {
        extraConfig = ''
        allow 192.168.0.0/24;
        deny all;
        ''; # NOTE: this config instructs nginx reverse proxy to only accept local requests.
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
  ## sample config of 'settings.json'
  # {
  #   "server_id": "0bf55f81af9b418e9608e64ca915ab44",
  #   "providers": {
  #     "fanarttv--KHtzmV52": {
  #       "values": {},
  #       "type": "metadata",
  #       "domain": "fanarttv",
  #       "instance_id": "fanarttv--KHtzmV52",
  #       "enabled": true,
  #       "name": "fanart.tv",
  #       "last_error": null
  #     },
  #     "builtin--URJ8TW87": {
  #       "values": {},
  #       "type": "music",
  #       "domain": "builtin",
  #       "instance_id": "builtin--URJ8TW87",
  #       "enabled": true,
  #       "name": "Music Assistant",
  #       "last_error": null
  #     },
  #     "theaudiodb--pkbEUFfw": {
  #       "values": {},
  #       "type": "metadata",
  #       "domain": "theaudiodb",
  #       "instance_id": "theaudiodb--pkbEUFfw",
  #       "enabled": true,
  #       "name": "The Audio DB",
  #       "last_error": null
  #     },
  #     "musicbrainz--EWcUAerU": {
  #       "values": {},
  #       "type": "metadata",
  #       "domain": "musicbrainz",
  #       "instance_id": "musicbrainz--EWcUAerU",
  #       "enabled": true,
  #       "name": "MusicBrainz",
  #       "last_error": null
  #     }
  #   },
  #   "core": {
  #     "metadata": {
  #       "values": {
  #         "language": "en_US"
  #       },
  #       "domain": "metadata",
  #       "last_error": null
  #     },
  #     "webserver": {
  #       "values": {
  #         "bind_ip": "192.168.0.16"
  #       },
  #       "domain": "webserver",
  #       "last_error": null
  #     }
  #   }
  # }
}

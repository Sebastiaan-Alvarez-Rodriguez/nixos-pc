# declarative music assistant
# to use with snapcast, make snapcast listen for tcp requests, because [that is how music-assistant sends audio to it](https://github.com/SantiagoSotoC/music-assistant-server/blob/c6b2cb04414e192ba22c9ad00fcbcbc412a55cb8/music_assistant/providers/snapcast/__init__.py#L648)
#
# Intel
# interesting shairport cfg:
# https://github.com/OptimoSupreme/nixos-configs/blob/main/server/shairport-sync.nix
# it seems there may be an issue with external snapcast player - https://github.com/music-assistant/support/issues/3740

# note: error `(MainThread) [music_assistant.webserver] Error handling message: config/providers/get_entries: [Errno 2] No such file or directory: 'snapserver'`
# maybe because of providers/snapcast__init__.py:129 (if there is no `snapserver` found in env)... although expected other output 'command not found'

{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.music-assistant;
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in {
  options.my.services.music-assistant = with lib; {
    enable = mkEnableOption "music-assistant service";

    # bind-interface = mkOption {
    #   type = types.str;
    #   default = "0.0.0.0";
    #   description = "base_url for webserver";
    # }
    port = mkOption {
      type = types.port;
      default = 8095;
      description = "Port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
    }; # seb TODO: make port nixos-configurable if possible, or remove this option. For now, it only works if 8095 is used.

    config-path = mkOption {
      type = types.str;
      default = "/var/lib/music-assistant/";
      description = "Location where '.music-assistant' config directory is located";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    providers = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Extra music assistant addons to load";
    };

    extra-settings = mkOption {
      type = with types; attrs;
      default = {};
      description = "Extra settings for the 'settings'.json of music assistant.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = "snapcast" ? cfg.providers -> config.my.services.snapserver.enable;
        message = "To use snapcast integration, enable the snapserver on this host using `config.my.services.snapserver.enable = true;`";
      }
    ];
    services.music-assistant = {
      enable = true;
      providers = cfg.providers ++ lib.optionals config.my.services.home-assistant.enable [ "hass" "hass_players" ] ++ lib.optional config.my.services.jellyfin.enable "jellyfin";
      extraOptions = [ "--config" cfg.config-path "--log-level" "DEBUG" ];
      package = unstable.music-assistant;
    };

    systemd.services.music-assistant.path = lib.optional (builtins.elem "snapcast" cfg.providers) config.services.snapserver.package;

    services.home-assistant.extraComponents = [ "music_assistant" ];
  
    systemd.tmpfiles.rules = let
      f = pkgs.writeText "config.json" (builtins.toJSON (lib.recursiveUpdate
        {
          server_id = "8f3e479bc9ac416a9d07b8a0ba4deb13";
          providers = {
            builtin--RKeSqDHn = {
              values = {};
              type = "music";
              domain = "builtin";
              instance_id = "builtin--RKeSqDHn";
              enabled = true;
              name = "Music Assistant";
              last_error = null;
            };
            fanarttv--Sjgft6XD = {
              values = {};
              type = "metadata";
              domain = "fanarttv";
              instance_id = "fanarttv--Sjgft6XD";
              enabled = true;
              name = "fanart.tv";
              last_error = null;
            };
            theaudiodb--DxpRa6ZL = {
              values = {};
              type = "metadata";
              domain = "theaudiodb";
              instance_id = "theaudiodb--DxpRa6ZL";
              enabled = true;
              name = "The Audio DB";
              last_error = null;
            };
            musicbrainz--3AaBdBZd = {
              values = {};
              type = "metadata";
              domain = "musicbrainz";
              instance_id = "musicbrainz--3AaBdBZd";
              enabled = true;
              name = "MusicBrainz";
              last_error = null;
            };
          }; # TODO: maybe I should not hardcode the id's, and builtin plugins... But it makes the system definitely more configurable / reproducible.
          core = {
            metadata = {
              values.language = "en_US";
              domain = "metadata";
              last_error = null;
            };
            webserver = {
              values = {
                base_url = "https://ma.${config.networking.domain}";
                bind_port = cfg.port;
              };
              domain = "webserver";
              last_error = null;
            };
          };
        }
        cfg.extra-settings
      ));
    in [
      "d ${cfg.config-path} 0755 music-assistant music-assistant -"
      "L+ ${cfg.config-path}/settings.json - - - - ${f}"
      "z ${cfg.config-path}/settings.json 0644 root root - -" # seb TODO: symlink is removed by MA, changing link perms does not matter.
      # "L+ ${cfg.config-path}/settings.json.backup - - - - ${f}"
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
  #         "values": {
  #           "base_url": "http://192.168.0.16:8099",
  #           "bind_port": 8099
  #         },
  #       "domain": "webserver",
  #       "last_error": null
  #     }
  #   }
  # }

  # {"core":{
  #  "metadata":{"domain":"metadata","last_error":"null","values":{"language":"en_US"} }
  #  "webserver":{"domain":"webserver","last_error":"null","values":{"base_url":"https://ma.h.mijn.place","bind_port":8095}}
  #}
  # ,"providers":{"builtin--RKeSqDHn":{"domain":"builtin","enabled":true,"instance_id":"builtin--RKeSqDHn","last_error":"null","name":"Music Assistant","type":"music","values":{}}
  # ,"fanarttv--Sjgft6XD":{"domain":"fanarttv","enabled":true,"instance_id":"fanarttv--Sjgft6XD","last_error":"null","name":"fanart.tv","type":"metadata","values":{}}
  # ,"musicbrainz--3AaBdBZd":{"domain":"musicbrainz","enabled":true,"instance_id":"musicbrainz--3AaBdBZd","last_error":"null","name":"MusicBrainz","type":"metadata","values":{}}
  # ,"theaudiodb--DxpRa6ZL":{"domain":"theaudiodb","enabled":true,"instance_id":"theaudiodb--DxpRa6ZL","last_error":"null","name":"The Audio DB","type":"metadata","values":{}}}
  # ,"server_id":"8f3e479bc9ac416a9d07b8a0ba4deb13"}
  
}

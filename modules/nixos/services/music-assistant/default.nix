# declarative music assistant
# to use with snapcast, make snapcast listen for tcp requests, because [that is how music-assistant sends audio to it](https://github.com/SantiagoSotoC/music-assistant-server/blob/c6b2cb04414e192ba22c9ad00fcbcbc412a55cb8/music_assistant/providers/snapcast/__init__.py#L648)
#
# Intel
# interesting shairport cfg:
# https://github.com/OptimoSupreme/nixos-configs/blob/main/server/shairport-management-sync.nix
# it seems there may be an issue with external snapcast player - https://github.com/music-assistant/support-management/issues/3740

# note: `DEEZER` provider does not work because it needs you to have a non-free account.
# note: error `(MainThread) [music_assistant.webserver] Error handling message: config/providers/get_entries: [Errno 2] No such file or directory: 'snapserver'`
# maybe because of providers/snapcast__init__.py:129 (if there is no `snapserver` found in env)... although expected other output 'command not found'

{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.music-assistant;
  # unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in {
  options.my.services.music-assistant = with lib; {
    enable = mkEnableOption "music-assistant service";

    port = mkOption {
      type = types.port;
      default = 8095;
      description = "UI port for music-assistant web interface (note: only listens to connections from 192.168.0.0/24 so a global-facing port can be used)";
    }; # seb TODO: make port nixos-configurable if possible, or remove this option. For now, it only works if 8095 is used.

    port-free = {
      start = mkOption {
        type = types.port;
        description = "start of free port range. The free range is used to deliver audio to client implementations as needed (e.g. streaming to a 'snapserver' when using snapcast integration).";
      };
      end = mkOption {
        type = types.port;
        description = "end of free port range. The free range is used to deliver audio to client implementations as needed (e.g. streaming to a 'snapserver' when using snapcast integration).";
      };

      # current (2025) facts:
      # must use < 0.30 snapserver
      # The docs about it: https://github.com/badaix/snapcast/blob/develop/doc/json_rpc_api/control.md#streamaddstream
      # (check different release versions)
    };

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
      description = "Extra music assistant providers to load (see https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/mu/music-assistant/providers.nix)";
    };

    extra-settings = mkOption {
      type = with types; attrs;
      default = {};
      description = "Extra settings for the 'settings'.json of music assistant.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = let
      abs = a: (if a < 0 then -a else a);
    in if abs(cfg.port-free.end - cfg.port-free.start) < 20 then [ "Having less than 20 ports for music-assistant may result in buggy behavior, as it does not cleanly reuse ports." ] else [];
    assertions = [ { assertion = "snapcast" ? cfg.providers -> config.my.services.snapserver.enable; message = "To use snapcast integration, enable the snapserver on this host using `config.my.services.snapserver.enable = true;`"; } ];

    services.music-assistant = {
      enable = true;
      providers = cfg.providers ++ lib.optionals config.my.services.home-assistant.enable [ "hass" "hass_players" ] ++ lib.optional config.my.services.jellyfin.enable "jellyfin";
      extraOptions = [ "--config" cfg.config-path "--log-level" "DEBUG" ];
      # package = unstable.music-assistant.override { librespot = pkgs.librespot; }; # seb NOTE: using librespot 0.5.0 because librespot 0.6.0 complains:
      # package = unstable.music-assistant;
      package = pkgs.music-assistant;

    };

    systemd.services.music-assistant = {
      path = let
        base = [ pkgs.lsof ] ++ lib.optionals (builtins.elem "spotify" cfg.providers) [ pkgs.librespot ];
      in base ++ lib.optional (builtins.elem "snapcast" cfg.providers) config.services.snapserver.package;
      environment.SNAPSERVER_STREAM_PORT_START = toString cfg.port-free.start; 
      environment.SNAPSERVER_STREAM_PORT_END = toString cfg.port-free.end; 
    };

    services.home-assistant.extraComponents = [ "music_assistant" ];
  
    # seb: TODO is this enough of a backup?
    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.config-path ]; };

    my.services.nginx.virtualHosts.ma = {
      port = cfg.port;
      useACMEHost = config.networking.domain;
      # local-only = true;

      extraConfig = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.port}/";
          proxyWebsockets = true;
          # local-only = true;
          extraConfig = ''
            allow 192.168.0.16/24;
            deny all;
          '';
        };
        # seb TODO spotify callback idea:
        # 1. I can only add complete urls as callback.
        # 2. music assistant wants to use <url>/callback/<session-id of auth_helper> (which changes every time)
        # 3. Because of 1, I need some intermediary to basically accept <session-id> as a get-param and forward to the right url.
        # 4. music-assistant.io/callback appears to do that, but: it changes my full url to an ip.
        # 5. it must stay a full url.
        # 6. TODO try: maybe change the state param?
        locations."/callback" = lib.mkIf ((builtins.elem "deezer" cfg.providers) || (builtins.elem "spotify" cfg.providers)) { # needed for authentication URLs
          proxyPass = "http://127.0.0.1:8097";
        };
      };
    };
  };
}

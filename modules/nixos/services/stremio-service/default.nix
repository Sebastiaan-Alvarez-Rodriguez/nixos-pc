# Get full features when watch movies/series using the stremio web ui.
# Useful for e.g. ipads, which do not have a stremio app providing all features.

# seb TODO: provide some form of security so random's cannot use this server
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.stremio-service;
in {
  options.my.services.stremio-service = with lib; {
    enable = mkEnableOption "stremio-service for getting a fully-featured web experience. Needed to e.g. download torrents";

    package = mkOption {
      type = types.package;
      # default = inputs.self.packages.${system}.stremio-service;
      default = pkgs.stremio;
      description = "Package to use";
    };

    port = mkOption {
      type = types.port;
      default = 11470; # port has to be 11470 (for http) or 12470 (for https), cannot be modified... "just use docker bro". https://github.com/Stremio/stremio-service/issues/43
      description = "Internal port for stremio-service";
    };

    web-ui-address = mkOption {
      type = types.str;
      default = "";
      description = "address of custom web ui, if you run one. If not, just leave empty.";
    };

    settings = mkOption {
      type = with types; attrs;
      default = {};
      example = {
        cacheSize = 2*1024*1024*1024; # 2gb cache by default
        btMaxConnections = 55;
      };
      description = "Extra settings to provide.";
    };

    state-dir = mkOption {
      type = types.str;
      default = "stremio-service";
      description = "Directory under `/var/lib` for storing stremio-service files";
    };
  };

  config = let
    final-state-dir = "/var/lib/${cfg.state-dir}";
  in lib.mkIf cfg.enable {
    users.users.stremio = {
      description = "stremio service";
      home = final-state-dir;
      group = "stremio";
      isSystemUser = true;
    };
    users.groups.stremio = { };
    systemd.services.stremio-service = {
      description = "stremio-service - for a fully-featured web experience with stremio";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NO_CORS = "1";
        CASTING_DISABLED="1"; # no need to search for cast-capable devices, as a server.
      };
      path = with pkgs; [ ffmpeg ps ];
      serviceConfig = {
        User = "stremio";
        Group = "stremio";
        ExecStart = "${cfg.package}/opt/stremio/node ${cfg.package}/opt/stremio/server.js --webui-url='${lib.escapeShellArg cfg.web-ui-address}' -platform offscreen"; # this forces Qt to not render.
        DynamicUser = false;
        StateDirectory = cfg.state-dir;
        WorkingDirectory = final-state-dir;
        ReadWritePaths = "";
      };
    };

    systemd.tmpfiles.rules = let
      settings-file = pkgs.writeText "server-settings.json" (builtins.toJSON ({
        serverVersion = "4.20.8"; # NOTE: should match server json file.
        appPath = "${final-state-dir}/.stremio-server";
        cacheRoot = "${final-state-dir}/.stremio-server";
        cacheSize = 2*1024*1024*1024; # 2gb cache by default
        btMaxConnections = 55;
        btHandshakeTimeout = 20000;
        btRequestTimeout = 4000;
        btDownloadSpeedSoftLimit = 2621440;
        btDownloadSpeedHardLimit = 3670016;
        btMinPeersForStable = 5;
        remoteHttps = "";
        localAddonEnabled = false;
        transcodeHorsepower = 0.75;
        transcodeMaxBitRate = 0;
        transcodeConcurrency = 1;
        transcodeTrackConcurrency = 1;
        transcodeHardwareAccel = true;
        transcodeProfile = null;
        allTranscodeProfiles = [ "aapi-renderD128" ];
        transcodeMaxWidth = 1920;
      } // cfg.settings)); # passed cfg.settings override the default values.
    in [
      "d ${final-state-dir}/ 0755 stremio stremio - -"
      "d ${final-state-dir}/.stremio-server 0770 stremio stremio - -"
      "L+ ${final-state-dir}/.stremio-server/server-settings.json - - - - ${settings-file}"
    ];

    my.services.backup.global-excludes = [ final-state-dir ]; # no need to keep the video cache (max 2GB) and the above settings...

    my.services.nginx.virtualHosts.stremio = {
      inherit (cfg) port;
      extraConfig = {
        extraConfig = ''
          proxy_buffering off;
        '';
        locations."/" = {
          proxyWebsockets = true;
        };
      };
    };
  };
}

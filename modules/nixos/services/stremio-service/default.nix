# Get full features when watch movies/series using the stremio web ui.
# Useful for e.g. ipads, which do not have a stremio app providing all features.
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.stremio-service;
in {
  options.my.services.stremio-service = with lib; {
    enable = mkEnableOption "stremio-service for getting a fully-featured web experience. Needed to e.g. download torrents";

    package = mkOption {
      type = types.package;
      default = inputs.self.packages.${system}.stremio-service;
      description = "Package to use";
    };

    port = mkOption {
      type = types.port;
      default = 11470; # port has to be 11470, cannot be modified... "just use docker bro". https://github.com/Stremio/stremio-service/issues/43
      description = "Internal port for stremio-service";
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

  config = lib.mkIf cfg.enable {
    systemd.services.stremio-service = {
      description = "stremio-service - for a fully-featured web experience with stremio";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "stremio";
        Group = "stremio";
        ExecStart = " ${lib.getExe cfg.package} -s";
        DynamicUser = false;
        StateDirectory = cfg.state-dir;
        ReadWritePaths = "";
      };
    };

    systemd.tmpfiles.rules = let
      settings-file = pkgs.writeText "server-settings.json" (builtins.toJSON ({
        serverVersion = "4.20.8"; # NOTE: should match server json file.
        appPath = "${cfg.state-dir}/.stremio-server";
        cacheRoot = "${cfg.state-dir}/.stremio-server";
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
      "d ${cfg.state-dir}/.stremio-server 0770 stremio stremio - -"
      "L+ ${cfg.state-dir}/server-settings.json - - - - ${settings-file}"
    ];

    my.services.nginx.virtualHosts.stremio = {
      inherit (cfg) port;
    };
  };
}

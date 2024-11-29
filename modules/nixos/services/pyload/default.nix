# Download manager
# seb NOTE: Does not seam to work too well.
{ config, lib, ... }: let
  cfg = config.my.services.pyload;
in {
  options.my.services.pyload = with lib; {
    enable = mkEnableOption "pyload download manager";

    credentialsFile = mkOption {
      type = types.path;
      example = "/run/secrets/pyload-credentials.env";
      description = "pyload credentials. Should contain 'PYLOAD_DEFAULT_USERNAME=<user>' and 'PYLOAD_DEFAULT_PASSWORD=<pass>'";
    };

    downloadDirectory = mkOption {
      type = types.str;
      default = "/data/downloads/pyload";
      example = "/var/lib/pyload/download";
      description = "Download directory";
    };

    port = mkOption {
      type = types.port;
      default = 9093;
      example = 8080;
      description = "Internal port for webui";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pyload = {
      enable = true;
      group = "media"; # Use media group when downloading files
      listenAddress = "127.0.0.1"; # Listening on `localhost` leads to 502 with the reverse proxy...
      inherit (cfg) credentialsFile downloadDirectory port;
    };

    # Set-up media group
    users.groups.media = { };

    my.services.nginx.virtualHosts = {
      pyload = {
        inherit (cfg) port;
      };
    };

    # FIXME: fail2ban
  };
}

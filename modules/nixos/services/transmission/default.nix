# Small seedbox setup, inspired by https://github.com/delroth/infra.delroth.net/blob/master/roles/seedbox.nix
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.transmission;
in {
  options.my.services.transmission = with lib; {
    enable = mkEnableOption "Transmission torrent client";

    credentialsFile = mkOption {
      type = types.path;
      description = "Credential file as a json configuration file to be merged with the main one. Should contain `rpc-username` and `rpc-password`";
    };

    download-dir = mkOption {
      type = types.str;
      default = "/data/downloads";
      description = "Download base directory";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.transmission_4;
      description = "Transmission package to use";
    };

    port = mkOption {
      type = types.port;
      default = 9091;
      description = "Internal port for webui";
    };

    peer-port = mkOption {
      type = types.port;
      default = 30251;
      description = "Peering port";
    };
  };

  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;
      group = "media";

      downloadDirPermissions = "775";

      inherit (cfg) credentialsFile package;

      settings = {
        incomplete-dir = "${cfg.download-dir}/.incomplete";


        rpc-enabled = true;
        rpc-port = cfg.port;
        rpc-authentication-required = true;

        # Proxied behind Nginx.
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";

        inherit (cfg) download-dir peer-port;
      };
    };

    # Transmission wants to eat *all* my RAM if left to its own devices
    systemd.services.transmission = {
      serviceConfig = {
        MemoryMax = "20%";
      };
    };

    users.groups.media = { }; # Set-up media group

    my.services.nginx.virtualHosts = {
      transmission = {
        inherit (cfg) port;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.peer-port ];
      allowedUDPPorts = [ cfg.peer-port ];
    };
  };
}

# A picture/video management webserver
{ config, lib, inputs, system, ... }: let
  cfg = config.my.services.immich;
  domain-prefix = "img";
  domain = config.networking.domain;
in {
  options.my.services.immich = with lib; {
    enable = mkEnableOption "immich media server";
    port = mkOption {
      type = types.port;
      default = 9055;
      description = "Internal port for webui";
    };
    media-dir = mkOption {
      type = types.path;
      default = "/data/immich";
      description = "Directory used to store media files. If it is not the default, the directory has to be created manually such that the immich user is able to read and write to it.";
    };
  };

  config = lib.mkIf cfg.enable {
    # seb TODO:
    # Package "pgvecto-rs-0.3.0" is broken
    # In nixpkgs: https://github.com/NixOS/nixpkgs/issues/381551
    #
    # Alternatively I build another package myself, e.g. lycheeorg/lychee or piwigo.
    # for lychee:
    # sample laravel package: https://github.com/NixOS/nixpkgs/blob/57443256a0191e0d9f5f6cd130e930096581be48/nixos/modules/services/web-apps/pixelfed.nix
    # nix thread: https://discourse.nixos.org/t/how-to-deploy-laravel-app-to-nixos-machine/12572/3

    services.immich = {
      enable = true;
      host = "localhost";
      inherit (cfg) port;

      package = inputs.nixpkgs-unstable.legacyPackages.${system}.immich;

      mediaLocation = cfg.media-dir;
      accelerationDevices = [ "/dev/dri/renderD128" ];

      settings.server.externalDomain = "https://${domain-prefix}.${domain}";


      database = {
        enable = true;
        createDB = true; # create DB etc if not exists
        name = config.users.users.immich.name;
        user = config.users.users.immich.name;
      };

      openFirewall = false;
    };

    # Set-up media-location
    systemd.tmpfiles.rules = [ "d ${cfg.media-dir} 0700 ${config.users.users.immich.name} ${config.users.users.immich.group} -" ];

    # Set-up database
    my.services.postgresql = {
      enable = true;
      ensureDatabases = [ config.users.users.immich.name ];
      ensureUsers = [ { name = config.users.users.immich.name; ensureDBOwnership = true; } ];
    };

    my.services.nginx.virtualHosts.${domain-prefix} = {
      inherit (cfg) port;
    };
  };
}

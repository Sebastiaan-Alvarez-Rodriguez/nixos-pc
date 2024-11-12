# A vnc server
# see https://ylianst.github.io/MeshCentral/install/

{ config, lib, ... }: let
  cfg = config.my.services.meshcentral;
  domain-prefix = "mesh";
  # pg-user = "meshcentral";
in {
  options.my.services.meshcentral = with lib; {
    enable = mkEnableOption "meshcentral Media Server";
    enableIntelAMT = mkEnableOption "enable Intel AMT";

    backup-path = mkOption {
      type = types.str;
      default = "/var/lib/meshcentral/backups";
      description = "location for meshcentral backups";
    };

    new-accounts = mkEnableOption "enable creation of new accounts";

    port = mkOption {
      type = types.port;
      default = 3344;
      description = "Enable Intel AMT for Intels Active Management Technology";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
    #   {
    #     assertion = cfg.enable -> config.my.postgresql.enable;
    #     message = "Must enable postgres to store data of meshcentral";
    #   }
      {
        assertion = cfg.enableIntelAMT -> (config.boot.extraModulePackages ? "mei");
        description = "Must enable mei kernel module to support Intel AMT";
      }
    ];
    services.meshcentral = {
      enable = true;
      settings = {
        # uses settings from: https://raw.githubusercontent.com/Ylianst/MeshCentral/master/meshcentral-config-schema.json
        # example config: https://github.com/Ylianst/MeshCentral/blob/master/sample-config.json
        settings = { # I need to do this because the wrap is incorrect.
          cert = "${domain-prefix}.${config.networking.domain}";

          # postgres = {
          #   host = "127.0.0.1";
          #   user = pg-user;
          #   password = ...; # seb NOTE: there is no good solution, as the nix wrap uses a dynamic user sadly (i.e. so we cannot use an authentication rule pointing to a map, as with e.g. vaultwarden).
          #   port = config.services.postgresql.settings.port;
          #   database = pg-user;
          # };

          autoBackup.backupPath = cfg.backup-path;
          autoBackup.keepLastDaysBackup = 0; # we backup daily, no need to keep older versions.
          WANonly = true; # only handle WAN devices
          # LANonly = true; # only handle LAN devices

          # port settings
          port = cfg.port;
          aliasPort = 443;
          redirPort = 0;
          exactports = true;

          # intel AMT related settings
          amtManager = cfg.enableIntelAMT;
          amtScanner = !(config.services.meshcentral ? LANonly && config.services.meshcentral.LANonly) && cfg.enableIntelAMT;
          mpsPort = if cfg.enableIntelAMT then 4433 else 0;
          mpsHighSecurity = lib.mkIf cfg.enableIntelAMT true;

          tlsOffload = "127.0.0.1,::1";
          domains = {
            "" = {
              title = "Helium";
              title2 = "mesh vnc";
              newAccounts = cfg.new-accounts;
              userNameIsEmail = true;
              # certUrl = "https://${config.networking.domain}/";
              # certUrl = "https://127.0.0.1";
              # certUrl = "https://${domain-prefix}.${config.networking.domain}";
              certUrl = "https://${domain-prefix}.${config.networking.domain}:443";
              ignoreAgentHashCheck = true; # seb TODO: enable if certUrl wont work
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [ # ensures the backup directory exists and is world-readable.
      "d ${cfg.backup-path} 0775 root root -"
    ];

    # my.services.postgresql = {
    #   authentication = "local ${config.users.users.meshcentral.name} all peer map=superuser_map"; # seb: NOTE if I ever get a conflict for this attribute, change to list option type and merge in custom service.
    #   ensureDatabases = [ pg-user ];
    #   ensureUsers = [
    #     {
    #       name = pg-user;
    #       ensureDBOwnership = true;
    #     }
    #   ];
    # };

    my.services.backup.paths = [ cfg.backup-path ];
    my.services.nginx.virtualHosts.${domain-prefix} = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;

      extraConfig = {
        extraConfig = ''
          proxy_buffering off;
          proxy_send_timeout 330s;
          proxy_read_timeout 330s;
        '';
        locations."/".proxyWebsockets = true;
        # locations."/".extraConfig = ''
        #   proxy_send_timeout 330s;
        #   proxy_read_timeout 330s;
        # '';
      };
    };
  };
}

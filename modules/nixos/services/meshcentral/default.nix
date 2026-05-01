# A remote desktop service, https://docs.meshcentral.com/
#
# Basic installtion:
# 1. Make an account on the webserver.
# 2. Make a new 'Device group'.
# 3. On the device to be controlled, download the agent using the 'add agent' button.
# 4. Install the agent on the device
# 5. >>> NOTE: IF you get an error 'cannot find the procedure' on Windows 10/11, then: Rightclick installer > properties > compatibility > 'disable optimizations for full-screen'
#
# To take over a device with installed agent:
# 1. Go to the webserver
# 2. Click the correct device in the correct device group
# 3. Go to 'Desktop' and hit 'connect'

{ config, lib, ... }: let
  cfg = config.my.services.meshcentral;
  domain-prefix = "mesh";
in {
  options.my.services.meshcentral = with lib; {
    enable = mkEnableOption "meshcentral Media Server";
    enableIntelAMT = mkEnableOption "enable Intel AMT";

    new-accounts = mkEnableOption "enable creation of new accounts";
    ignore-hash = mkEnableOption "Sometimes clients cannot connect due to web cert hash mismatches. If set, ignores hashes.";

    port = mkOption {
      type = types.port;
      default = 3344;
      description = "Listen port for meshcentral web server";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    backup-path = mkOption {
      type = types.str;
      default = "/var/lib/meshcentral/backups";
      description = "location for meshcentral backups";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
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
        settings = {
          cert = "${domain-prefix}.${config.networking.domain}";
          port = cfg.port;
          aliasPort = 443;
          redirPort = 0;
          exactports = true;
          agentPong = 300; # sure

          autoBackup.backupPath = cfg.backup-path;
          autoBackup.keepLastDaysBackup = 0; # we backup daily, no need to keep older versions.
          WANonly = true; # only handle WAN devices


          tlsOffload = "127.0.0.1";

          # intel AMT related settings
          amtManager = cfg.enableIntelAMT;
          amtScanner = !(config.services.meshcentral ? LANonly && config.services.meshcentral.LANonly) && cfg.enableIntelAMT;
          mpsPort = if cfg.enableIntelAMT then 4433 else 0;
          mpsHighSecurity = lib.mkIf cfg.enableIntelAMT true;
        };
        domains = {
          "" = {
            title = "Helium";
            title2 = "mesh vnc";
            newAccounts = cfg.new-accounts;
            userNameIsEmail = true;
            certUrl =  "https://${domain-prefix}.${config.networking.domain}";
            IgnoreAgentHashCheck = cfg.ignore-hash;
          };
        };
      };
    };
    # force non-dynamic user (so we can correctly setup permissions for backup directory)
    systemd.services.meshcentral.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "meshcentral";
    };
    users.users.meshcentral = {
      description = "meshcentral user";
      group = "meshcentral";
      isSystemUser = true;
    };
    users.groups.meshcentral = {};

    systemd.tmpfiles.rules = [ # ensures the backup directory exists and is world-readable.
      "d ${cfg.backup-path} 0777 meshcentral meshcentral -"
    ];

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.backup-path ]; };
    my.services.nginx.virtualHosts.${domain-prefix} = {
      inherit (cfg) port;
      useACMEHost = config.networking.domain;

      dest-ipv6 = true; # meshcentral only binds to tcp6 port
      extraConfig = {
        extraConfig = ''
          proxy_buffering off;
          proxy_send_timeout 330s;
          proxy_read_timeout 330s;
        '';
        locations."/".proxyWebsockets = true;
      };
    };
  };
}

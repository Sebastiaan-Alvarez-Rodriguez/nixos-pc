{ inputs, pkgs, config, lib, ... }:
let
  sebas-webserver = inputs.self.packages.${pkgs.system}.sebas-webserver;
  cfg = config.services.sebas-webserver;
  user = "sebaswebserver";
  group = "sebaswebserver";
in with lib; {
  options.services.sebas-webserver = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, start the webserver.
      '';
    };
    port = mkOption {
      type = types.int;
      default = 80;
      description = ''
        Webserver port.
      '';
    };
    interface = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = ''
        Webserver interface.
      '';
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/sebas-webserver";
      description = ''
        Sebas webserver home.
      '';
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set, launches the server in debug-mode.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${user} = {
      isSystemUser = true;
      description = "Webserver service user";
      home = cfg.dataDir;
      createHome = true;
      group = group;
    };

    users.groups.${group} = {};

    systemd.services.sebas-webserver = {
      description = "Sebas webserver service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = user;
        Group = group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${sebas-webserver}/bin/webserver --interface ${cfg.interface} --port ${toString cfg.port} ${optionalString cfg.debug "--debug"} ";
      };
    };
  };
}

# backend server for kitchenowl
# Modified from: https://cyberchaos.dev/kloenk/nix/-/blob/main/modules/kitchenowl/default.nix
# Seb TODO: Add fail2ban rules to prevent spam.
{ lib, config, pkgs, inputs, system, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.my.services.kitchenowl;
  subdomain = "kitchenowl";
  kitchenowlDomain = "${subdomain}.${config.networking.domain}";

  kitchenowl-web = inputs.self.packages.${system}.kitchenowl-web;
  kitchenowl-backend = inputs.self.packages.${system}.kitchenowl-backend;
in {
  options.my.services.kitchenowl = {
    enable = mkEnableOption "Kitchenowl self-hosted grocery list and recipe manager";

    web = {
      enable = mkEnableOption "add web ui"; # seb NOTE: web GUI is extremely slow / buggy, at least on firefox-based browsers.
      package = mkOption {
        type = types.package;
        default = kitchenowl-web;
        description = "Kitchenowl web package to use";
      };
    };

    package = mkOption {
      type = types.package;
      default = kitchenowl-backend;
      description = "Kitchenowl backend package to use";
    };

    data-dir = mkOption {
      type = types.path;
      description = "Path for kitchenowl data";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };

    settings = {
      open-registration = mkEnableOption "Open registration";
      email-mandatory = mkEnableOption "Email is mandatory";
      use-natural-language = mkEnableOption "use natural language toolkit (nltk)";

      db = {
        type = mkOption {
          type = types.enum [ "sqlite" "postgresql" ];
          default = "postgresql";
        };
        name = mkOption {
          type = types.str;
          default = {
            "sqlite" = "${cfg.data-dir}/backend.db";
            "postgresql" = "kitchenowl";
          }.${cfg.settings.db.type};
        };
      };
    };

    extra-settings = mkOption {
      type = types.attrsOf (types.oneOf [ types.str types.int types.path ]);
      default = { };
      description = "Kitchenowl settings. Those are applied via environment variables, so most have to be all upercase. See https://docs.kitchenowl.org/self-hosting/advanced/";
    };

    settings-file = mkOption {
      type = types.either types.path (types.listOf types.path);
      default = [ ];
      description = "Files passed via `EnvironmentFile` to the kitchenowl backend service.";
    };

    upgrade-default-items = mkEnableOption "Upgrade default items" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    users.users.kitchenowl = {
      description = "kitchenowl Service";
      group = "kitchenowl";
      isSystemUser = true;
    };
    users.groups.kitchenowl = { };
    users.users.nginx.extraGroups = [ "kitchenowl" ]; # Allow nginx to access the UNIX socket

    systemd.tmpfiles.rules = [ "d ${cfg.data-dir} 0700 ${config.users.users.kitchenowl.name} ${config.users.users.kitchenowl.group} -" ];

    my.services.kitchenowl.extra-settings = {
      FRONT_URL = "https://${kitchenowlDomain}";

      OPEN_REGISTRATION = lib.boolToString cfg.settings.open-registration;
      EMAIL_MANDATORY = lib.boolToString cfg.settings.email-mandatory;

      DB_DRIVER = cfg.settings.db.type;
      DB_NAME = cfg.settings.db.name;
    };

    my.services.postgresql = mkIf (cfg.settings.db.type == "postgresql") {
      enable = true;
      authentication = "local ${config.users.users.kitchenowl.name} ${config.users.users.kitchenowl.name} peer map=kitchenowl_map";
      identMap = "kitchenowl_map ${config.users.users.kitchenowl.name} ${config.users.users.kitchenowl.name}";

      ensureDatabases = [ config.users.users.kitchenowl.name ];
      ensureUsers = [{
        inherit (config.users.users.kitchenowl) name;
        ensureDBOwnership = true;
      }];
    };

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.data-dir ]; };

    systemd.services.kitchenowl-backend = {
      description = "Kitchenowl grocey list and recipe manager";
      requires = lib.optional (cfg.settings.db.type == "postgresql") "postgresql.service";
      after = lib.optional (cfg.settings.db.type == "postgresql") "postgresql.service";

      environment = cfg.extra-settings // {
        PYTHONPATH = cfg.package.pythonPath;
        STORAGE_PATH = cfg.data-dir;
        NLTK_DATA = lib.mkIf cfg.settings.use-natural-language (pkgs.symlinkJoin { # natural language toolkit
          name = "kitchenowl-nltk-data";
          paths = cfg.package.nltkData;
        });
      };
      serviceConfig = {
        Type = "notify";
        EnvironmentFile = if builtins.isList cfg.settings-file then cfg.settings-file else [ cfg.settings-file ];
        User = "kitchenowl";
        Group = "kitchenowl";
        # DynamicUser = true;
        # PrivateTmp = true;
        StateDirectory = "kitchenowl";
        ExecStartPre = pkgs.writeShellScript "kitchenowl-pre-start" ''
          mkdir -p ${cfg.data-dir}/upload

          ${cfg.package.python3Packages.python}/bin/python3 -m flask \
            --app ${cfg.package}/opt/kitchenowl/wsgi.py \
            db upgrade \
            --directory ${cfg.package}/opt/kitchenowl/migrations

          ${lib.optionalString cfg.upgrade-default-items ''
            echo "Upgrading default items"
            ${cfg.package.python3Packages.python}/bin/python3 ${cfg.package}/opt/kitchenowl/upgrade_default_items.py
          ''}
        '';
        ExecStart = ''
          ${cfg.package.python3Packages.gunicorn}/bin/gunicorn wsgi:app \
            --worker-class gevent \
            --pythonpath ${cfg.package}/opt/kitchenowl
        '';
      };
    };
    systemd.sockets.kitchenowl-backend = {
      wantedBy = [ "sockets.target" ];
      socketConfig.ListenStream = "/run/kitchenowl/gunicorn.socket";
    };

    my.services.nginx.virtualHosts.${subdomain} = let
      unixPath = config.systemd.sockets.kitchenowl-backend.socketConfig.ListenStream;
    in {
      root = cfg.web.package;
      extraConfig = {
        locations."/" = lib.mkIf cfg.web.enable {
          tryFiles = "$uri $uri/ /index.html";
          extraConfig = ''
            client_max_body_size 32M;
          '';
        };
        locations."/api/".proxyPass = "http://unix:${unixPath}";
        locations."/socket.io/" = {
          proxyWebsockets = true;
          proxyPass = "http://unix:${unixPath}";
        };
      };
    };
  };
}

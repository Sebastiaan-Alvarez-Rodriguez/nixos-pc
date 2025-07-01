# Grafana dashboards for all the things!
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.monitoring;
  prefix = "monitoring";
in {
  options.my.services.monitoring = with lib; {
    enable = mkEnableOption "monitoring";

    grafana = {
      port = mkOption {
        type = types.port;
        default = 10500;
        description = "Internal port";
      };

      username = mkOption {
        type = types.str;
        example = "admin";
        description = "Admin username";
      };

      password-file = mkOption {
        type = types.str;
        description = "Admin password stored in a file";
      };

      secret-key-file = mkOption {
        type = types.str;
        description = "Secret key stored in a file";
      };
    };

    prometheus = {
      port = mkOption {
        type = types.port;
        default = 10501;
        description = "Internal port";
      };

      exporter-port = mkOption {
        type = types.port;
        default = 10100;
        description = "Prometheus exporter port";
      };

      scrapeInterval = mkOption {
        type = types.str;
        default = "15s";
        description = "Scrape interval";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          domain = "${prefix}.${config.networking.domain}";
          root_url = "https://${prefix}.${config.networking.domain}/";
          http_port = cfg.grafana.port;
          http_addr = "127.0.0.1";
        };

        security = {
          admin_user = cfg.grafana.username;
          admin_password = "$__file{${cfg.grafana.password-file}}";
          secret_key = "$__file{${cfg.grafana.secret-key-file}}";
          disable_gravatar = true;
        };
      };

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:${toString cfg.prometheus.port}";
            jsonData = {
              timeInterval = cfg.prometheus.scrapeInterval;
            };
          }
        ];

        dashboards.settings.providers = [
          {
            name = "Node Exporter";
            options.path = pkgs.nur.repos.alarsyo.grafanaDashboards.node-exporter;
            disableDeletion = true;
          }
        ];
      };
    };

    services.prometheus = {
      enable = true;
      port = cfg.prometheus.port;
      listenAddress = "127.0.0.1";

      retentionTime = "2y";

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = cfg.prometheus.exporter-port;
          listenAddress = "127.0.0.1";
        };
      };

      globalConfig = {
        scrape_interval = cfg.prometheus.scrapeInterval;
      };

      scrapeConfigs = [
        {
          job_name = config.networking.hostName;
          static_configs = [{
            targets = [ "127.0.0.1:${toString cfg.prometheus.exporter-port}" ];
          }];
        }
      ];
    };

    my.services.nginx.virtualHosts.${prefix} = {
      inherit (cfg.grafana) port;
    };
  };
}

# declarative MA
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.ddns-updater;
in {
  options.my.services.ddns-updater = with lib; {
    enable = mkEnableOption "dynamic-dns update service (to automatically update DNS records when this node's IP changes)";
    settings = lib.mkOption {
      type = with types; listOf (attrs);
      example = [
        {
          provider = "namecheap";
          domain = "sub.example.com";
          password = "@password-sub-example-com@";
        }
      ];
    };
    secrets = mkOption {
      type = types.attrs;
      default = {};
      example = literalExample ''
        {
          "@password-sub-example-com@" = config.age.secrets."some/location".path;
          "@other-com@" = config.age.secrets."some/other".path;
        }
      '';
      description = "Secret tag mapping to secret location (tags are substituted securely with path contents).";
    };

    web-ui = {
      enable = mkEnableOption "Enable web-ui";
      port = mkOption {
        type = types.port;
        default = 8000;
        description = "web-ui port";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.ddns-updater = {
      enable = true;
      environment = {
        "SERVER_ENABLED" = cfg.web-ui.enable;
        "LISTENING_ADDRESS" = ":${cfg.web-ui.port}";
      };
    };
    systemd.services.ddns-updater = let
      f = pkgs.writeText "config.json" builtins.toJSON { settings = cfg.settings; }; 
      replace-func = token: secret-path: "${pkgs.replace-secret}/bin/replace-secret @testing-it@ ${cfg.secrets} /var/lib/ddns-updater/cfg.json";
    in {
      preStart = ''
        install --owner root --mode 400 -D ${f} /var/lib/ddns-updater/cfg.json
      '' +  lib.concatMapAttrsStringSep "\n" replace-func cfg.secrets;
      path = with pkgs; [ replace-secret ];

      environment = lib.mkForce {}; # seb TODO: test if removed: https://discourse.nixos.org/t/how-to-remove-an-attribute-from-another-nixos-file/383/4
      serviceConfig.EnvironmentFile = "/var/lib/ddns-updater/cfg.json"; # seb TODO: make path configurable.
    };

    my.services.nginx.virtualHosts.ddns = {
      inherit (cfg.web-ui) port;
    };

    # systemd.tmpfiles.rules = [
    #   "d ${cfg.config-path} 0755 music-assistant music-assistant -"
    # ];
  };
}

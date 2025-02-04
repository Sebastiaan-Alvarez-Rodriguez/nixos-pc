# declarative MA
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.ddns-updater;
  statedir = "/var/lib/ddns-updater"; # state directory path as created by systemd StateDirectory definition.
  configpath = "${statedir}/config.json"; # path to env specification for ddns-updater.
in {
  options.my.services.ddns-updater = with lib; {
    enable = mkEnableOption "dynamic-dns update service (to automatically update DNS records when this node's IP changes)";
    package = mkPackageOption pkgs "ddns-updater" { };
    settings = mkOption {
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
    assertions = [
      {
        assertion = !config.services.ddns-updater.enable; message = "Cannot use ddns-updater alongside this service, as it screws up secret permissions.";
      }
    ];

    systemd.services.ddns-updater = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      preStart = let
        f = pkgs.writeText "config.json" "${(builtins.toJSON { settings = cfg.settings; })}";
        replace-func = token: secret-path: "${pkgs.replace-secret}/bin/replace-secret ${token} ${secret-path} ${configpath}";
      in ''
        ${pkgs.coreutils}/bin/install --mode 600 -D ${f} ${configpath}
      '' + lib.concatStringsSep "\n" (lib.mapAttrsToList replace-func cfg.secrets);
      path = with pkgs; [ coreutils replace-secret ];

      unitConfig.Description = "DDNS-updater service";
      serviceConfig = {
        Environment = "DATADIR=${statedir}"; # DDNS-updater will use this dir to read the 'config.json' file
        ExecStart = lib.getExe cfg.package;
        DynamicUser = lib.mkForce false;
        User = "ddns-updater";
        StateDirectory = "ddns-updater";
        Restart = "on-failure";
        RestartSec = 30;
        TimeoutSec = "5min";
      };
    };

    users.users.ddns-updater = {
      description = "ddns-updater Service";
      group = "ddns-updater";
      isSystemUser = true;
    };
    users.groups.ddns-updater = {};

    my.services.nginx.virtualHosts.ddns = {
      inherit (cfg.web-ui) port;
    };
  };
}

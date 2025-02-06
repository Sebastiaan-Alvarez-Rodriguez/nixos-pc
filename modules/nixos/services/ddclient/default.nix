# declarative DDNS update client
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.ddclient;
  statedir = "/var/lib/ddclient"; # state directory path as created by systemd StateDirectory definition.
  configpath = "${statedir}/dd.config"; # path to specification for ddclient.

  dd-custom = inputs.self.packages.${system}.ddclient;
in {
  options.my.services.ddclient = with lib; {
    enable = mkEnableOption "dynamic-dns update service (to automatically update DNS records when this node's IP changes)";
    package = mkOption {
      type = types.package;
      default = dd-custom;
      description = "ddclient package to use";
    };

    domains = lib.mkOption {
      type = with types; listOf str;
      description = ''
        Domain name(s) to synchronize.
      '';
    };

    interval = lib.mkOption {
      default = "10min";
      type = types.str;
      description = "The interval at which to run the check and update. See {command}`man 7 systemd.time` for the format.";
    };

    protocol = lib.mkOption {
      default = "dyndns2";
      type = types.str;
      description = "Protocol to use with dynamic DNS provider (see https://ddclient.net/protocols.html).";
    };

      quiet = lib.mkOption {
        default = false;
        type = types.bool;
        description = ''
          Print no messages for unnecessary updates.
        '';
      };

    server = lib.mkOption {
      default = "";
      type = types.str;
      description = "Server address.";
    };

    ssl = lib.mkOption {
      default = true;
      type = types.bool;
      description = "Whether to use SSL/TLS to connect to dynamic DNS provider.";
    };

    use = lib.mkOption {
      default = "";
      type = types.str;
      description = "Method to determine the IP address to send to the dynamic DNS provider.";
    };

    usev4 = lib.mkOption {
      default = "webv4, webv4=ipify-ipv4";
      type = types.str;
      description = "Method to determine the IPv4 address to send to the dynamic DNS provider. Only used if `use` is not set.";
    };

    usev6 = lib.mkOption {
      default = "webv6, webv6=ipify-ipv6";
      type = types.str;
      description = "Method to determine the IPv6 address to send to the dynamic DNS provider. Only used if `use` is not set.";
    };

    verbose = lib.mkOption {
      default = false;
      type = types.bool;
      description = "Print verbose information.";
    };

    zone = lib.mkOption {
      default = "";
      type = types.str;
      description = "zone as required by some providers.";
    };

    extraConfig = lib.mkOption {
      default = "";
      type = types.lines;
      description = "Extra configuration. Contents will be added verbatim to the configuration file."; 
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
      description = "Secret tag mapping to secret location (tags are substituted securely with pointed file's contents).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ddclient = let
      boolToStr = bool: if bool then "yes" else "no";
      configfile = pkgs.writeText "ddclient.conf" ''
        cache=${statedir}/ddclient.cache
        foreground=YES
        ${lib.optionalString (cfg.use != "") "use=${cfg.use}"}
        ${lib.optionalString (cfg.use == "" && cfg.usev4 != "") "usev4=${cfg.usev4}"}
        ${lib.optionalString (cfg.use == "" && cfg.usev6 != "") "usev6=${cfg.usev6}"}
        protocol=${cfg.protocol}
        ${lib.optionalString (cfg.server != "") "server=${cfg.server}"}
        ${lib.optionalString (cfg.zone != "")   "zone=${cfg.zone}"}
        ssl=${boolToStr cfg.ssl}
        wildcard=YES
        quiet=${boolToStr cfg.quiet}
        verbose=${boolToStr cfg.verbose}
        ${cfg.extraConfig}
        ${lib.concatStringsSep "," cfg.domains}
      '';    
    in {
      description = "Dynamic DNS Client";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartTriggers = [ configfile ];

      preStart = let
        replace-func = token: secret-path: "${pkgs.replace-secret}/bin/replace-secret ${token} ${secret-path} ${configpath}";
      in ''
        ${pkgs.coreutils}/bin/install --mode 600 --owner=$USER -D ${configfile} ${configpath}
      '' + lib.concatStringsSep "\n" (lib.mapAttrsToList replace-func cfg.secrets);
      path = with pkgs; [ coreutils replace-secret ] ++ (lib.optional (lib.hasPrefix "if," cfg.use || lib.hasPrefix "ifv4," cfg.usev4 || lib.hasPrefix "ifv6," cfg.usev6) pkgs.iproute2);

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectoryMode = "0700";
        RuntimeDirectory = builtins.baseNameOf statedir;
        StateDirectory = builtins.baseNameOf statedir;
        Type = "oneshot";
        ExecStart = "${lib.getExe cfg.package} -file ${configpath}";
      };
    };

    systemd.timers.ddclient = {
      description = "Run ddclient";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.interval;
        OnUnitInactiveSec = cfg.interval;
      };
    };
    
  };
}

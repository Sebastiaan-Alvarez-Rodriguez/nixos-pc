# Control fans on dell machines. Provides `i8kmon` and `i8kctl`.
# Allows to configure on-startup fan configuration commands.
# see pkg `i8kutils` for usage.
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.fancontrol-i8k;
  i8kutils = inputs.self.packages.${system}.i8kutils;
in {
  options.my.services.fancontrol-i8k = with lib; {
    enable = mkEnableOption "Control fans on dell machines";
    package = mkOption {
      type = types.package;
      default = i8kutils;
      description = "i8kutils package to use";
    };

    quiet-start = mkEnableOption "turn off all fans at the start of this machine";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.elem "dell-smm-hwmon" config.boot.initrd.kernelModules;
        message = "Must have `dell-smm-hwmon` in `boot.initrd.kernelModules`!";
      }
      {
        assertion = builtins.elem "dell-smm-hwmon" config.boot.kernelModules;
        message = "Must have `dell-smm-hwmon` in `boot.kernelModules`!";
      }
    ];
    systemd.services.fancontrol-i8k = lib.mkIf cfg.quiet-start {
      description = "Fan-control";
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ coreutils cfg.package ];

      serviceConfig = {
        # DynamicUser = true;
        # User = "fancontrol-i8k";
        # RuntimeDirectoryMode = "0700";
        # RuntimeDirectory = builtins.baseNameOf statedir;
        # StateDirectory = builtins.baseNameOf statedir;
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/i8kmon"; # we just run `i8kmon` as it monitors and reduces fan speed as needed
      };
    };

    environment.systemPackages = [ cfg.package ];

    # users.users.fancontrol-i8k = {
    #   description = "fancontrol-i8k Service";
    #   group = "fancontrol-i8k";
    #   isSystemUser = true;
    # };
    # users.groups.fancontrol-i8k = {};
  };
}

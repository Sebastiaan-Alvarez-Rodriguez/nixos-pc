{ config, lib, pkgs, ...}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  cfg = config.programs.swaybg-dynamic;
in {
  options.programs.swaybg-dynamic = with lib.types; {
    enable = mkEnableOption "swaybg-dynamic";

    package = mkOption {
      type = package;
      default = pkgs.swaybg;
      defaultText = literalExpression "pkgs.swaybg";
      description = ''
        swaybg package to use. Set to <code>null</code> to use the default package.
      '';
    };

    images = mkOption {
      type = path;
      description = ''
        Path to images folder to use as backgrounds.
      '';
    };

    mode = mkOption {
      type = enum [ "stretch" "fit" "fill" "center" "tile" ]; # solid-color not allowed
      default = "fill";
      description = ''
        The background mode to use for the images.
      '';
    };

    systemdTarget = mkOption {
      type = str;
      default = "graphical-session.target";
      description = ''
        The systemd target that will automatically start the swaybg service.
      '';
    };

    interval = mkOption {
      type = types.str;
      default = "5m";
      description = ''
        Interval to change backgrounds (only used with "random" selection).
      '';
    };

    selection = mkOption { # TODO: 'random' is broken for now (swaybg does not listen to stop signals?)
      type = enum [ "random-boot" "random" ];
      default = "random-boot";
      description = ''
        Selection strategy for background images.
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.user.services.swaybg-dynamic = {
      Unit = {
        Description = "swaybg-dynamic background service";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "/bin/sh -c '${cfg.package}/bin/swaybg -i $(/run/current-system/sw/bin/ls -d ${cfg.images}/* | /run/current-system/sw/bin/sort -R | /run/current-system/sw/bin/tail -1) -m ${cfg.mode}'";
        ExecStop = "/bin/sh -c '/run/current-system/sw/bin/systemctl kill --signal=SIGKILL swaybg-dynamic.service'";
        TimeoutStopSec=2;
        Restart = "always";
      };

      Install.WantedBy = [ cfg.systemdTarget ];
    };
    systemd.user.timers.swaybg-dynamic = mkIf (cfg.selection == "random") {
      Install.WantedBy = [ "timers.target" ];
      # partOf = [ "swaybg-dynamic.service" ];
      Timer = {
        OnBootSec = "1s"; # Run it 1 second after boot
        OnUnitActiveSec = "${toString cfg.interval}"; 
        Unit = "swaybg-dynamic.service";
      };
    };
  };
}

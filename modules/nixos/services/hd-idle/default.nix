# Suspends drives after an amount of idling. Automatically resumes drives when a new read/write comes in.
# Implementation from here: https://www.reddit.com/r/NixOS/comments/751i5t/comment/do3f3l7/
{ config, lib, ... }: let
  cfg = config.my.services.hd-idle;
in {
  options.my.services.hd-idle = with lib; {
    enable = mkEnableOption "hd-idle";

    drives = mkOption {
      type = with types; listOf str;
      default = [];
      example = [ "/dev/sda1", "dev/disk/by-uuid/<SOME UUID>" ];
      description = "Drives to suspend";
    };

    timeout-seconds = mkOption {
      type = types.int;
      default = 600;
      description = "amount of idle seconds before autosuspend";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.hd-idle = let
      allcommands = builtins.concatStringSep "\n" (builtins.map (drive: "${pkgs.hd-idle}/bin/hd-idle -i 0 -a ${drive} -i ${cfg.timeout-seconds}") cfg.drives);
      f = pkgs.writeShellScript "hd-idle-script" ''
        #!/usr/bin/env bash
        ${allcommands}
      '';
    in {
      description = "External HD spin down daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${f}";
      };
    };
  };
}

{ config, lib, pkgs, ... }: let
  cfg = config.my.home.ssh;
in {
  options.my.home.ssh = with lib; {
    enable = mkEnableOption "ssh configuration";

    mosh = {
      enable = mkEnableOption "mosh configuration";
      package = mkPackageOption pkgs "mosh" { };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.ssh.enable = true;
    }

    (lib.mkIf cfg.mosh.enable {
      home.packages = [ cfg.mosh.package ];
    })
  ]);
}

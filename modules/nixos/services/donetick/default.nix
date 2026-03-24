# an open-source, user-friendly app for managing tasks and chores,
# featuring customizable options to help you and others stay organized 
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.donetick;
  donetick = inputs.self.packages.${system}.donetick;
in {
  options.my.services.donetick = with lib; {
    enable = mkEnableOption "Control fans on dell machines";
    package = mkOption {
      type = types.package;
      default = donetick;
      description = "donetick package to use";
    };
  };

  # TODO: ensure selfhosted.yaml is in place. 
  config = lib.mkIf cfg.enable {
    systemd.services.donetick = {
      description = "Task managing task";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ coreutils cfg.package ];

      serviceConfig = {
        ExecStart = "DT_ENV=selfhosted ${cfg.package}/bin/donetick";
      };
    }; 

    environment.systemPackages = [ cfg.package ];
  };
}

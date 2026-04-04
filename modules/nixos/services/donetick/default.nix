# an open-source, user-friendly app for managing tasks and chores,
# featuring customizable options to help you and others stay organized 
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.donetick;
  donetick = inputs.self.packages.${system}.donetick;
  yamlFormat = pkgs.formats.yaml {};
  configFile = yamlFormat.generate "selfhosted.yaml" cfg.settings;
in {
  options.my.services.donetick = with lib; {
    enable = mkEnableOption "Task management program";
    package = mkOption {
      type = types.package;
      default = donetick;
      description = "donetick package to use";
    };

    settings = lib.mkOption {
      type = yamlFormat.type;
      description = "Configuration yaml file for doneticks. See: https://github.com/donetick/donetick/blob/main/config/selfhosted.yaml";
      default = {
        is_done_tick_dot_com = false;
        is_user_creation_disabled = false;
        database.migration = true;
      };
      example = {
        name = "h.donetick";
        is_user_creation_disabled = true;
        database.type = "postgres";
        jwt.secret = "a_32_chars_long_string";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: nixos complains that this is a read-only file system,
    # which makes sense, but not really sure how to solve atm.
    # nice video on these yaml files and activationScripts:
    # https://www.youtube.com/watch?v=84noqMHDx5k
    system.activationScripts.setupConfig = ''
        mkdir -p ${cfg.package}/config
        cp ${configFile} ${cfg.package}/config/
    '';
    
    systemd.services.donetick = {
      description = "Task managing program";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        DT_ENV = "selfhosted";
      };
      
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/donetick";
      };
    }; 

    environment.systemPackages = [ cfg.package ];
  };
}

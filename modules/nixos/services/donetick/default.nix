# an open-source, user-friendly app for managing tasks and chores,
# featuring customizable options to help you and others stay organized 
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.donetick;
  donetick = inputs.self.packages.${system}.donetick;
in {
  options.my.services.donetick = with lib; {
    enable = mkEnableOption "Task management program";
    package = mkOption {
      type = types.package;
      default = donetick;
      description = "donetick package to use";
    };

    config_folder = "config";
    data_folder = "data";

    settings = lib.mkOption {
      type = (pkgs.formats.yaml {}).generate "${./config/selfhosted.yaml}";
      description = "Configuration yaml file for doneticks. See: https://github.com/donetick/donetick/blob/main/config/selfhosted.yaml";
      default = {
        is_done_tick_dot_com = false;
        is_user_creation_disabled = false;
        database.migration = true;
        jwt.secret = "change_me_to_a_secure_random_string_32_chars_long"; 
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
    systemd.services.donetick = {
      description = "Task managing program";
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

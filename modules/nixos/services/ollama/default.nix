# Ollama

{ config, lib, ... }: let
  cfg = config.my.services.ollama;
in {
  options.my.services.ollama = with lib; {
    enable = mkEnableOption "Ollama LLM facilitator service";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      user = "ollama";
      group = "ollama";
    };

    systemd.services.ollama = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = lib.mkForce false;
        Restart = "on-failure";
      };
    };

    systemd.tmpfiles.rules = [ # ensure directory exists
      "d ${config.services.ollama.home} 0755 ${config.systemd.services.ollama.serviceConfig.User} ${config.systemd.services.ollama.serviceConfig.Group} -"
      "d ${config.services.ollama.models} 0755 ${config.systemd.services.ollama.serviceConfig.User} ${config.systemd.services.ollama.serviceConfig.Group} -"
    ];

  };
  
}

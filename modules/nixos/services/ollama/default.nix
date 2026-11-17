# Ollama

{ config, lib, ... }: let
  cfg = config.my.services.ollama;
in {
  options.my.services.ollama = with lib; {
    enable = mkEnableOption "Ollama LLM facilitator service";
  };

  config = lib.mkIf cfg.enable {
    services.ollama.enable = true;

    systemd.services.ollama = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
  
}

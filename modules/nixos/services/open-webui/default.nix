# Open-WebUI -- For LLMs
{ config, lib, ... }: let
  cfg = config.my.services.open-webui;
  prefix = "webui";
 in {
  options.my.services.open-webui = with lib; {
    enable = mkEnableOption "Open WebUI service";

    port = mkOption {
      type = types.port;
      default = 3232;
      example = 8080;
      description = "Internal port for webui";
    };

    data-dir = mkOption {
      type = types.str;
      default = "/data/open-webui";
    };

    backup-routes = mkOption {
      type = with types; listOf str;
      description = "Restic backup routes to use for this data.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;

      host = "127.0.0.1";
      port = cfg.port;

      stateDir = cfg.data-dir;

      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        ENABLE_SIGNUP = "True"; 
        ENABLE_ADMIN_CHAT_ACCESS = "False"; 
        BYPASS_ADMIN_ACCESS_CONTROL = "False";
        IFRAME_CSP = "";
        THREAD_POOL_SIZE = "40"; # Recommended 2000 or higher for many users, but for weak hardware, keep default 40.
        FORWARDED_ALLOW_IPS = "127.0.0.1";
        ENABLE_CONTEXT_COMPACTION = "True"; # This will summarize long chats, do we want this?
        ENABLE_FOLLOW_UP_GENERATION = "False";
        ENABLE_CODE_EXECUTION = "False";
        ENABLE_COMMUNITY_SHARING = "False";
        WEBUI_SESSION_COOKIE_SAME_SITE = "strict"; # blocks session cookies from being sent with requests initiated by third-party websites
        CORS_ALLOW_ORIGIN = "https://${prefix}.${config.networking.domain}"; # TODO: set to something else than "*"
        ENABLE_IMAGE_GENERATION = "False";            
      };
    };

    systemd.services.open-webui = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "openwebui";
        Group = "openwebui";
        Restart = "on-failure";
      };
    };

    my.services.nginx.virtualHosts.${prefix} = {
      inherit (cfg) port;
    };

    my.services.backup.routes = lib.my.toAttrsUniform cfg.backup-routes { paths = [ cfg.data-dir ]; };

    systemd.tmpfiles.rules = [ # ensure directory exists
      "d ${cfg.data-dir} 0700 ${config.systemd.services.open-webui.serviceConfig.User} ${config.systemd.services.open-webui.serviceConfig.Group} -"
    ];
    users.users.openwebui = {
      description = "openwebui Service";
      group = "openwebui";
      isSystemUser = true;
    };
    users.groups.openwebui = {};
    # users.groups.openwebui = lib.optionalAttrs config.my.services.ollama.enable { "ollama" };

  };
}

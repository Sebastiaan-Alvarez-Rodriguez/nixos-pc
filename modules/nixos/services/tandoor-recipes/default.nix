# grocery/recipe service
# argumentation mealy vs grocy vs tandoor: https://www.reddit.com/r/selfhosted/comments/o1hc34/recipe_managementmeal_plannng_comments_on_mealie/
{ config, lib, ... }: let
  cfg = config.my.services.tandoor-recipes;
in {
  options.my.services.tandoor-recipes = with lib; {
    enable = mkEnableOption "Tandoor Recipes service";

    media-path = mkOption {
      type = types.path;
      default = "/data/tandoor";
    };
    port = mkOption {
      type = types.port;
      default = 4536;
      example = 8080;
      description = "Internal port for webui";
    };

    secretKeyFile = mkOption {
      type = types.str;
      example = "/var/lib/tandoor-recipes/secret-key.env";
      description = "Secret key as an 'EnvironmentFile' (see `systemd.exec(5)`). Must contain 'SECRET_KEY=<Django generated secret>'";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tandoor-recipes = {
      enable = true;

      port = cfg.port;
      extraConfig = let
        tandoorRecipesDomain = "recipes.${config.networking.domain}";
      in {
        # Use PostgreSQL
        DB_ENGINE = "django.db.backends.postgresql";
        POSTGRES_HOST = "/run/postgresql";
        POSTGRES_USER = "tandoor_recipes";
        POSTGRES_DB = "tandoor_recipes";

        # Security settings
        ALLOWED_HOSTS = tandoorRecipesDomain;
        CSRF_TRUSTED_ORIGINS = "https://${tandoorRecipesDomain}";

        MEDIA_ROOT = cfg.media-path;
        TIMEZONE = config.time.timeZone;
      };
    };

    systemd.tmpfiles.rules = [ # ensure directory exists
      "d ${cfg.media-path} 0700 ${config.systemd.services.tandoor-recipes.serviceConfig.User} ${config.systemd.services.tandoor-recipes.serviceConfig.Group} -"
    ];

    systemd.services = {
      tandoor-recipes = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];

        serviceConfig = {
          EnvironmentFile = cfg.secretKeyFile;
        };
      };
    };

    # Set-up database
    my.services.postgresql = {
      enable = true;
      ensureDatabases = [ "tandoor_recipes" ];
      ensureUsers = [
        {
          name = "tandoor_recipes";
          ensureDBOwnership = true;
        }
      ];
    };

    my.services.nginx.virtualHosts = {
      recipes = {
        inherit (cfg) port;

        extraConfig = {
          # Allow bulk upload of recipes for import/export
          locations."/".extraConfig = ''
            client_max_body_size 0;
          '';
        };
      };
    };
  };
}

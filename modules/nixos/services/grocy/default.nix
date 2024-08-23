# Groceries and household management
# argumentation mealy vs grocy vs tandoor: https://www.reddit.com/r/selfhosted/comments/o1hc34/recipe_managementmeal_plannng_comments_on_mealie/
{ config, lib, ... }: let
  cfg = config.my.services.grocy;
  grocyPrefix = "grocy";
in {
  options.my.services.grocy = with lib; {
    enable = mkEnableOption "Grocy household ERP";
  };

  config = lib.mkIf cfg.enable {
    services.grocy = {
      enable = true;

      # The service sets up the reverse proxy automatically
      hostName = "${grocyPrefix}.${config.networking.domain}";

      nginx.enableSSL = false; # Configure SSL by hand

      settings = {
        currency = "EUR";
        culture = "en";
        calendar = {
          firstDayOfWeek = 1; # Start on Monday
          showWeekNumber = true;
        };
      };
    };

    my.services.nginx.virtualHosts.${grocyPrefix} = {
      useACMEHost = config.networking.domain;
    };
  };
}

{ config, lib, pkgs, ... }: let
  cfg = config.my.home.firefox;
in {
  imports = [ ./tridactyl ];

  options.my.home.firefox = with lib; {
    enable = mkEnableOption "firefox configuration";

    tridactyl = { # seb: TODO how is this different from mkEnableOption?
      enable = mkOption {
        type = types.bool;
        description = "tridactyl configuration";
        example = false;
        default = config.my.home.firefox.enable;
      };
      term = mkOption {
        type = types.str;
        description = "terminal program";
        default = config.my.home.terminal.program;
      };
    };

    ff2mpv = {
      enable = mkOption {
        type = types.bool;
        description = "ff2mpv configuration";
        default = config.my.home.mpv.enable;
      };
    };
  };

  config.programs.firefox = lib.mkIf cfg.enable {
    enable = true;

    package = pkgs.firefox.override {
      nativeMessagingHosts = ([ ]
        ++ lib.optional cfg.tridactyl.enable pkgs.tridactyl-native
        # Watch videos using mpv
        ++ lib.optional cfg.ff2mpv.enable pkgs.ff2mpv-go
      );
    };

    profiles = {
      default = {
        id = 0;

        settings = {
          "browser.bookmarks.showMobileBookmarks" = true; # Mobile bookmarks
          "browser.download.useDownloadDir" = false; # Ask for download location
          "browser.in-content.dark-mode" = true; # Dark mode
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false; # Disable top stories
          "browser.newtabpage.activity-stream.feeds.sections" = false;
          "browser.newtabpage.activity-stream.feeds.system.topstories" = false; # Disable top stories
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false; # Disable pocket
          "extensions.pocket.enabled" = false; # Disable pocket
          "media.eme.enabled" = true; # Enable DRM
          "media.gmp-widevinecdm.enabled" = true; # Enable DRM
          "media.gmp-widevinecdm.visible" = true; # Enable DRM
          "signon.autofillForms" = false; # Disable built-in form-filling
          "signon.rememberSignons" = false; # Disable built-in password manager
          "ui.systemUsesDarkTheme" = true; # Dark mode
        };

        extensions = with pkgs.nur.repos.rycee.firefox-addons; ([
          # bitwarden
          # consent-o-matic
          form-history-control
          refined-github
          ublock-origin
        ]
        ++ lib.optional (cfg.tridactyl.enable) tridactyl
        ++ lib.optional (cfg.ff2mpv.enable) ff2mpv
        );
      };
    };
  };
  # legacy:
  # let
  #   custom-firefox = pkgs.wrapFirefox pkgs.firefox-unwrapped {
  #     extraPolicies = {
  #       DisableFirefoxStudies = true;
  #       DisablePocket = true;
  #       DisableTelemetry = true;
  #       DisableFirefoxAccounts = false;
  #       FirefoxHome = {
  #         Pocket = false;
  #         Snippets = false;
  #       };
  #       UserMessaging = {
  #         ExtensionRecommendation = false;
  #         SkipOnboarding = false;
  #       };
  #     };
  #   };
  # in {
  #   programs.firefox = {
  #     enable = true;
  #     package = custom-firefox;
  #   };
  # }

  
}

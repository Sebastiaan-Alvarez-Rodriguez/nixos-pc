{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.rofi;
in {
  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      terminal = config.my.home.terminal.program; # null by default

      # use regular 'rofi' package for xserver gm?
      package = pkgs.rofi.override {
        plugins = with pkgs; [ rofi-emoji rofi-calc ];
      };
      extraConfig = {
        modi = "drun,filebrowser,run,window,emoji,calc";
        separator-style = "dash";
        color-enabled = true;
        show-icons = true;
        display-drun = "󰣇";
        display-filebrowser = " ";
        display-run = "";
        display-window = " ";
        display-emoji = "󰚜";
        display-calc = "";
        drun-display-format = "{name}";
        window-format = "{w}{t}";
        sidebar-mode = true;
      };

      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        "*" = if config.my.home.stylix.enable then {
            main-bg = "#${config.lib.stylix.colors.base00}e6";
            main-fg = "#${config.lib.stylix.colors.base05}ff";
            main-br = "#${config.lib.stylix.colors.base0D}ff";

            select-bg = "#${config.lib.stylix.colors.base07}ff";
            select-fg = "#${config.lib.stylix.colors.base00}ff";
        } else { # hardcoded colors if no stylix
          main-bg = "#11111be6";
          main-fg = "#cdd6f4ff";
          main-br = "#cba6f7ff";
          select-bg = "#b4befeff";
          select-fg = "#11111bff";
        };

        window = {
          enabled = true;
          width = mkLiteral "63em";
          border = 2;
          border-radius = 16;

          border-color = lib.mkDefault (mkLiteral "@main-br");
          background-color = lib.mkDefault (mkLiteral "@main-bg");

          cursor = "default";
        };

        mainbox = {
          enabled = true;
          padding = mkLiteral "2em 1em 1em";
        };

        mode-switcher = {
          enabled = true;
          orientation = mkLiteral "horizontal";
          # width = mkLiteral "3.8em";

          padding = mkLiteral "1em";
          margin = mkLiteral "1.5em 0 0 0";
          spacing = mkLiteral "1.2em";

          background-color = mkLiteral "transparent";
          border = 2;
          border-radius = 16;
          # background image here? (~/.cache/hyde/wall.blur)
        };

        inputbar = {
          enabled = true; # setting this to false hides the input bar (keypresses are still processed)
          border = 2;
          border-radius = 16;
          padding = mkLiteral "1em 2em";
          spacing = 8;
          children = builtins.map mkLiteral [ "prompt" "entry" ]; # added "prompt" after 1
          background-color = mkLiteral "@main-bg";
        };

        prompt = {
          text-color = lib.mkDefault (mkLiteral "@main-fg");
        };

        entry = {
          enabled = true;
          placeholder = "Search...";
          text-color = lib.mkDefault (mkLiteral "@normal-text");
          cursor = mkLiteral "text";
        };

        message = {
          margin = mkLiteral "12px 0 0";
          border-radius = 16;
          border-color = lib.mkDefault (mkLiteral "@main-br");
          background-color = mkLiteral "@main-bg";
        };

        button = {
          border-radius = 16;
          background-color = lib.mkDefault (mkLiteral "@main-bg");
          text-color = lib.mkDefault (mkLiteral "@main-fg");
          cursor = mkLiteral "pointer";
        };

        "button selected" = {
          background-color = lib.mkDefault (mkLiteral "@main-fg");
          text-color = lib.mkDefault (mkLiteral "@main-bg");
        };

        textbox = {
          padding = mkLiteral "8px 24px";
        };

        listview = {
          enabled = true;
          spacing = mkLiteral "0em";
          padding = mkLiteral "0em";
          columns = 1;
          lines = 8;

          cycle = true;
          dynamic = true;
          scrollbar = false;

          layout = mkLiteral "vertical";

          margin = mkLiteral "12 0 0";
          reverse = false;
          expand = false;
          fixed-height = true;
          fixed-columns = true;
          cursor = "default";

          background-color = "transparent";
          text-color = lib.mkDefault (mkLiteral "@main-fg");
        };

        element = {
          enabled = true;
          spacing = mkLiteral "0.8em";
          padding = mkLiteral "0.4em 0.4em 0.4em 1.5em";
          cursor = mkLiteral "pointer";
          background-color = mkLiteral "transparent";
          text-color = lib.mkDefault (mkLiteral "@main-fg");
          border-radius = 16;
        };
        "element selected.normal" = {
          background-color = lib.mkDefault (mkLiteral "@select-bg");
          text-color = lib.mkDefault (mkLiteral "@select-fg");
        };

        dummy = {
          background-color = "transparent";
        };

        element-icon = {
          size = mkLiteral "2.8em";
          cursor = mkLiteral "inherit";
          background-color = lib.mkDefault (mkLiteral "transparent");
          text-color = lib.mkDefault (mkLiteral "inherit");
        };

        element-text = {
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
          cursor = mkLiteral "inherit";
          background-color = lib.mkDefault (mkLiteral "transparent");
          text-color = lib.mkDefault (mkLiteral "inherit");
        };
      };
    };

    my.home.wm.hyprland.binds.launcher = let
      base = "rofi -combi-modi drun,run,window,emoji,calc -show ";
    in {
      application = "${base} drun";
      executable = "${base} run";
      window = "${base} window";
      emoji = "${base} emoji";
      calc = "${base} calc";
    };
  };
}

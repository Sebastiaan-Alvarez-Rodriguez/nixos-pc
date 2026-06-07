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
        modi = "drun,run,window,emoji,calc";
        separator-style = "dash";
        color-enabled = true;
        show-icons = true;
        display-drun = "󰣇";
        display-run = "";
        display-filebrowser = " ";
        display-window = " ";
        drun-display-format = "{name}";
        window-format = "{w}{t}";
        # sidebar-mode = true;
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
          height = mkLiteral "33em";

          transparency = "real";
          fullscreen = false;
          cursor = "default";
          spacing = mkLiteral "0em";
          padding = mkLiteral "0em";

          # remove: border = 2;
          # remove: border-radius = 16;

          border-color = lib.mkDefault (mkLiteral "@main-br");
          background-color = lib.mkDefault (mkLiteral "@main-bg");
        };

        # mainbox = {
        #   enabled = true;
        #   spacing = mkLiteral "0em";
        #   padding = mkLiteral "0em";
        #   orientation = mkLiteral "horizontal";
        #   # children = builtins.map mkLiteral [ "dummywall" "listbox" ]; 
        # };

        dummywall = {
          spacing = mkLiteral "0em";
          padding = mkLiteral "0em";
          width = mkLiteral "37em"; # AI reduced to 24em for some reason
          expand = false;
          background-color = mkLiteral "transparent";
          # background image here? (~/.cache/hyde/wall.thmb): https://github.com/HyDE-Project/HyDE/blob/a51460a7b1a822ee7194318b60a38850f711b923/Configs/.local/share/hyde/rofi/themes/style_1.rasi#L58
        };

        mode-switcher = {
          enabled = true;
          orientation = mkLiteral "vertical";
          width = mkLiteral "3.8em";
          padding = mkLiteral "9.2em 0.5em 9.2em 0.5em";
          spacing = mkLiteral "1.2em";

          background-color = mkLiteral "transparent";
          # background image here? (~/.cache/hyde/wall.blur)
        };

        button = {
          border-radius = mkLiteral "2em";
          background-color = lib.mkDefault (mkLiteral "@main-bg");
          text-color = lib.mkDefault (mkLiteral "@main-fg");
          cursor = mkLiteral "pointer";
        };

        "button selected" = {
          background-color = lib.mkDefault (mkLiteral "@main-fg");
          text-color = lib.mkDefault (mkLiteral "@main-bg");
        };

        inputbar = {
          enabled = true; # setting this to false hides the input bar (keypresses are still processed)
          children = builtins.map mkLiteral [ "prompt" "entry" ]; # added "prompt" after 1
          background-color = mkLiteral "transparent";
        };

        entry = {
          enabled = true; # changed to true after 1
          expand = true; # added after 1
          placeholder = mkLiteral "\"Search...\""; # added after 1
          text-color = lib.mkDefault (mkLiteral "@normal-text");
          cursor = mkLiteral "text";
        };

        listbox = {
          spacing = mkLiteral "0em";
          padding = mkLiteral "2em";
          children = builtins.map mkLiteral [ "dummy" "listview" "dummy" ];
          background-color = mkLiteral "transparent";
        };

        sidebar = {
          width = "24em";
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

          reverse = false;
          expand = false;
          fixed-height = true;
          fixed-columns = true;
          cursor = "default";

          background-color = "transparent";
          text-color = lib.mkDefault (mkLiteral "@main-fg");
        };

        dummy = {
          background-color = "transparent";
        };

        element = {
          enabled = true;
          spacing = mkLiteral "0.8em";
          padding = mkLiteral "0.4em 0.4em 0.4em 1.5em";
          cursor = mkLiteral "pointer";
          background-color = mkLiteral "transparent";
          text-color = lib.mkDefault (mkLiteral "@main-fg");
        };

        "element selected.normal" = {
          background-color = lib.mkDefault (mkLiteral "@select-bg");
          text-color = lib.mkDefault (mkLiteral "@select-fg");
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

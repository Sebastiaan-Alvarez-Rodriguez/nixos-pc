# terminal programs, i.e. foot.
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.terminal;
in {
  options.my.home.terminal = with lib; {
    program = mkOption {
      type = with types; nullOr (enum [ "foot" ]);
      default = null;
      description = "Which terminal to use for home session";
    };
  };

  config = lib.mkIf (cfg.program != null) (lib.mkMerge [
    (lib.mkIf (cfg.program == "foot") {
      programs.foot = {
        enable = true;
        server.enable = true;
        settings = {
          main = {
            term = "foot";
            font = "monospace:size=7, Noto Color Emoji:size=7";
            dpi-aware = "yes";
          };
          mouse.hide-when-typing = "yes";
          scrollback.lines = 65536;
          colors = {
            background = "181818";
            foreground = "dddddd";

            regular0 = "000000";
            regular1 = "cc0403";
            regular2 = "19cb00";
            regular3 = "cecb00";
            regular4 = "0d73cc";
            regular5 = "cb1ed1";
            regular6 = "0dcdcd";
            regular7 = "dddddd";

            bright0 = "767676";
            bright1 = "f2201f";
            bright2 = "23fd00";
            bright3 = "fffd00";
            bright4 = "1a8fff";
            bright5 = "14ffff";
            bright6 = "ffffff";
          };
        };
      };

      programs.ssh = { # Remote servers cannot deal with TERM=foot
        extraConfig = ''
          SetEnv TERM=xterm-256color
        '';
      };

      systemd.user.services.foot.Install.WantedBy = lib.optionals (config.my.home.wm.manager == "river") [ "river-session.target" ];
      home.packages = with pkgs; [
        xdg-utils # xdg-open required for foot url thingy
      ];
    })
  ]);
}

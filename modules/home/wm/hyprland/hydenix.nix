{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.home.wm.hyprland.hydenix;
in {
  imports = [ inputs.hydenix.homeModules.default ];
  options.my.home.wm.hyprland.hydenix = with lib; {
    enable = mkEnableOption "Use hydenix theme for hyprland";

    # modkey = mkOption {
    #   type = types.str;
    #   default = "SUPER"; # This is the 'windows' key on most keyboards.
    #   description = "Modkey to use for issuing commands to hyprland.hydenix";
    # };
    extra-config = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra lines to append to config of hydenix";
    };
  };

  config = lib.mkIf config.my.home.wm.hyprland.hydenix.enable {
    assertions = [
      { assertion = config.my.home.wm.hyprland.enable; message = "hydenix is a theme for hyprland, so requires hyprland enabled."; }
    ];


    # home-manager/local hydenix configuration
    # for more options, see https://github.com/richen604/hydenix/blob/main/template/docs/options.md
    # and here: https://github.com/richen604/hydenix/tree/main/hydenix/modules/hm
    hydenix.hm = {
      enable = true;

      # integrated program options
      comma.enable = false;
      editors = {
        enable = true;
        vscode.enable = false;
        neovim.enable = false;
        vim = true; # only adds styling
        default = config.my.home.editor.main.path;
      };
      fastfetch.enable = true;
      firefox.enable = false;
      git.enable = false;
      gtk.enable = true; # seb NOTE: I have some config in radon for this disabled... Let this do it? Or disable here, merge from profile / separate home module?
      hyde.enable = true;
      lockscreen = {
        enable = true;
        hyprlock = true; # other option: swaylock
      };
      notifications.enable = true;
      qt.enable = true; # only adds styling
      rofi.enable = true;
      screenshots.enable = true;
      shell = {
        enable = true;
        zsh.enable = false;
        starship.enable = false;
        bash.enable = false;
        fish.enable = true;
        fastfetch.enable = false;
      };
      social.enable = false;
      spotify.enable = true;
      swww.enable = true; # wallpapers
      terminals.enable = false; # they have only kitty, no foot
      theme = { # find themes here: https://github.com/HyDE-Project/hyde-gallery
        enable = true;
        active = "Catppuccin Mocha"; # the default
        themes = [ # all available themes on this host for this user
          "Catppuccin Mocha"
          "Catppuccin Latte"
        ];
      };
      uwsm.enable = true;
      waybar.enable = true; # seb TODO: I want this, but miss 'python-pyamdgpuinfo'... Is it me or does it just not work? Package appears to not exist
      wlogout.enable = true;
      xdg.enable = true;

      # hyprland configuration options
      hyprland = { # see specifically here for options: https://github.com/richen604/hydenix/blob/main/hydenix/modules/hm/hyprland/options.nix
        enable = true; # use this flake's own hyprland
        animations = {
          enable = true;
          preset = "standard"; # "fast" or "minimal-1" or "minimal-2" also sound nice
        };
        workflows = {
          enable = true;
          active = "default"; # could also be "editing", "gaming", "powersaver", or "snappy"
        };
        hypridle = {
          enable = true; # seb TODO: is it an idle lock-out thing?
        };
        keybindings = {
          enable = true; # I handle keybinds in the hyprland config TODO
          # extraConfig = '''';
          # overrideConfig = '''';
        };
        windowrules.enable = true; # seb TODO: what is this?
        nvidia.enable = false;
        pyprland.enable = true; # seb TODO: This extends hyprland functionality. Does this theme need it? If not, disable it?
        monitors.enable = true; # seb TODO: what is configured here?
      };
    };
  };
}

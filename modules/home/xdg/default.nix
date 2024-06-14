{ config, lib, ... }:
let
  cfg = config.my.home.xdg;
in
{
  options.my.home.xdg = with lib; {
    enable = mkEnableOption "XDG configuration";
    homedirs.enable = mkEnableOption "XDG configuration";
  };

  config.xdg = lib.mkIf cfg.enable {
    enable = true; # NOTE this manages the user directories if enabled.
    mime.enable = true; # File types
    mimeApps.enable = true; # File associatons
    userDirs = { # User directories
      enable = true;
      # lowercased
      desktop = "\$HOME/desktop";
      documents = "\$HOME/documents";
      download = "\$HOME/downloads";
      music = "\$HOME/music";
      pictures = "\$HOME/pictures";
      publicShare = "\$HOME/public";
      templates = "\$HOME/templates";
      videos = "\$HOME/videos";
    };
    # A tidy home is a tidy mind
    dataFile = {
      "bash/.keep".text = "";
      "gdb/.keep".text = "";
      "tig/.keep".text = "";
    };
    # configHome = "~/.config";
    configHome = config.home.homeDirectory/.config;
    dataHome = config.home.homeDirectory/.data;
  };

  # I want a tidier home
  config.home.sessionVariables = with config.xdg; lib.mkIf cfg.enable {
    ANDROID_HOME = "${dataHome}/android";
    ANDROID_USER_HOME = "${configHome}/android";
    CARGO_HOME = "${dataHome}/cargo";
    DOCKER_CONFIG = "${configHome}/docker";
    GRADLE_USER_HOME = "${dataHome}/gradle";
    HISTFILE = "${dataHome}/bash/history";
    INPUTRC = "${configHome}/readline/inputrc";
    PSQL_HISTORY = "${dataHome}/psql_history";
    PYTHONPYCACHEPREFIX = "${cacheHome}/python/";
    PYTHONUSERBASE = "${dataHome}/python/";
    PYTHON_HISTORY = "${stateHome}/python/history";
    REDISCLI_HISTFILE = "${dataHome}/redis/rediscli_history";
    REPO_CONFIG_DIR = "${configHome}/repo";
    XCOMPOSECACHE = "${dataHome}/X11/xcompose";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${configHome}/java";
  };
  # defaults:
  # environment.sessionVariables = {
  #   XDG_CACHE_HOME = "$HOME/.cache";
  #   XDG_CONFIG_DIRS = "/etc/xdg";
  #   XDG_CONFIG_HOME = "$HOME/.config";
  #   XDG_DATA_DIRS = "/usr/local/share/:/usr/share/";
  #   XDG_DATA_HOME = "$HOME/.local/share";
  #   XDG_STATE_HOME = "$HOME/.local/state";
  # };
}

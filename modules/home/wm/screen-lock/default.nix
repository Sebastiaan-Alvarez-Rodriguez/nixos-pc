{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm.apps.screen-lock;

  notficationCmd = let
    duration = toString (cfg.notify.delay * 1000);
    notifyCmd = "${lib.getExe pkgs.libnotify} -u critical -t ${duration}";
  in
    # Needs to be surrounded by quotes for systemd to launch it correctly
    ''"${notifyCmd} -- 'Locking in ${toString cfg.notify.delay} seconds'"'';
in {
  options.my.home.wm.apps.screen-lock = with lib; {
    command = mkOption {
      type = types.str;
      default = "${lib.getExe pkgs.i3lock} -n -c 000000";
      description = "Locker command to run";
    };

    cornerLock = {
      enable = mkEnableOption "Move mouse to upper-left corner to lock instantly, lower-right corner to disable auto-lock.";
      delay = mkOption {
        type = types.int;
        default = 5;
        description = "How many seconds before locking this way";
      };
    };

    notify = {
      enable = my.mkDisableOption "Notify when about to lock the screen";
      delay = mkOption {
        type = types.int;
        default = 5;
        description = ''
          How many seconds in advance should there be a notification.
          This value must be lesser than or equal to `cornerLock.delay` when both options are enabled.
        '';
      };
    };

    timeout = mkOption {
      type = types.ints.between 1 60;
      default = 15;
      description = "Inactive time interval to lock the screen automatically";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = let
          inherit (cfg) cornerLock notify;
          bothEnabled = cornerLock.enable && notify.enable;
          cornerLockHigherThanNotify = cornerLock.delay >= notify.delay;
        in
          bothEnabled -> cornerLockHigherThanNotify;
        message = ''
          `config.my.home.wm.apps.notify.delay` cannot have a value higher than
          `config.my.home.wm.apps.cornerLock.delay`.
        '';
      }
      {
        assertion = config.my.home.gm.x.enable;
        message = "screen-lock module requires x graphics manager (set my.home.gm.x.enable = true)";
      }

    ];

    services.screen-locker = {
      enable = true;

      inactiveInterval = cfg.timeout;

      lockCmd = cfg.command;

      xautolock = {
        extraOptions = lib.optionals cfg.cornerLock.enable [
          # Mouse corners: instant lock on upper-left, never lock on lower-right
          "-cornerdelay"
          "${toString cfg.cornerLock.delay}"
          "-cornerredelay"
          "${toString cfg.cornerLock.delay}"
          "-corners"
          "+00-"
        ] ++ lib.optionals cfg.notify.enable [
          "-notify"
          "${toString cfg.notify.delay}"
          "-notifier"
          notficationCmd
        ];
      };
    };
  };
}

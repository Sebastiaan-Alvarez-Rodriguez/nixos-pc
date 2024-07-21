{ config, lib, ... }: let
  cfg = config.my.profiles.lockscreen;
in {
  config = (lib.mkMerge [
    (lib.mkIf ((config.my.home ? wm) && config.my.home.wm.swaylock.enable) {
      security.pam.services.swaylock = {}; # required for swaylock to authenticate.
    })
  ]);
}

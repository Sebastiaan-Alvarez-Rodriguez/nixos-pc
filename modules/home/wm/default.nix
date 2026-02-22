{ config, lib, pkgs, ... }: let
  cfg = config.my.home.wm;
in {
  imports = [ ./i3 ./hyprland ./river ./apps ];
}

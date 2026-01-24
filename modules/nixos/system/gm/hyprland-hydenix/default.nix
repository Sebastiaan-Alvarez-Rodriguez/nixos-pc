  # Hydenix configuration - system part (disabled all things hydenix should not touch)
{ config, lib, pkgs, ... }: let
  cfg = config.my.system.hydenix;
in {
  options.my.system.hydenix = {
    enable = mkEnableOption "enable hydenix (system preparation) (do not forget home module activation)";
    enable-bluetooth = mkEnableOption "enable hydenix bluetooth instead of overriding it from hydenix to disabled";
  };
  config = lib.mkIf cfg.enable {
    hydenix = {
      enable = true; # Enable Hydenix modules
      # Basic System Settings (REQUIRED):
      hostname = config.my.hardware.networking.hostname;
      timezone = "Europe/Amsterdam";
      locale = "en_US.UTF-8";
      # For more configuration options, see: ./docs/options.md
      audio.enable = false;
      boot.enable = false;
      gaming.enable = false;
      hardware.enable = true;
      network.enable = false;
      nix.enable = true;
      sddm.enable = false; # seb NOTE: is nice to actually use, but cannot use it due to backend bug (wait until modern AMD gpu is supported on the wayland backend (weston)).
      system.enable = true;
    };
    hardware.bluetooth.enable = lib.mkForce cfg.enable-bluetooth; # hydenix system enables bluetooth, don't like it.
    programs.gnupg.agent.enable = lib.mkForce false; # seb NOTE: do not ask for passwords of keys with gpg agents
  };
}

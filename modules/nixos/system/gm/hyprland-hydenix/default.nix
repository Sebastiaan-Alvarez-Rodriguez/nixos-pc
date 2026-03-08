  # Hydenix configuration - system part (disabled all things hydenix should not touch).
  # Start this environment using command: `Hyprland`
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.system.hyprland-hydenix;
in {
  imports = [ inputs.hydenix.nixosModules.default ];
  options.my.system.hyprland-hydenix = with lib; {
    enable = mkEnableOption "enable hydenix (system preparation) (do not forget home module activation)";
    enable-bluetooth = mkEnableOption "enable hydenix bluetooth instead of overriding it from hydenix to disabled";

    hostname = mkOption {
      type = types.str;
      default = config.my.hardware.networking.hostname;
      example = "host";
      description = "hostname for this device";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/Amsterdam";
      description = "Timezone for this device";
    };
    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Locale for this device";
    };
  };
  config = lib.mkIf cfg.enable {
    hydenix = {
      enable = true; # Enable Hydenix modules
      # Basic System Settings (REQUIRED):
      hostname = lib.mkDefault cfg.hostname;
      timezone = lib.mkDefault cfg.timezone;
      locale = lib.mkDefault cfg.locale;
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

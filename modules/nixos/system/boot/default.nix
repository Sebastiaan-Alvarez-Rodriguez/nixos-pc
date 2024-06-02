{ config, lib, ... }:
let
  cfg = config.my.system.boot;
in
{
  options.my.system.boot = with lib; {
    enable = mkEnableOption "custom boot configuration";
    kind = mkOption {
      type = with types; nullOr (enum ["systemd" "grub"]); # https://nlewo.github.io/nixos-manual-sphinx/development/option-declarations.xml.html
      default = null;
      
      description = "Bootloader to use";
    };
    tmp = {
      clean = mkEnableOption "clean `/tmp` on boot.";
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Any extra configuration that should be applied.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = (lib.my.recursiveMerge [
      {
        tmp.cleanOnBoot = cfg.tmp.clean;
        loader = {
          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/boot/efi";

          # grub
          grub = lib.mkIf (cfg.kind == "grub") {
            enable = true;
            version = 2;
            device = "nodev";
            efiSupport = true;
            enableCryptodisk = true;
          };
          # systemd-boot
          systemd-boot.enable = (cfg.kind == "systemd");
        };
      }
      cfg.extraConfig
    ]);
  };
}

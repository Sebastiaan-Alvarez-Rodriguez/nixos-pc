# configuration for compatible HID++ mouses, e.g. MX master 3(s)
# from: https://github.com/PixlOne/logiops/wiki/Configuration
# docs: https://deepwiki.com/PixlOne/logiops/2-installation-and-configuration
#
# problem: cannot get device identifier via shell. Would only be possible when bluetooth-connecting the device with `logid`.
# issue: https://github.com/PixlOne/logiops/issues/463#issuecomment-2973488432
# There are references to Solaar - an alternative GUI-based program. With nix support.
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.logiops;

  deviceOption = with lib; types.submodule ({ name, ... }: {
    options = {
      dpi = mkOption {
        type = types.int;
        description = "Set DPI for mouse. Default mx master 3s equals 1000, max is 8000.";
        default = 1000; 
      };
      hiresscroll = {
        hires = mkEnableOption "Enable high-resolution scrolling. It scrolls pixel-by-pixel, similar to trackpads, rather than line-by-line scrolling. Feature only works when using bluetooth, not with bolt receiver.";
        invert = mkEnableOption "Invert scroll direction";
        target = mkEnableOption "Target mode for scrolling";
      };
      smartshift = {
        on = mkEnableOption "Enable smartshift. It automatically shifts the scroll wheel's mode between ratchet and smooth scrolling based on the user's scrolling speed.";
        treshold = mkOption {
          type = types.ints.between 0 255;
          description = "treshold to switch to free scrolling";
          default = 30;
        };
        torque = mkOption {
          type = types.int;
          description = "torque (only on smartshiftV2 devices)";
          default = 30;
        };
      };
    };
  });
in {
  options.my.services.logiops = with lib; {
    enable = mkEnableOption "logiops mouse configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.logiops;
      description = "Logiops package to use";
    };

    devices = mkOption {
      type = types.attrsOf deviceOption;
      default = {};
      description = ''
        per-device configuration.
        To get the correct identifier for your device, plug-in the device and run `nix shell nixpkgs#logiops -c sudo logid`.
        Full configuration option example: https://deepwiki.com/PixlOne/logiops/2-installation-and-configuration#complete-configuration-example
      '';
      example = litteralExample ''
        {
          "<identifier name>" = {
            dpi = 1000;
            hiresscroll.hires = true;
            smartshift = {
              on = true;
              treshold = 30;
              torque = 50;
            };
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.logiops = let
    configfile = pkgs.writeText "logiops.cfg" (lib.my.toLibConfig {
      devices = lib.mapAttrsToList (name: value: value // { name = name; }) cfg.devices;
    });
    in {
      description = "Logiops service";
      after = [ "multi-user.target" ];
      wants = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -c ${configfile}";
        DynamicUser = true;
        # StateDirectory = cfg.stateDir;
        # ReadWritePaths = "";
      };
    };
  };
}

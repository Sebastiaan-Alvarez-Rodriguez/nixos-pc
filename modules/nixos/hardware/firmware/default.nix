{ config, lib, ... }: let
  cfg = config.my.hardware.firmware;
in {
  options.my.hardware.firmware = with lib; {
    enable = mkEnableOption "firmware configuration";

    cpu-flavor = mkOption {
      type = with types; nullOr (enum [ "intel" "amd" ]);
      default = null;
      example = "intel";
      description = "Which kind of CPU to activate micro-code updates";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      hardware = {
        enableRedistributableFirmware = true;
      };
    }

    (lib.mkIf (cfg.cpu-flavor == "intel") {
      hardware = {
        cpu.intel.updateMicrocode = true;
      };
    })

    (lib.mkIf (cfg.cpu-flavor == "amd") {
      hardware = {
        cpu.amd.updateMicrocode = true;
      };
    })
  ]);
}

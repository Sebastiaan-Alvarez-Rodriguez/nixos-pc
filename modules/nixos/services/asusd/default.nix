# Control fans on asus machines. Provides `asusctl`
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.asusd;
in {
  options.my.services.asusd = with lib; {
    enable = mkEnableOption "Control fans on asus machines";
    package = mkOption {
      type = types.package;
      default = pkgs.asusctl;
      description = "package to use";
    };

    asusd-config = {
      charge_control_end_threshold = mkOption {
        type = with types; nullOr int;
        default = null;
        description = "battery charge limit in percents.";
      };

      disable_nvidia_powerd_on_battery = mkOption {
        type = types.boolean;
        default = true;
        description = "disables dGPU when on battery";
      };

      ac_command = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "An optional command/script to run when power is changed to AC";
      };

      bat_command = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "An optional command/script to run when power is changed to battery";
      };

      platform_profile_linked_epp = mkOption {
        type = types.boolean;
        default = true;
        description = "Set true if energy_performance_preference should be set if the platform profile is changed";
      };

      platform_profile_on_battery = mkOption {
        type = types.enum [ "quiet" "balanced" "performance" ];
        default = "quiet";
        description = "Which platform profile to use on battery power";
      };

      change_platform_profile_on_battery = mkOption {
        type = types.boolean;
        default = true;
        description = "Should the throttle policy be set on bat/ac change?";
      };

      platform_profile_on_ac = mkOption {
        type = types.enum [ "quiet" "balanced" "performance" ];
        default = "performance";
        description = "Which platform profile to use on AC power";
      };

      change_platform_profile_on_ac = mkOption {
        type = types.boolean;
        default = true;
        description = "Should the throttle policy be set on bat/ac change?";
      };
      
      profile_quiet_epp = mkOption {
        type = types.enum [ "Power" "BalancePower" "Performance" ];
        default = "Power";
        description = "The energy_performance_preference for this platform profile";
      };

      profile_balanced_epp = mkOption {
        type = types.enum [ "Power" "BalancePower" "Performance" ];
        default = "BalancePower";
        description = "The energy_performance_preference for this platform profile";
      };
      
      profile_performance_epp = mkOption {
        type = types.enum [ "Power" "BalancePower" "Performance" ];
        default = "Performance";
        description = "The energy_performance_preference for this platform profile";
      };

      profile_custom_epp = mkOption {
        type = types.enum [ "Power" "BalancePower" "Performance" ];
        default = "Performance";
        description = "The energy_performance_preference for this platform profile";
      };
      # pub ac_profile_tunings: Tunings,
      # pub dc_profile_tunings: Tunings,
      # pub armoury_settings: HashMap<FirmwareAttribute, i32>,
      # #[serde(skip_serializing_if = "Option::is_none", default)]
      # pub screenpad_gamma: Option<f32>,
      # #[serde(skip_serializing_if = "Option::is_none", default)]
      # pub screenpad_sync_primary: Option<bool>,
      # /// Temporary state for AC/Batt

    };

    fancurves = mkOption {
      type = with types; nullOr (listOf (submodule {
        options = {
          temperature = mkOption {
            type = int;
            description = "temperature setpoint in degrees C.";
          };
          fanspeed = mkOption {
            type = int;
            description = "fancurve setpoint in percents.";
          };
        };
      }));
      default = null;
      description = "Fancurve configuration";
    };
  };

  config = let
    optvalstr = var: val: lib.optionalString (val != null) "\"${var}\": ${val}";
  in lib.mkIf cfg.enable {
    services.asusd = {
      inherit (cfg) enable package;
      asusdConfig.text = builtins.concatStringsSep ",\n" [
        (optvalstr "bat_charge_limit" cfg.asusd-config.battery-charge-limit)
      ];

      enableUserService = false;

      fanCurvesConfig.text = let
        mkcurvepointstr = point: "${builtins.toString point.temperature}:${builtins.toString point.fanspeed}";
        mkcurvestr = points: builtins.concatStringsSep "," (builtins.map mkcurvepointstr (lib.sort (a: b: a.temperature < b.temperature) points));
      in lib.optionalString (cfg.fancurves != null) (mkcurvestr cfg.fancurves);
    };
  };
}

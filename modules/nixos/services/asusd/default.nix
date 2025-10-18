# Control fans and power management on asus machines. Provides `asusctl`
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
        type = with types; int;
        default = 100;
        description = "battery charge limit in percents (is overridden by others like TLP or chargectl).";
      };

      disable_nvidia_powerd_on_battery = mkOption {
        type = types.bool;
        default = true;
        description = "disables dGPU when on battery";
      };

      ac_command = mkOption {
        type = with types; str;
        default = "";
        description = "An optional command/script to run when power is changed to AC";
      };

      bat_command = mkOption {
        type = with types; str;
        default = "";
        description = "An optional command/script to run when power is changed to battery";
      };

      platform_profile_linked_epp = mkOption {
        type = types.bool;
        default = true;
        description = "Set true if energy_performance_preference should be set if the platform profile is changed";
      };

      platform_profile_on_battery = mkOption {
        type = types.enum [ "Quiet" "Balanced" "Performance" ];
        default = "Quiet";
        description = "Which platform profile to use on battery power";
      };

      change_platform_profile_on_battery = mkOption {
        type = types.bool;
        default = true;
        description = "Should the throttle policy be set on bat/ac change?";
      };

      platform_profile_on_ac = mkOption {
        type = types.enum [ "Quiet" "Balanced" "Performance" ];
        default = "Performance";
        description = "Which platform profile to use on AC power";
      };

      change_platform_profile_on_ac = mkOption {
        type = types.bool;
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
    };

    fancurves = let
      fan-options = with types; (submodule { options = {
        pwm = mkOption {
          type = listOf (int);
          description = "PWM values for when specified temperature is reached (this is specified in 'temp')";
        };
        temp = mkOption {
          type = listOf (int);
          description = "Temp values (PWM values at same index are applied)";
        };
        enabled = mkOption {
          default = true;
          description = "Enable the curve setting. I don't know what this is for.";
        };
      };});
      profile-options = with types; nullOr (submodule { options = {
        cpu = mkOption { type = fan-options; description = "CPU config"; };
        gpu = mkOption { type = fan-options; description = "GPU config"; };
      };});
      profiles-options = with types; (submodule { options = {
        balanced = mkOption {
          type = profile-options;
          default = null;
          description = "balanced config";
        };
        performance = mkOption {
          type = profile-options;
          default = null;
          description = "performance config";
        };
        quiet = mkOption {
          type = profile-options;
          default = null;
          description = "quiet config";
        };
        custom = mkOption {
          type = profile-options;
          default = null;
          description = "custom config";
        };
      };});
    in mkOption {
      type = profiles-options;
      default = {
        balanced = {
          cpu = { pwm = [ 28 40 48 58 71 102 119 135 ]; temp = [ 20 48 51 54 57 61 65 98 ]; };
          gpu = { pwm = [ 35 53 63 71 86 112 130 155]; temp = [ 20 48 51 54 57 61 65 98 ]; };
        };
        performance = {
          cpu = { pwm = [ 45 58 71 89 102 114 135 158 ]; temp = [ 20 50 55 60 65 70 75 98 ]; };
          gpu = { pwm = [ 63 71 86 102 112 124 155 178 ]; temp = [ 20 50 55 60 65 70 75 98 ]; };
        };
        quiet = {
          cpu = { pwm = [ 17 28 35 40 48 58 71 89 ]; temp = [ 20 44 47 50 53 56 60 98 ]; };
          gpu = { pwm = [ 28 35 45 53 63 71 86 102 ]; temp = [ 20 44 47 50 53 56 60 98 ]; };
        };
        custom = null;
      };
      example = {balanced = { cpu = {pwm = [30 80 178]; temp = [20 70 85];};};};
      description = "Fancurve configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = let
      cmp-pwm-tmp = attrs: (builtins.length attrs.pwm) == (builtins.length attrs.temp);
      cmp-min-setpoints = attrs: (builtins.length attrs.temp) >= 8; # must have 8 setpoints at least... Undocumented.
      unequal-pwm-tmp = builtins.attrNames (lib.filterAttrs (k: v: ((v != null) && !((cmp-pwm-tmp v.cpu) && (cmp-pwm-tmp v.gpu)))) cfg.fancurves);
      too-few-setpoints = builtins.attrNames (lib.filterAttrs (k: v: ((v != null) && !((cmp-min-setpoints v.cpu) && (cmp-min-setpoints v.gpu)))) cfg.fancurves);
    in [
      { assertion = (builtins.length unequal-pwm-tmp) == 0; message = "Found fancurves with non-equal amount of temp-setpoints and fan pwm values: [${builtins.toString unequal-pwm-tmp}]"; }
      { assertion = (builtins.length too-few-setpoints) == 0; message = "Found fancurves with less than 8 temp-setpoints (this is required for BOTH cpu AND gpu): [${builtins.toString too-few-setpoints}]"; }
    ];
    services.asusd = {
      inherit (cfg) enable package;
      asusdConfig.text = let
        # function to produce a single config line
        removenulls = attrs: lib.filterAttrs (k: v: v != null) attrs;
        except = keys: attrs: builtins.removeAttrs attrs keys;
        mkval = val: if builtins.isBool val then (lib.boolToString val) else (builtins.toString val);
        mkentry = var: val: "${var}: ${(mkval val)},";
        mkentries = attrs: (lib.mapAttrsToList mkentry (except ["ac_command" "bat_command"] (removenulls attrs)));
      in ''
        (
          ${builtins.concatStringsSep "\n  " (mkentries cfg.asusd-config)}
          ac_command: "${cfg.asusd-config.ac_command}",
          bat_command: "${cfg.asusd-config.bat_command}",
          ac_profile_tunings: {},
          dc_profile_tunings: {
            Quiet: (
              enabled: false,
              group: {},
            ),
          },
          armoury_settings: {},
        )
      '';

      enableUserService = false;

      fanCurvesConfig.text = let
        mkcurvestr = points: ''(${builtins.concatStringsSep ", " (builtins.map builtins.toString points)})'';
        mkfansettings = target: opts: ''
          fan: ${target},
          pwm: ${mkcurvestr opts.pwm},
          temp: ${mkcurvestr opts.temp},
          enabled: ${if opts.enabled then "true" else "false"},'';
        mkprofilesettings = opts: lib.concatLines [
          "    ${mkfansettings "CPU" opts.cpu}"
          "),"
          "("
          "    ${mkfansettings "GPU" opts.gpu}"
        ];
        mkprofile = name: profile-opts: if profile-opts == null then "[]" else lib.concatLines [
          "    ${name}: ["
          "        ("
          "        ${mkprofilesettings profile-opts}"
          "        ),"
          "    ],"
        ];
      in ''
        (
            profiles: (
                ${mkprofile "balanced" cfg.fancurves.balanced}
                ${mkprofile "performance" cfg.fancurves.performance}
                ${mkprofile "quiet" cfg.fancurves.quiet}
                ${mkprofile "custom" cfg.fancurves.custom}
            ),
        )'';
    };
    systemd.services.asusd.preStart = let
      pick-contents = item: if item.source != null then item.source else item.text;
      mkoverride-etc = path: contents: lib.optionalString (contents != null) ''
        rm -f /etc/${path}
        cp ${pkgs.writeText (builtins.baseNameOf path) (pick-contents contents)} /etc/${path}
        chmod 664 /etc/${path}
      '';
    in builtins.concatStringsSep "\n" [
      (mkoverride-etc "asusd/anime.ron" config.services.asusd.animeConfig)
      (mkoverride-etc "asusd/asusd.ron" config.services.asusd.asusdConfig)
      (mkoverride-etc "asusd/profile.ron" config.services.asusd.profileConfig)
      (mkoverride-etc "asusd/fan_curves.ron" config.services.asusd.fanCurvesConfig)
      (mkoverride-etc "asusd/asusd_user_ledmodes.ron" config.services.asusd.userLedModesConfig)
    ];
  };
}

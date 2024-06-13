{ config, lib, pkgs, ... }: let
  cfg = config.my.hardware.sound;
in {
  options.my.hardware.sound = with lib; {
    pipewire = {
      enable = mkEnableOption "pipewire configuration";
    };
    pulse = {
      enable = mkEnableOption "pulseaudio configuration";
    };
  };

  config = (lib.mkMerge [
    {
      assertions = [
        {
          assertion = builtins.all (lib.id) [ (cfg.pipewire.enable -> !cfg.pulse.enable) (cfg.pulse.enable -> !cfg.pipewire.enable) ];
          message = "`config.my.hardware.sound.pipewire.enable` and `config.my.hardware.sound.pulse.enable` are incompatible.";
        }
      ];

      environment.systemPackages = [ pkgs.pavucontrol ];
    }

    (lib.mkIf cfg.pipewire.enable {
      security.rtkit.enable = true;
      sound.enable = true; # seb: TODO is this required here?
      hardware.pulseaudio.enable = false; # explicitly disable.

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # seb: NOTE: I don't know what this does, but I do know it sets the LD_LIBRARY_PATH variable to a string instead of a list, which means it cannot merge.
        # Kind of like: https://github.com/NixOS/nixpkgs/issues/20225
        # jack.enable = true; 
      };
    })
    
    # Pulseaudio setup
    (lib.mkIf cfg.pulse.enable {
      # ALSA
      sound.enable = true;
      hardware.pulseaudio.enable = true;
    })
  ]);
}

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
      services.pulseaudio.enable = false; # explicitly disable.

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      environment.systemPackages = with pkgs; [ pamixer playerctl ];
    })
    
    # Pulseaudio setup
    (lib.mkIf cfg.pulse.enable {
      # ALSA
      services.pulseaudio.enable = true;
    })
  ]);
}

{ config, lib, pkgs, ... }: let
  cfg = config.my.hardware.graphics;
in {
  options.my.hardware.graphics = with lib; {
    amd = {
      enable = mkEnableOption "graphics configuration";
      enableKernelModule = lib.my.mkDisableOption "Kernel driver module";
      amdvlk = lib.mkEnableOption "Use AMDVLK instead of Mesa RADV driver";
    };

    intel = {
      enable = mkEnableOption "graphics configuration";
      enableKernelModule = lib.my.mkDisableOption "Kernel driver module";
    };
  };

  config = lib.mkIf (cfg.amd.enable || cfg.intel.enable) (lib.mkMerge [
    {
      hardware.opengl.enable = true;
      environment.variables = rec { # Set session env vars
        LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib";
        LD_PREFIX_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib";
      };
    }

    # AMD GPU
    (lib.mkIf cfg.amd.enable {
      boot.initrd.kernelModules = lib.mkIf cfg.amd.enableKernelModule [ "amdgpu" ];

      hardware.opengl = {
        extraPackages = with pkgs; [ rocmPackages.clr rocmPackages.clr.icd ] ++ lib.optional cfg.amd.amdvlk amdvlk; # first part adds rocm-openCL
        extraPackages32 = with pkgs; [ ] ++ lib.optional cfg.amd.amdvlk driversi686Linux.amdvlk ;
      };
    })

    # Intel GPU
    (lib.mkIf cfg.intel.enable {
      boot.initrd.kernelModules = lib.mkIf cfg.intel.enableKernelModule [ "i915" ];

      environment.variables = {
        VDPAU_DRIVER = "va_gl";
      };

      hardware.opengl = {
        extraPackages = with pkgs; [
          # Open CL
          intel-compute-runtime

          # VA API
          intel-media-driver
          intel-vaapi-driver
          libvdpau-va-gl
        ];
      };
    })
    # seb: add NVIDIA
  ]);
}

{ config, lib, pkgs, ... }: let
  cfg = config.my.hardware.graphics;
in {
  options.my.hardware.graphics = with lib; {
    amd = {
      enable = mkEnableOption "graphics configuration";
      enableKernelModule = mkEnableOption "Kernel driver module";
      amdvlk = mkEnableOption "Use AMDVLK instead of Mesa RADV driver";
    };

    intel = {
      enable = mkEnableOption "graphics configuration";
      enableKernelModule = mkEnableOption "Kernel driver module";
    };

    nvidia = {
      enable = mkEnableOption "graphics configuration";
      package = mkOption {
        type = with types; package;
        default = config.boot.kernelPackages.nvidiaPackages.stable;
        description = "Package to use as driver. Any version from https://nixos.wiki/wiki/Nvidia (section 'Determining the Correct Driver Version')";
      };

      powermanagement.enable = mkEnableOption "Enable experimental power management through systemd.";
      powermanagement.finegrained = mkEnableOption "Enable experimental power management on PRIME offload.";
      prime = mkOption {
        type = with types; submodule {
          options.offload = mkEnableOption "Enable gpu offloading. Mutual exclusive to nvidia.prime.sync. This is more power-efficient.";
          options.sync.enable = mkEnableOption "Enable gpu syncing. Mutual exclusive to offloading. This is more performant.";

          options.amdgpuBusID = mkOption {
            type = nullOr (str);
            default = null;
            example = "PCI:4:0:0";
            description = "AMD (integrated) bus ID. Get this value by running `nix run nixpkgs#lshw -- -c display`. https://nixos.wiki/wiki/Nvidia";
          };
          options.intelgpuBusID = mkOption {
            type = nullOr (str);
            default = null;
            example = "PCI:4:0:0";
            description = "Intel (integrated) bus ID. Get this value by running `nix run nixpkgs#lshw -- -c display`. https://nixos.wiki/wiki/Nvidia";
          };
          options.nvidiagpuBusID = mkOption {
            type = nullOr (str);
            default = null;
            example = "PCI:4:0:0";
            description = "Nvidia gpu bus ID. Get this value by running `nix run nixpkgs#lshw -- -c display`. https://nixos.wiki/wiki/Nvidia";
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.amd.enable or cfg.intel.enable) (lib.mkMerge [
    {
      assertions = [
        {
          assertion = (lib.count (x: x) [cfg.amd.enable cfg.intel.enable cfg.nvidia.enable]) <= 1;
          message = "At most 1 of graphics.amd.enable, graphics.intel.enable, graphics.nvidia.enable may be enabled. found: \"${builtins.toString [cfg.amd.enable cfg.intel.enable cfg.nvidia.enable]}\"";
        }
        {
          assertion = cfg.nvidia.enable && (cfg.nvidia.prime.offload || cfg.nvidia.prime.sync) -> cfg.nvidia.prime.nvidiagpuBusId != null;
          message = "When using nvidia.prime.offload/sync, then nvidia.prime.nvidiagpuBusId must be set.";
        }
        {
          assertion = cfg.nvidia.enable && (cfg.nvidia.prime.offload || cfg.nvidia.prime.sync) -> (cfg.nvidia.prime.amdgpuBusId != null && cfg.nvidia.prime.intelgpuBusId == null) || (cfg.nvidia.prime.amdgpuBusId == null && cfg.nvidia.prime.intelgpuBusId != null);
          message = "When using nvidia.prime.offload/sync, then exactly 1 of nvidia.prime.amdgpuBusId, nividia.prime.intelgpuBusId must be set. found: \"${builtins.toString [cfg.nvidia.prime.amdgpuBusId cfg.nvidia.prime.intelgpuBusId]}\"";
        }
      ];
      hardware.opengl.enable = true;
      environment.variables = { # Set session env vars
        LD_LIBRARY_PATH = ["/run/opengl-driver/lib:/run/opengl-driver-32/lib"];
        LD_PREFIX_PATH = ["/run/opengl-driver/lib:/run/opengl-driver-32/lib"];
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

    # Nvidia GPU
    (lib.mkIf cfg.nvidia.enable {
      # Inspired by: https://nixos.wiki/wiki/Nvidia
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true; # Enable the nvidia settings menu
        # NOTE: Open source driver does not support sleep/hibernate.
        open = false; # Uses open-source variant of driver. NOTE: This is not 'nouveau'. Supported GPU's: https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
  
        powerManagement.enable = cfg.nvidia.powermanagement.enable; # Experimental: Enables nvidia's power mgmt. May cause sleep/suspend to fail.
        powerManagement.finegrained = cfg.nvidia.powermanagement.finegrained; # Experimental: Turns off GPU when not in use. Only works on gpu's having Turing or newer architecture. 

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = cfg.nvidia.package;

        prime = { 
          offload = lib.mkIf cfg.nvidia.prime.offload {
          	enable = true;
          	enableOffloadCmd = true;
          };
          sync.enable = cfg.nvidia.prime.sync;
      		amdgpuBusId = lib.mkIf (cfg.nvidia.prime.amdgpuBusId != null) cfg.nvidia.prime.amdgpuBusId;
      		nvidiaBusId = lib.mkIf (cfg.nvidia.prime.nvidiagpuBusId != null) cfg.nvidia.prime.nvidiagpuBusId;
          intelBusId = lib.mkIf (cfg.nvidia.prime.intelgpuBusId != null) cfg.nvidia.prime.intelgpuBusId;
        };
        # programs DO NOT use nvidia gpu by default. To activate it, use `nvidia-offload <program> <args>`
      };
      
    })
  ]);
}

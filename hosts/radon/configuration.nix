{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader.
  # boot.loader = {
    # grub = {
      # enable = true;
      # version = 2;
      # device = "nodev";
      # efiSupport = true;
      # enableCryptodisk = true;
    # };
    # efi = {
      # canTouchEfiVariables = true;
      # efiSysMountPoint = "/boot/efi";
    # };
  # };

  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";


  boot = {
    cleanTmpDir = true;
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd = {
      # Setup keyfile
      secrets = {
        "/crypto_keyfile.bin" = null;
      };
      # Load amd gpu kernel module
      kernelModules = [ "amdgpu" ];
    };
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
    # Allow NTFS reading https://nixos.wifi/wiki/NTFS
    supportedFilesystems = [ "ntfs" ];
  };

  # Allow NTFS writing
  # fileSystems."/mnt/TITAN" =
  # { device = "/dev/nvme1n1p2";
    # fsType = "ntfs3";
    # options = [ "rw" "uid=1000"];
  # };
 
  # Allow openGL. https://nixos.wiki/wiki/OpenGL
  hardware.opengl.enable = true;
  environment.variables = rec { # Set session env vars
      LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib";
      LD_PREFIX_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = "radon";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.utf8";
    LC_IDENTIFICATION = "nl_NL.utf8";
    LC_MEASUREMENT = "nl_NL.utf8";
    LC_MONETARY = "nl_NL.utf8";
    LC_NAME = "nl_NL.utf8";
    LC_NUMERIC = "nl_NL.utf8";
    LC_PAPER = "nl_NL.utf8";
    LC_TELEPHONE = "nl_NL.utf8";
    LC_TIME = "nl_NL.utf8";
  };

  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;

    # Use amdgpu driver for Xserver
    videoDrivers = [ "amdgpu" ];

    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;

    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  virtualisation.docker.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Adds adb program. Users must be added to the "adbusers" group
  programs.adb.enable = true;
   
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  };

  # For all those executables with hardcoded /lib64 dynamic linker
  programs.nix-ld.enable = true;

  # Service to take over pcs of other people
  services.teamviewer.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };


  environment.systemPackages = [
    pkgs.home-manager
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rdn = {
    isNormalUser = true;
    description = "rdn";
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers"];
    shell = pkgs.fish;
    password = "changeme";
  };

  system.stateVersion = "22.05"; # Do not change
}

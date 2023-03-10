{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  ## Boot
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
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    '';
    # Allow NTFS reading https://nixos.wifi/wiki/NTFS
    supportedFilesystems = [ "ntfs" ];

    # Emulate for aarch64-linux builds
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = "polonium";
    networkmanager.enable = true;
  };

  hardware.bluetooth.enable = true;

  # Video
  hardware.nvidia = {
    modesetting.enable = true;
    prime = {
      sync.enable = false;
      offload.enable = true;
      # nvidiaBusId = "PCI:1:0:0";
      # intelBusId = "PCI:4:0:0";
    };
    powerManagement.enable = true;
  };

  time.timeZone = "Europe/Amsterdam";
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
    
    # Enable the KDE Plasma Desktop Environment.
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;

    # Configure keymap in X11
    layout = "us";
    xkbVariant = "";

    # Enable touchpad support (enabled default in most desktopManagers).
    libinput.enable = true;
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

  # Run games with this program for more optimized performance.
  programs.gamemode.enable = true;


  # Power saving
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  services.power-profiles-daemon.enable=false; # conflicts with tlp, https://github.com/linrunner/TLP/issues/564


  # Set password with ‘passwd’.
  users.users.rdn = {
    isNormalUser = true;
    description = "rdn";
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "adbusers" ];
    shell = pkgs.fish;
    password = "changeme";
  };

  users.users.mrs = {
    isNormalUser = true;
    description = "mrs";
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "adbusers" ];
    shell = pkgs.fish;
    password = "changeme";
  };
  

  environment.systemPackages = with pkgs; [
    pkgs.home-manager
  ];

  system.stateVersion = "22.05"; # Do not change
}

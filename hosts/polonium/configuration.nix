{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  ## Boot
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.secrets = { # Setup keyfile
      "/crypto_keyfile.bin" = null;
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
    # binfmt.emulatedSystems = [ "aarch64-linux" ];
  };
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "polonium";
  networking.networkmanager.enable = true;

  # Input
  services.xserver.xkbOptions = "caps:hyper,compose:rctrl";
  console.useXkbConfig = true;

  hardware.bluetooth.enable = true;

  # Video
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   prime.sync.enable = false;
  #   prime.offload.enable = true;
  #   #prime.nvidiaBusId = "PCI:1:0:0";
  #   #prime.intelBusId = "PCI:4:0:0";
  #   powerManagement.enable = true;
  # };
  hardware.nvidia = {
    modesetting.enable = true;
    prime.sync.enable = true;
    prime.offload.enable = false;
    powerManagement.enable = true;
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  programs.xwayland.enable = true;

  services.greetd = {
    enable = true;
    restart = false;
    settings = rec {
      initial_session =
      let
        run = pkgs.writeShellScript "start-river" ''
          # Seems to be needed to get river to properly start
          sleep 1
          # Set the proper XDG desktop so that xdg-desktop-portal works
          # This needs to be done before river is started
          export XDG_CURRENT_DESKTOP=river
          ${pkgs.river}/bin/river
        '';
      in
      {
        command = "${run}";
        user = "rdn";
      };
      default_session = initial_session;
    };
  };

  services.dbus.enable = true;

  services.logind = {
    #lidSwitch = "ignore";
    #lidSwitchDocked = "ignore";
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Now use wayland, xserver appears to crash
  # services.xserver = {
  #   # Enable the X11 windowing system.
  #   enable = true;
    
  #   # Enable the KDE Plasma Desktop Environment.
  #   displayManager.sddm.enable = true;
  #   desktopManager.plasma5.enable = true;

  #   # Configure keymap in X11
  #   layout = "us";
  #   xkbVariant = "";

  #   # Enable touchpad support (enabled default in most desktopManagers).
  #   libinput.enable = true;
  # };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

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

  programs.adb.enable = true; # Note: Users must be added to the "adbusers" group
  programs.fish.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  };
  programs.gamemode.enable = true; # Run games with this program for more optimized performance.
  programs.dconf.enable = true;


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

  system.stateVersion = "23.05"; # Do not change
}

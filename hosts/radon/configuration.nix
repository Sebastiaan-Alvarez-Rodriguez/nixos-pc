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
    tmp.cleanOnBoot = true;
    loader.systemd-boot.enable = true;
    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
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

  # services.openssh = {
  #   enable = true;
  #   settings.PermitRootLogin = "no";
  #   settings.PasswordAuthentication = true;
  # };

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

  networking.hostName = "radon";
  networking.networkmanager.enable = true;

  # Set your time zone.
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
    extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];
  };

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
  programs.fish.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  };
  programs.dconf.enable = true;
  # For all those executables with hardcoded /lib64 dynamic linker
  programs.nix-ld.enable = true;

  # Service to take over pcs of other people
  # services.teamviewer.enable = true;

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

  system.stateVersion = "23.05"; # Do not change
}

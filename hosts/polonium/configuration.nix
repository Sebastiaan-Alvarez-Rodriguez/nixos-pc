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

  # networking.firewall = {
  #   allowedTCPPorts = [
  #     21025 # starbound server - local hosting tmp
  #   ];
  #   allowedUDPPorts = [ ];
  # };

  # networking.nameservers = [ "127.0.0.1" "::1" ];
  # dhcpcd.extraConfig = "nohook resolv.conf"; # If using dhcpcd
  # networking.networkmanager.dns = "none";
  # services.resolved.enable = false; # must be disabled

  # ## Encrypted DNS
  # services.dnscrypt-proxy2 = { # https://nixos.wiki/wiki/Encrypted_DNS
  #   enable = true; # TODO: fix... see config options: https://github.com/DNSCrypt/dnscrypt-proxy/wiki/Configuration
  #   # error is 'stamp too short. Probably fixable... Might be known by cobra'
  #   settings = {
  #     ipv6_servers = true;
  #     require_dnssec = true;
  #     require_nolog = true; # We shall not log DNS queries
  #     http3 = false; # experimental HTTP3 support (Note that this uses UDP port 443 instead of TCP)

  #     server_names = ["ipv4-pythons-space-nolog-secure" "ipv6-pythons-space-nolog-secure"];
  #     static = { # https://dnscrypt.info/stamps/
  #       "ipv4-pythons-space-nolog-secure".stamp = "sdns://AQcAAAAAAAAADDkyLjYzLjE3My41MQAQMi5kbnNjcnlwdC1jZXJ0Lg";
  #       "ipv6-pythons-space-nolog-secure".stamp = "sdns://AQcAAAAAAAAAJVsyYTA1OjE1MDA6NzAyOjM6MWMwMDo1NGZmOmZlMDA6MTQzY10AEDIuZG5zY3J5cHQtY2VydC4";
  #     };
  #   };
  # };
  # systemd.services.dnscrypt-proxy2.serviceConfig = {
  #   StateDirectory = "dnscrypt-proxy";
  # };

  # networking.nameservers = [ "92.63.173.51" "2a05:1500:702:3:1c00:54ff:fe00:143c" ];

  # Temporarily enable SSH connection for file syncs
  # services.openssh = {
  #   enable = true;
  #   passwordAuthentication = true;
  # };

  # Input
  services.xserver.xkbOptions = "caps:hyper,compose:rctrl";
  console.useXkbConfig = true;

  hardware.bluetooth.enable = true;

  # Video
  hardware.nvidia = {
    # modesetting.enable = true;
    nvidiaSettings = true; # Enable the nvidia settings menu
    open = true; # Uses open-source variant of driver. NOTE: This is not 'nouveau'. Supported GPU's: https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    
    # powerManagement.enable = true; # Experimental: Enables nvidia's power mgmt. May cause sleep/suspend to fail.
    # powerManagement.finegrained = true; # Experimental: Turns off GPU when not in use. Only works on gpu's having Turing or newer architecture. 

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # prime = { # WARNING: Make sure to use the correct Bus ID values for your system! Use `nix run nixpkgs#lshw -- -c display`. https://nixos.wiki/wiki/Nvidia.
    #   offload = {
    #   	enable = true;
    #   	enableOffloadCmd = true;
    #   };
  		# amdgpuBusId = "PCI:4:0:0";
  		# nvidiaBusId = "PCI:1:0:0";
    # };
    # programs DO NOT use nvidia gpu by default. To activate it, use `nvidia-offload <program> <args>`
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
          WLR_DRM_DEVICES=/dev/dri/card0 ${pkgs.river}/bin/river
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
    config.common.default = "*";
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

  # services.syncthing = {
  #   enable = true;
  #   user = "rdn";
  #   overrideDevices = true; # Overrides web ui input
  #   overrideFolders = true; # Overrides web ui input
  #   settings.devices = {
  #     "apex" = {id="QJOIABO-SMQWMLF-I2EX26V-UBDX6PR-LRS2ZMU-3PRAJAL-DJ3BUYO-22XBEAU";};
  #     "polonium" = {id="US6ZAVZ-7UAT7ZU-EBJHDA7-3TAT2DM-UXEXXGR-OA3EL2P-ZAFKQYP-DGQ4PAX";};
  #   };
  # };

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
  
# tracker website blocking
  networking.extraHosts = ''
    0.0.0.0  connect.facebook.net
    0.0.0.0 datadome.co
    0.0.0.0 usage.trackjs.com
    0.0.0.0 googletagmanager.com
    0.0.0.0 firebaselogging-pa.googleapis.com
    0.0.0.0 redshell.io
    0.0.0.0 api.redshell.io
    0.0.0.0 treasuredata.com
    0.0.0.0 api.treasuredata.com
    0.0.0.0 in.treasuredata.com
    0.0.0.0 cdn.rdshll.com
    0.0.0.0 t.redshell.io
    0.0.0.0 innervate.us
  '';

  environment.systemPackages = with pkgs; [
    # brightnessctl # brightness keys on laptop
    home-manager
    # playerctl # volume keys on laptop
    asusctl
  ];

  system.stateVersion = "23.11"; # Do not change
}

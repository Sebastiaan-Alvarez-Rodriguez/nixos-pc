{ config, pkgs, ... }:

{
  imports = [
      ./hardware-configuration.nix
    ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
  };

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  
  boot.supportedFilesystems = [ "ntfs" ]; # Allow NTFS reading https://nixos.wifi/wiki/NTFS
  fileSystems."/mnt/CORSAIR" = { # Allow NTFS writing
    device = "/dev/nvme1n1p4";
    fsType = "ntfs3";
    options = [ "rw" "uid=1000"];
  };

  networking = {
    hostName = "polonium";
    networkmanager.enable = true;
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

  # Define a user account. Set password with ‘passwd’.
  users.users.rdn = {
    isNormalUser = true;
    description = "rdn";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
      git
      wget
      micro
      kate
    ];
  };

  environment.systemPackages = with pkgs; [
    pkgs.home-manager
  ];


  system.stateVersion = "22.05"; # Do not change
}

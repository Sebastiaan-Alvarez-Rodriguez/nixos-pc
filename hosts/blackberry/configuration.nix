{ config, pkgs, ... }: {

  boot.supportedFilesystems = [ "vfat" "f2fs" "ntfs" "cifs" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = "blackberry";
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
}
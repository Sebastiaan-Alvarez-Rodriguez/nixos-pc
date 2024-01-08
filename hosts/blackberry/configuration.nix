{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    supportedFilesystems = [ "vfat" "f2fs" "ntfs" "cifs" ];
    # loader.raspberryPi = { # as from https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3
    #   enable = true;
    #   version = 3;
    #   uboot.enable = true;
    #   firmwareConfig = ''
    #     core_freq=250
    #   '';
    # };
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.bluetooth.enable = false;

  networking = {
    hostName = "blackberry";
    # networkmanager.enable = true; # do not enable this: Compile error occurs.

    firewall = {
      allowedTCPPorts = [
        80    # HTTP
        443   # HTTPS
        8000  # HTTP django
      ];
    };
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

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.restic.server = { # backup server for restic.
    # options: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/restic-rest-server.nix
    enable = true;
    listenAddress = "0.0.0.0:1001";
    dataDir = "/data/restic/repositories";
    appendOnly = true; # WARN: keep this on always! If a backup-client is hacked, it can never change things.
    extraFlags = "--htpasswd-file /data/restic/passwdfile"; # Generate this file using `htpasswd -B -c passwdfile <USERNAME>`. Outputfile will contain 'USERNAME:hash'.
    privateRepos = true; # users can only access their own repositories. i.e. user 'abc' can only access repositories named 'abc', or subrepositories like 'abc/one', 'abc/another' etc.
  };

  programs.fish.enable = true;

  # Define a user account. Set password with ‘passwd’.
  users.users.rdn = {
    isNormalUser = true;
    description = "rdn";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    password = "changeme";
    openssh.authorizedKeys.keyFiles = [
      ../../res/keys/blackberry.rsa.pub
    ];
  };

  environment.systemPackages = with pkgs; [
    home-manager
  ];

  system.stateVersion = "23.11";
}

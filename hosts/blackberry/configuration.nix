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
        # 18357 # ssh
        18358 # restic server
        1001  # restic server
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
    # ports = [18357];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.restic.server = { # backup server for restic.
    # options: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/backup/restic-rest-server.nix
    enable = true;
    listenAddress = "0.0.0.0:18358";
    dataDir = "/data/restic/repositories";
    appendOnly = true; # WARN: keep this on always! If a backup-client is hacked, it can never change things.
    extraFlags = ["--htpasswd-file" "/data/restic/passwdfile"]; # Generate this file using `htpasswd -B -c passwdfile <USERNAME>`. Outputfile will contain 'USERNAME:hash'.
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
    openssh.authorizedKeys.keys = [
      "ssh-rsa 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 rdn@radon"
    ];
  };

  environment.systemPackages = with pkgs; [
    home-manager
    rsync # somehow not installed by default
  ];

  system.stateVersion = "23.11";
}

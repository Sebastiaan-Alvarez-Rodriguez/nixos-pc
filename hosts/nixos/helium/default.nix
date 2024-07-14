{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  my.system.boot = {
    enable = true;
    tmp.clean = true;
    # kind = "grub";
  };

  networking.firewall = {
    allowedTCPPorts = [
      80    # HTTP
      443   # HTTPS
      587   # mail
      993   # mail
    ];
  };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users = [ "rdn" ];
    nix = {
      enable = true;
      inputs.link = true;
      inputs.addToRegistry = true;
      inputs.addToNixPath = true;
      inputs.overrideNixpkgs = true;
    };
    packages = {
      enable = true;
      allowUnfree = true;
      default-pkgs = with pkgs; [ curl micro vim wget ];
    };
  };

  my.home = { # seb: TODO remove all unneeded packages from /modules/home. Especially watch out for pkgs guarded by mkDisableOption's, since they are by default enabled
    bat.enable = true;
    # bitwarden = {
    #   enable = true;
    #   pinentry = pkgs.pinentry-gtk2; # Use graphical pinentry  
    #   mail = //... wait what? Should this not be different per-user?
    # };
    editor.main = {
      package = pkgs.helix;
      path = "${pkgs.helix}/bin/hx";
    };
    # gpg.enable = true;
    # gpg.pinentry = pkgs.pinentry-gtk2; # Use a small popup to enter passwords
    nix = {
      enable = true;
      inputs.link = true;
      inputs.addToRegistry = true;
      inputs.addToNixPath = true;
      inputs.overrideNixpkgs = true;
    };

    packages = {
      enable = true;
      allowUnfree = true;
      # additionalPackages = with pkgs; [ jellyfin-media-player ]; # Wraps the webui and mpv together
    };
  };

  my.services = {
    adblock.enable = true;
    fail2ban.enable = true;
    flood.enable = true;
    # seb: TODO create *arr config as wanted:
    # indexers.prowlarr.enable = true;
    # pirate = {
    #   enable = true;
    #   bazarr.enable = true;
    #   lidarr.enable = true;
    #   radarr.enable = true;
    #   sonarr.enable = true;
    # };
    
    # # FLOSS music streaming server
    # navidrome = {
    #   enable = true;
    #   musicFolder = "/data/media/music";
    # };

    nginx = {
      enable = true;
      monitoring.enable = false;
      sso.enable = false;
      acme.default-mail = "a@b.com";
    };
    postgresql = {
      enable = true;
      dataDir = "/data/postgres";
    };
    pyload = {
      enable = true;
      credentialsFile = config.age.secrets."services/pyload/secret".path;
    };
    ssh-server.enable = true;
    # Recipe manager
    tandoor-recipes = {
      enable = true;
      secretKeyFile = config.age.secrets."services/tandoor-recipes/secret".path;
    };
    # transmission = { # seedbox. seb: TODO configure seedbox?
    #   enable = true;
    #   credentialsFile = secrets."transmission/credentials".path; # seb: TODO Get secrets on-board.
    # };
    # vikunja = { # Self-hosted todo app
    #   enable = true;
    #   mail = {
    #     enable = true;
    #     configFile = secrets."vikunja/mail".path; # seb: TODO Get secrets on-board.
    #   };
    # };
    # wireguard.enable = true; # seb: TODO fix wireguard config.
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users = let
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/keys/users/rdn.rsa.pub) ];
    };
  };
  age.identityPaths = [ "/home/rdn/.ssh/agenix" ]; # list of paths to recipient keys to try to use to decrypt the secrets

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "23.11"; # Do not change
}

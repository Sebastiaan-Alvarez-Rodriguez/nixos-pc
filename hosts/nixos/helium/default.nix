{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  my.system.boot = {
    enable = true;
    tmp.clean = true;
    # kind = "grub";
    kind = "systemd";
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
    editor.main = {
      package = pkgs.helix;
      path = "${pkgs.helix}/bin/hx";
    };
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
    backup = {
      enable = true;
      repository = "rest:https://restic.mijn.place/helium/";
      environment-file = config.age.secrets."services/backup-server/xenon-client-helium".path;
      password-file = config.age.secrets."services/backup-server/xenon-repo-helium".path;
      paths = [ "/data" "/home" ];
      timer-config = { OnCalendar = "19:30"; Persistent = true; };
      prune-opts = []; # cannot prune, because --> server is append-only, so no deleting/pruning.
    };
    home-assistant.enable = true;
    grocy.enable = true;

    fail2ban.enable = true;
    # flood.enable = true;
    indexers.prowlarr.enable = true;
    # # FLOSS music streaming server
    # navidrome = {
    #   enable = true;
    #   musicFolder = "/data/media/music";
    # };
    jellyfin.enable = true;

    meshcentral = {
      enable = true;
      new-accounts = false;
      backup-path = "/data/meshcentral/backup";
    };

    nfs = {
      enable = false; # seb: TODO see nfs config for potential exploit
      folders."/data" = [{
        subnet = "192.168.2.0/24"; # Only allow local access. NFS is not meant for global internet.
        flags = [ "rw" "hide" "insecure" "subtree_check" "fsid=root" ];
      }];
    };
    nginx = {
      enable = true;
      monitoring.enable = false;
      sso.enable = false;
      acme.default-mail = "a@b.com";
    };
    pirate = {
      bazarr.enable = true;
      lidarr.enable = true;
      radarr.enable = true;
      # sonarr.enable = true;
    };
    backup.exclude = [ "/data/media/movies" "/data/downloads" ]; # downloads / seeds / movies are not to be backed up.

    postgresql = {
      enable = true;
      dataDir = "/data/postgres";
    };
    postgresql-backup = {
      enable = true;
      backupAll = true;
      location = "/data/postgres-backup"; # this path is automatically added to backup.
      startAt = "*-*-* 18:30:00";
    };
    sqlite-backup = {
      enable = true;
      startAt = "*-*-* 18:30:00";
    };

    ssh-server.enable = true;

    # tandoor-recipes = { # seb: NOTE disabled due to dependency on insecure python3.11-js2py-0.74
    #   enable = true;
    #   secretKeyFile = config.age.secrets."services/tandoor-recipes/secret".path;
    # };
    transmission = {
      enable = true;
      download-dir = "/data/downloads";
      credentialsFile = config.age.secrets."services/transmission/secret".path;
    };
    vikunja.enable = true;
    vaultwarden.enable = true;
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

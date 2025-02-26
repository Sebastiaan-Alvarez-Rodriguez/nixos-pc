{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  my.system.boot = {
    enable = true;
    tmp.clean = true;
    kind = "systemd";
  };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users = [ "mrs" "rdn" ];
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

  my.home = {
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
    secrets.prefixes = [ "common/ddns" ];
    adblock.enable = true;
    backup = {
      enable = true;
      routes = let # common configuration below
        password-file = config.age.secrets."hosts/helium/services/backup-client/repo-helium".path;
        paths = [ "/data" "/home" "/etc/machine-id" "var/lib" "/var/lib/nixos"]; # /etc/machine-id should be unique to a given host, used by some software (e.g: ZFS). /var/lib/nixos contains the UID/GID map, and other useful state.
        exclude = [ "/data/media/movies" "/data/downloads" ]; # downloads / seeds / movies are not to be backed up.
        timer-config = { OnCalendar = "19:30"; Persistent = true; };
        prune-opts = []; # cannot prune, because --> servers are append-only, so no deleting/pruning.
      in {
        # blackberry = { # seb TODO: point blackberry.mijn.place
        #   repository = "rest:https://restic.blackberry.mijn.place/helium/";
        #   environment-file = config.age.secrets."hosts/helium/services/backup-client/blackberry-client-helium".path; # seb TODO: make a new secret
        #   inherit password-file paths exclude timer-config prune-opts;
        # };
        xenon = {
          repository = "rest:https://restic.mijn.place/helium/";
          environment-file = config.age.secrets."hosts/helium/services/backup-client/xenon-client-helium".path;
          inherit password-file paths exclude timer-config prune-opts;
        };
      };
    };
    backup-server = {
      enable = true;
      append-only = true;
      data-dir = "/data/backup";
      credentials-file = config.age.secrets."hosts/helium/services/backup-server/helium".path;
    };
    ddclient = {
      enable = true;
      usev6="no";
      protocol = "porkbun";
      server = "api.porkbun.com";
      domains = [ config.networking.domain "*.${config.networking.domain}"];
      root-domain = "mijn.place";
      extraConfig = ''
        apikey=@DDNS-api-key@
        secretapikey=@DDNS-secret-api-key@
      '';
      secrets = {
        "@DDNS-api-key@" = config.age.secrets."common/ddns/api-key".path;
        "@DDNS-secret-api-key@" = config.age.secrets."common/ddns/secret-api-key".path;
      };
    };
    home-assistant.enable = true;
    grocy = {
      enable = true;
      backup-routes = [ "xenon" ];
    };

    fail2ban.enable = true;
    # flood.enable = true;
    indexers.prowlarr.enable = true;
    # # FLOSS music streaming server
    # navidrome = {
    #   enable = true;
    #   musicFolder = "/data/media/music";
    # };
    jellyfin.enable = true;
    music-assistant = {
      enable = true; # seb TODO enable to continue development
      providers = [ "spotify" ];
    };

    rustdesk = {
      enable = true;
      enforce-key = true;
      private-keyfile = config.age.secrets."hosts/helium/services/rustdesk/private-key".path;
      public-keyfile = config.age.secrets."hosts/helium/services/rustdesk/public-key".path;
    };

    nfs = {
      enable = false; # seb: NOTE nfs ports must be closed to the WAN due to potential ddos forward behavior.
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
      acme.backup-routes = [ "xenon" ];
    };
    pirate = {
      bazarr.enable = true;
      lidarr.enable = true;
      radarr.enable = true;
      # sonarr.enable = true;
    };

    postgresql = {
      enable = true;
      dataDir = "/data/postgres";
    };
    postgresql-backup = {
      enable = true;
      backupAll = true;
      location = "/data/postgres-backup"; # this path is automatically added to backup.
      startAt = "*-*-* 18:30:00";
      backup-routes = [ "xenon" ];
    };
    sqlite-backup = {
      enable = true;
      startAt = "*-*-* 18:30:00";
    };

    ssh-server.enable = true;
    # snapserver.enable = true;

    # tandoor-recipes = { # seb: NOTE disabled due to dependency on insecure python3.11-js2py-0.74
    #   enable = true;
    #   secretKeyFile = config.age.secrets."hosts/helium/services/tandoor-recipes/secret".path;
    # };
    transmission = {
      enable = true;
      download-dir = "/data/downloads";
      credentialsFile = config.age.secrets."hosts/helium/services/transmission/secret".path;
    };
    vikunja = {
      enable = true;
      backup-routes = [ "xenon" ];
    };
    vaultwarden.enable = true;
    wireguard = {
      enable = true;
    };
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users = let
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    users.mrs = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/keys/users/rdn.rsa.pub) ];
    };
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/keys/users/mrs.rsa.pub) ];
    };
  };
  age.identityPaths = [ "/home/rdn/.ssh/agenix" ]; # list of paths to recipient keys to try to use to decrypt the secrets

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "23.11"; # Do not change
}

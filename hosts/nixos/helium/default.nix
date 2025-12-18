{ inputs, config, pkgs, system, ... }: {
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

  # age.identityPaths = [ "/home/rdn/.ssh/helium.ed25519" "/home/mrs/.ssh/helium.ed25519" ]; # list of paths to recipient keys to try to use to decrypt the secrets
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEGsYoh6qvSV9Bz4M6OVaZY8L8jVVQptkQaKc6zgh4T";
    masterIdentities = [ "~/.ssh/deploy/helium-deploy.ed25519" "~/.ssh/deploy/backup/backup-helium-deploy.ed25519" ];
    storageMode = "local";
    localStorageDir = ../../../secrets/age/${config.my.hardware.networking.hostname};
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
    avahi = {
      enable = true;
      host = "h";
    };
    backup = {
      enable = true;
      routes = let # common configuration below
        password-file = config.age.secrets."helium/backup-client/repo-helium".path;
        paths = [ "/data" "/home" "/etc/machine-id" "var/lib" "/var/lib/nixos"]; # /etc/machine-id should be unique to a given host, used by some software (e.g: ZFS). /var/lib/nixos contains the UID/GID map, and other useful state.
        exclude = [ "/data/media/movies" "/data/downloads" ]; # downloads / seeds / movies are not to be backed up.
        timer-config = { OnCalendar = "19:30"; Persistent = true; };
        prune-opts = []; # cannot prune, because --> servers are append-only, so no deleting/pruning.
      in {
        # blackberry = { # seb TODO: point blackberry.mijn.place
        #   repository = "rest:https://restic.blackberry.mijn.place/helium/";
        #   environment-file = config.age.secrets."helium/backup-client/blackberry-client-helium".path; # seb TODO: make a new secret
        #   inherit password-file paths exclude timer-config prune-opts;
        # };
        xenon = {
          repository = "rest:https://restic.mijn.place/helium/";
          environment-file = config.age.secrets."helium/backup-client/xenon-client-helium".path;
          inherit password-file paths exclude timer-config prune-opts;
        };
      };
    };
    backup-server = {
      enable = true;
      append-only = true;
      data-dir = "/data/backup";
      credentials-file = config.age.secrets."helium/backup-server/helium".path;
    };
    bind = {
      enable = true;
      zones.${config.networking.domain}.conf = ''
        ns           IN      A       192.168.0.16
        @            IN      A       192.168.0.16
        *            IN      A       192.168.0.16
      ''; # routes all nameserver-requests and all domain requests for "*.h.mijn.place" and "h.mijn.place" itself to helium.
    };
    ddclient = {
      enable = true;
      usev6="no";
      protocol = "porkbun";
      server = "api.porkbun.com";
      domains = [ config.networking.domain "*.${config.networking.domain}" "fail2ban.mijn.place" ];
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
    fail2ban = {
      enable = true;
      ignore-ips = [ "127.0.0.0/24" "192.168.0.0/16" "172.16.0.0/12" "10.0.0.0/8" "fail2ban.mijn.place"];
    };
    fancontrol-i8k = {
      enable = true;
      quiet-start = true;
    };
    home-assistant = {
      enable = true;
      custom_components.floor3d-card = {
        enable = true;
        model = let model-pkg = inputs.self.packages.${system}.house-model; in "${model-pkg}/model.glb"; 
      };
      custom_components.visonic = {
        enable = true;
        ui = {
          enable = true;
          sensors.motion = { "z01" = "woonkamer-bank"; "z02" = "woonkamer-keuken"; "z03" = "woonkamer-zithoek"; "z04" = "werkkamer beneden"; "z05" = "slaapkamer"; "z06" = "garage-binnendeur"; "z07" = "garage-raam"; "z20" = "logeer-klein"; "z21" = "logeer-groot"; "z22" = "werkkamer-boven"; "z23" = "hal-boven"; };
          sensors.magnet = { "z11" = "voordeur"; "z12" = "pui voortuin"; "z13" = "slaapkamer tuin"; "z14" = "woonkamer tuin"; "z15" = "pui tuin"; "z16" = "meterkast"; };
        };
      };
      code.scripts = {
        "notify" = "${pkgs.hass.script.notify}/default.yaml";
        "notify_emergency" = "${pkgs.hass.script.notify_emergency}/default.yaml";
      };
    };
    # zigbee2mqtt = {
    #   enable = true;
    #   dataDir = "/data/zigbee2mqtt";
    #   settings = {
    #     # see: https://www.zigbee2mqtt.io/guide/configuration/
    #     # see also: https://dongle.sonoff.tech/guide/dongle-m/donglem-getting-started/
    #     homeassistant.enabled = config.services.home-assistant.enable;
    #     permit_join = true;
    #     serial = {
    #       port = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Max_MG24_188322831df1ef11bf04c10a6d9880ab-if00-port0";
    #       adapter = "ember";
    #       rtscts = false;
    #       baudrate = 115200;
    #     };
    #   };
    # };
    jellyfin.enable = true;
    monitoring = {
      enable = true;
      grafana = {
        username = "admin";
        password-file = config.age.secrets."helium/monitoring/password".path;
        secret-key-file = config.age.secrets."helium/monitoring/secret-key".path;
      };
    };
    music-assistant = {
      enable = true;
      backup-routes = [ "xenon" ];
      port = 8095;
      port-free.start = 9004;
      port-free.end = 9999;
      providers = [ "deezer" "jellyfin" "snapcast" "spotify" ];
    };
    snapserver = {
      enable = true; # seb TODO enable to continue development
      port = 9001; # for clients
      json-rpc.tcp = {
        enable = true;
        port = 9002;
      };
      json-rpc.http = {
        enable = true;
        port = 9003;
      };

      streams.default = {
        type = "tcp"; # this is what music-assistant sends (TODO: make this hard-configured)
        codec = "flac";
        sampleFormat = "48000:16:2";
        query = { mode = "client"; };
        location = "127.0.0.1:9004"; # seb TODO: found here: https://github.com/SantiagoSotoC/music-assistant-server/blob/c6b2cb04414e192ba22c9ad00fcbcbc412a55cb8/music_assistant/providers/snapcast/__init__.py#L228
        # TODO is: make configurable in music-assistant: DEFAULT_SNAPSERVER_PORT
        # note that in snapserver, this port should be the 'json-rpc tcp' port.
        # query = { mode = "server"; };
        # location = "127.0.0.1:9004";
      };
    };
    stremio-service.enable = true; # seb TODO: provide some form of security so random's cannot use this server

    # pingvin-share = { # seb TODO: wait until a version `>1.13.0` on unstable.
    #   enable = true;
    #   backup-routes = [ "xenon" ];
    # };
    photoprism = {
      enable = true;
      backup-routes = [ "xenon" ];
    };
    rustdesk = {
      enable = true;
      enforce-key = true;
      private-keyfile = config.age.secrets."helium/rustdesk/private-key".path;
      public-keyfile = config.age.secrets."helium/rustdesk/public-key".path;
    };

    nfs = {
      enable = false; # seb: NOTE nfs ports must be closed to the WAN due to potential ddos forward behavior.
      folders."/data/storage" = [{
        subnet = "192.168.0.0/24"; # Only allow local access. NFS is not meant for global internet.
        flags = [ "rw" "hide" "insecure" "subtree_check" "fsid=root" ];
      }];
    };
    nginx = {
      enable = true;
      local-subnet = "192.168.0.0/24";
      monitoring.enable = false; # seb: TODO enable dashboard?
      sso = {
        enable = true;
        subdomain = "auth";
        authKeyFile = config.age.secrets."helium/nginx/auth-key".path;
        users = {
          rdn = {
            passwordHashFile = config.age.secrets."helium/nginx/rdn-pass".path;
            totpSecretFile = config.age.secrets."helium/nginx/rdn-totp".path;
          };
        };
        groups = {
          root = [ "rdn" ];
          users = [ "rdn" ]; # add other users here
        };
      };
      acme.default-mail = "a@b.com";
      acme.backup-routes = [ "xenon" ];
    };
    pirate = {
      bazarr.enable = true;
      lidarr.enable = true;
      radarr.enable = true;
      # sonarr.enable = true;
      backup-routes = [ "xenon" ];
    };
    prowlarr = {
      enable = true;
      backup-routes = [ "xenon" ];
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

    syncthing = let
      identity = import ./../../../modules/nixos/services/syncthing/id.nix { age-secrets = config.age.secrets; };
    in {
      sync-dir = "/data/syncthing/data";
      cfg-dir = "/data/syncthing/config";
      data-dir = "/data/storage/syncthing";
      server = {
        enable = true;
        private-keyfile = identity.helium.private-keyfile;
        certfile = identity.helium.certfile;
        backup-routes = [ "xenon" ];
      };
    };

    tandoor-recipes = {
      enable = true;
      secretKeyFile = config.age.secrets."helium/tandoor-recipes/secret".path;
    };
    transmission = {
      enable = true;
      download-dir = "/data/downloads";
      credentialsFile = config.age.secrets."helium/transmission/secret".path;
    };
    vaultwarden.enable = true;
    vikunja = {
      enable = true;
      backup-routes = [ "xenon" ];
      mail = {
        enable = true;
        host = "mail.mijn.place";
        port = 587;
        authtype = "login";
        username = "vikunja";
        password-file = config.age.secrets."helium/vikunja/mail".path;
        from-email = "vikunja@mijn.place";
        force-ssl = true;
      };
    };
    webdav = { # seb TODO: make secure before it becomes important in any way
      enable = false;
      data-dir = "/data/storage/webdav";
      backup-routes = [ "xenon" ];
    };
    wireguard = {
      enable = false;
    };
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users = let
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    users.mrs = {
      isNormalUser = true;
      description = "mrs";
      extraGroups = groupsIfExist [ "syncthing" "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/users/mrs/helium.ed25519.pub) ];
    };
    users.rdn = {
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "syncthing" "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/users/rdn/helium.ed25519.pub) ];
    };
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "23.11"; # Do not change
}

{ inputs, config, pkgs, lib, system, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  networking.firewall.allowedTCPPorts = [ 1182 ]; # for squid

  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEGsYoh6qvSV9Bz4M6OVaZY8L8jVVQptkQaKc6zgh4T";
    masterIdentities = [ "~/.ssh/deploy/helium-deploy.ed25519" "~/.ssh/deploy/backup/backup-helium-deploy.ed25519" "~/.ssh/deploy/common-deploy.ed25519" "~/.ssh/deploy/backup/backup-common-deploy.ed25519" ];
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };

  my.system.boot = {
    enable = true;
    tmp.clean = true;
    kind = "systemd";
  };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users."rdn" = { config, ... }: {
      imports = [
        "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
        "${inputs.self}/hosts/homes/rdn@helium" # specific home module of a user, e.g. hosts/homes/user@host.
      ];
      my.home = {
        bat.enable = true;
        editor = {
          helix = true;
          editor-name = "hx";
        };
        nix = {
          enable = true;
          inputs.link = true;
          inputs.addToRegistry = true;
          inputs.addToNixPath = true;
          inputs.overrideNixpkgs = true;
        };
      };
    };
    home.users."mrs" = { config, ... }: {
      imports = [
        "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
        "${inputs.self}/hosts/homes/mrs@helium" # specific home module of a user, e.g. hosts/homes/user@host.
      ];
    };
    packages = {
      enable = true;
      allowUnfree = true;
    };
  };

  my.services = {
    secrets.prefixes = [ "common/ddns" ];
    avahi = {
      enable = true;
      allow-interfaces = [ "enp2s0" ];
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
          sensors.magnet = { "z11" = "voordeur"; "z12" = "pui voor"; "z13" = "slaapkamer"; "z14" = "woonkamer tuin"; "z15" = "pui achter"; "z16" = "meterkast"; "z08" = "serverkast"; };
          sensors.other = { "garage_ctrl_a_garage_door_contact" = "garage A"; "garage_ctrl_b_garage_door_contact" = "garage B";};
        };
      };
      code.scripts = {
        "notify" = "${pkgs.hass.script.notify}/default.yaml";
        "notify_emergency" = "${pkgs.hass.script.notify_emergency}/default.yaml";
      };
    };
    mosquitto = {
      enable = true;
      data-dir = "/data/mosquitto";

      listeners = let
        allow-everything-settings = { # these settings are needed to allow all topics to be published and read by all connected entities.
          acl = [ "pattern readwrite #" ];
          omitPasswordAuth = true;
          settings.allow_anonymous = true;
        };
        apply-allow = list: builtins.map (x: allow-everything-settings // x) list;
       in apply-allow [
        { port = 11000; address = "127.0.0.1"; } # last bit allows anonymous connections (i.e. no authentication), which is fine for this localhost-only service.
      ];
    };
    zigbee2mqtt = {
      enable = true;
      data-dir = "/data/zigbee2mqtt";
      settings = {
        # see: https://www.zigbee2mqtt.io/guide/configuration/
        # see also: https://dongle.sonoff.tech/guide/dongle-m/donglem-getting-started/
        homeassistant.enabled = config.my.services.home-assistant.enable;
        permit_join = true;
        mqtt.server = "mqtt://127.0.0.1:11000";
        serial = {
          port = "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Max_MG24_188322831df1ef11bf04c10a6d9880ab-if00-port0";
          # port = "tcp://192.168.0.18:6638";
          adapter = "ember";
          rtscts = false;
          baudrate = 115200;
        };
        advanced.channel = 15; # this mixes well with 2.4gHz wifi channel 1 to have no/little interference
        # DO NOT USE channel 26. Everyone thinks that is a great channel. It is not - almost none of my devices support that channel.
      };
      auth-token = config.age.secrets."helium/zigbee2mqtt/auth-token.yaml".path;
      backup-routes = [ "xenon" ];
    };
    jellyfin.enable = false;
    joplin.enable = true;
    monitoring = {
      enable = false;
      grafana = {
        username = "admin";
        password-file = config.age.secrets."helium/monitoring/password".path;
        secret-key-file = config.age.secrets."helium/monitoring/secret-key".path;
      };
    };
    music-assistant = {
      enable = true;
      config-path = "/data/music-assistant";
      backup-routes = [ "xenon" ];
      providers = [ "snapcast" "spotify" ];
    };
    # snapserver = {
    #   enable = true;
    #   json-rpc.tcp = {
    #     enabled = true; # control needed by music-assistant
    #     port = 9002;
    #   };
    #   json-rpc.http = {
    #     enabled = true;
    #     port = 9003;
    #   };

    #   stream = {
    #     port = 9001;
    #     source = let
    #       proto = "tcp";
    #       tcp_mode = "client";
    #       codec = "flac";
    #       sample-format = "48000:16:2";
    #       build-source = port: "${proto}://127.0.0.1:${builtins.toString port}?name=mass${builtins.toString port}&mode=${tcp_mode}&codec=${codec}&sampleFormat=${sample-format}";
    #     # in builtins.map build-source (lib.range config.my.services.music-assistant.port-free.start config.my.services.music-assistant.port-free.end);
    #     in build-source 4953;
    #   };
    # };
    # stremio-service.enable = true; # seb TODO: provide some form of security so randoms cannot use this server

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
    meshcentral = {
      enable = true;
      new-accounts = false;
      backup-routes = [ "xenon" ];
      backup-path = "/data/meshcentral/backup";
    };
    # squid = {
    #   enable = true;
    #   port = 1182;
    #   listen-address = "0.0.0.0";
    #   allowed-ports = [
    #     443
    #     563
    #     21114 # rustdesk
    #     21115 # rustdesk
    #     21116 # rustdesk
    #     21117
    #     21118
    #     21119
    #   ];
    #   allowed-hosts = [ "rustdesk.${config.networking.domain}" "api.rustdesk.com" ];
    #   auth.files = [ config.age.secrets."helium/squid/squid-users".path ];
    # };
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
        enable = false;
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
      bazarr.enable = false;
      lidarr.enable = false;
      radarr.enable = false;
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
      identities = import ./../../../modules/nixos/services/syncthing/id.nix { age-secrets = config.age.secrets; };
    in {
      cfg-dir = "/data/syncthing/config";
      data-dir = "/data/storage/syncthing";
      devices = builtins.removeAttrs identities [ "helium" ];
      server = {
        enable = true;
        private-keyfile = identities.helium.private-keyfile;
        certfile = identities.helium.certfile;
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
    vaultwarden = {
      enable = true;
      mail = {
        enable = true;
        server = "mail.mijn.place";
        from = "vaultwarden@mijn.place";
        user = "vaultwarden@mijn.place";
        password-file = config.age.secrets."helium/vaultwarden/mail".path;
        security = "force_tls"; # starttls
      };
    };
    vikunja = {
      # Current login problems:
      # postfix xenon: NOQUEUE: reject: RCPT from unknown[62.250.26.19]: 554 5.7.1 <unknown[62.250.26.19]>: Client host rejected: Access denied; from=<vikunja@mijn.place> to=<sebastiaan-vikunja@mijn.place> proto=ESMTP helo=<helium>
      # fix lies in modifying
      # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/master/mail-server/postfix.nix?ref_type=heads#L187
      # I think it declines client host (i.e. 'helium') because 'helium' is not resolvable as a domain.
      # In the submission protocols, there probably is missing something to allow it.
      # Alternatively, I have to make vikunja use a domain name as helo specified by me!
      enable = true;
      backup-routes = [ "xenon" ];
      mail = {
        enable = true;
        host = "mail.mijn.place";
        port = 466; # reroute 466 --> 25 on xenon
        username = "vikunja@mijn.place";
        password-file = config.age.secrets."helium/vikunja/mail".path;
        from-email = "vikunja@mijn.place";
      };
    };
    webdav = { # seb TODO: make secure before it becomes important in any way
      enable = false;
      users = [ "rdn" ];
      data-dir = "/data/storage/webdav";
      backup-routes = [ "xenon" ];
    };
    wireguard = {
      enable = false;
    };
  };

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

  programs.fish.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = lib.mkForce "23.11"; # Do not change
}

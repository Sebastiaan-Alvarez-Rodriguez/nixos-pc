{ inputs, config, lib, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYqumFR46e3dAw3oSK1EIi0J81xV6F07lW5+FwekuVH";
    masterIdentities = [ "~/.ssh/deploy/xenon-deploy.ed25519" "~/.ssh/deploy/backup/backup-xenon-deploy.ed25519" ];
    storageMode = "local";
    localStorageDir = ../../../secrets/rekey/${config.my.hardware.networking.hostname};
  };

  networking.firewall = {
    allowedTCPPorts = [
      80    # HTTP
      443   # HTTPS
      465   # mail (new, replacement for 587)
      466   # mail (custom --> forwards to port 25)
      587   # mail (legacy, replaced by 465)
      993   # mail
    ];
  };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users."rdn" = { config, ... }: {
      imports = [
        "${inputs.self}/modules/home" # generic home module so we have access to all my.home.... options.
        "${inputs.self}/hosts/homes/rdn@xenon" # specific home module of a user, e.g. hosts/homes/user@host.
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
        "${inputs.self}/hosts/homes/mrs@xenon" # specific home module of a user, e.g. hosts/homes/user@host.
      ];
    };
    packages = {
      enable = true;
      allowUnfree = true;
    };
  };

  my.services = {
    backup = {
      enable = true;
      routes = let # common configuration below
        password-file = config.age.secrets."xenon/backup-client/repo-xenon".path;
        paths = [ "/data" "/home" "/etc/machine-id" "/var/lib/nixos"]; # /etc/machine-id should be unique to a given host, used by some software (e.g: ZFS). /var/lib/nixos contains the UID/GID map, and other useful state.
        timer-config = { OnCalendar = "19:30"; Persistent = true; };
        prune-opts = []; # cannot prune, because --> servers are append-only, so no deleting/pruning.
      in {
        # seb TODO: setup blackberry backup route here
        # blackberry = {
        #   repository = "rest:https://restic.blackberry.mijn.place/helium/";
        #   environment-file = config.age.secrets."xenon/backup-client/blackberry-client-xenon".path;
        #   inherit password-file paths timer-config prune-opts;
        # };
        helium = {
          repository = "rest:https://restic.h.mijn.place/xenon";
          environment-file = config.age.secrets."xenon/backup-client/helium-client-xenon".path;
          inherit password-file paths timer-config prune-opts;
        };
      };
    };
    backup-server = {
      enable = true;
      append-only = true;
      data-dir = "/data/backup";
      credentials-file = config.age.secrets."xenon/backup-server/xenon".path;
    };
    # wireguard.enable = true; # seb: TODO uncomment after handling wireguard config.
    fail2ban.enable = true;
    ssh-server.enable = true;
    mailserver = {
      enable = true;
      webserver.enable = true;

      domain-prefix = "mail";
      domains = [ "mijn.place" ];

      # certificateFile = "/var/lib/acme/mijn.place/fullchain.pem";
      # keyFile = "/var/lib/acme/mijn.place/key.pem";
      useACMEHost = "mijn.place";

      state-version = 3;
      extraConfig = let sendOnlyRejectMessage = "This account cannot receive emails. Please mail to mail@mijn.place."; in {
        # A list of all login accounts. To create a password hash, use
        # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
        loginAccounts = {
          "sebastiaan@mijn.place" = {
            aliasesRegexp = [ "/^sebastiaan-.*@mijn.place$/" ]; # allows to reply using any matched address. NOTE: use PCRE regex. Start and end with `/` character. Make a full match.
            hashedPasswordFile = config.age.secrets."xenon/mail/sebastiaan".path;
          };
          "mariska@mijn.place" = {
            aliasesRegexp = [ "/^mariska-.*@mijn.place$/" ];
            hashedPasswordFile = config.age.secrets."xenon/mail/mariska".path;
          };
          "mail@mijn.place" = {
            catchAll = [ "mijn.place" ]; # a sink for all otherwise unmatched emails by (in order): existing mailboxes; (virtual) aliases;
            aliasesRegexp = [ "/^(?!sebastiaan)(?!mariska).+@mijn.place$/" ];
            hashedPasswordFile = "/data/mail/mailserver.pwd";
          };
          "vaultwarden@mijn.place" = {
            sendOnly = true;
            inherit sendOnlyRejectMessage;
            hashedPasswordFile = config.age.secrets."xenon/mail/vaultwarden".path;
          };
          "vikunja@mijn.place" = {
            sendOnly = true;
            inherit sendOnlyRejectMessage;
            hashedPasswordFile = config.age.secrets."xenon/mail/vikunja".path;
          };
          "noreply@mijn.place" = {
            sendOnly = true;
            inherit sendOnlyRejectMessage;
            hashedPasswordFile = config.age.secrets."xenon/mail/noreply".path;
          };
        };

        rejectRecipients = [ "odido@mijn.place" ]; # add owned mailadresses (e.g. 'test@me.com') to block all mails sent to them. 
        # Useful when you have a catchAll-account AND you provided a company a catchAll address like companyname@me.com AND you want to block the company sending more mails landing in your catchAll.
        rejectSender = []; # add mailaddresses (e.g. 'test@malicious.com', or even '@malicious.com') which may never send mails here.
      };

      backup-routes = [ "helium" ];
    };
    nginx.streams = {
      "466" = { # redirect to port 25 for smtp
        destination = "127.0.0.1:25";
        type = "tcp";
      };
      "[::]:466" = {
        destination = "[::ffff:127.0.0.1]:25";
        type = "tcp";
      };
    };

    nginx = {
      enable = true;
      monitoring.enable = false;
      sso.enable = false;
      acme.default-mail = "a@b.com";
      acme.backup-routes = [ "helium" ];
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
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/users/mrs/xenon.ed25519.pub) ];
    };
    users.rdn = {
      password = "changeme";
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/users/rdn/xenon.ed25519.pub) ];
    };
  };

  programs.fish.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = lib.mkForce "23.11"; # Do not change
}

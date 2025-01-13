{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  boot.tmp.cleanOnBoot = true;
  # https://github.com/NixOS/nixpkgs/issues/71273
  networking.interfaces.ens3.tempAddress = "disabled";

  networking.firewall = {
    allowedTCPPorts = [
      80    # HTTP
      443   # HTTPS
      587   # mail
      993   # mail
    ];
  };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users = [ "rdn" ]; # NOTE: Define normal users here. These users' home profiles will be populated with the settings from 'my.home' configuration below.
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
    backup = {
      enable = true;
      routes = let # common configuration below
        password-file = config.age.secrets."hosts/xenon/services/backup-client/repo-xenon".path;
        paths = [ "/data" "/home" "/etc/machine-id" "/var/lib/nixos"]; # /etc/machine-id should be unique to a given host, used by some software (e.g: ZFS). /var/lib/nixos contains the UID/GID map, and other useful state.
        timer-config = { OnCalendar = "19:30"; Persistent = true; };
        prune-opts = []; # cannot prune, because --> servers are append-only, so no deleting/pruning.
      in {
        # seb TODO: setup blackberry backup route here
        # blackberry = {
        #   repository = "rest:https://restic.blackberry.mijn.place/helium/";
        #   environment-file = config.age.secrets."hosts/xenon/services/backup-client/blackberry-client-xenon".path;
        #   inherit password-file paths timer-config prune-opts;
        # };
        helium = {
          repository = "rest:https://restic.h.mijn.place/helium";
          environment-file = config.age.secrets."hosts/xenon/services/backup-client/helium-client-xenon".path;
          inherit password-file paths timer-config prune-opts;
        };
      };
    };
    backup-server = {
      enable = true;
      data-dir = "/data/backup";
      credentials-file = config.age.secrets."hosts/xenon/services/backup-server/xenon".path;
    };
    # wireguard.enable = true; # seb: TODO uncomment after handling wireguard config.
    fail2ban.enable = true;
    ssh-server.enable = true;
    mailserver = {
      enable = true;
      webserver.enable = true;

      domain-prefix = "mail";
      domains = [ "mijn.place" ];

      certificateScheme = "manual";
      certificateFile = "/var/lib/acme/mijn.place/fullchain.pem";
      keyFile = "/var/lib/acme/mijn.place/key.pem";

      extraConfig = {
        # A list of all login accounts. To create a password hash, use
        # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
        loginAccounts = {
          "sebastiaan@mijn.place" = {
            aliasesRegexp = [ "/^sebastiaan-.*@mijn.place$/" ]; # allows to reply using any matched address. NOTE: use PCRE regex. Start and end with `/` character. Make a full match.
            hashedPasswordFile = "/home/rdn/.pwd/sebastiaan-mailserver.pwd";
          };
          "mariska@mijn.place" = {
            aliasesRegexp = [ "/^mariska-.*@mijn.place$/" ];
            hashedPasswordFile = "/home/mrs/.pwd/mariska-mailserver.pwd";
          };
          "mail@mijn.place" = {
            catchAll = [ "mijn.place" ]; # a sink for all otherwise unmatched emails by (in order): existing mailboxes; (virtual) aliases;
            aliasesRegexp = [ "/^(?!sebastiaan)(?!mariska).+@mijn.place$/" ];
            hashedPasswordFile = "/data/mail/mailserver.pwd";
          };
          "noreply@mijn.place" = {
            hashedPasswordFile = "/home/rdn/.pwd/noreply-mailserver.pwd";
            sendOnly = true;
            sendOnlyRejectMessage = "This account cannot receive emails. Please mail to mail@mijn.place.";
          };
        };

        rejectRecipients = []; # add owned mailadresses (e.g. 'test@me.com') to block all mails sent to them. 
        # Useful when you have a catchAll-account AND you provided a company a catchAll address like companyname@me.com AND you want to block the company sending more mails landing in your catchAll.
        rejectSender = []; # add mailaddresses (e.g. 'test@malicious.com', or even '@malicious.com') which may never send mails here.
      };

      backup-routes = [ "helium" ];
    };
    nginx = {
      enable = true;
      monitoring.enable = false;
      sso.enable = false;
      acme.default-mail = "a@b.com";
      acme.backup-routes = [ "helium" ];
    };
  };

  environment.systemPackages = [ pkgs.home-manager ];

  users = let
    groupExists = grp: builtins.hasAttr grp config.users.groups;
    groupsIfExist = builtins.filter groupExists;
  in {
    users.rdn = {
      password = "changeme";
      isNormalUser = true;
      description = "rdn";
      extraGroups = groupsIfExist [ "docker" "networkmanager" "wheel" ];
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [ (builtins.readFile ../../../secrets/keys/users/rdn.rsa.pub) ];
    };
  };

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.utf8";

  system.stateVersion = "23.11"; # Do not change
}

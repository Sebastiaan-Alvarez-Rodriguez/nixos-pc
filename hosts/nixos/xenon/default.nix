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
    bat.enable = true; # like cat, but with syntax highlighting & more
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

  my.services = { # seb: TODO uncomment after handling wireguard config.
    # wireguard.enable = true;
    fail2ban.enable = true;
    ssh-server.enable = true;
    mailserver = {
      enable = true;
      domain-prefix = "mail";
      domains = [ "mijn.place" ];

      certificateScheme = "manual";
      certificateFile = "/var/lib/acme/mijn.place/fullchain.pem";
      keyFile = "/var/lib/acme/mijn.place/key.pem";

      extraConfig = {
        # A list of all login accounts. To create a password hash, use
        # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
        loginAccounts = {
          "mail@mijn.place" = {
            catchAll = [ "mijn.place" ]; # all catchAll-mailaddresses you gave to companies end here.
            aliases = [ "@mijn.place" ]; # You can now reply using ANY address. Useful to reply to catchAll-mailaddresses.
            hashedPasswordFile = "/data/mail/mailserver.pwd";
          };
          "sebastiaan@mijn.place" = {
            hashedPasswordFile = "/home/rdn/.pwd/sebastiaan-mailserver.pwd";
          };
          "mariska@mijn.place" = {
            hashedPasswordFile = "/home/mrs/.pwd/mariska-mailserver.pwd";
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
    };
    nginx = {
      enable = true;
      monitoring.enable = false;
      sso.enable = false;
      acme.default-mail = "a@b.com";
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

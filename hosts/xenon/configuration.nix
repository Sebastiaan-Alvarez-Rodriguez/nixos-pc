{ inputs, config, pkgs, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    inputs.simple-nixos-mailserver.nixosModule
    # sebas-webserver
  ];

  ## nixpkgs
  nixpkgs.config.allowUnfree = true;
  
  ## Boot
  boot.tmp.cleanOnBoot = true;

  ## Networking
  networking.hostName = "xenon";
  networking.domain = "mijn.place";
  networking.firewall.allowPing = true;

  # https://github.com/NixOS/nixpkgs/issues/71273
  networking.interfaces.ens3.tempAddress = "disabled";

  networking.firewall = {
    allowedTCPPorts = [
      80    # HTTP
      443   # HTTPS
      587   # mail
      993   # mail
      11111 # SSH

    ];
  };

  services.openssh = {
    enable = true;
    ports = [11111];
    allowSFTP = false;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };


  mailserver = {
    enable = true;
    fqdn = "mail.mijn.place";
    domains = [ "mijn.place" ];

    # A list of all login accounts. To create a password hash, use
    # nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "super secret password" | cut -d: -f2
    loginAccounts = {
        "mail@mijn.place" = {
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

    # Requires certificate files to exist! Currently provided by acme service in global config.
    certificateScheme = "manual";
    certificateFile = "/var/lib/acme/mijn.place/fullchain.pem";
    keyFile = "/var/lib/acme/mijn.place/key.pem";
  };

  ## Nginx
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # nginx complains that this is required.
    commonHttpConfig = "server_names_hash_bucket_size 64;";

    virtualHosts."alvarez-rodriguez.nl" = {
      enableACME = true;
      forceSSL = true;
      root = "/var/www/alvarez-rodriguez.nl";
    };

    virtualHosts."sebastiaan.alvarez-rodriguez.nl" = {
      useACMEHost = "alvarez-rodriguez.nl";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:1111";
    };
    
    virtualHosts."mijn.place" = { # required for mail
      enableACME = true;
      forceSSL = true;
    };
  
    virtualHosts."vwd.mijn.place" = {
      useACMEHost = "mijn.place";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:4567"; # Reroute to vaultwarden.
      };
    };
  };

  ## SSL
  security.acme = {
    defaults.email = "a@b.com"; # need to explicitly set this for roundcube
    acceptTerms = true;
    certs = {
      "mijn.place" = {
        email = "sebastiaanalva@gmail.com";
        postRun = "systemctl reload nginx.service";
        extraDomainNames = [
          "mail.mijn.place" # Required for mail auth using TLS
          "vwd.mijn.place" # For vaultwarden
        ];
      };
      "alvarez-rodriguez.nl" = {
        email = "sebastiaanalva@gmail.com";
        postRun = "systemctl reload nginx.service";
        extraDomainNames = [
          "sebastiaan.alvarez-rodriguez.nl"
        ];
      };
    };
  };

  ## Misc
  time.timeZone = "Europe/Amsterdam";

  ## System
  nix.gc = {
    automatic = true;
    dates = "06:00";
  };

  programs.fish.enable = true;

  system.stateVersion = "23.11";

  ## Users
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa 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 rdn@radon"
  ];

  users.users.rdn = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa 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 rdn@radon"
    ];
  };

  users.users.mrs = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [];
  };

  ## Packages
  environment.systemPackages = with pkgs; [
    pkgs.home-manager
    pkgs.git
    pkgs.helix
  ];
}

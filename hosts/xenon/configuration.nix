{ inputs, pkgs, lib, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware-configuration.nix
    inputs.simple-nixos-mailserver.nixosModule
    sebas-webserver
  ];

  ## Nix
  nixpkgs = {
    overlays = [
      inputs.self.overlays.default
    ];

    config.allowUnfree = true;
  };

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
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL48N945VH8Nk39u+8S09iBbxeD5qrG+vf6JavSfQn9yDXChMVRJa6MvL5pBXtl9YfokHPZH1S6XIdWnzPqgRsqtjsAQDhtVlo/+JzgbrfCZ9JU5LmMr+vcM1i4ysldva01CvOE5izBHCNWD9j108p6lNQdcUEdD9HVCfaDQwy4Ap6zWYHKcDh0H2YUsktIqiynprh+71P23RQB9aFtvF0JF99Es/RSgfed6MmkaZeg7G2D3DzLVXcrR7uPOmVc3BXbN5w9yeIZj8uCZDTczsVpd6l/FlTQGf7jW1eBahXzfWZK340tFNE9C7GD/7QdGqC9NsXE2jei03udnERB9Vo/ukwGZR3sQzei+Hnme1H+TE00xtv/RlbHuWPT+m36HR22mKf5C6pI4IZzsEze8RVFfzpHm3QOibA+iknIFtARRrTHGf6zAXHI8SmRggadP2kzyF0YXWBer/f3i3pFSmAZHcat5yQzWmDGXehc5aMXvOXab6tp3+vCCeVEATPZl4gKM7OKEYjm4OJ39RD8J4OVrmhAv1LiiKbXChsTUq6Ydwd9hqt0O9WOJmRStxEBM2PVAaon9PzcdvsxrUk04kEZY9l0aev5qi+oELyPl2sfgMHbXzyLENc/aoBmVpHndBmYTqbasvEOsfkeDIvZsWzoMCqaZXNjQPlRfIJFitSBw== radon@rdn"
  ];

  users.users.rdn = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDL48N945VH8Nk39u+8S09iBbxeD5qrG+vf6JavSfQn9yDXChMVRJa6MvL5pBXtl9YfokHPZH1S6XIdWnzPqgRsqtjsAQDhtVlo/+JzgbrfCZ9JU5LmMr+vcM1i4ysldva01CvOE5izBHCNWD9j108p6lNQdcUEdD9HVCfaDQwy4Ap6zWYHKcDh0H2YUsktIqiynprh+71P23RQB9aFtvF0JF99Es/RSgfed6MmkaZeg7G2D3DzLVXcrR7uPOmVc3BXbN5w9yeIZj8uCZDTczsVpd6l/FlTQGf7jW1eBahXzfWZK340tFNE9C7GD/7QdGqC9NsXE2jei03udnERB9Vo/ukwGZR3sQzei+Hnme1H+TE00xtv/RlbHuWPT+m36HR22mKf5C6pI4IZzsEze8RVFfzpHm3QOibA+iknIFtARRrTHGf6zAXHI8SmRggadP2kzyF0YXWBer/f3i3pFSmAZHcat5yQzWmDGXehc5aMXvOXab6tp3+vCCeVEATPZl4gKM7OKEYjm4OJ39RD8J4OVrmhAv1LiiKbXChsTUq6Ydwd9hqt0O9WOJmRStxEBM2PVAaon9PzcdvsxrUk04kEZY9l0aev5qi+oELyPl2sfgMHbXzyLENc/aoBmVpHndBmYTqbasvEOsfkeDIvZsWzoMCqaZXNjQPlRfIJFitSBw== radon@rdn"
    ];
  };

  users.users.mrs = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable 'sudo' for the user
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGy2yFMY9UfVpD3gjXDer85xz2laT+ecM+Ouo9KJF6f6T+b7EkPv6d3nwdTvw65cEEIT4maYUkqPEvQuv4npK1t2gbNjSJYC5E+sObKtbkfB6GTcAz2vLCr50McIoMuxpCYNYm9F72/J1t8iCyCueNEGynjwNsJWHrr2QYMLLVsRFpQu8PFTCBqLkSDehEJuuD4J758+69Yt3XbnIR2n91bmnyNgk3HVf8RSp1+o58VTzeuYmBYoV9gTPQ4uNDrUQEVb6Pp3Sfxd9nsc9hrJcLCqnrVbRgg6g9ciMR08zv938RpQMoXCe3nmZ4yLZrYkt7qbod+5XhnFd0zjHwL3bpDCdS6W6N0a9caJwd1M2tnzwZQT7bYegO4xb4WLk4zNlShJiuF4v8rvZG6n/KH5nsvpsCy+9BppB9E/hPAOpe0CiqLYovsVViJDrv6tjUoJ84bvv5pdwJv88bptipuybentvDJwajT8PKuQldt9bakVn8QR6O6oFCIBAr/2ruaC8a02itnbU6HIH7TrusfPRXwpLLGFE25Rxhiu55LqEP0vaiv7RupxJ0XfwAQbwm3U9uxTYz/pde6qdAyxkYxuen7hVyIjOOQC/sNyl4ze6PG/DKVJoH4H0lZFPNTgBJjWW3Df/Z+7A3a4azjmFupaXbskRT9ECYzDEARjBO6ZvPnQ== mariska@cody"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDU37yoauBIVa35ZF7Ng3Qao2TqG+E6fx85FLaRaQDilwHlmStNLZkFWzjQ2Yw/TOph4DqDwgqX5BOscdaloTLAWZ0ks9CRMKXORki1i1tiTPJTZDd5bTcaRn2HaaCqGKrbzIQUgQOq4OrtaqHX4W82OAK49Fwbm7Hw+fl3Nqh182OwMTuL3upRuDvLfhLqGtNBnYtm8Y0wJciom5yx17jekcI893mQ25GsQO5BL9iQYSAvTWDrgSqfDi0glfVce8C05nGxoJpt606RBGE8JcQ7bLnMByVFQIE+hmvWC67J7GoGZT8e3RA1mM8tQqFwo7qXqYUTH6/3w+952cUagybqDso1JADspA/b7jqwdj4InPTUGFJF97iVgZ9nk3zZrODLnMyCE9AU3kdBg/aigDMKzgWiUA7NygCRiSNn4klI8+80mZldjZ0HRMXe8JT8wHZS5jC+1nfmfCistiEnJvyQCxkqavS96Q9B+Fs5KTrH6t8MlkjLMzQGkn7iL379gFh4LODT9aZ5Ubbb8dws5LP2HpZSHvfKTP9ctzj/YrBenxC9gJLEN3y8WNSNvHh+Z7/XxmZcWMUggBX6NNbFsxps8tD63m5TuCu70BKQyhgZtsffpWH8uWKieMM12y9yccBpDP91TZnFceDLi4v5bXOsAwxLRKIu6akQRkcz1Fc0Sw== mariska@bb8"
    ];
  };

  ## Packages
  environment.systemPackages = with pkgs; [
    pkgs.home-manager
    pkgs.git
    pkgs.helix
  ];
}

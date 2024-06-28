# A simple mailserver, based on https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.services.mailserver;
in {
  imports = with inputs.self.nixosModules; [ inputs.simple-nixos-mailserver.nixosModule ];

  options.my.services.mailserver = with lib; {
    enable = mkEnableOption "mailserver";
    fqdn = mkOption {
      type = types.str;
      description = "Fully qualified domain name";
      example = "mail.test.it";
    };

    domains = mkOption {
      type = with types; listOf (str);
      description = "Domains to process. This is the domain people write behind the '@' in mail addresses";
      example = "test.it";
    };

    certificateScheme = mkOption {
      type = types.enum [ "manual" ];
      description = "How to get a certificate for proving mails sent from this domain are legit";
    };
    certificateFile = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Where certificate chainfile is stored";
    };
    keyFile = mkOption {
      type = with types; nullOr (str);
      default = null;
      description = "Where certificate keyfile is stored";
    };

    extraConfig = mkOption {
      type = with types; attrs;
      example = "Extra configuration to add to mailserver. See for options: https://nixos-mailserver.readthedocs.io/en/latest/options.html";
      description = "List of session names and commands to execute after-login";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      mailserver = {
        enable = true;
        fqdn = cfg.fqdn;
        domains = cfg.domains;

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

        # Requires certificate files to exist! Currently provided by acme service in global config.
        certificateScheme = cfg.certificateScheme;
        certificateFile = cfg.certificateFile;
        keyFile = cfg.keyFile;
      };

      my.services.nginx.virtualHosts = let
        mkDomains = name: {
          ${name} = {
            enableACME = true;
            forceSSL = true;
          };
        };
      in (lib.mkMerge (builtins.map mkDomains cfg.domains));
    }

    (lib.mkIf (cfg.certificateScheme == "manual") {
      security.acme = let
        mkSpec = name: {
          ${name} = {
            email = lib.mkDefault "a@b.com";
            postRun = "systemctl reload nginx.service";
            extraDomainNames = lib.mkIf (cfg.fqdn != name) [ cfg.fqdn ]; 
          };
        };
      in {
        defaults.email = lib.mkDefault "a@b.com"; # Required for roundcube
        acceptTerms = lib.mkDefault true;
        certs = (lib.mkMerge (builtins.map mkSpec cfg.domains));
      };
    })
  ]);
}

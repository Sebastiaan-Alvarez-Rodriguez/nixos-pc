# A simple mailserver, based on https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.services.mailserver;
in {
  imports = with inputs.self.nixosModules; [ inputs.simple-nixos-mailserver.nixosModule ];

  options.my.services.mailserver = with lib; {
    enable = mkEnableOption "mailserver";
    domain-prefix = mkOption {
      type = types.str;
      description = "Prefix to add to config.networking.domain for mail routing";
      example = "mail";
    };

    domains = mkOption {
      type = with types; listOf (str);
      description = "Extra domains to process.";
      example = "test.it";
      default = [ config.networking.domain ];
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
      default = {};
      description = "List of session names and commands to execute after-login";
    };
  };

  config = lib.mkIf cfg.enable {
    # seb: TODO warn if security.acme.certs does not contain config.networking.domain.
    mailserver = (lib.mkMerge [
      {
        enable = true;
        fqdn = "${cfg.domain-prefix}.${config.networking.domain}";
        domains = cfg.domains;

        # Requires certificate files to exist! Currently provided by acme service in global config.
        certificateScheme = cfg.certificateScheme;
        certificateFile = cfg.certificateFile;
        keyFile = cfg.keyFile;
      }
      cfg.extraConfig
    ]);
  };
}

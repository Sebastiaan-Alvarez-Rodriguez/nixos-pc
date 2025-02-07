{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  # my.system.boot = {
  #   enable = true;
  #   tmp.clean = true;
  #   kind = "systemd";
  # };

  my.system = { # contains common system packages and settings shared between hosts.
    home.users = [ "rdn" ];
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
    };
  };

  my.services = {
    secrets.prefixes = [ "common/ddns" ];
    backup-server = {
      enable = true;
      data-dir = "/data/backup";
      append-only = true;
      private-repos = true;
      credentials-file = config.age.secrets."hosts/blackberry/services/backup-server/blackberry".path;
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
    # wireguard.enable = true; # seb: TODO uncomment after handling wireguard config.
    fail2ban.enable = true;
    ssh-server.enable = true;
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

  system.stateVersion = "24.11"; # Do not change
}

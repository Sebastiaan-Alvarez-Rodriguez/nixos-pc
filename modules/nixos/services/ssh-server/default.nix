# An SSH server, using 'mosh' to not have hanging terminals when switching/losing internet access.
# mosh requires server and clientside package to work.
{ config, lib, ... }: let
  cfg = config.my.services.ssh-server;
in {
  options.my.services.ssh-server = with lib; {
    enable = mkEnableOption "SSH Server using 'mosh'";
    port = mkOption {
      type = types.port;
      description = "Port to open ssh server on. Best to not use port 22.";
      default = 8188;
    };
    permitRootLogin = mkEnableOption "allow root to login (best to not allow this)";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings = {
        PermitRootLogin = if cfg.permitRootLogin then "yes" else "no";
        PasswordAuthentication = false;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ]; # explicitly open network port

    programs.mosh.enable = true; # Opens the relevant UDP ports.
  };
}

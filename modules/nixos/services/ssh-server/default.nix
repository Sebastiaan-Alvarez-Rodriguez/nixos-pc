# An SSH server, using 'mosh' to not have hanging terminals when switching/losing internet access.
# mosh requires server and clientside package to work.
{ config, lib, ... }: let
  cfg = config.my.services.ssh-server;
in {
  options.my.services.ssh-server = {
    enable = lib.mkEnableOption "SSH Server using 'mosh'";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Opens the relevant UDP ports.
    programs.mosh.enable = true;
  };
}

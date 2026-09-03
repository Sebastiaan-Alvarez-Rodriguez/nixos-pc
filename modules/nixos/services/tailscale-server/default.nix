# tailscale server using restic's rest server. NOTE: tailscale data from clients using 'tailscale' service.
{ config, pkgs, lib, ... }: let
  cfg = config.my.services.tailscale-server;
  excludeArg = with builtins; with pkgs; "--exclude-file=" + (writeText "excludes.txt" (concatStringsSep "\n" cfg.exclude));
in {
  options.my.services.tailscale-server = with lib; {
    enable = mkEnableOption "Enable tailscales for this host";

    auth-file = mkOption {
      type = types.path;
      description = "key file for authenticating this node at the control server (if headscale is used, this key goes to headscale)";
    };

    port = mkOption {
      type = types.port;
      default = 41641;
      description = "Internal port for tailscale server";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      port = cfg.port;
      useRoutingFeatures = "server";

      authKeyFile = cfg.auth-file;

      extraUpFlags = [ "--advertise-exit-node" ] ++ lib.optional config.my.services.headscale.enable "--login-server=http://127.0.0.1:6192";
    };
  };
}

# Filter and ban unauthorized access
{ config, lib, ... }: let
  cfg = config.my.services.fail2ban;
  wg-cfg = config.my.services.wireguard;
in {
  options.my.services.fail2ban = with lib; {
    enable = mkEnableOption "fail2ban daemon";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;

      ignoreIP = [ "127.0.0.0/8" ] ++ lib.optionals wg-cfg.enable [ "${wg-cfg.net.v4.subnet}.0/${toString wg-cfg.net.v4.mask}" "${wg-cfg.net.v6.subnet}::/${toString wg-cfg.net.v6.mask}" ]; # loopback addresses ++ Wireguard IPs

      maxretry = 5;

      bantime-increment = {
        enable = true;
        rndtime = "5m"; # Use 5 minute jitter to avoid unban evasion
      };

      jails.DEFAULT.settings = {
        findtime = "4h";
        bantime = "10m";
      };
    };
  };
}

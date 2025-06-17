# declarative DNS client
{ config, lib, pkgs, inputs, system, ... }: let
  cfg = config.my.services.bind;
  local-networks = [ "127.0.0.0/24" "192.168.0.0/16" "::1/128" ];
in {
  options.my.services.bind = with lib; {
    enable = mkEnableOption "DNS service";
    package = mkOption {
      type = types.package;
      default = pkgs.bind;
      description = "package to use";
    };

    zones = lib.mkOption {
      type = with types; attrsOf (submodule ({ name, ...}: {
        options = {
          allow-query = mkOption {
            type = nullOr (listOf str);
            default = local-networks;
            description = "Which sources may request a lookup for this zone.";
          };

          mail = mkOption {
            type = str;
            default = "nonsense.something.local";
            description = "The mailing address to contact the authority for this zone. Note that the first '.' will be replaced by '@' to form the mail address.";
          };

          conf = mkOption {
            type = lines;
            description = "Bind config for the zone. See https://wiki.nixos.org/wiki/Bind for examples.";
          };
        };
      }));
    };
    forwarders = lib.mkOption {
      type = with types; listOf str;
      default = config.networking.nameservers;
      description = "List of servers we should forward requests to.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 53 ]; # explicitly open network port

    services.bind = {
      enable = true;

      cacheNetworks = local-networks; # allowed networks to use us as a resolver. Note: This is for recursive queries only. Block all requests in each zone using `allowQuery`
      forwarders = cfg.forwarders;

      forward = "only"; # do not try to resolve if no forwarders succeed
      
      zones = let
        gen-conf = k: { ... } @ args: {
          master = true;
          allowQuery = args.allow-query;
          file = pkgs.writeText k ''
            @            IN      SOA     ns.${k}. ${args.mail}. (
                                               2    ; Serial
                                               3h   ; Refresh
                                               1h   ; Retry
                                               1w   ; Expire
                                               1h)  ; Negative Cache TTL
                         IN      NS      ns.${k}.
            ${args.conf}
          ''; # NOTE: this conf sets up an 'authority' for given zone name.
          # All a user config must do, is make an entry like this: `ns        IN       A      <ip-to-this-server>`.
          # This entry must be placed at the start of the conf, so that it is matched first.
        };
      in
        lib.mapAttrs gen-conf cfg.zones;
    };

    services.fail2ban.jails."bind" = {
      enabled = true;
      settings = {
        filter = "bind";
        action = "iptables-allports";
      };
    };

    environment.etc."fail2ban/filter.d/bind.conf".text = ''
      [Definition]
      failregex = ^.*client @0x[0-9a-f]+ <HOST>#[0-9]+ .+ denied.+$
      journalmatch = _SYSTEMD_UNIT=bind.service
    '';
  };
}

# A simple, in-kernel VPN service
#
# Strongly inspired by https://github.com/delroth/infra.delroth.net/blob/master/roles/wireguard-peer.nix
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.wireguard;

  # rings = { # all wireguard networks
  #   core = {
  #     servers = {
  #       helium = {
  #         ips = [ "10.100.0.1/24" ];
  #         listenPort = 50505;
          
  #       };
  #     };
  #     clients = [];
  #   };
  # };
  peers = { # seb TODO: set hosts here? More clean config options?
    # "Server"
    helium = {
      clientNum = 1;
      publicKey = "PLdgsizztddri0LYtjuNHr5r2E8D+yI+gM8cm5WDfHQ=";
      externalIp = "37.187.146.15";
    };

    # "Clients"
    radon = {
      clientNum = 2;
      publicKey = "QJSWIBS1mXTpxYybLlKu/Y5wy0GFbUfn4yPzpF1DZDc=";
    };
  };
  thisPeer = peers."${config.networking.hostName}";
  thisPeerIsServer = thisPeer ? externalIp;
  # Only connect to clients from server, and only connect to server from clients
  otherPeers = let
    allOthers = lib.filterAttrs (name: _: name != config.networking.hostName) peers;
    shouldConnectToPeer = _: peer: thisPeerIsServer != (peer ? externalIp);
  in
    lib.filterAttrs shouldConnectToPeer allOthers;

  # extIface = config.my.hardware.networking.externalInterface;
  extIface = "eno1"; # seb TODO remove this, uncomment above.

  mkInterface = clientAllowedIPs: {
    listenPort = cfg.port;
    address = with cfg.net; with lib; [
      "${v4.subnet}.${toString thisPeer.clientNum}/${toString v4.mask}"
      "${v6.subnet}::${toString thisPeer.clientNum}/${toHexString v6.mask}"
    ];
    # privateKeyFile = config.age.secrets."wireguard/private-key".path;
    privateKey = ""; # seb TODO: remove this and uncomment above

    peers = let
      mkPeer = _: peer: lib.mkMerge [
        { inherit (peer) publicKey; }
        (lib.optionalAttrs thisPeerIsServer { # Only forward from server to clients
          allowedIPs = with cfg.net; [ "${v4.subnet}.${toString peer.clientNum}/32" "${v6.subnet}::${toString peer.clientNum}/128" ];
        })
        (lib.optionalAttrs (!thisPeerIsServer) {
          allowedIPs = clientAllowedIPs; # Forward all traffic through wireguard to server
          persistentKeepalive = 10; # Roaming clients need to keep NAT-ing active
          endpoint = "${peer.externalIp}:${toString cfg.port}"; # We know that `peer` is a server, set up the endpoint
        })
      ];
    in
      lib.mapAttrsToList mkPeer otherPeers;

    # Set up clients to use configured DNS servers
    dns = let
      toInternalIps = peer: [
        "${cfg.net.v4.subnet}.${toString peer.clientNum}"
        "${cfg.net.v6.subnet}::${toString peer.clientNum}"
      ];
      # We know that `otherPeers` is an attribute set of servers
      internalIps = lib.flatten (lib.mapAttrsToList (_: peer: toInternalIps peer) otherPeers);
      internalServers = lib.optionals cfg.dns.useInternal internalIps;
    in
      lib.mkIf (!thisPeerIsServer) (internalServers ++ cfg.dns.additionalServers);
  };
in {
  options.my.services.wireguard = with lib; {
    enable = mkEnableOption "Wireguard VPN service";

    simpleManagement = mkEnableOption "manage units without password prompts";

    startAtBoot = mkEnableOption "Should the VPN service be started at boot. Must be true for the server to work reliably.";

    iface = mkOption {
      type = types.str;
      default = "wg";
      example = "wg0";
      description = "Name of the interface to configure";
    };

    port = mkOption {
      type = types.port;
      default = 50505;
      example = 51820;
      description = "Port to configure for Wireguard";
    };

    dns = {
      useInternal = my.mkDisableOption ''
        Use internal DNS servers from wireguard 'server'
      '';

      additionalServers = mkOption {
        type = with types; listOf str;
        default = [ "1.0.0.1" "1.1.1.1" ];
        description = "Which DNS servers to use in addition to adblock ones";
      };
    };

    net = {
      # seb FIXME: use new ip library to handle this more cleanly
      v4 = {
        subnet = mkOption {
          type = types.str;
          default = "10.0.0";
          example = "10.100.0";
          description = "Which prefix to use for internal IPs";
        };
        mask = mkOption {
          type = types.int;
          default = 24;
          example = 28;
          description = "The CIDR mask to use on internal IPs";
        };
      };
      # FIXME: extend library for IPv6
      v6 = {
        subnet = mkOption {
          type = types.str;
          default = "fd42:42:42";
          example = "fdc9:281f:04d7:9ee9";
          description = "Which prefix to use for internal IPs";
        };
        mask = mkOption {
          type = types.int;
          default = 64;
          example = 68;
          description = "The CIDR mask to use on internal IPs";
        };
      };
    };

    internal = {
      enable = mkEnableOption ''
        Additional interface which does not route WAN traffic, but gives access to wireguard peers.
        Is useful for accessing DNS and other internal services, without having to route all traffic through wireguard.
        Is automatically disabled on server, and enabled otherwise.
      '' // {
        default = !thisPeerIsServer;
      };

      name = mkOption {
        type = types.str;
        default = "lan";
        example = "internal";
        description = "Which name to use for this interface";
      };

      startAtBoot = my.mkDisableOption ''
        Should the internal VPN service be started at boot.
      '';
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Normal interface should route all traffic from client through server
    {
      networking.wg-quick.interfaces."${cfg.iface}" = mkInterface [ "0.0.0.0/0" "::/0" ];
    }

    # Additional inteface is only used to get access to "LAN" from wireguard
    (lib.mkIf cfg.internal.enable {
      networking.wg-quick.interfaces."${cfg.internal.name}" = mkInterface [ "${cfg.net.v4.subnet}.0/${toString cfg.net.v4.mask}" "${cfg.net.v6.subnet}::/${toString cfg.net.v6.mask}" ];
    })

    # Expose port
    { networking.firewall.allowedUDPPorts = [ cfg.port ]; }

    # Allow NATing wireguard traffic on server
    (lib.mkIf thisPeerIsServer {
      networking.nat = {
        enable = true;
        externalInterface = "eno1"; # seb: TODO uncomment and make like target: extIface;
        internalInterfaces = [ cfg.iface ];
      };
    })

    # Set up forwarding to WAN
    (lib.mkIf thisPeerIsServer {
      networking.wg-quick.interfaces."${cfg.iface}" = {
        postUp = with cfg.net; ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${cfg.iface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING \
              -s ${v4.subnet}.${toString thisPeer.clientNum}/${toString v4.mask} \
              -o ${extIface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${cfg.iface} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING \
              -s ${v6.subnet}::${toString thisPeer.clientNum}/${toString v6.mask} \
              -o ${extIface} -j MASQUERADE
        '';
        preDown = with cfg.net; ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i ${cfg.iface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING \
              -s ${v4.subnet}.${toString thisPeer.clientNum}/${toString v4.mask} \
              -o ${extIface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -i ${cfg.iface} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING \
              -s ${v6.subnet}::${toString thisPeer.clientNum}/${toString v6.mask} \
              -o ${extIface} -j MASQUERADE
        '';
      };
    })

    # When not needed at boot, ensure that there are no reverse dependencies
    (lib.mkIf (!cfg.startAtBoot) {
      systemd.services."wg-quick-${cfg.iface}".wantedBy = lib.mkForce [ ];
    })

    # Same idea, for internal-only interface
    (lib.mkIf (cfg.internal.enable && !cfg.internal.startAtBoot) {
      systemd.services."wg-quick-${cfg.internal.name}".wantedBy = lib.mkForce [ ];
    })

    # Make systemd shut down one service when starting the other
    (lib.mkIf (cfg.internal.enable) {
      systemd.services."wg-quick-${cfg.iface}" = {
        conflicts = [ "wg-quick-${cfg.internal.name}.service" ];
        after = [ "wg-quick-${cfg.internal.name}.service" ];
      };
      systemd.services."wg-quick-${cfg.internal.name}" = {
        conflicts = [ "wg-quick-${cfg.iface}.service" ];
        after = [ "wg-quick-${cfg.iface}.service" ];
      };
    })

    # Make it possible to manage those units without using passwords, for admins
    (lib.mkIf cfg.simpleManagement {
      environment.etc."polkit-1/rules.d/50-wg-quick.rules".text = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units") {
            var unit = action.lookup("unit")
            if (unit == "wg-quick-${cfg.iface}.service" || unit == "wg-quick-${cfg.internal.name}.service") {
              var verb = action.lookup("verb");
              if (verb == "start" || verb == "stop" || verb == "restart") {
                if (subject.isInGroup("wheel")) {
                  return polkit.Result.YES;
                }
              }
            }
          }
        });
      '';
    })
  ]);
}

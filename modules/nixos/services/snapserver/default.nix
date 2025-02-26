# A FLOSS media server
{ config, lib, ... }: let
  cfg = config.my.services.snapserver;
in {
  options.my.services.snapserver = with lib; {
    enable = mkEnableOption "snapserver Media Server";

    port = mkOption {
      type = types.port;
      default = 5778;
      description = "Port for snapclients to listen on";
    };

    listen-address = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Interface to listen for snapclients";
    };

    codec = mkOption {
      type = with types; nullOr enum [ "pcm" "flac" "vorbis" "opus" ];
      default = "flac";
      description = "Default audio compression method from server to clients.";
    };

    json-rpc = {
      tcp = {
        enable = mkEnableOption "snapserver JSON RPC over TCP";
        port = mkOption {
          type = types.port;
          default = 5776;
          description = "Internal port for JSON RPC over TCP";
        };
      };

      http = {
        enable = mkEnableOption "snapserver JSON RPC over HTTP";
        port = mkOption {
          type = types.port;
          default = 5777;
          description = "Internal port for JSON RPC over HTTP";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.snapserver = {
      enable = true;
      port = cfg.port;
      listenAddress = cfg.listen-address;

      tcp = {
        inherit (cfg.json-rpc.tcp) enable port;
        listenAddress = "127.0.0.1";
      };
      
      http = {
        inherit (cfg.json-rpc.http) enable port;
        listenAddress = "127.0.0.1";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.port ] ++ lib.optional cfg.json-rpc.tcp.enable cfg.json-rpc.tcp.port; # no need to enable json-rpc.http.port, we just setup nginx to passthrough below if enabled.
      extraCommands = ''
        iptables -A INPUT -p tcp --dport ${toString cfg.port} -j DROP
        iptables -A INPUT -p tcp --dport ${toString cfg.json-rpc.tcp.port} -j DROP
      '';
    };

    my.services.nginx.virtualHosts.snapserver = lib.mkIf cfg.json-rpc.http.enable {
      port = cfg.json-rpc.http.port;
      extraConfig = {
        locations."/" = {
          extraConfig = ''
            proxy_buffering off;
          '';
        };
        # Too bad for the repetition...
        locations."/socket" = {
          proxyPass = "http://127.0.0.1:${toString cfg.json-rpc.http.port}/";
          proxyWebsockets = true;
        };
      };
    };
  };
}

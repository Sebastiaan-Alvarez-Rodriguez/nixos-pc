# A synchronisation audio stream server
{ config, lib, pkgs, ... }: let
  cfg = config.my.services.snapserver;
in {
  options.my.services.snapserver = with lib; {
    enable = mkEnableOption "snapserver Media Server";

    # codec = mkOption {
    #   type = with types; nullOr enum [ "pcm" "flac" "vorbis" "opus" ];
    #   default = "flac";
    #   description = "Default audio compression method from server to clients.";
    # };

    json-rpc = {
      tcp = { # json-rpc control interface - tcp
        enabled = mkEnableOption "snapserver JSON RPC over TCP";
        port = mkOption {
          type = types.port;
          default = 9002; # normally 1705
          description = "port for JSON RPC over TCP";
        };
        bind_to_address = mkOption {
          default = "0.0.0.0";
          description = "Address to listen on.";
        };
      };

      http = { # json-rpc control interface - http
        enabled = mkEnableOption "snapserver JSON RPC over HTTP";
        port = mkOption {
          type = types.port;
          default = 9003; # normally 1780
          description = "port for JSON RPC over HTTP";
        };
        bind_to_address = mkOption {
          default = "0.0.0.0";
          description = "Address to listen on.";
        };
      };
    };

    stream = {
      port = mkOption {
        type = types.port;
        default = 9001; # normally 1704
        description = "port for snapclients to listen on. WARNING: use a non-public facing port, as there is no authentication and no encryption.";
      };

      bind_to_address = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Interface to listen on for snapclients";
      };

      source = mkOption {
        type = with types; either str (listOf str);
        example = "pipe:///tmp/snapfifo?name=default";
        description = "One or multiple URIs to PCM input streams.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.snapserver = {
      enable = true;
      package = pkgs.snapcast; # should use the override
      settings = {
        tcp = {
          inherit (cfg.json-rpc.tcp) enabled port bind_to_address;
        };
        http = {
          inherit (cfg.json-rpc.http) enabled port bind_to_address;
        };

        inherit (cfg) stream;
      };
    };
    users.users.snapserver = {
      description = "snapserver Service";
      group = "snapserver";
      isSystemUser = true;
    };
    users.groups.snapserver = { };
    systemd.services.snapserver.serviceConfig = {
      DynamicUser = lib.mkForce false; # otherwise, error when starting avahi client in daemon: https://github.com/eworm-de/pacredir/issues/1#issuecomment-1085017998
      User = "snapserver";
      Group = "snapserver";
    };

    networking.firewall = {
      allowedTCPPorts = [ cfg.stream.port ];
      allowedUDPPorts = [ cfg.stream.port ];
    };

    my.services.nginx.virtualHosts.snapserver = lib.mkIf cfg.json-rpc.http.enabled {
      # seb TODO: this does not work yet...
      # https://github.com/badaix/snapweb/issues/54
      port = cfg.json-rpc.http.port;
      local-only = true;
      extraConfig = {
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://127.0.0.1:${toString cfg.json-rpc.http.port}/";
          extraConfig = ''
            proxy_buffering off;
          '';
        };
      };
    };
  };
}

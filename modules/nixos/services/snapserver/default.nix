# A FLOSS media server
{ config, lib, ... }: let
  cfg = config.my.services.snapserver;
in {
  options.my.services.snapserver = with lib; {
    enable = mkEnableOption "snapserver Media Server";

    port = mkOption {
      type = types.port;
      default = 9001; # normally 5778
      description = "Port for snapclients to listen on. WARNING: use a non-public facing port, as there is no authentication and no encryption.";
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
          default = 9002; # normally 5776
          description = "Internal port for JSON RPC over TCP";
        };
      };

      http = {
        enable = mkEnableOption "snapserver JSON RPC over HTTP";
        port = mkOption {
          type = types.port;
          default = 9003; # normally 5777
          description = "Internal port for JSON RPC over HTTP";
        };
      };
    };

    streams = mkOption {
      type = with types; attrsOf (submodule {
        options = {
          location = mkOption {
            type = types.oneOf [ types.path types.str ];
            description = ''
              For type `pipe` or `file`, the path to the pipe or file.
              For type `espot`, `airplay` or `process`, the path to the corresponding binary.
              For type `tcp`, the `host:port` address to connect to or listen on.
              For type `meta`, a list of stream names in the form `/one/two/...`. Don't forget the leading slash.
              For type `alsa`, use an empty string.
            '';
          };
          type = mkOption {
            type = types.enum [ "pipe" "espot" "airplay" "file" "process" "tcp" "alsa" "spotify" "meta" ];
            default = "pipe";
            description = "The type of input stream.";
          };
          query = mkOption {
            type = attrsOf str;
            default = { };
            description = "Key-value pairs that convey additional parameters about a stream.";
            example = literalExpression ''
              # for type == "pipe":
              {
                mode = "create";
              };
              # for type == "process":
              {
                params = "--param1 --param2";
                logStderr = "true";
              };
              # for type == "tcp":
              {
                mode = "client";
              }
              # for type == "alsa":
              {
                device = "hw:0,0";
              }
            '';
          };
          sampleFormat = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              Default sample format.
            '';
            example = "48000:16:2";
          };

          codec = mkOption {
            type = with types; nullOr str;
            default = null;
            description = ''
              Default audio compression method.
            '';
            example = "flac";
          };
        };
      });
      default = { default = { }; };
      description = "The definition for an input source.";
      example = literalExpression ''
        {
          mpd = {
            type = "pipe";
            location = "/run/snapserver/mpd";
            sampleFormat = "48000:16:2";
            codec = "pcm";
          };
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.snapserver = {
      enable = true;
      port = cfg.port;
      listenAddress = cfg.listen-address;

      tcp = {
        inherit (cfg.json-rpc.tcp) enable port;
      };
      
      http = {
        inherit (cfg.json-rpc.http) enable port;
      };

      inherit (cfg) streams;
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

    # networking.firewall = {
    #   allowedTCPPorts = [ cfg.port ]
      # seb TODO: should next command parts be disabled? Probably yes, I don't want to expose json-rpc to remotes.
      # ++ lib.optional (cfg.json-rpc.tcp.enable cfg.json-rpc.tcp.port; # no need to enable json-rpc.http.port, we just setup nginx to passthrough below if enabled.
      # seb NOTE: below statements probably should drop incoming traffic from the outside network to ports... But not sure. It seems to break internal comms?
      # extraCommands = ''
      #   iptables -A INPUT -p tcp --dport ${toString cfg.port} -j DROP
      #   iptables -A INPUT -p tcp --dport ${toString cfg.json-rpc.tcp.port} -j DROP
      # '';
    # };

    my.services.nginx.virtualHosts.snapserver = lib.mkIf cfg.json-rpc.http.enable {
      # seb TODO: this does not work yet...
      # https://github.com/badaix/snapweb/issues/54
      port = cfg.json-rpc.http.port;
      local-only = true;
      # extraConfig = {
        # locations."/" = {
        #   extraConfig = ''
        #     proxy_buffering off;
        #   '';
        # };
        # Too bad for the repetition...
        # locations."/socket" = {
        #   proxyPass = "http://127.0.0.1:${toString cfg.json-rpc.http.port}/";
        #   proxyWebsockets = true;
        # };
      # };
    };
  };
}

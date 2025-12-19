# a mqtt broker
# seb TODO: services.mosquitto.persistence is enabled by default. Will this not cause too much data build-up over the years for no purpose?
{ config, inputs, lib, pkgs, ... }: let
  cfg = config.my.services.mosquitto;
  listenerOptions = with lib.types; submodule {
    options = {
      port = lib.mkOption {
        type = port;
        description = "Port to listen on. Must be set to 0 to listen on a unix domain socket.";
        default = 11000;
      };

      address = lib.mkOption {
        type = nullOr str;
        description = "Address to listen on. Listen on `0.0.0.0`/`::` when unset";
        default = null;
      };

      authPlugins = lib.mkOption {
        type = listOf attrs;
        description = "Authentication plugin to attach to this listener. Refer to the [mosquitto.conf documentation](https://mosquitto.org/man/mosquitto-conf-5.html) for details on authentication plugins.";
        default = [ ];
      };

      users = lib.mkOption {
        type = attrs;
        example = {
          john = {
            password = "123456";
            acl = [ "readwrite john/#" ];
          };
        };
        description = "set of users and their passwords and ACLs.";
        default = { };
      };

      omitPasswordAuth = lib.mkOption {
        type = bool;
        description = "Omits password checking, allowing anyone to log in with any user name unless other mandatory authentication methods (eg TLS client certificates) are configured.";
        default = false;
      };

      acl = lib.mkOption {
        type = listOf str;
        description = "Additional ACL items to prepend to the generated ACL file.";
        example = [ "pattern read #" "topic readwrite anon/report/#" ];
        default = [ ];
      };

      settings = lib.mkOption {
        type = submodule {
          freeformType = attrs;
        };
        description = "Additional settings for this listener.";
        default = { };
      };
    };
  };
in {
  options.my.services.mosquitto= with lib; {
    enable = mkEnableOption "mosquitto";

    listeners = lib.mkOption {
      type = with types; listOf listenerOptions;
      default = [];
      description = "Listeners to configure on this broker.";
    };

    data-dir = mkOption {
      type = types.path;
      description = "Path for mosquitto data";
    };
  };

  config = lib.mkIf cfg.enable {
    services.mosquitto = {
      enable = true;
      dataDir = cfg.data-dir;
      listeners = cfg.listeners;
    };
  };
}

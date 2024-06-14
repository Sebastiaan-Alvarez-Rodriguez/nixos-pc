{ config, lib, pkgs, ... }: let
  cfg = config.my.home.editor;
in {
  options.my.home.editor = with lib; {
    editors = mkOption {
      type = with types; listOf (package);
      default = [];
      description = "Editors for home session";
    };

    main = with types; mkOption {
      type = nullOr (submodule {
      
        options.package = mkOption {
          type = package;
          example = "pkgs.helix";
          description = "Default editor package";
        };
        options.path = mkOption {
          type = str;
          example = "\${pkgs.helix}/bin/hx";
          description = "Default editor binary path";
        };
      });
      default = null;
    };
  };

  config = (lib.mkMerge [
    {
      assertions = [
        {
          assertion = lib.unique cfg.editors;
          message = "Remove duplicates from home.editor.editors, found: \"${builtins.toString cfg.editors}\"";
        }
      ];
    }

    (lib.mkIf (cfg.main != null) {
      home.sessionVariables.EDITOR = lib.mkIf (cfg.main.path != null) cfg.main.path;
      home.packages = cfg.editors ++ lib.optional (!(cfg.main.package == null || (builtins.elem cfg.main.package cfg.editors))) cfg.main.package; # adds main.package if not present.
    })

    (lib.mkIf (builtins.elem pkgs.helix cfg.editors) {
      home.packages = [ pkgs.python3Packages.python-lsp-server ]; # LSPs for helix
    })
  ]);
}

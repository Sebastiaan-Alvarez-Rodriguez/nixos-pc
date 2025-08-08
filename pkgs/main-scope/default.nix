{ pkgs, ... }: {
  
  breeze-obsidian-cursor = pkgs.callPackage ./breeze-obsidian-cursor { };

  bw-pass = pkgs.callPackage ./bw-pass { };

  ddclient = pkgs.callPackage ./ddclient { };

  dragger = pkgs.callPackage ./dragger { };

  i3-get-window-criteria = pkgs.callPackage ./i3-get-window-criteria { };

  i8kutils = pkgs.callPackage ./i8kutils { };

  kitchenowl-desktop = pkgs.callPackage ./kitchenowl/frontend { targetFlutterPlatform = "linux"; };
  kitchenowl-web = pkgs.callPackage ./kitchenowl/frontend { targetFlutterPlatform = "web"; };
  kitchenowl-backend = pkgs.callPackage ./kitchenowl/backend { };

  matrix-notifier = pkgs.callPackage ./matrix-notifier { };

  osc52 = pkgs.callPackage ./osc52 { };

  osc777 = pkgs.callPackage ./osc777 { };

  rbw-pass = pkgs.callPackage ./rbw-pass { };

  stremio-service = pkgs.callPackage ./stremio-service { };
  stremio-web = pkgs.callPackage ./stremio-web { };
}

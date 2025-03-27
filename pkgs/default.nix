{ pkgs }: {
  
  breeze-obsidian-cursor = pkgs.callPackage ./breeze-obsidian-cursor { };

  bw-pass = pkgs.callPackage ./bw-pass { };

  ddclient = pkgs.callPackage ./ddclient { };

  dragger = pkgs.callPackage ./dragger { };

  home-assistant-visonic = pkgs.callPackage ./home-assistant-visonic { };

  i3-get-window-criteria = pkgs.callPackage ./i3-get-window-criteria { };

  kitchenowl-desktop = pkgs.callPackage ./kitchenowl/frontend { targetFlutterPlatform = "linux"; };
  kitchenowl-web = pkgs.callPackage ./kitchenowl/frontend { targetFlutterPlatform = "web"; };
  kitchenowl-backend = pkgs.callPackage ./kitchenowl/backend { };

  matrix-notifier = pkgs.callPackage ./matrix-notifier { };

  osc52 = pkgs.callPackage ./osc52 { };

  osc777 = pkgs.callPackage ./osc777 { };

  rbw-pass = pkgs.callPackage ./rbw-pass { };
}

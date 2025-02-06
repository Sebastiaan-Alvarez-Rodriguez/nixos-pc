{ pkgs }: pkgs.lib.makeScope pkgs.newScope (self: with self; {
  
  breeze-obsidian-cursor = pkgs.callPackage ./breeze-obsidian-cursor { };

  bw-pass = pkgs.callPackage ./bw-pass { };

  ddclient = pkgs.callPackage ./ddclient { };

  diff-flake = pkgs.callPackage ./diff-flake { };

  dragger = pkgs.callPackage ./dragger { };

  home-assistant-visonic = pkgs.callPackage ./home-assistant-visonic { };

  i3-get-window-criteria = pkgs.callPackage ./i3-get-window-criteria { };

  matrix-notifier = pkgs.callPackage ./matrix-notifier { };

  osc52 = pkgs.callPackage ./osc52 { };

  osc777 = pkgs.callPackage ./osc777 { };

  rbw-pass = pkgs.callPackage ./rbw-pass { };
})

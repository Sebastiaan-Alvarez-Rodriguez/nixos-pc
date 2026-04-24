# Default rdn (graphical) user configuration
{ inputs, config, lib, pkgs, ...}: {
  home.packages = with pkgs; [
    adbfs-rootless
    chromium
    # droidcam
    galculator
    gamemode
    gparted
    heroic
    # hotspot
    # jetbrains.idea-community
    joplin-desktop
    # logiops
    # proton-caller
    qbittorrent
    rustdesk-flutter
    telegram-desktop # alternative: kotatogram-desktop
    signal-desktop
    # teams-for-linux
    teamspeak6-client
    tor-browser
    vlc
  ];
  
}

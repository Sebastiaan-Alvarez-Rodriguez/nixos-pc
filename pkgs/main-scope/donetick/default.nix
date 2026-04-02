{ pkgs, lib, ... }: let
  pname = "donetick";
  version = "0.1.74";
in pkgs.buildGoModule {
  inherit pname version;

  src = pkgs.fetchFromGitHub {
    owner = "donetick";
    repo = "donetick";
    rev = "v${version}";
    hash = "sha256-+0HKbrjfc7LZBXgnHk0AKkwBHSv78valvQqIJjM1nM4=";
  };

  vendorHash = "sha256-ZWGhOb1j20b8KFLvWCi2MHUNlP1JTwRD0g6Iw+FGp5c=";
  meta = {
    homepage = "https://donetick.com/";
    description = "an open-source, user-friendly app for managing tasks and chores, featuring customizable options to help you and others stay organized";
  };
}

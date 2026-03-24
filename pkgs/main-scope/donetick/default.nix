{ pkgs, lib, ... }: let
  pname = "donetick";
  version = "v0.1.74";
in lib.buildGoModule {
  inherit pname, version;

  src = fetchFromGitHub {
    owner = "donetick";
    repo = "donetick";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  vendorHash = "sha256-6hCgv2/8UIRHw1kCe3nLkxF23zE/7t5RDwEjSzX3pBQ=";
  meta = {
    homepage = "https://donetick.com/";
    description = "an open-source, user-friendly app for managing tasks and chores, featuring customizable options to help you and others stay organized";
  }
}

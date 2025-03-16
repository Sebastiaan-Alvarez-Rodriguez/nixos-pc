# modified from https://cyberchaos.dev/kloenk/nix/-/blob/main/pkgs/kitchenowl/flutter.nix
{ pkgs, lib, targetFlutterPlatform ? "linux", ... }: pkgs.flutter327.buildFlutterApplication ( rec {
  pname = "kitchenowl-${targetFlutterPlatform}";
  version = "0.6.10";
  src = pkgs.fetchFromGitHub {
  	owner = "TomBursch";
  	repo = "Kitchenowl";
  	rev = "v${version}";
  	hash = "sha256-Fc6sjmf6V54Fg0TfkGo2khlXm2Rrk3TCGMsEyY42bCg=";
  };
  inherit targetFlutterPlatform;

  postPatch = ''
    cd kitchenowl
  '';

  pubspecLock = lib.importJSON ./pubspec.lock.json; # convert available 'pubspec.lock.json' using `cat pubspec.lock | nix run nixpkgs#yj`

} // lib.optionalAttrs (targetFlutterPlatform == "linux") {
  nativeBuildInputs = [ pkgs.imagemagick ];
  runtimeDependencies = [ pkgs.util-linux ];
} // lib.optionalAttrs (targetFlutterPlatform == "web") { })

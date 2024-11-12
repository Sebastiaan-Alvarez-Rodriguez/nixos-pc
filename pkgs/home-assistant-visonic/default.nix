{ pkgs, lib, fetchgit }: pkgs.stdenv.mkDerivation rec {
  pname = "home-assistant-visonic";
  version = "0.9.9.9";
  src = pkgs.fetchFromGitHub {
    owner = "davesmeghead";
    repo = "visonic";
    rev = version;
    hash = "sha256-pxKgFlL59N6tSng4rJ6f97qVgKzEY5a7euZGtPjsZjc="; # Run `nix-prefetch-url` to get the sha256 hash
  };
  # no installPhase given. The default installPhase essentially copies the cloned repo files to the nix-designated $out directory.

  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
  meta = with lib; {
    description = "Nix package wrap for home-assistant visonic plugin";
    homepage = "https://github.com/davesmeghead/visonic/tree/${version}";
    license = licenses.asl20;
  };
}

{ pkgs, lib, fetchgit }: pkgs.stdenv.mkDerivation rec {
  # NOTE: after installation, restart home-assistant service, then
  # go to your website > settings > Devices & services > integrations  and search for "Visonic Intruder Alarm".
  pname = "home-assistant-visonic";
  version = "0.12.3.0";
  src = pkgs.fetchFromGitHub {
    owner = "davesmeghead";
    repo = "visonic";
    rev = version;
    hash = "sha256-N8GLZ0t5NfPfiO9+giP1idQfV6O49He+JarSxWU5Lqo=";
  };

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

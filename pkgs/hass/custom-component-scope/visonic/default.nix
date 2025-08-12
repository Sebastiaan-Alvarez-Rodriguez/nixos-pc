{ pkgs, lib, fetchgit }: pkgs.stdenv.mkDerivation rec {
  # NOTE: after installation, restart home-assistant service, then
  # go to your website > settings > Devices & services > integrations  and search for "Visonic Intruder Alarm".
  pname = "home-assistant-visonic";
  version = "0.12.2.0";
  src = pkgs.fetchFromGitHub {
    owner = "davesmeghead";
    repo = "visonic";
    rev = "5e7d88ad38cc85f8b47e16cdfceb1f66a6cff09b";
    hash = "sha256-7hJE4yGYQMz/T7UtKvj8fwjjWS+aRPpuILW2Dm4w2f4=";
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

{ lib, fetchFromGitHub, perlPackages, autoreconfHook, perl, curl, }:

let
  myPerl = perl.withPackages (ps: [ ps.JSONPP ]);
in
perlPackages.buildPerlPackage rec {
  pname = "ddclient";
  version = "4.0.0";

  outputs = [ "out" ];

  src = fetchFromGitHub {
    owner = "ddclient";
    repo = "ddclient";
    rev = "v${version}";
    sha256 = "sha256-d1G+AM28nBpMWh1QBjm78KKeOL5b5arxERYRCXohwBg=";
  };

  postPatch = ''
    touch Makefile.PL
  '';

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [
    curl
    myPerl
  ];

  # Prevent ddclient from picking up build time perl which is implicitly added
  # by buildPerlPackage.
  configureFlags = [
    "--with-perl=${lib.getExe myPerl}"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ddclient $out/bin/ddclient
    install -Dm644 -t $out/share/doc/ddclient COP* README.* ChangeLog.md

    runHook postInstall
  '';

  # TODO: run upstream tests
  doCheck = false;

  meta = with lib; {
    description = "An up-to-date version of ddclient";
    homepage = "https://ddclient.net";
    license = with licenses; [ mit ];
    mainProgram = "dd-client";
    platforms = platforms.linux;
  };
}

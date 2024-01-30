{ stdenv, python3, runtimeShell }:
let
  python = python3.withPackages (p: with p; [
    flask
    flask-bootstrap
    waitress
  ]);
in stdenv.mkDerivation {
  pname = "sebas-webserver";
  version = "1.0";

  srcs = [
    ./webserver.py
    ./data
    ./static
    ./templates
    ./utils
  ];

  # Prevent nix from trying to unpack python files...
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    for srcFile in $srcs; do
      local tgt=$(stripHash $srcFile)
      cp -r $srcFile $out/bin/$tgt
    done

    cat > "$out/bin/webserver" << EOF
    #!${runtimeShell}
    ${python}/bin/python "$out/bin/webserver.py" \$@

    EOF
    chmod a+x "$out/bin/webserver"
  '';
}

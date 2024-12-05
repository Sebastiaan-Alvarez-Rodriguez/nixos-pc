{ lib
, stdenv
, javaPackages
, fetchFromGitHub
, fetchurl
, fetchpatch
, autoPatchelfHook
, makeWrapper
# , eclipse-sdk
, maven
, openjdk8
, atk
, cairo
, freetype
, gcc
, glib
, glibc
# , gtk2
, gtk4
, jre8
, libXtst
, perl
, python2
, swt
# , swt_jdk8
# , swt-jdk8-gtk3
, webkitgtk
}:

(maven.buildMavenPackage.override {
}) rec {
  pname = "capella";
  version1 = "7";
  version2 = "0";
  version3 = "0";
  version12 = "${version1}.${version2}";
  version = "${version12}.${version3}";

  src = fetchFromGitHub {
    owner = "eclipse-capella";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-+9dJuP+MzUZdzyjdjzgWNa5AyCv2U0Pz6v8MkBta4Gk=";
  };

  # mvnSha256 = "YyUuSH0RlRBAHToWSnrE7/5gM2hAj9ZhnVft5B4ZI0A=";
  # mvnParameters = "";

  nativeBuildInputs = [
    autoPatchelfHook
    # eclipse-sdk
    makeWrapper
    maven
    openjdk8
  ];

  buildInputs = [
    atk # libatk
    cairo # libcairo
    freetype # libfreetype.so.6
    gcc # stdc++ 6
    glib # libglib2
    glibc # libc6
    # gtk2 # libgtk2
    gtk4
    # java.lang.NoClassDefFoundError: javax/xml/bind/JAXBException javax/xml/bind/JAXBException
    openjdk8 # java 8
    libXtst # libxtst6
    ### perl # plugins/.*.pl
    ### python2 # modelio/{app,platform}/.*.py
    # javascript # {{modelio/{app,platform}},{doc/plugins}}/.*.js
    # swt-jdk8-gtk3 #
    swt
    webkitgtk # libwebkitgtk-1.0
  ];

  JAVA_HOME = openjdk8.home;
  LANG = "C.UTF-8";
  LC_ALL = "C.UTF-8";
  # mvnParameters = "--errors --debug";

  installPhase =
    let
      productTargetPath = "$NIX_BUILD_TOP/${src.name}/products/target/products/org.polarsys.capella";
    in
      if stdenv.hostPlatform.isLinux then ''
    runHook preInstall
    mkdir --parents $out/bin
    cp -rv \
      ${productTargetPath}/linux/gtk/x86_64/Modelio\ ${version12}/* \
      $out/
    makeWrapper $out/modelio $out/bin/modelio \
      --prefix PATH : ${openjdk8}/bin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath ([ gcc glib gtk4 swt webkitgtk ])} \
      --prefix SWT_GTK2 : 1 \
      --prefix SWT_GTK3 : 0 \
      --prefix SWT_WEBKIT2 : 1 \
      --prefix LIBOVERLAY_SCROLLBAR : 0 \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --prefix _JAVA_AWT_WM_NONREPARENTING : 1 \
      --prefix _JAVA_OPTIONS : "-Dawt.useSystemAAFontSettings=on"
    # install -D --mode=644 \
    #   ${productTargetPath}/linux/gtk/x86_64/Modelio ${version12}/* \
    #   --target-directory=$out/
    # ln --symbolic $out/usr/lib/modelio-open-source${version}/modelio $out/bin/modelio
    # ln --symbolic $out/usr/lib/modelio-open-source${version}/modelio.sh $out/bin/modelio.sh
    # rm --recursive --force $out/usr/lib/modelio-open-source${version}/jre
    # ln --symbolic ${jre8.home}/jre $out/usr/lib/modelio-open-source${version}/jre
    runHook postInstall
  '' else if stdenv.hostPlatform.isDarwin then ''
    # ${productTargetPath}/macosx/cocoa/x86_64/Modelio ${version12}.app/
  '' else if stdenv.hostPlatform.isWindows then ''
    # ${productTargetPath}/win32/win32/x86_64/Modelio ${version12}/
  '' else ''
    #
  '';

  meta = with lib; {
    description = "Open Source Solution for Model-Based Systems Engineering";
    homepage = "https://mbse-capella.org/";
    changelog = "https://github.com/eclipse-capella/capella/releases";
    license = licenses.gpl3;
    platforms = [
      "x86_64-darwin"
      "x86_64-linux"
      "x86_64-windows"
    ];
    # maintainers = with maintainers; [
    #   yuu
    # ];
  };
}

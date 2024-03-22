{ lib, stdenv, kernel, bc }:
stdenv.mkDerivation rec {
  pname = "ruckus_cp210x";
  version = "${kernel.version}-2024-03-22";

  src = ./.;

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = [ bc ] ++ kernel.moduleBuildDependencies;
  makeFlags = kernel.makeFlags;
  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/$(KVERSION) "$out/lib/modules/${kernel.modDirVersion}"
  '';
  preInstall = ''
    mkdir -p "$out/lib/modules/${kernel.modDirVersion}"
  '';
  enableParallelBuilding = true;

  meta = with lib; {
    description = "Ruckus cp210x driver";
    platforms = platforms.linux;
  };
}

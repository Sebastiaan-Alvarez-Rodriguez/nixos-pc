{ pkgs, lib, stdenv, bc }:
stdenv.mkDerivation rec {
  pname = "ruckus_cp210x";
  version = "${pkgs.linuxPackages.kernel.version}-2024-03-22";

  src = ./.;

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = [ bc ] ++ pkgs.linuxPackages.kernel.moduleBuildDependencies;
  makeFlags = pkgs.linuxPackages.kernel.makeFlags;
  prePatch = ''
    substituteInPlace ./Makefile \
      --replace /lib/modules/$(KVERSION) "$out/lib/modules/${pkgs.linuxPackages.kernel.modDirVersion}"
  '';
  preInstall = ''
    mkdir -p "$out/lib/modules/${pkgs.linuxPackages.kernel.modDirVersion}"
  '';
  enableParallelBuilding = true;

  meta = with lib; {
    description = "Ruckus cp210x driver";
    platforms = platforms.linux;
  };
}

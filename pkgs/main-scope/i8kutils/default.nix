# Control Dell fans
# Usage:
# List fans and temperatures:
# ```bash
# i8kctl
# ```
# Read a specific fan (with `<NUM>` as the fan number):
# ```bash
# i8kctl fan<NUM>
# ```
#
# Set a specific fan (requires `su` rights):
# ```bash
# i8kctl fan<NUM> <value>
# ```
# It seems for `<value`: `0 = off, 1=cooling, 2=avg-rpm 3=max-rpm`.
#
#
# Use `i8kmon` to automatically operate fan speeds (requires `su` rights to apply):
# When temperatures increase, the fan state is increased, but only as long as needed.
# To debug:
# ```bash
# i8kmon -v
# ```

{ stdenv, lib, fetchFromGitHub, pkgs, tcl, tclPackages }: stdenv.mkDerivation rec {
  pname = "i8kutils";
  version = "1.58";

  src = fetchFromGitHub {
    owner = "Wer-Wolf";
    repo = "i8kutils";
    rev = "4508a550037b48a89f81f1e0c49c8afd39944d1b";
    hash = "sha256-mzFEvG3YShE38cpyqfnp9vf8DjjqEoy0hGrecDYqdCo=";
  };

  mesonFlags = [
    "-Dmoduledir=${placeholder "out"}/lib"
  ];

  postUnpack = ''
    sed -i '/etc/d' source/meson.build
  '';

  nativeBuildInputs = with pkgs; [ meson ninja ];
  buildInputs = with pkgs; [ pkg-config cmake systemd makeWrapper tcl tclPackages.tcllib];

  postInstall = ''
    wrapProgram "$out/bin/i8kmon" \
      --set PATH ${lib.makeBinPath [ tcl ]} \
      --set TCL8_6_TM_PATH "$out/lib" \
      --set TCLLIBPATH "${tcl}/lib ${tclPackages.tcllib}/lib"
    wrapProgram "$out/bin/i8kctl" \
      --set PATH ${lib.makeBinPath [ tcl ]} \
      --set TCL8_6_TM_PATH "$out/lib" \
      --set TCLLIBPATH "${tcl}/lib ${tclPackages.tcllib}/lib"
  '';

  meta = with lib; {
    description = "A userspace-program to control fans on Dell";
    homepage = "https://github.com/Wer-Wolf/i8kutils";
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}

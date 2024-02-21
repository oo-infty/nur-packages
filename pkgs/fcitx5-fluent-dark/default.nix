{ lib
, stdenvNoCC
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation rec {
  pname = "fcitx5-fluent-dark";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "Reverier-Xu";
    repo = "FluentDark-fcitx5";
    rev = "v${version}";
    hash = "sha256-wefleY3dMM3rk1/cZn36n2WWLuRF9dTi3aeDDNiR6NU=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fcitx5/themes/
    cp -r FluentDark* $out/share/fcitx5/themes/

    runHook postInstall
  '';

  meta = with lib; {
    description = "A Fluent-Design dark theme with blur effect and shadow";
    homepage = "https://github.com/Reverier-Xu/FluentDark-fcitx5";
    changelog = "https://github.com/Reverier-Xu/FluentDark-fcitx5/releases/tag/${src.rev}";
    license = licenses.mpl20;
    platforms = platforms.all;
  };
}

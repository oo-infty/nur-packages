{ lib
, stdenv
, fetchurl

, fribidi
, gnutls
, gtk2
, libxml2
, pkg-config
}:

stdenv.mkDerivation {
  pname = "tickr";
  version = "0.7.1";

  src = fetchurl {
    url = "http://www.open-tickr.net/src/tickr-0.7.1.tar.gz";
    hash = "sha256-ORUpoRW4INXCyse0ZvrMRyK3+Q4CqwrNc1Co6Xrc7lg=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    fribidi
    gnutls
    gtk2
    libxml2
  ];

  patchPhase = ''
    runHook prePatch

    substituteInPlace src/tickr/tickr.h \
        --replace-fail "/usr/share" "$out/share"

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    # -Wformat is required by -Wsecurity-format
    NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wformat" make

    runHook post
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/64x64/apps
    mkdir -p $out/share/tickr/pixmaps

    cp -r src/tickr/tickr $out/bin
    cp -r tickr.desktop $out/share/applications/tickr.desktop
    cp -r images/tickr-icon.* imags/tickr-rss-icon.* $out/share/tickr/pixmaps
    ln -s $out/share/tickr/pixmaps/tickr-icon.png $out/share/icons/hicolor/64x64/apps/tickr-icon.png

    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/share/applications/tickr.desktop \
        --replace-fail "/usr/bin" "$out/bin" \
        --replace-fail "/usr/share" "$out/share"
  '';
}

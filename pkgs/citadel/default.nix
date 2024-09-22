{ lib
, stdenvNoCC
, fetchFromGitHub
, copyDesktopItems
, makeDesktopItem 
, fetchYarnDeps
, nodejs
, yarn
, bun
, cargo-tauri
, fixup_yarn_lock
, rustPlatform
, jq
, cmake
, pkg-config
, dbus
, openssl
, freetype
, libsoup
, gtk3
, webkitgtk
, sqlite
}:

let
  pname = "citadel";
  version = "0.2.0-unstable-2024-06-05";

  src = fetchFromGitHub {
    owner = "every-day-things";
    repo = "citadel";
    rev = "3cdbfd843529a4fa2010c09cfc89422dd7ba59fe";
    hash = "sha256-FSg78yzeDvV6ItUNZLUvzwkeGVwmeEYu3wvUgKsnEz8=";
  };

  frontend = stdenvNoCC.mkDerivation {
    inherit version src;
    pname = "citadel-frontend";

    nativeBuildInputs = [
      bun
      nodejs
      yarn
      fixup_yarn_lock
    ];

    offlineCache = fetchYarnDeps {
      yarnLock = ./yarn.lock;
      hash = "sha256-9BXHAJ+e5VLgoh/o1ntDa6zcPc2yosS9a09lEcXgNAs=";
    };

    configurePhase = ''
      cp ${./yarn.lock} yarn.lock
      chmod +w yarn.lock
      fixup_yarn_lock yarn.lock

      export HOME=$NIX_BUILD_TOP
      yarn config --offline set yarn-offline-mirror $offlineCache
      yarn install --offline --frozen-lockfile --ignore-scripts --no-progress --non-interactive
      patchShebangs node_modules/
    '';

    buildPhase = ''
      bun build:web
    '';

    installPhase = ''
      cp -r dist $out
    '';
  };
in
rustPlatform.buildRustPackage {
  inherit pname version src;
  sourceRoot = "${src.name}/src-tauri";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "tauri-plugin-persisted-scope-0.1.3" = "sha256-ArFpd05E/pbBAOl1OHtH/jTucp9wzaaVcoQa/xBqbWw=";
    };
  };

  nativeBuildInputs = [
    jq
    cargo-tauri
    cmake
    pkg-config
    copyDesktopItems
  ];

  buildInputs = [
    dbus
    openssl
    freetype
    libsoup
    gtk3
    webkitgtk
    sqlite
  ];

  postPatch = ''
    ln -sf ${./Cargo.lock} Cargo.lock
    mv tauri.conf.json tauri.conf.json.tmp
    jq '.build.distDir = "${frontend}" | .build.beforeBuildCommand = ""' tauri.conf.json.tmp > tauri.conf.json
  '';

  buildPhase = ''
    runHook preBuild

    cargo tauri build --bundles none

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv target/release/citadel $out/bin/citadel

    mkdir -p $out/share/icons/hicolor/{32x32,128x128}/apps
    mv icons/32x32.png $out/share/icons/hicolor/32x32/apps
    mv icons/128x128.png $out/share/icons/hicolor/128x128/apps

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "citadel";
      exec = "citadel";
      icon = "citadel";
      desktopName = "Citadel";
      genericName = "E-book library management";
      comment = "Manage your ebook library without frustrations.";
      categories = [ "Office" ];
    })
  ];

  meta = {
    description = "Calibre compatible e-book library manager without frustrations";
    homepage = "https://github.com/every-day-things";
    changelog = "https://github.com/every-day-things/citadel/releases/tag/app-v0.2.0";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "citadel";
    maintainers = with lib.maintainers; [ oo-infty ];
  };
}

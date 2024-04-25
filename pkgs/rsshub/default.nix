{ lib
, fetchFromGitHub
, buildNpmPackage
, nodejs
, bash
}:

buildNpmPackage {
  pname = "rsshub";
  version = "unstable-2024-04-25";

  src = fetchFromGitHub {
    owner = "DIYgod";
    repo = "RSSHub";
    rev = "a77d65277209ee113bc10a22eda2a641e93e5c62";
    hash = "sha256-R196ufaNa/+733oGWt43efmWKbM0X1TECoGCyeFXdD8=";
  };

  npmDepsHash = "sha256-VOd9V0ztXumtiwKY+SV9gM372oS+Y5sKq5pR94p7FP8=";
  makeCacheWritable = true;

  env.PUPPETEER_SKIP_DOWNLOAD = 1;

  buildInputs = [
    nodejs
    bash
  ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/rsshub
    cp -r lib node_modules assets api package.json tsconfig.json $out/lib/rsshub

    cat << EOF > $out/bin/rsshub
    #!${bash}/bin/bash
    cd $out/lib/rsshub
    export TSX_TSCONFIG_PATH=$out/lib/rsshub/tsconfig.json
    export NODE_ENV=production
    export NO_LOGFILES=true
    ./node_modules/.bin/cross-env ./node_modules/.bin/tsx lib/index.ts
    EOF

    chmod +x $out/bin/rsshub

    runHook postInstall
  '';

  meta = with lib; {
    description = "An open source, easy to use, and extensible RSS feed generator";
    homepage = "https://github.com/DIYgod/RSSHub";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" "aarch664-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}

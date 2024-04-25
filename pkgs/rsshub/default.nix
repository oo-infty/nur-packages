{ lib
, fetchFromGitHub
, buildNpmPackage
, nodejs
}:

buildNpmPackage rec {
  pname = "rsshub";
  version = "1.0.0-master-614f6dc";

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
  ];

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/node_modules/rsshub

    cp -r lib node_modules assets api $out/lib/node_modules/rsshub
    cp -r package.json tsconfig.json $out/lib/node_modules/rsshub

    makeWrapper "$out/lib/node_modules/rsshub/node_modules/.bin/cross-env" $out/bin/rsshub \
        --add-flags "NODE_ENV=production" \
        --add-flags "$out/lib/node_modules/rsshub/node_modules/.bin/tsx" \
        --add-flags "$out/lib/node_modules/rsshub/lib/index.ts"

    runHook postInstall
  '';

  meta = with lib; {
    description = "An open source, easy to use, and extensible RSS feed generator";
    homepage = "https://github.com/DIYgod/RSSHub";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" "aarch664-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}

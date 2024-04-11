{ lib
, buildNpmPackage
, fetchFromGitHub
, nodejs
}:

buildNpmPackage rec {
  pname = "lx-music-sync-server";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "lyswhut";
    repo = "lx-music-sync-server";
    rev = "v${version}";
    hash = "sha256-FRk7bY2ijlCgzbtN6yRHP2pFQYQsAYj7RxpHVU0IYQo=";
  };

  npmDepsHash = "sha256-04OYD/H/vnlQBgG9o6FZfPc0xHE1MLURlGeqtbvLTZc=";
  makeCacheWritable = true;

  buildInputs = [
    nodejs
  ];

  postInstall = ''
    cp -r server $out/lib/node_modules/lx-music-sync-server
    mkdir -p $out/bin

    # FIXME: allow configurable LOG_PATH and DATA_PATH
    makeWrapper ${nodejs}/bin/node $out/bin/lx-music-sync-server \
        --add-flags "$out/lib/node_modules/lx-music-sync-server/index.js" \
        --set LOG_PATH /home/oo-infty/.cache/lx-music-sync-server/logs \
        --set DATA_PATH /home/oo-infty/.cache/lx-music-sync-server/data \
  '';
}

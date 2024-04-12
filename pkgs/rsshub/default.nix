{ lib
, fetchFromGitHub
, buildNpmPackage
}:

buildNpmPackage rec {
  pname = "rsshub";
  version = "1.0.0-master-614f6dc";

  src = fetchFromGitHub {
    owner = "DIYgod";
    repo = "RSSHub";
    rev = "614f6dc12fe1a55aa6aeb86c6553ad778f755a95";
    hash = "sha256-nsXWZsCQgZwtQWggB3KYJg4ULWJsk+qDCCPcTsdXqlU=";
  };

  npmDepsHash = "sha256-cZUFNoj1vps2JK5xMlyYKRulOyfw1IDGH/+KZwWL1C8=";
  makeCacheWritable = true;

  env.PUPPETEER_SKIP_DOWNLOAD = 1;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  meta = with lib; {
    description = "An open source, easy to use, and extensible RSS feed generator";
    homepage = "https://github.com/DIYgod/RSSHub";
    license = licenses.mit;
    platforms = [ "x86_64-linux" "i686-linux" "aarch664-linux" "x86_64-darwin" "aarch64-darwin"];
  };
}

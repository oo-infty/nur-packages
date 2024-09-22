nix-env -f . -qa \* --meta --xml --allowed-uris https://static.rust-lang.org --drv-path --show-trace -I nixpkgs=$(nix-instantiate --find-file nixpkgs) -I $PWD --option restrict-eval true

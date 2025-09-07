with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "pangea-bundler-env";
    inherit ruby;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };
in stdenv.mkDerivation {
  name = "pangea";
  buildInputs = [ env ];
}

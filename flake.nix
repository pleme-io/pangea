{
  description = "cloud renderer, world creator";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.ruby-nix.url = "github:inscapist/ruby-nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    nixpkgs,
    ruby-nix,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ruby-nix.overlays.ruby];
      };
      rnix = ruby-nix.lib pkgs;
      rnix-env = rnix {
        name = "pangea";
        gemset = ./gemset.nix;
      };
      env = rnix-env.env;
      ruby = rnix-env.ruby;
      pangea-cli = pkgs.stdenv.mkDerivation {
        name = "pangea-cli";
        src = ./.;
        nativeBuildInputs = [pkgs.makeWrapper];
        buildInputs = [env ruby];
        installPhase = ''
          mkdir -p $out/bin
          cp bin/pangea $out/bin/pangea-real
          chmod +x $out/bin/pangea-real

          # Find GEM_HOME dynamically (ruby-nix puts gems here)
          GEM_HOME=$(find ${env}/lib/ruby/gems -maxdepth 1 -type d | tail -n1)
          RUBYLIB=$(find ${env}/lib/ruby -maxdepth 1 -type d | tail -n1)

          makeWrapper $out/bin/pangea-real $out/bin/pangea \
            --set GEM_HOME $GEM_HOME \
            --set GEM_PATH $GEM_HOME \
            --set RUBYLIB $RUBYLIB
        '';
      };
    in {
      packages = {
        default = pangea-cli;
        pangea = pangea-cli;
      };
      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = with pkgs; [env ruby opentofu];
          shellHook = ''
            PATH=$PWD/bin:$PATH
          '';
        };
      };
    });
}

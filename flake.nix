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
        buildInputs = [env ruby];
        installPhase = ''
          mkdir -p $out/bin
          cp bin/pangea $out/bin/pangea-real
          chmod +x $out/bin/pangea-real

          # Wrap with correct Ruby env
          makeWrapper $out/bin/pangea-real $out/bin/pangea \
            --set GEM_HOME ${env}/lib/ruby/gems/${ruby.version} \
            --set GEM_PATH ${env}/lib/ruby/gems/${ruby.version} \
            --set RUBYLIB ${env}/lib/ruby/${ruby.version}
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

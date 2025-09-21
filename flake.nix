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
    in {
      packages = {
        inherit env ruby;
        pangea = pkgs.stdenv.mkDerivation {
          pname = "pangea";
          version = "1.0.0";
          src = ./.;
          buildInputs = [env ruby];
          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/lib
            
            # Copy gem environment
            cp -r ${env}/lib/* $out/lib/
            
            # Copy pangea source code to lib
            cp -r $src/lib/* $out/lib/
            
            # Create a wrapper script that sets up the Ruby environment
            cat > $out/bin/pangea <<EOF
            #!${ruby}/bin/ruby
            # Suppress dry-types warnings about mutable defaults
            ENV['DRY_TYPES_WARNINGS'] = 'false'
            \$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
            require 'pangea/cli/application'
            Pangea::CLI::Application.new.run
            EOF
            
            chmod +x $out/bin/pangea
          '';
        };
      };
      devShells = rec {
        default = dev;
        dev = pkgs.mkShell {
          buildInputs = with pkgs; [env ruby opentofu];
          shellHook = ''
            PATH=$PWD/bin:$PATH
            export RUBYLIB=$PWD/lib:$RUBYLIB
          '';
        };
      };
    });
}

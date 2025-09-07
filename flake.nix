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
      pangea-script = pkgs.writeText "pangea" ''
        #!${ruby}/bin/ruby
        ext = File.expand_path('../ext', __dir__)
        $LOAD_PATH.unshift(ext) unless $LOAD_PATH.include?(ext)
        require 'pangea'
        Pangea::App.run
      '';
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
            cp -r ${env}/lib $out
            cp -r ${env}/bin $out
            cp -r $src/lib $out/ext
            cp -r ${pangea-script} $out/bin/pangea
            chmod +x $out/bin/pangea
            rm -rf $out/bin/ruby-lsp
          '';
        };
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

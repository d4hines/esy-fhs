{
  description = "Esy package manager packaged for Nix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.anmonteiro.url = "github:anmonteiro/nix-overlays";
  outputs = { self, nixpkgs, flake-utils, anmonteiro }:
    let
      defaultExtraPackages = [ ];
      defaultExtraBuildCommands = "";
      defaultRunScript = "bash -c $SHELL";
      lib = {
        makeFHS =
          { extraPackages ? defaultExtraPackages
          , extraBuildCommands ? defaultExtraBuildCommands
          , runScript ? defaultRunScript
          , system
          }:
          let pkgs = import nixpkgs {
            inherit system;
            overlays = [ anmonteiro.overlay ];
          }; in
          pkgs.buildFHSUserEnv
            {
              inherit runScript;
              name = "esy-fhs";
              targetPkgs = pkgs: with pkgs; extraPackages ++ [
                binutils
                curl
                esy
                gcc
                git
                glib.dev
                gmp
                gnupatch
                gnumake
                gnum4
                linuxHeaders
                nodejs
                nodePackages.npm
                patch
                perl
                pkgconfig
                unzip
                which
              ];
              extraBuildCommands = ''
                cp ${pkgs.esy}/lib/ocaml/4.12.0/site-lib/esy/esyBuildPackageCommand $out/usr/lib/esy
                cp ${pkgs.esy}/lib/ocaml/4.12.0/site-lib/esy/esyRewritePrefixCommand $out/usr/lib/esy
                ${extraBuildCommands}
              '';
            };
        makeFHSApp =
          { extraPackages ? defaultExtraPackages
          , extraBuildCommands ? defaultExtraBuildCommands
          , runScript ? defaultRunScript
          , system
          }:
          let drv =
            lib.makeFHS { inherit extraPackages extraBuildCommands runScript system; };
          in
          flake-utils.lib.mkApp { inherit drv; };
      };
    in
    { inherit lib; } //
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs {
        inherit system;
        overlays = [ anmonteiro.overlay ];
      };
      in
      {
        packages = { esy = pkgs.esy; };
        defaultApp = lib.makeFHSApp { inherit system; };
      });
}

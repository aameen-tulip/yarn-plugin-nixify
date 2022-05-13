{ system        ? builtins.currentSystem
, pkgs          ? import <nixpkgs> { inherit system; }
, lib           ? pkgs.lib
, stdenv        ? pkgs.stdenv
, nodejs        ? pkgs."nodejs-14_x"
, nix-gitignore ? pkgs.nix-gitignore
}:
let
  nodeEnv = import ./node-env.nix {
    inherit (pkgs) python2 runCommand writeTextFile writeShellScript;
    inherit pkgs nodejs lib stdenv;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
  nodePackages = import ./node-packages.nix {
    inherit (pkgs) fetchurl fetchgit;
    inherit nodeEnv nix-gitignore stdenv lib;
  };
in stdenv.mkDerivation {
  pname = "yarn-plugin-nixify";
  version = "0.1.0";
  src = nix-gitignore.gitignoreSourcePure [
    "*.nix"
    "node_modules/"
    ".yarn/cache/"
    "dist/"
  ] ( lib.cleanSource ./. );
  nativeBuildInputs = [nodejs];
  configurePhase = ''
    ln -s ${nodePackages.nodeDependencies}/lib/node_modules .
    export NODE_PATH="$PWD/node_modules"
    export PATH="''${PATH+$PATH:}$PWD/node_modules/.bin"
  '';
  buildPhase = ''HOME="$TMP" npm run build-dev'';
  installPhase = "mv ./dist/ $out";
}

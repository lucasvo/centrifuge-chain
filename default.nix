{ mozilla ? import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/d46240e8755d91bc36c0c38621af72bf5c489e13.tar.gz)
, pkgs ?  import <nixpkgs> { overlays = [ mozilla ]; }
}:

let
  nightlyRustPlatform =
    let
      nightly = pkgs.rustChannelOf {
        date = "2019-11-19";
        channel = "nightly";
      };
    in
    pkgs.makeRustPlatform {
      rustc = nightly.rust.override {
        targets = ["wasm32-unknown-unknown"];
      };
      cargo = nightly.rust;
    };
in
  with pkgs;
  nightlyRustPlatform.buildRustPackage rec {
    pname = "centrifuge-chain";
    version = "0.0.1";

    src = ./.;

    cargoSha256 = "0l624wllbwq44fla66s8pdyfca6vhrasaxgl1qwd73xljx3rrac2";
    verifyCargoDeps = true;
    preConfigure = ''
      export SKIP_WASM_BUILD=1
    '';

    meta = with stdenv.lib; {
      description = "centrifuge-chain";
      homepage = "https://github.com/centrifuge/centrifuge-chain";
      license = licenses.gpl3;
      maintainers = [];
      platforms = platforms.all;
    };
  }

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
        extensions = [ "rust-src" "rust-analysis" "rustfmt-preview" ];
        targets = [ "wasm32-unknown-unknown" ];
      };
      cargo = nightly.rust;
    };
in
  with pkgs;
  nightlyRustPlatform.buildRustPackage rec {
    pname = "centrifuge-chain";
    version = "0.0.1";

    src = builtins.filterSource
      (path: type: type != "directory" || baseNameOf path != "target")
      ./.;
    buildInputs = [ rustc openssl pkgconfig cmake llvmPackages.clang-unwrapped libbfd libopcodes libunwind autoconf automake libtool];
    cargoSha256 = "0l624wllbwq44fla66s8pdyfca6vhrasaxgl1qwd73xljx3rrac2";
    LIBCLANG_PATH="${llvmPackages.libclang}/lib";
    RUST_SRC_PATH="${rustc}/lib/rustlib/src/rust/src";
    ROCKSDB_LIB_DIR="${rocksdb}/lib";
    PROTOC = "${protobuf}/bin/protoc";
    preConfigure = ''
      export NIX_CXXSTDLIB_LINK=""
    '';

    meta = with stdenv.lib; {
      description = "centrifuge-chain";
      homepage = "https://github.com/centrifuge/centrifuge-chain";
      license = licenses.gpl3;
      maintainers = [];
      platforms = platforms.all;
    };
  }

{
  mozilla ? import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/d46240e8755d91bc36c0c38621af72bf5c489e13.tar.gz)
  ,
  pkgs ? import <nixpkgs> { overlays = [ mozilla ]; },
  nightly ? pkgs.rustChannelOf { date = "2019-11-19"; channel = "nightly"; }
}:
let
  rustc = nightly.rust.override {
    extensions = [ "rust-src" "rust-analysis" "rustfmt-preview" ];
    targets = [ "wasm32-unknown-unknown" ];
  };
in
  with pkgs;
  stdenv.mkDerivation {
  name = "centrifuge-chain";
  buildInputs = [ rustc openssl pkgconfig cmake llvmPackages.clang-unwrapped libbfd libopcodes libunwind autoconf automake libtool];
  LIBCLANG_PATH="${llvmPackages.libclang}/lib";
  RUST_SRC_PATH="${rustc}/lib/rustlib/src/rust/src";
  ROCKSDB_LIB_DIR="${rocksdb}/lib";
  PROTOC = "${protobuf}/bin/protoc";
  shellHook = ''
    export NIX_CXXSTDLIB_LINK=""
  '';
}

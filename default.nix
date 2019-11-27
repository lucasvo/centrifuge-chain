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

      wasmLib = pkgs.fetchzip {
        url = "https://static.rust-lang.org/dist/rust-std-nightly-wasm32-unknown-unknown.tar.gz";
        sha256 = "1vcaqiy0srrlqak1grnn4fcchjhjf1r3h6wvmwyvapmc7xymkrx3";
      };

      buildInputs = [ rustc openssl pkgconfig cmake llvmPackages.clang-unwrapped libbfd libopcodes libunwind autoconf automake libtool];
      cargoSha256 = "1pqw7c2cxk60bww56xm17g3grq337i2b76hr9msw9rjllwy8shw2";
      #    LIBCLANG_PATH="${llvmPackages.libclang}/lib";
      #    RUST_SRC_PATH="${rustc}/lib/rustlib/src/rust/src";
      #    ROCKSDB_LIB_DIR="${rocksdb}/lib";
      #    PROTOC = "${protobuf}/bin/protoc";


      # preBuild might not be the right place to put this but for
      # testing that should suffice.
      #
      # This script tries to work around the fact that `rustc --print sysroot` is
      # in the nix store and therefore can not be modified. The regular
      # installation instructions of the wasm libs are to just copy the contents of
      # the folder to sysroot.
      #
      # Instead I am trying to copy the libs into another temporary folder that is
      # writeable and add the wasm libs there. PWD (/build) however is not writeable
      # by this script.
      #
      preBuild = ''
        cp -r $(rustc --print sysroot) rust_sysroot
        cp -r  ${wasmLib}/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown rust_sysroot/lib/rustlib/
        export RUSTFLAGS="--sysroot `pwd`/rust_sysroot"
      '';
      cargoBuildFlags = ["-v"];

    meta = with stdenv.lib; {
      description = "centrifuge-chain";
      homepage = "https://github.com/centrifuge/centrifuge-chain";
      license = licenses.gpl3;
      maintainers = [];
      platforms = platforms.all;
    };
  }

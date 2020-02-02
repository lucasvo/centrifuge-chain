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
        sha256 = "16ssivapv1qz27xyqkkfna2nmpbq1isxxy4aad7r202d28rz7m55";
      };

      buildInputs = [ rustc openssl pkgconfig cmake llvmPackages.clang-unwrapped libbfd libopcodes libunwind autoconf automake libtool];
      cargoSha256 = "12nn6ysr58pjs4yaqyl67vkjp6iznwcpld82f5vjc2c343lk6gi7";
      #    LIBCLANG_PATH="${llvmPackages.libclang}/lib";
      #    RUST_SRC_PATH="${rustc}/lib/rustlib/src/rust/src";
      #    ROCKSDB_LIB_DIR="${rocksdb}/lib";
      #    PROTOC = "${protobuf}/bin/protoc";


      # preBuild might not be the right place to put this but for
      # testing that should suffice.
      #
      # This script is a workaround because `rustc --print sysroot` is
      # in the nix store and therefore can not be modified. The regular
      # installation instructions of the wasm libs are to just copy the contents of
      # the folder to sysroot.

      # Install instructions for target install
      # https://rustwasm.github.io/wasm-pack/book/prerequisites/non-rustup-setups.html
      preBuild = ''
        cp -r $(rustc --print sysroot) $NIX_BUILD_TOP/rust_sysroot
        chmod -R +w $NIX_BUILD_TOP/rust_sysroot
        cp -r  ${wasmLib}/rust-std-wasm32-unknown-unknown/lib/rustlib/wasm32-unknown-unknown $NIX_BUILD_TOP/rust_sysroot/lib/rustlib/
      '';
      preConfigure = ''
        echo $BUILD
        ls $BUILD
        cat >> $NIX_BUILD_TOP/.cargo/config <<EOF
        [build]
        "rustflags" = "--sysroot $NIX_BUILD_TOP/rust_sysroot/"
        EOF
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

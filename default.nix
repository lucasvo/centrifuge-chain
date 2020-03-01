{ mozilla ? import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/d46240e8755d91bc36c0c38621af72bf5c489e13.tar.gz)
, pkgs ?  import <nixpkgs> { overlays = [ mozilla ]; }
}:

let
  rustNightly = pkgs.rustChannelOf {
    sha256 = "125khcn07ki9waarp85g21slyd35li7rh31ppyahr22pi00y7zrj";
    date = "2019-11-13";
    channel = "nightly";
  };
  rustWasm = rustNightly.rust.override {
    extensions = [ "rust-src" "rust-analysis" "rustfmt-preview" ];
    targets = [ "wasm32-unknown-unknown" ];
  };
  nightlyRustPlatform = pkgs.makeRustPlatform {
    rustc = rustWasm;
    cargo = rustNightly.cargo;
  };

in
  with pkgs;
  nightlyRustPlatform.buildRustPackage rec {
    pname = "centrifuge-chain";
    version = "0.0.1";

    src = builtins.filterSource
      (path: type: type != "directory" || baseNameOf path != "target")
      ./.;
    nativeBuildInputs = [ rustWasm rustNightly.cargo ];
    buildInputs = [ rustWasm openssl pkgconfig cmake llvmPackages.clang-unwrapped libbfd libopcodes libunwind autoconf automake libtool];
    cargoSha256 = "12nn6ysr58pjs4yaqyl67vkjp6iznwcpld82f5vjc2c343lk6gi7";

    cargoBuildFlags = ["-v"];

    meta = with stdenv.lib; {
      description = "centrifuge-chain";
      homepage = "https://github.com/centrifuge/centrifuge-chain";
      license = licenses.gpl3;
      maintainers = [];
      platforms = platforms.all;
    };
  }

# This file constructs the standard build environment for the
# Linux/i686 platform.  It's completely pure; that is, it relies on no
# external (non-Nix) tools, such as /usr/bin/gcc, and it contains a C
# compiler and linker that do not search in default locations,
# ensuring purity of components produced by it.

# The function defaults are for easy testing.
{ system ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform ? null, config ? {} }:

rec {

  lib = import ../../../lib;

  bootstrapFiles =
    if system == "i686-linux" then import ./bootstrap/i686.nix
    else if system == "x86_64-linux" then import ./bootstrap/x86_64.nix
    else if system == "armv5tel-linux" then import ./bootstrap/armv5tel.nix
    else if system == "armv6l-linux" then import ./bootstrap/armv6l.nix
    else if system == "armv7l-linux" then import ./bootstrap/armv6l.nix
    else if system == "mips64el-linux" then import ./bootstrap/loongson2f.nix
    else abort "unsupported platform for the pure Linux stdenv";


  commonPreHook =
    ''
      export NIX_ENFORCE_PURITY=1
      havePatchELF=1
      ${if system == "x86_64-linux" then "NIX_LIB64_IN_SELF_RPATH=1" else ""}
      ${if system == "mips64el-linux" then "NIX_LIB32_IN_SELF_RPATH=1" else ""}
    '';


  # The bootstrap process proceeds in several steps.


  # 1) Create a standard environment by downloading pre-built binaries
  # of coreutils, GCC, etc.


  # Download and unpack the bootstrap tools (coreutils, GCC, Glibc, ...).
  bootstrapTools = derivation {
    name = "bootstrap-tools";

    builder = bootstrapFiles.sh;

    args =
      if system == "armv5tel-linux" || system == "armv6l-linux" 
        || system == "armv7l-linux"
      then [ ./scripts/unpack-bootstrap-tools-arm.sh ]
      else [ ./scripts/unpack-bootstrap-tools.sh ];

    # FIXME: get rid of curl.
    inherit (bootstrapFiles) bzip2 mkdir curl cpio;

    tarball = import <nix/fetchurl.nix> {
      inherit (bootstrapFiles.bootstrapTools) url sha256;
    };

    inherit system;

    # Needed by the GCC wrapper.
    langC = true;
    langCC = true;
  };


  # This function builds the various standard environments used during
  # the bootstrap.
  stdenvBootFun =
    {gcc, extraAttrs ? {}, overrides ? (pkgs: {}), extraPath ? [], fetchurl}:

    import ../generic {
      inherit system config;
      name = "stdenv-linux-boot";
      preHook =
        ''
          # Don't patch #!/interpreter because it leads to retained
          # dependencies on the bootstrapTools in the final stdenv.
          dontPatchShebangs=1
          ${commonPreHook}
        '';
      shell = "${bootstrapTools}/bin/sh";
      initialPath = [bootstrapTools] ++ extraPath;
      fetchurlBoot = fetchurl;
      inherit gcc;
      # Having the proper 'platform' in all the stdenvs allows getting proper
      # linuxHeaders for example.
      extraAttrs = extraAttrs // { inherit platform; };
      overrides = pkgs: (overrides pkgs) // {
        inherit fetchurl;
      };
    };

  # Build a dummy stdenv with no GCC or working fetchurl.  This is
  # because we need a stdenv to build the GCC wrapper and fetchurl.
  stdenvLinuxBoot0 = stdenvBootFun {
    gcc = "/no-such-path";
    fetchurl = null;
  };


  fetchurl = import ../../build-support/fetchurl {
    stdenv = stdenvLinuxBoot0;
    curl = bootstrapTools;
  };


  # The Glibc include directory cannot have the same prefix as the GCC
  # include directory, since GCC gets confused otherwise (it will
  # search the Glibc headers before the GCC headers).  So create a
  # dummy Glibc.
  bootstrapGlibc = stdenvLinuxBoot0.mkDerivation {
    name = "bootstrap-glibc";
    buildCommand = ''
      mkdir -p $out
      ln -s ${bootstrapTools}/lib $out/lib
      ln -s ${bootstrapTools}/include-glibc $out/include
    '';
  };


  # A helper function to call gcc-wrapper.
  wrapGCC =
    { gcc ? bootstrapTools, libc, binutils, coreutils, shell ? "", name ? "bootstrap-gcc-wrapper" }:

    lib.makeOverridable (import ../../build-support/gcc-wrapper) {
      nativeTools = false;
      nativeLibc = false;
      inherit gcc binutils coreutils libc shell name;
      stdenv = stdenvLinuxBoot0;
    };


  # Create the first "real" standard environment.  This one consists
  # of bootstrap tools only, and a minimal Glibc to keep the GCC
  # configure script happy.
  stdenvLinuxBoot1 = stdenvBootFun {
    gcc = wrapGCC {
      libc = bootstrapGlibc;
      binutils = bootstrapTools;
      coreutils = bootstrapTools;
    };
    inherit fetchurl;
  };


  # 2) These are the packages that we can build with the first
  #    stdenv.  We only need binutils, because recent Glibcs
  #    require recent Binutils, and those in bootstrap-tools may
  #    be too old.
  stdenvLinuxBoot1Pkgs = allPackages {
    inherit system platform;
    bootStdenv = stdenvLinuxBoot1;
  };

  binutils1 = stdenvLinuxBoot1Pkgs.binutils.override { gold = false; };


  # 3) 2nd stdenv that we will use to build only Glibc.
  stdenvLinuxBoot2 = stdenvBootFun {
    gcc = wrapGCC {
      libc = bootstrapGlibc;
      binutils = binutils1;
      coreutils = bootstrapTools;
    };
    overrides = pkgs: {
      inherit (stdenvLinuxBoot1Pkgs) perl;
    };
    inherit fetchurl;
  };


  # 4) These are the packages that we can build with the 2nd
  #    stdenv.
  stdenvLinuxBoot2Pkgs = allPackages {
    inherit system platform;
    bootStdenv = stdenvLinuxBoot2;
  };


  # 5) Build Glibc with the bootstrap tools.  The result is the full,
  #    dynamically linked, final Glibc.
  stdenvLinuxGlibc = stdenvLinuxBoot2Pkgs.glibc;


  # 6) Construct a third stdenv identical to the 2nd, except that this
  #    one uses the Glibc built in step 5.  It still uses the recent
  #    binutils and rest of the bootstrap tools, including GCC.
  stdenvLinuxBoot3 = stdenvBootFun {
    gcc = wrapGCC {
      binutils = binutils1;
      coreutils = bootstrapTools;
      libc = stdenvLinuxGlibc;
    };
    overrides = pkgs: {
      glibc = stdenvLinuxGlibc;
      inherit (stdenvLinuxBoot1Pkgs) perl;
      # Link GCC statically against GMP etc.  This makes sense because
      # these builds of the libraries are only used by GCC, so it
      # reduces the size of the stdenv closure.
      gmp = pkgs.gmp.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
      mpfr = pkgs.mpfr.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
      mpc = pkgs.mpc.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
      isl = pkgs.isl.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
      cloog = pkgs.cloog.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
      ppl = pkgs.ppl.override { stdenv = pkgs.makeStaticLibraries pkgs.stdenv; };
    };
    extraAttrs = {
      glibc = stdenvLinuxGlibc;   # Required by gcc47 build
    };
    extraPath = [ stdenvLinuxBoot1Pkgs.paxctl ];
    inherit fetchurl;
  };


  # 7) The packages that can be built using the third stdenv.
  stdenvLinuxBoot3Pkgs = allPackages {
    inherit system platform;
    bootStdenv = stdenvLinuxBoot3;
  };


  # 8) Construct a fourth stdenv identical to the second, except that
  #    this one uses the new GCC from step 7.  The other tools
  #    (e.g. coreutils) are still from the bootstrap tools.
  stdenvLinuxBoot4 = stdenvBootFun {
    gcc = wrapGCC rec {
      binutils = binutils1;
      coreutils = bootstrapTools;
      libc = stdenvLinuxGlibc;
      gcc = stdenvLinuxBoot3Pkgs.gcc.gcc;
      name = "";
    };
    extraPath = [ stdenvLinuxBoot3Pkgs.xz ];
    overrides = pkgs: {
      inherit (stdenvLinuxBoot1Pkgs) perl;
      inherit (stdenvLinuxBoot3Pkgs) gettext gnum4 gmp;
    };
    inherit fetchurl;
  };


  # 9) The packages that can be built using the fourth stdenv.
  stdenvLinuxBoot4Pkgs = allPackages {
    inherit system platform;
    bootStdenv = stdenvLinuxBoot4;
  };


  # 10) Construct the final stdenv.  It uses the Glibc and GCC, and
  #     adds in a new binutils that doesn't depend on bootstrap-tools,
  #     as well as dynamically linked versions of all other tools.
  #
  #     When updating stdenvLinux, make sure that the result has no
  #     dependency (`nix-store -qR') on bootstrapTools or the
  #     first binutils built.
  stdenvLinux = import ../generic rec {
    inherit system config;

    preHook =
      ''
        # Make "strip" produce deterministic output, by setting
        # timestamps etc. to a fixed value.
        commonStripFlags="--enable-deterministic-archives"
        ${commonPreHook}
      '';

    initialPath =
      ((import ../common-path.nix) {pkgs = stdenvLinuxBoot4Pkgs;})
      ++ [stdenvLinuxBoot4Pkgs.patchelf stdenvLinuxBoot4Pkgs.paxctl ];

    gcc = wrapGCC rec {
      inherit (stdenvLinuxBoot4Pkgs) binutils coreutils;
      libc = stdenvLinuxGlibc;
      gcc = stdenvLinuxBoot4.gcc.gcc;
      shell = stdenvLinuxBoot4Pkgs.bash + "/bin/bash";
      name = "";
    };

    shell = stdenvLinuxBoot4Pkgs.bash + "/bin/bash";

    fetchurlBoot = fetchurl;

    extraAttrs = {
      inherit (stdenvLinuxBoot3Pkgs) glibc;
      inherit platform bootstrapTools;
      shellPackage = stdenvLinuxBoot4Pkgs.bash;
    };

    overrides = pkgs: {
      inherit gcc;
      inherit (stdenvLinuxBoot3Pkgs) glibc;
      inherit (stdenvLinuxBoot4Pkgs) binutils;
      inherit (stdenvLinuxBoot4Pkgs)
        gzip bzip2 xz bash coreutils diffutils findutils gawk
        gnumake gnused gnutar gnugrep gnupatch patchelf
        attr acl paxctl;
    };
  };

}

x@{builderDefsPackage
  , fetchgit, qt4, ecl, xorgserver
  , xkbcomp, xkeyboard_config
  , ...}:
builderDefsPackage
(a :  
let 
  helperArgNames = ["stdenv" "fetchurl" "builderDefsPackage"] ++ 
    ["fetchgit"];

  buildInputs = map (n: builtins.getAttr n x)
    (builtins.attrNames (builtins.removeAttrs x helperArgNames));
  sourceInfo = rec {
    method = "fetchgit";
    rev = "9097bf98446ee33c07bb155d800395775ce0d9b2";
    url = "git://gitorious.org/eql/eql";
    hash = "1fp88xmmk1sa0iqxahfiv818bp2sbf66vqrd4xq9jb731ybdvsb8";
    version = rev;
    name = "eql-git-${version}";
  };
in
rec {
  srcDrv = a.fetchgit {
    url = sourceInfo.url;
    sha256 = sourceInfo.hash;
    rev = sourceInfo.rev;
  };
  src = srcDrv + "/";

  inherit (sourceInfo) name version;
  inherit buildInputs;

  phaseNames = ["setVars" "fixPaths" "doQMake" "doMake" "doDeploy"];

  setVars = a.fullDepEntry (''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -fPIC"
  '') [];

  fixPaths = a.fullDepEntry (''
    sed -re 's@[(]in-home "gui/.command-history"[)]@(concatenate '"'"'string (ext:getenv "HOME") "/.eql-gui-command-history")@' -i gui/gui.lisp
  '') ["minInit" "doUnpack"];

  doQMake = a.fullDepEntry (''
    cd src
    qmake eql_exe.pro
    make
    cd ..
    cd src
  '') ["addInputs" "doUnpack" "buildEQLLib"];

  doDeploy = a.fullDepEntry (''
    cd ..
    mkdir -p $out/bin $out/lib/eql/ $out/include $out/include/gen $out/lib
    cp -r . $out/lib/eql/build-dir
    ln -s $out/lib/eql/build-dir/eql $out/bin
    ln -s $out/lib/eql/build-dir/src/*.h $out/include
    ln -s $out/lib/eql/build-dir/src/gen/*.h $out/include/gen
    ln -s $out/lib/eql/build-dir/libeql*.so* $out/lib
  '') ["minInit"];

  buildEQLLib = a.fullDepEntry (''
    cd src
    ecl -shell make-eql-lib.lisp
    qmake eql_lib.pro
    make
    cd ..
  '') ["doUnpack" "addInputs"];


  meta = {
    description = "Embedded Qt Lisp (ECL+Qt)";
    maintainers = with a.lib.maintainers;
    [
      raskin
    ];
    platforms = with a.lib.platforms;
      linux;
  };
  passthru = {
    updateInfo = {
      downloadPage = "http://password-taxi.at/EQL";
      method = "fetchgit";
      rev = "370b7968fd73d5babc81e35913a37111a788487f";
      url = "git://gitorious.org/eql/eql";
      hash = "2370e111d86330d178f3ec95e8fed13607e51fed8859c6e95840df2a35381636";
    };
    inherit srcDrv;
  };
}) x


{ cabal, constraints, dataHash, mtl, QuickCheck, safe, tagged
, tasty, tastyGolden, tastyQuickcheck, tastyTh, treeView
, utf8String
}:

cabal.mkDerivation (self: {
  pname = "syntactic";
  version = "2.0";
  sha256 = "0b90afdfymsbgllk8np3xfkgrn2b5ry3n2wbpkn660rknsayw94x";
  buildDepends = [ constraints dataHash mtl safe tagged treeView ];
  testDepends = [
    QuickCheck tagged tasty tastyGolden tastyQuickcheck tastyTh
    utf8String
  ];
  meta = {
    homepage = "https://github.com/emilaxelsson/syntactic";
    description = "Generic representation and manipulation of abstract syntax";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

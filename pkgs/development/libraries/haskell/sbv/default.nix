{ cabal, async, deepseq, filepath, HUnit, mtl, QuickCheck, random
, syb
}:

cabal.mkDerivation (self: {
  pname = "sbv";
  version = "3.1";
  sha256 = "19rn5ynqqjz0zw7gcb0y4clzxxnmq56a2qx369mz283455l86h5j";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    async deepseq filepath HUnit mtl QuickCheck random syb
  ];
  testDepends = [ filepath HUnit syb ];
  meta = {
    homepage = "http://leventerkok.github.com/sbv/";
    description = "SMT Based Verification: Symbolic Haskell theorem prover using SMT solving";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

{ cabal, doctest, filepath, tagged, transformers
, transformersCompat
}:

cabal.mkDerivation (self: {
  pname = "distributive";
  version = "0.4.4";
  sha256 = "0s2ln9jv7bh4ri2y31178pvjl8x6nik5d0klx7j2b77yjlsgblc2";
  buildDepends = [ tagged transformers transformersCompat ];
  testDepends = [ doctest filepath ];
  meta = {
    homepage = "http://github.com/ekmett/distributive/";
    description = "Distributive functors -- Dual to Traversable";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

{ cabal, attoparsec, hspec, hspecExpectations, text }:

cabal.mkDerivation (self: {
  pname = "hspec-attoparsec";
  version = "0.1.0.1";
  sha256 = "12246p4k0axv6w5jxnid9hyl4cbl3vmd46b7xxli7nq2iw79nl8v";
  buildDepends = [ attoparsec hspecExpectations text ];
  testDepends = [ attoparsec hspec hspecExpectations text ];
  meta = {
    homepage = "http://github.com/alpmestan/hspec-attoparsec";
    description = "Utility functions for testing your attoparsec parsers with hspec";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

{ cabal, exceptions, pipes, transformers }:

cabal.mkDerivation (self: {
  pname = "pipes-safe";
  version = "2.2.0";
  sha256 = "1m44a2pbws73jbr2ca48i94mrfwzlsibyc22i2w3fqq159qfg6ca";
  buildDepends = [ exceptions pipes transformers ];
  meta = {
    description = "Safety for the pipes ecosystem";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.ocharles ];
  };
})

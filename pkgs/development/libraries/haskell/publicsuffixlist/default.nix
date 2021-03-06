{ cabal, cereal, dataDefault, HUnit, idna, text, utf8String }:

cabal.mkDerivation (self: {
  pname = "publicsuffixlist";
  version = "0.1";
  sha256 = "0mbrmhgyjp8jms3fd3nq4knc4j97sw8ijrmnlfjs7qj8jw4vwzxk";
  buildDepends = [ cereal dataDefault text utf8String ];
  testDepends = [ cereal dataDefault HUnit idna text utf8String ];
  meta = {
    homepage = "https://github.com/litherum/publicsuffixlist";
    description = "Is a given string a domain suffix?";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

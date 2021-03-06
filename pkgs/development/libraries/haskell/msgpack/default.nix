{ cabal, attoparsec, blazeBuilder, deepseq, hashable, mtl
, QuickCheck, testFramework, testFrameworkQuickcheck2, text
, unorderedContainers, vector
}:

cabal.mkDerivation (self: {
  pname = "msgpack";
  version = "0.7.2.5";
  sha256 = "1iwibyv5aqp5h98x4s5pp3hj218l2k3vff87p727mh74f5j6l3s8";
  buildDepends = [
    attoparsec blazeBuilder deepseq hashable mtl text
    unorderedContainers vector
  ];
  testDepends = [
    QuickCheck testFramework testFrameworkQuickcheck2
  ];
  jailbreak = true;
  meta = {
    homepage = "http://msgpack.org/";
    description = "A Haskell implementation of MessagePack";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

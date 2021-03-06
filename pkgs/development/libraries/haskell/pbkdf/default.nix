{ cabal, binary, byteable, bytedump, cryptohash, utf8String }:

cabal.mkDerivation (self: {
  pname = "pbkdf";
  version = "1.1.1.1";
  sha256 = "1nbn8kan43i00g23g8aljxjpaxm9q1qhzxxdgks0mc4mr1f7bifx";
  buildDepends = [ binary byteable bytedump cryptohash utf8String ];
  testDepends = [ binary byteable bytedump cryptohash utf8String ];
  meta = {
    homepage = "https://github.com/cdornan/pbkdf";
    description = "Haskell implementation of the PBKDF functions from RFC-2898";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})

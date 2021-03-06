{ cabal, alsaCore, alsaLib, extensibleExceptions, sampleFrame
, storableRecord
}:

cabal.mkDerivation (self: {
  pname = "alsa-pcm";
  version = "0.6.0.3";
  sha256 = "0rq0i17xhd0x7dnlhdf3i1fdvmyxrsbm0w0k9lrx20xpy4gw2zfs";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    alsaCore extensibleExceptions sampleFrame storableRecord
  ];
  pkgconfigDepends = [ alsaLib ];
  meta = {
    homepage = "http://www.haskell.org/haskellwiki/ALSA";
    description = "Binding to the ALSA Library API (PCM audio)";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.stdenv.lib.platforms.linux;
  };
})

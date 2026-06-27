#!/usr/bin/env bash
# Cross-compile ScummVM (scumm engine) for Windows x64 via docker mingw-w64.
# Self-builds SDL2 + zlib (mingw static). Compressed-audio codecs disabled (FOA +
# Chinese voice are raw VOC) -> runtime deps = SDL2(static) + the 3 mingw runtime DLLs.
# Prefix persisted under /work/build-win so reruns skip already-built deps.
set -euo pipefail
SDL2_VER=2.30.9 ; SCUMMVM_REF=ae89011b ; H=x86_64-w64-mingw32
PFX=/work/build-win/win-prefix ; SRC=/work/build-win/src ; SV=/work/build-win/scummvm-win
mkdir -p "$PFX" "$SRC"

echo "== toolchain =="
apt-get update -qq && apt-get install -y -qq g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
  binutils-mingw-w64-x86-64 mingw-w64-tools make curl git ca-certificates nasm xz-utils pkg-config >/dev/null

if [ ! -f "$PFX/lib/libSDL2.a" ]; then
  echo "== build SDL2 (mingw static) =="
  cd "$SRC"; [ -d SDL2-$SDL2_VER ] || curl -sL "https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VER}/SDL2-${SDL2_VER}.tar.gz" | tar xz
  cd SDL2-$SDL2_VER && ./configure --host=$H --prefix="$PFX" --disable-shared --enable-static --disable-render-d3d >/tmp/c.log 2>&1 || { tail -15 /tmp/c.log; exit 1; }
  make -j"$(nproc)" >/tmp/m.log 2>&1 || { tail -20 /tmp/m.log; exit 1; }; make install >/dev/null
fi
echo "SDL2: $(ls $PFX/lib/libSDL2.a)"

if [ ! -f "$PFX/lib/libz.a" ]; then
  echo "== build zlib (mingw static) =="
  cd "$SRC"; [ -d zlib-1.3.1 ] || curl -sL "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz" | tar xz
  cd zlib-1.3.1 && make -f win32/Makefile.gcc PREFIX=${H}- BINARY_PATH="$PFX/bin" INCLUDE_PATH="$PFX/include" LIBRARY_PATH="$PFX/lib" install >/tmp/z.log 2>&1 || { tail -15 /tmp/z.log; exit 1; }
fi
echo "zlib: $(ls $PFX/lib/libz.a)"

echo "== scummvm clone + patch =="
rm -rf "$SV"
git clone --depth 1 https://github.com/scummvm/scummvm.git "$SV" -q
cd "$SV"
git apply /work/patches/scumm-cjk.patch
# cross-compile: force little-endian (x64 Windows always LE; ScummVM's runtime
# endian check can't run a .exe on Linux). Same idea as its emscripten case.
sed -i '/^echo_n "Checking endianness... "/a _endian=little' configure
echo "patched."

echo "== configure (scumm only, minimal deps, self SDL2) =="
export PATH="$PFX/bin:$PATH"
export SDL2_CONFIG="$PFX/bin/sdl2-config"
./configure --host=$H --backend=sdl --enable-engine=scumm --disable-all-engines --enable-engine=scumm \
  --with-sdl-prefix="$PFX" --with-zlib-prefix="$PFX" \
  --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth --disable-tremor \
  --disable-faad --disable-mpeg2 --disable-a52 --disable-theoradec --disable-vpx \
  --disable-png --disable-jpeg --disable-gif --disable-freetype2 --disable-libcurl \
  --disable-sndio --disable-timidity --disable-sparkle --disable-discord \
  --enable-release >/tmp/svc.log 2>&1 || { echo "--- configure FAIL ---"; tail -30 /tmp/svc.log; exit 1; }
echo "configured."
make -j"$(nproc)" >/tmp/svm.log 2>&1 || { echo "--- make FAIL ---"; tail -30 /tmp/svm.log; exit 1; }
ls -la "$SV"/scummvm.exe && echo "BUILD OK: scummvm.exe"
# stage exe + the 3 mingw runtime DLLs (SDL2 is static-linked)
mkdir -p /work/build-win/out
cp "$SV"/scummvm.exe /work/build-win/out/
for d in libgcc_s_seh-1 libstdc++-6 libwinpthread-1; do
  f=$(find /usr/lib/gcc/$H /usr/$H -name "$d.dll" 2>/dev/null | head -1); [ -n "$f" ] && cp "$f" /work/build-win/out/ || true
done
ls -la /work/build-win/out/

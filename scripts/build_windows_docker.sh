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
# stage exe + EVERY non-system DLL it needs (objdump BFS over the import tree).
# This build static-links SDL2/zlib/libstdc++/libgcc/winpthread, so the import
# table is all-Windows-system and the walk bundles 0 DLLs (exe is self-contained);
# the walk still future-proofs against a build that links something dynamically.
mkdir -p /work/build-win/out
cp "$SV"/scummvm.exe /work/build-win/out/
OBJDUMP=$H-objdump
SEARCH="/usr/lib/gcc/$H/*-win32 /usr/lib/gcc/$H /usr/$H/lib /usr/$H/bin $PFX/bin $PFX/lib"
SYS='^(kernel32|user32|gdi32|gdiplus|winmm|ole32|oleaut32|shell32|shlwapi|advapi32|ws2_32|wsock32|imm32|msvcrt|version|setupapi|winspool\.drv|comctl32|comdlg32|dwmapi|uxtheme|hid|ntdll|rpcrt4|crypt32|wininet|iphlpapi|dbghelp|d3d9|d3d11|dxgi|dinput8|opengl32|glu32|avicap32|mscoree|powrprof|secur32|userenv|netapi32|cfgmgr32|bcrypt|api-ms-)'
declare -A seen; queue="scummvm.exe"
while [ -n "$queue" ]; do
  cur=$(printf '%s' "$queue" | head -1); queue=$(printf '%s' "$queue" | tail -n +2)
  curpath=$(ls /work/build-win/out/$cur 2>/dev/null || find $SEARCH -maxdepth 1 -iname "$cur" 2>/dev/null | head -1)
  [ -z "$curpath" ] && continue
  for dll in $($OBJDUMP -p "$curpath" 2>/dev/null | awk "/DLL Name/{print tolower(\$3)}" | sort -u); do
    [ -n "${seen[$dll]:-}" ] && continue; seen[$dll]=1
    echo "$dll" | grep -qiE "$SYS" && continue
    f=$(find $SEARCH -maxdepth 1 -iname "$dll" 2>/dev/null | head -1)
    [ -n "$f" ] && cp -n "$f" /work/build-win/out/ && echo "  bundle DLL: $dll" && queue=$(printf '%s\n%s' "$queue" "$dll")
  done
done
echo "non-system DLLs bundled: $(ls /work/build-win/out/*.dll 2>/dev/null | wc -l)  (0 = fully static, self-contained)"
ls -la /work/build-win/out/

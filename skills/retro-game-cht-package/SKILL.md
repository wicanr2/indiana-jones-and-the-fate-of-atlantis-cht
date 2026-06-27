---
name: retro-game-cht-package
description: 把一個「patched-ScummVM(或 SDL2)老遊戲繁中化」專案打包成三平台可玩成品的 SOP。涵蓋 Linux 單檔 AppImage(slim 自備遊戲 / full 內嵌遊戲開箱即玩)、Windows 用 docker mingw-w64 cross-compile(自編 SDL2 靜態連結、關掉 mad/vorbis/flac 壓縮編解碼、force little-endian 繞 cross 端序檢測、objdump 遞迴收所有非系統 DLL、打成 .zip)、macOS 走 GitHub Actions(自編 universal SDL2 不用 brew sdl2、dylibbundler)再抓 .app artifact 回本機注入語音+遊戲。也涵蓋 slim/full 版權切分(原版遊戲資料 + TTS 中文語音只進本機完整包、不上公開 CI)。當使用者談到「打包這個中文化」「Windows/AppImage/macOS 三平台」「cross-compile Windows」「docker mingw」「自編 SDL2」「AppImage 開箱即玩」「把遊戲也包進去」「DLL 都要打包」「Checking endianness unknown」「scummvm.exe 缺 DLL」「macos github action 編完抓回來打包」「dist-all」時觸發。**主動觸發**:使用者只說「幫這個漢化專案出 Windows / Linux / Mac 版」也套用。
---

# 老遊戲漢化專案 → 三平台打包 SOP

把一個「自家 patch 過的 ScummVM(或 SDL2)引擎 + 中文資產(字型 .dcjk / 譯表 .tab / 配音 .voc / 標題 .spr)」漢化專案,打成 Linux / Windows / macOS 三平台可玩成品。worked example:`indiana-jones-...-cht`(`scripts/package_appimage.sh`、`scripts/build_windows_docker.sh`、`scripts/package_windows.sh`、`scripts/package_macos_local.sh`、`.github/workflows/build-macos.yml`)。

## 平台分工(各走最省事的路)

| 平台 | 怎麼編 | 為什麼 |
|---|---|---|
| **Linux** | 本機 AppImage(bundle 系統 .so + AppRun) | 本機就是 Linux,直接 |
| **Windows** | 本機 **docker mingw-w64 cross-compile** | 不需 Windows 機,docker 內 cross 編 .exe |
| **macOS** | **GitHub Actions** macos runner → 抓 artifact 回本機注入 | Apple SDK EULA 只准 Apple host 編;後處理回本機 |

## slim / full 版權切分(鐵則)

- **slim**:引擎 + **自製**中文資產(字型/譯表/標題;**不含** TTS 語音也行)。**可公開散布**。
- **full**:再加 **TTS 中文語音(可能數百 MB)+ 原版遊戲資料**(`*.001`/`MONSTER.SOU` 等,**LucasArts/版權方所有**)→ 開箱即玩。**只進本機 `dist-all/`,個人自留,絕不上公開 CI / release**。
- `dist-all/`、cross-build 中間產物(`build-win/`)一律 `.gitignore`。

## Linux:單檔 AppImage(參考 willy 的 package_appimage)

```
AppDir/
  usr/bin/scummvm         # 引擎
  usr/lib/*.so            # ldd 撈出、排除 glibc/loader 的相依
  usr/share/<proj>/       # 中文資產(--extrapath 餵)
  game/                   # full 才有:內嵌遊戲資料
  AppRun .desktop .DirIcon
```
- AppRun 找遊戲順序:① 參數傳的路徑 ② 內嵌 `game/`(full 開箱即玩)③ .AppImage 旁 / CWD。`--extrapath=usr/share/<proj>` 餵中文資產、`-p <game>` 餵遊戲。
- `appimagetool --appimage-extract-and-run AppDir out.AppImage`(工具常在 `/home/anr2/zak-cht-build/appimagetool`)。
- **驗證**:full AppImage 不傳任何路徑直接跑,應偵測內嵌遊戲 + 顯示中文(實測過 30MB slim / 155MB full)。

## Windows:docker mingw-w64 cross-compile(關鍵踩雷全在這)

```bash
docker run --rm -v $PWD:/work -w /work debian:12-slim bash scripts/build_windows_docker.sh
```
- toolchain:`apt install g++-mingw-w64-x86-64 binutils-mingw-w64-x86-64`(binutils 給 cross objdump/strings)。
- **自編 SDL2 + zlib 靜態**(`--host=x86_64-w64-mingw32 --disable-shared --enable-static`),prefix 持久化到掛載目錄,reruns 跳過。
- **[HARD] cross 端序檢測會卡死**:ScummVM `configure` 編一個 .exe 用 `strings` 判端序,cross 到 mingw 後 `strings` 抓不到 marker → 「Checking endianness... unknown」→ `exit 1`。修法:configure 前 `sed -i '/^echo_n "Checking endianness... "/a _endian=little' configure`(x64 Windows 恆 LE;ScummVM 對 emscripten 已有同款 force)。
- **相依瘦身**:原版 + TTS 語音都是 raw VOC → `--disable-mad --disable-vorbis --disable-flac --disable-fluidsynth ...` 全關;再加 `--extra-ldflags="-static -static-libgcc -static-libstdc++"` → .exe 幾乎零外部相依。
- **[HARD] DLL 全收(objdump BFS)**:別寫死 DLL 清單。對 .exe 跑 `$HOST-objdump -p` 抓 `DLL Name`,過濾掉 Windows 系統 DLL(kernel32/user32/gdi32/msvcrt/ole32/...),把剩下的非系統 DLL 從 mingw sysroot 複製,**遞迴**對每個 bundled DLL 再掃。靜態連結後通常一個都不剩(import 表只有系統 DLL),但這個走訪保證未來改動動態連結時不漏。
- **[HARD] git clone source**:`git init + fetch --depth1 origin <SHA> + checkout FETCH_HEAD` 在 GitHub **抓不到任意 commit**(空 tree → patch 找不到檔)。用 `git clone --depth 1`(HEAD)+ `git apply patch`(patch 通常乾淨套 HEAD);要 pin commit 得 full clone + checkout。
- `scripts/package_windows.sh slim|full`:.exe + 收到的 DLL + 資產(+ full 的語音/遊戲)→ 目錄 → **`zip`**(參考 willy `dist/*.zip`)。
- **驗證**:`file scummvm.exe` 應為 `PE32+ ... x86-64`。**wine 在 dev box 不可靠**(Xvfb/wineboot 常抓不到輸出,且 ScummVM Windows 把 log 寫 `%APPDATA%/ScummVM/Logs/` **不寫 stdout**);驗到「PE32+ 有效 + wine 首跑達 SDL 視窗建立(objdump import 表正常、~100+ X requests)」即可,完整玩法驗證留給真 Windows。wine 別試超過 2-3 次(rabbit hole)。

## macOS:GitHub Action 編 → 抓回本機注入(參考 mac-app-cross-pack)

- `.github/workflows/build-macos.yml`:**`runs-on: macos-14`**(⚠️ **macos-13 已退役 → run 永遠 queued 卡死**;macos-14 = Apple Silicon/arm64,自編 universal 兩弧都涵蓋;舊 Intel 要 `macos-15-intel`),**自編 universal SDL2**(`--disable-shared --enable-static CFLAGS="-arch x86_64 -arch arm64 -mmacosx-version-min=11.0"`,⚠️ **arm64 最低 11.0,不能寫 10.13 否則衝突**),**不用 `brew sdl2`**(brew 的會變 sdl2-compat → 黑畫面);`git clone --depth1` + patch;configure 同樣關壓縮編解碼。⚠️ **ScummVM configure 沒有 `--extra-cflags/ldflags`**(寫了會 "unrecognized option" 整個 build 炸),arch 改用**環境變數** `CXXFLAGS="$ARCH" CFLAGS="$ARCH" LDFLAGS="$ARCH"` 傳進去;`dylibbundler` 把非系統 dylib 收進 `.app/Contents/libs`;上傳 `.app` artifact。
- 觸發 + 抓回:`gh workflow run build-macos.yml` → `gh run watch <id> --exit-status` → `gh run download <id>`。
- `scripts/package_macos_local.sh <下載的.app>`:把 TTS 語音 + 你的遊戲資料注入 `.app/Contents/Resources/data/` → full `.app` 到 `dist-all/macos/`(個人自留)。
- 細節(Gatekeeper `xattr -dr com.apple.quarantine`、APFS DMG Windows 讀不到改 `.tar.gz`、universal lipo)見 `mac-app-cross-pack` skill。

## 不要做

- ❌ 把原版遊戲資料 / 版權語音放進公開 CI 或 git → 散布盜版。
- ❌ Windows DLL 寫死清單 → 改動後缺 DLL。用 objdump BFS。
- ❌ 為了「自編 SDL2」結果 macOS 用了 `brew sdl2`(其實是 sdl2-compat)→ 黑畫面。一律 from source。
- ❌ cross-compile 還想跑 .exe 驗端序 → 用 sed force little-endian。
- ❌ wine 在 dev box 反覆鑽 → 抓到 PE 有效 + 載入到圖形初始化就收手。

## 何時套用 / 不套用

- 套用:任何 patched-ScummVM / SDL2 老遊戲漢化專案要出三平台成品。
- 配合:`mac-app-cross-pack`(macOS DMG 細節)、`dev-setup-bundle`(dev 環境)、`retro-game-playtest`(可玩性驗證)、`82-cross-platform-port-verification` rule(跨平台分歧)。
- 不套用:純 Linux 自用(只要 AppImage 那段);非 SDL/ScummVM 引擎(相依不同)。

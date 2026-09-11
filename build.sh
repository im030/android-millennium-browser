#!/bin/bash
set -x

source common.sh
set_keys
export VERSION=$(grep -m1 -o '[0-9]\+\(\.[0-9]\+\)\{3\}' vanadium/args.gn)
export CHROMIUM_SOURCE=https://chromium.googlesource.com/chromium/src.git # https://github.com/chromium/chromium.git
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y sudo lsb-release file nano git curl python3 python3-pillow imagemagick librsvg2-bin
sudo dpkg --add-architecture i386; sudo apt-get update; sudo apt-get install -y libgcc-s1:i386

git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"
mkdir -p chromium/src/out/Default; cd chromium/src
git init
git remote add origin $CHROMIUM_SOURCE

for ((i = 0 ; i <= 30 ; i++)); do
    if git fetch --depth 1 $CHROMIUM_SOURCE +refs/tags/$VERSION:chromium_$VERSION; then
        break
    fi
done
git checkout $VERSION
cp $SCRIPT_DIR/.gclient ../.gclient

# https://grapheneos.org/build#browser-and-webview
rm -rf $SCRIPT_DIR/vanadium/patches/*trichrome-apk-build-targets.patch
rm -rf $SCRIPT_DIR/vanadium/patches/*javascript-optimizer-{site-setting,settings-UI}.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*component-updates.patch # check if this actually needs to be removed
# rm -rf $SCRIPT_DIR/vanadium/patches/*{pdf,PDF,for-content-public,toolbar-button,configs-from-config-app,new-tab-card,predictive-back*}*.patch
# rm -rf $SCRIPT_DIR/vanadium/patches/*crashpad*.patch
replace "$SCRIPT_DIR/vanadium/patches" "VANADIUM" "MILLENNIUM"
replace "$SCRIPT_DIR/vanadium/patches" "Vanadium" "Millennium"
replace "$SCRIPT_DIR/vanadium/patches" "vanadium" "millennium"
git am --whitespace=nowarn --keep-non-patch $SCRIPT_DIR/vanadium/patches/*.patch

function apply() {
    git am --whitespace=nowarn --keep-non-patch "$1" || (
        patch -p1 < "$1" || { git add .; git reset --hard; return 1; }
        git add .
        git commit -m "$(echo "$1" | sed 's|.*/||g')"
    )
}
apply "$SCRIPT_DIR/custom-patches/0001-allow-background-audio-playback.patch"
# apply "$SCRIPT_DIR/custom-patches/0002-bromite-Share-Intent.patch"



gclient sync -D --no-history --nohooks
gclient runhooks --verbose
./build/install-build-deps.sh --no-prompt

source $SCRIPT_DIR/patch.sh

if [ ! -f v8/tools/builtins-pgo/profiles/x64.profile ]; then
    find v8 -name "x64.profile" || true
    python3 v8/tools/builtins-pgo/download_profiles.py --depot-tools ../../depot_tools --check-v8-revision download --force
fi

if [ ! -f build/util/LASTCHANGE ]; then
    python3 build/util/lastchange.py -o build/util/LASTCHANGE
fi

if [ ! -f build/util/LASTCHANGE.committime ]; then
    date -u +%s > build/util/LASTCHANGE.committime
fi

# cp $SCRIPT_DIR/args.gn out/Default/args.gn
# gn gen out/Default # gn args out/Default; echo 'treat_warnings_as_errors = false' >> out/Default/args.gn

gn gen --args="$(cat $SCRIPT_DIR/args.gn)" out/Default

mkdir -p out/tmp out/release

cat DEPS

autoninja -C out/Default trichrome_chrome_64_bundle_apks trichrome_library_64_apk trichrome_webview_64_apk system_webview_shell_apk
export PATH=$PWD/third_party/jdk/current/bin/:$PATH
mv "$(find out/Default/apks -name 'TrichromeLibrary64.apk')" out/release/TrichromeLibrary-$VERSION-arm64-v8a.apk
mv "$(find out/Default/apks -name 'TrichromeWebview64.apk')" out/release/TrichromeWebview-$VERSION-arm64-v8a.apk
java -jar "third_party/android_build_tools/bundletool/cipd/bundletool.jar" build-apks --mode universal --bundle out/Default/TrichromeChrome64.aab --output out/tmp/ --output-format DIRECTORY
mv out/tmp/universal.apk out/release/TrichromeBrowser-$VERSION-arm64-v8a.apk

# TODO: fix sign apk
# export ANDROID_HOME=$PWD/third_party/android_sdk/public
# sign_apk out/tmp/$VERSION-arm64-v8a.apk out/release/$VERSION-arm64-v8a.apk
# sign_aab out/tmp/$VERSION-arm64-v8a.aab out/release/$VERSION-arm64-v8a.aab
rm -rf $SCRIPT_DIR/keys

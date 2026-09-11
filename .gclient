solutions = [
  {
    'name': 'src',
    'url': 'https://chromium.googlesource.com/chromium/src.git',
    'managed': False,
    'custom_deps': {
      'src/third_party/apache-windows-arm64': None,
      'src/third_party/updater/chrome_win_x86': None,
      'src/third_party/updater/chrome_win_x86_64': None,
      'src/third_party/updater/chromium_win_x86': None,
      'src/third_party/updater/chromium_win_x86_64': None,
      'src/third_party/gperf': None,
      'src/third_party/lighttpd': None,
      'src/third_party/lzma_sdk/bin/host_platform': None,
      'src/third_party/lzma_sdk/bin/win64': None,
      'src/third_party/perl': None,
      'src/tools/skia_goldctl/win': None,
      'src/third_party/screen-ai/windows_amd64': None,
      'src/third_party/screen-ai/windows_386': None,
      'src/third_party/cronet_android_mainline_clang/linux-amd64': None,
      'src/testing/libfuzzer/fuzzers/wasm_corpus': None,
      'src/third_party/angle/third_party/VK-GL-CTS/src': None,
    },
    'custom_vars': {
      'checkout_android_prebuilts_build_tools': True,
      'checkout_pgo_profiles': True,
      'checkout_telemetry_dependencies': False,
      'codesearch': 'Debug',
    },
  },
]
hooks = [
  {
    'name': 'fetch_filter_lists',
    'condition': 'checkout_android',
    'action': ['python3',
              '../vanadium/tools/filter_lists/filter_list_download.py',
              '--output',
              'src/titanium/android_config/filter_lists/filter_lists_easylist.txt',
              '--urls',
              'https://easylist-downloads.adblockplus.org/antiadblockfilters.txt',
              'https://easylist.to/easylist/easylist.txt',
              'https://easylist.to/easylist/easyprivacy.txt']
  },
  {
    'name': 'apply_subprojects_patches',
    'condition': 'checkout_android',
    'action': ['python3',
              '../vanadium/tools/common/apply_subprojects_patches.py',
              '--base_patch_dir',
              '../vanadium/subprojects_patches',
              '--src_dir',
              'src']
  },
  {
    'name': 'fetch_titanium_extension',
    'condition': 'checkout_android',
    'action': ['python3',
              '../extensions/bundle.py',
              '../extensions/dist',
              'titanium',
              'https://github.com/jqssun/android-titanium-extension/releases/latest/download/titanium.crx']
  },
]
target_os = ['android']
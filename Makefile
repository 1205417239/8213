name: Build LinguaTweak

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Theos
        run: |
          rm -rf "$HOME/theos"
          git clone --depth=1 https://github.com/roothide/theos.git "$HOME/theos"

      - name: Setup Theos
        run: |
          echo "THEOS=$HOME/theos" >> $GITHUB_ENV
          echo "THEOS_MAKE_PATH=$HOME/theos/makefiles" >> $GITHUB_ENV
          echo "PATH=$HOME/theos/bin:/opt/homebrew/bin:$PATH" >> $GITHUB_ENV

      - name: Check environment
        run: |
          echo "THEOS=$THEOS"
          echo "THEOS_MAKE_PATH=$THEOS_MAKE_PATH"

      - name: Build arm64e
        run: |
          make clean
          make package ARCHS=arm64e FINALPACKAGE=1

      - name: Upload deb
        uses: actions/upload-artifact@v4
        with:
          name: LinguaTweak-arm64e
          path: |
            packages/*.deb
            .theos/packages/*.deb
          if-no-files-found: error

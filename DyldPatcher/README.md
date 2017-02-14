# iOS Dylib Patching Demo

This repository serve as a tool to teach iOS Developers how to inject using dynamic libraries into Ipa Files

## Main Components (included)
- [optool](https://github.com/alexzielenski/optool)
- patchapp.sh (code was modified from https://github.com/bamtan/PokemonGoAnywhere/blob/master/patchapp.sh)

## How to patch a ipa file
1. Download a cracked ipa. (eg. https://www.iphonecake.com)
2. Use Xcode to create an iOS Dynamic Framework (see below as an example). Build the framework target for iphoneos (non-iphonesimulator)
3. Reveal the framework in finder and locate the dynamic library binary.
4. Copy the dynamic library binary file and any depedent dylibs into a folder (lets call it DYLIBS). You may need additional XCode stock swift dylib which you can find them at ```/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift```. Copy any required swift dylib into the DYLIBS folder
5. Go to the root level of this repository and run ```sh ./patchapp.sh cracked.ipa ./DYLIBS```
6. You will see an output file called "cracked-patch.ipa". Use Cydia Impactor (http://www.cydiaimpactor.com) to sign the new and install it into your device.

#### This repository was inspired by the work of https://github.com/bamtan/PokemonGoAnywhere



# HackingFacebook

Bypassing Facebook for iOS's SSL Pinning, allow us to capture decrypted HTTPS request send from Facebook, with tools like [Charles](https://www.charlesproxy.com/).

## Description

This repository shows how to kill the certificate pinning in [Facebook for iOS](https://itunes.apple.com/cn/app/facebook/id284882215?mt=8).

I've successfully captured decrypted https requests from Facebook with Charles by apply this patch. I tested the currently newest Facebook for iOS version 79.0, this patch may become invalid with newer version.

## About
- Inspired by https://github.com/nabla-c0d3/ssl-kill-switch2, https://github.com/nabla-c0d3/ssl-kill-switch2/issues/13
- Contents of `DyldPatcher` is created by [depoon](https://github.com/depoon), the original repo is https://github.com/depoon/iOSDylibInjectionDemo, and an article about this https://medium.com/@kennethpoon/how-to-perform-ios-code-injection-on-ipa-files-1ba91d9438db#.mwx82zyds
- The `iResign` is modified version of https://github.com/maciekish/iReSign, created by Maciej Swic. I added support for injected libraries.
- The Aspects library is created by Peter Steinberger, licensed under MIT, the original repo is https://github.com/steipete/Aspects

## Instructions

1. Prepare `Facebook_extenstion_removed.ipa`
   - Get decrypted Facebook ipa, wether from  a jailbroken device or ipa download site (I'm using ipa downloaded from http://www.iphonecake.com)
   - Unzip ipa, Remove `Payload/Facebook.app/Plugins` folder, which contains App Extensions.
   - Zip the `Payload` folder, and rename to `Facebook_extenstion_removed.ipa`

2. Inject Code to `Facebook_extenstion_removed.ipa`
   - Build `DyldXcodeProject`, make sure the target is selected to real device (NOT iPhone Simulators), copy the result framework's binary file to a folder named `DyldsForInjection`
   - Use the script provide in `DyldPatcher`, patch the binary we generated, to `Facebook_extenstion_removed.ipa`, the patched file is named `Facebook_extenstion_removed-patched.ipa`
     
            cd DyldPatcher
            ./patchapp.sh Facebook_extenstion_removed.ipa DyldsForInjection

3. Resign `Facebook_extenstion_removed-patched.ipa`
   - Use the modified version of `iResign` to resign the file, the result file is `Facebook_extenstion_removed-patched-resigned.ipa`, this version will sign the dyld we injected correctly.

4. Install and Run
   - Install `Facebook_extenstion_removed-patched-resigned.ipa` via Xcode
   - Capture HTTPS requests like other apps with `Charles`!


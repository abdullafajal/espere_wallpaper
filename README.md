# Espere Wallpapers

Discover and save beautiful wallpapers, powered by [Pexels](https://www.pexels.com).
Pinterest-style masonry feed, Material You colours that match your wallpaper,
boards, favourites and one-tap "Set as wallpaper".

## Install (Android)

Download [`release/espere-wallpaper-v1.0.0.apk`](release/espere-wallpaper-v1.0.0.apk)
on your phone and open it. You may need to allow **Install unknown apps** for
your browser or file manager.

## Run from source

1. Install Flutter (stable).
2. Copy `.env.example` to `.env` and put your Pexels API key in it
   (get one free at https://www.pexels.com/api/).
3. `flutter pub get`
4. `flutter run`

Build a shareable APK: `flutter build apk --release`, then copy
`build/app/outputs/flutter-apk/app-release.apk` into `release/`.

## Brand assets

The app logo's editable SVG sources are in `assets/brand/source/`.

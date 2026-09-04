# Flutter smart download QR

A Flutter Web QR builder and mobile-app download landing page designed for
GitHub Pages.

## Features

- Generates one smart link for App Store and Google Play destinations.
- Creates a downloadable PNG QR code with `pretty_qr_code`.
- Supports an optional user-selected logo in the center of the QR image.
- Generates a plain QR code when no logo is selected.
- Keeps selected logo bytes out of the destination URL.
- Opens **Open download page** in a new browser tab.
- Redirects iPhone and iPad visitors to the App Store.
- Redirects Android visitors to Google Play.
- Shows both store buttons to desktop visitors.

## Logo behavior

There are two separate logo uses:

1. `assets/logo.png` is the application logo displayed on the download landing
   page. Replace this file to change the deployed landing-page branding.
2. **Choose app logo** selects an optional image for the center of the generated
   QR image. The original selected image is used for clear rendering.

The selected QR logo is not stored in the smart link and is not transferred to
the download page. If no image is selected, the QR has no center logo. Older
links that already contain embedded logo data remain readable.

The **Download QR** button exports the QR and its optional center logo as a PNG.

## Configure defaults

Edit `assets/config.json`:

```json
{
  "appName": "",
  "logoPath": "assets/logo.png",
  "appStoreUrl": "https://apps.apple.com/app/id1234567890",
  "googlePlayUrl": "https://play.google.com/store/apps/details?id=com.example.app"
}
```

The App Store and Google Play values prefill the form when they are not
placeholders. The app-name input starts empty. Keep all store links as complete
HTTPS URLs.

Replace the contents of `assets/logo.png` to customize the landing page. Keep
the filename lowercase and without spaces for reliable web deployment. Rebuild
and redeploy after changing assets or configuration.

## Run locally

From this project folder:

```bash
cd /Volumes/Apps/deeplinks_qr
flutter pub get
flutter run -d chrome
```

Alternatively, run a browser-independent local web server:

```bash
flutter run -d web-server
```

Open the URL printed by Flutter and enter:

1. The App Store link.
2. The Google Play link.
3. The app name.
4. An optional QR logo.

Select **Create QR code**. You can then download the QR, copy its smart link, or
open the download page in a new tab.

Automatic device redirects are best verified on real phones after deployment.

## Analyze, test, and build

```bash
flutter analyze
flutter test
flutter build web --release --base-href /YOUR_REPOSITORY_NAME/
```

For a GitHub user or organization site named `USERNAME.github.io`, build with:

```bash
flutter build web --release --base-href /
```

Flutter writes the production files to `build/web`.

## Deploy with GitHub Pages

The workflow in `.github/workflows/deploy.yml` analyzes, tests, builds, and
deploys the app whenever `main` is updated. It automatically uses
`/REPOSITORY_NAME/` for project sites and `/` for repositories named
`USERNAME.github.io`.

Create an empty GitHub repository, then run:

```bash
git init
git add .
git commit -m "Create app download landing page"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git
git push -u origin main
```

On GitHub, open **Settings → Pages** and set **Source** to **GitHub Actions**.
The deployed project-site URL will be:

```text
https://YOUR_USERNAME.github.io/YOUR_REPOSITORY_NAME/
```

The generated smart link stores only the app name and destination URLs in its
query string. Keep the complete query string when copying or sharing it.

## Redirect behavior

The download page checks the browser user agent and recognizes iPadOS devices
that identify themselves as macOS. Mobile visitors are redirected to the
matching store. Store buttons remain visible as a fallback when automatic
navigation is blocked or delayed.

## Main packages

- [`pretty_qr_code`](https://pub.dev/packages/pretty_qr_code) renders and
  exports the QR image.
- [`file_picker`](https://pub.dev/packages/file_picker) selects an optional QR
  logo and saves the exported PNG.
- [`image`](https://pub.dev/packages/image) validates selected image files.
- [`web`](https://pub.dev/packages/web) provides browser navigation and device
  detection without deprecated `dart:html` APIs.

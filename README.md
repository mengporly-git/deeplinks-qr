# Flutter QR download landing page

A single public URL for a QR code:

- Android visitors are sent automatically to Google Play.
- iPhone and iPad visitors are sent automatically to the App Store.
- Desktop visitors see both download buttons.

The app uses [`package:web`](https://pub.dev/packages/web) instead of the
deprecated `dart:html` library.

## 1. Customize the app

Edit `assets/config.json`:

```json
{
  "appName": "My App",
  "logoPath": "assets/logo.png",
  "appStoreUrl": "https://apps.apple.com/app/id1234567890",
  "googlePlayUrl": "https://play.google.com/store/apps/details?id=com.example.app"
}
```

Replace `assets/logo.png` with your own PNG, or add another image anywhere under
`assets/` and update `logoPath`. Keep the image filename lowercase and avoid
spaces for the most reliable web deployment.

Because the configuration is bundled into the web build, rebuild and redeploy
after changing it.

## 2. Run locally

From this project folder:

```bash
cd /Volumes/Apps/deeplinks_qr
flutter pub get
flutter run -d chrome
```

To test the desktop layout in any browser without Chrome device launching:

```bash
flutter run -d web-server
```

Open the local URL printed by Flutter. Automatic redirects are best verified on
a real iOS or Android device after deployment.

## 3. Check and build

```bash
flutter analyze
flutter test
flutter build web --release --base-href /YOUR_REPOSITORY_NAME/
```

For a GitHub user or organization site named `USERNAME.github.io`, use:

```bash
flutter build web --release --base-href /
```

The output is written to `build/web`.

## 4. Deploy with GitHub Pages

The workflow at `.github/workflows/deploy.yml` builds and deploys every push to
`main`. It automatically chooses `/REPOSITORY_NAME/` for project sites and `/`
for repositories named `USERNAME.github.io`.

Create an empty GitHub repository, then run:

```bash
git init
git add .
git commit -m "Create app download landing page"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git
git push -u origin main
```

On GitHub, open **Settings → Pages**, set **Source** to **GitHub Actions**, then
open the **Actions** tab to watch deployment. Your project-site URL will be:

```text
https://YOUR_USERNAME.github.io/YOUR_REPOSITORY_NAME/
```

Use that exact deployed URL when generating your one QR code. The QR image does
not need to change when you later update the app name, logo, or store URLs.

## How redirect detection works

The page checks the browser user agent. It also recognizes iPadOS devices that
identify themselves as macOS but have a touch screen. Store buttons stay visible
as a manual fallback if a browser blocks or delays automatic navigation.

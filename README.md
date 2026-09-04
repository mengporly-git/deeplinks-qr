# Flutter QR download landing page

A GitHub Pages-ready smart-link and QR builder:

- The root page provides a form for all destination links, QR name, app name,
  and logo.
- The form generates both a QR code and a shareable destination URL.
- Android visitors are sent automatically to Google Play.
- iPhone and iPad visitors are sent automatically to the App Store.
- Desktop visitors see both App Store and Google Play download buttons.

The app uses [`package:web`](https://pub.dev/packages/web) instead of the
deprecated `dart:html` library.

## 1. Set form defaults

Edit `assets/config.json`:

```json
{
  "appName": "",
  "logoPath": "assets/logo.png",
  "appStoreUrl": "https://apps.apple.com/app/id1234567890",
  "googlePlayUrl": "https://play.google.com/store/apps/details?id=com.example.app"
}
```

Replace `assets/logo.png` with your own PNG, or add another image anywhere under
`assets/` and update `logoPath`. Keep the image filename lowercase and avoid
spaces for the most reliable web deployment.

The store URL values prefill the browser form when they are not placeholders.
The app-name input intentionally starts empty. Rebuild and redeploy after
changing configuration defaults.

The logo control opens a local image picker. Selected images are resized and
compressed before being embedded in the smart link so the generated QR remains
portable across devices. The logo is also placed in the center of the QR image.
If no image is selected, `assets/logo.png` is used.

The generated result includes a **Download QR** button that saves the complete
QR and centered logo as a PNG image.

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

Open the local URL printed by Flutter, complete the form, and select **Create QR
code**. Automatic redirects are best verified on real devices after deployment.

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

Open that deployed URL, enter the store links, and select **Create QR code**.
Copy the generated destination link or use the displayed QR image. Store links
are encoded in that destination URL, so keep the complete query string.

## How redirect detection works

The destination page checks the browser user agent. It also recognizes iPadOS
devices that identify themselves as macOS. Store buttons stay visible as a
manual fallback if a browser blocks or delays automatic navigation.

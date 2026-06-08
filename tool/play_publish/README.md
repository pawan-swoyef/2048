# play_publish — push the store listing via the Play Developer API

Reads the listing copy from [`docs/store-listing.md`](../../docs/store-listing.md)
and uploads the **title + short description + full description** to the Google
Play Console for `com.number.twofoureight`, using the service-account key
`secretandstunts-e3a3e3c488d4.json` at the repo root.

## Run

```sh
cd tool/play_publish
dart pub get

# Validate the copy only (no network, no auth) — safe to run anytime:
dart run bin/push_listing.dart

# Actually push to Play:
dart run bin/push_listing.dart --commit
```

Options: `--key`, `--listing`, `--package`, `--language` (default `en-US`).

## One-time setup required before `--commit` works

The service account alone is **not** enough. All of these must be true:

1. **The app already exists in Play Console.** You cannot create an app via the
   API. Create `com.number.twofoureight` in the console first.
2. **Enable the API.** In Google Cloud console (project `secretandstunts`),
   enable *Google Play Android Developer API*.
3. **Grant the service account access in Play Console.**
   Play Console → *Users and permissions* → *Invite new users* →
   `paywallsuper@secretandstunts.iam.gserviceaccount.com` → give it at least
   **Edit store listing & images** (or Admin) for this app.
   (Linking the account under *Setup → API access* also works.)

If you see a 403 the account lacks permission; a 404 means the app/package
isn't found. The script prints the specific fix for each.

## What this does NOT do

The Play **listings** API only covers the three text fields. These are not part
of it and must still be done in the Play Console UI:

- Graphics: app icon (512×512), feature graphic (1024×500), phone screenshots
- App category and tags
- Content rating questionnaire
- Data safety form
- **Privacy policy URL** — required because the app shows ads. The HTML is at
  [`docs/privacy-policy.html`](../../docs/privacy-policy.html); host it at a
  public URL and paste that into the console.

Graphics *can* be uploaded via the API's separate `images` endpoint — ask if you
want this script extended to do that too.

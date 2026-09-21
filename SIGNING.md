# Android release signing

This template ships with a signing pattern already wired into
`android/app/build.gradle.kts`, but **no keystore** — you generate one
per project. Do not reuse the same keystore across multiple apps built
from this template; see the reasoning below.

If you skip all of this, `flutter build apk --release` and
`flutter run --release` still work — they just fall back to the debug
signing key, which is fine for local testing but cannot be published to
the Play Store.

## Why one keystore per project, not one shared keystore

A keystore is your app's production signing identity. Reusing one across
several different apps means a single leak (a committed file, a stolen
laptop, a misconfigured CI secret) compromises every app signed with it,
not just one — an attacker could push a malicious "update" to all of
them. It also means losing that one keystore locks you out of publishing
updates to every app that used it. Generating a fresh one per project
costs two minutes and contains the blast radius to that project only.

## 1. Generate a keystore (once per project)

```bash
keytool -genkey -v -keystore ~/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release
```

- Keep the resulting `.jks` file **outside this repo** (e.g. your home
  directory, or a password manager / secrets vault) — `android/.gitignore`
  already blocks `**/*.jks` and `**/*.keystore` from being committed if
  you do keep it inside the repo, but outside is safer still.
- You'll be prompted for a store password, your name/org details, and a
  key password. Write these down somewhere durable (a password manager)
  — if you lose them, you lose the ability to publish updates to this
  app under the same identity.

## 2. Local builds: android/key.properties

Copy `android/key.properties.example` to `android/key.properties` and
fill in the real values:

```properties
storePassword=<the store password you set above>
keyPassword=<the key password you set above>
keyAlias=release
storeFile=/absolute/path/to/release-keystore.jks
```

`android/key.properties` is already git-ignored — it will never be
committed. Once it exists, `flutter build apk --release` picks it up
automatically (see `android/app/build.gradle.kts`).

## 3. CI builds: GitHub secrets

The `build-android` job in `.github/workflows/ci.yml` looks for these
repository secrets (Settings → Secrets and variables → Actions →
Secrets, not Variables — secrets are encrypted and never displayed) and
writes them into `android/key.properties` at build time if all of them
are present:

| Secret name | Value |
|---|---|
| `KEYSTORE_BASE64` | The `.jks` file, base64-encoded (see below) |
| `KEYSTORE_STORE_PASSWORD` | Store password |
| `KEYSTORE_KEY_ALIAS` | Key alias (`release` in the example above) |
| `KEYSTORE_KEY_PASSWORD` | Key password |

Base64-encode the keystore file to paste into `KEYSTORE_BASE64`:

```bash
# macOS/Linux
base64 -i release-keystore.jks | pbcopy   # or | tee out.txt

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release-keystore.jks")) | Set-Clipboard
```

If these secrets aren't set, the CI build still runs — it just produces
a debug-signed APK, same as a local build without `key.properties`. Set
`BUILD_ENABLED=true` (see `.github/workflows/ci.yml`'s comments) to turn
the build job on at all; the signing secrets above are independent of
that toggle.

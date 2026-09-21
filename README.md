# 1️⃣ Clone your Flutter base template
git clone https://github.com/abdul-salam111/Flutter-Template.git education_app && cd education_app


# 2️⃣ Remove Git history (disconnect from template repo)
rm -rf .git

# 3️⃣ Rename Flutter app name (what shows on the device)
rename setAppName --targets ios,android --value "YourAppName"

# 4️⃣ Change the package/bundle ID (Android + iOS)
# Replace with your own reverse-domain identifier, e.g. com.yourcompany.yourapp
flutter pub global run change_app_package_name:main com.example.yourapp

# 5️⃣ Get dependencies
flutter pub get

# 6️⃣ Reinitialize Git for the new project
git init
git add .
git commit -m "Initial commit from template"

# 7️⃣ Add your new remote repo
git remote add origin https://github.com/abdulsalam/my_new_app.git

# 8️⃣ Push your new project to your own repository
git branch -M main
git push -u origin main


# 9 one-time setup: install the mason CLI so the `mason` command is
# available on your machine (it is NOT a project dependency — it's a
# code-generation tool you run from the terminal, so it's activated
# globally rather than added to pubspec.yaml)
dart pub global activate mason_cli

# 10 scaffold the example auth feature into a brand-new/empty project
# (only needed if you didn't clone this template with lib/ already in it —
# skip this if lib/features/auth already exists)
mason make setup_project_architecture


# 11 create any new feature
mason make create_feature

# 12 add a new page/sub-flow to a feature that already exists (e.g.
# "change_password" alongside auth's "signin"/"signup")
mason make add_page

# 13 add Firebase Authentication as a drop-in alternative to the REST-backed
# auth feature (implements the same IAuthRepository contract; not wired in
# as active by default — see bricks/add_firebase/README.md)
mason make add_firebase

# 14 remove a page/sub-flow added via add_page (or a feature's original
# page from create_feature) — deletes its files and removes its routes/DI/
# barrel-export wiring. Requires --confirm (or "y" at the prompt).
mason make remove_page --feature_name auth --page_name change_password --confirm

# 15 remove an entire feature module (every page it contains, plus all
# their routes/DI wiring) — the inverse of create_feature. Requires
# --confirm (or "y" at the prompt).
mason make remove_feature --feature_name notes --confirm

# 16 remove Firebase Authentication added by add_firebase — reverts the
# pubspec/Gradle/main.dart/injection_container.dart wiring and deletes the
# generated Firebase files. Refuses to run if auth is currently wired to
# FirebaseAuthRepositoryImpl (switch it back to AuthRepositoryImpl first).
mason make remove_firebase --confirm


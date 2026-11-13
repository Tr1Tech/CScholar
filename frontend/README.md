# The CScholar app (frontend)

This folder holds the screens you see in the browser and on a phone. You do not
need to change anything here to run the app — just follow the steps.

> **First:** the server must already be running. That is Step 4 of the main
> [README](../README.md). If `http://localhost:5000/api/health` does not load in
> your browser, finish that first.

---

## Run the app on your computer

Open a **new** terminal window (keep the server window open) and run:

```bash
cd CScholar
cd frontend
flutter pub get
```

**You should see** `Got dependencies!`

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

The first run can take **5–10 minutes** because it builds the app. When it
finishes, a Chrome window opens with the CScholar login screen.

### Sign in

```
Email:    admin@csu.edu.ph
Password: admin123
```

This is sample data for local testing only.

---

## Starting it again later

You only run `flutter pub get` once. After that:

```bash
cd CScholar\frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000
```

---

## Running it on a phone

`localhost` means "this device", so a phone cannot use `localhost`. Use the
address of the computer instead.

**Android emulator:**

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

**Real phone (same Wi-Fi as the computer):** find the computer's local IP
address (for example `192.168.1.20`) and use:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
```

If the phone still cannot connect, allow the backend through Windows Firewall
when it asks.

The address is built into the app. If you change it, stop the app (`Ctrl+C`) and
run the command again.

---

## If something goes wrong

| What you see | What to do |
|---|---|
| `flutter is not recognized` | Install Flutter and reopen the terminal (main README, Step 1) |
| `No pubspec.yaml file found` | You are in the wrong folder — `cd frontend` first |
| Dependency conflicts or strange build errors | Delete the `frontend/.dart_tool` folder, then run `flutter pub get` again |
| `Failed to fetch` / empty screens after login | The server is not running, or the address is wrong. Check `http://localhost:5000/api/health` |
| Port already in use | Another Flutter instance is running. Close it, or add `--web-port 8081` |
| Build is very slow the first time | Normal. Later runs are much faster |

**Never run `flutter create` inside this folder.** It overwrites shared project
files and creates conflicts for everyone else.

---

## For developers

<details>
<summary>Click to open</summary>

- Flutter 3.47 stable, Dart 3.13. `pubspec.lock` is committed so everyone
  resolves identical package versions.
- API address is compiled in via `--dart-define=API_BASE_URL=...` and read in
  `lib/core/config.dart`. Default: `http://localhost:5000`.
- The backend allows any origin by default. For deployment, set `CORS_ORIGINS`
  in `backend/.env` to the site's origin.

**Tests**

```bash
flutter test
```

The suite covers screen rendering at phone and desktop sizes, the material
system, pagination, auth flows, and the thesis model/status rules.

**Layout**

```
lib/
  core/          config, constants, design tokens, providers, router
  models/        API models (Thesis, User, ...)
  presentation/  screens, widgets, mobile shell
  services/      ApiService (HTTP)
test/            widget and unit tests
```

**Release build**

```bash
flutter build web --release --dart-define=API_BASE_URL=http://localhost:5000
python -m http.server 8080 -d build/web
```

</details>

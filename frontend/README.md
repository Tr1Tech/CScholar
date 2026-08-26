# Frontend (Flutter)

The Flutter app (web + mobile, single codebase) will be built in **Phase 9 (web)** and
**Phase 10 (mobile)**.

Flutter is **not installed yet** on this machine. Setup steps (for later):

1. Install the Flutter SDK: https://docs.flutter.dev/get-started/install
2. `flutter doctor` to verify the toolchain.
3. `flutter create .` inside this folder to initialize the project.

Flutter will communicate with the Flask backend only through the REST API (JSON).
It must NOT connect to PostgreSQL directly, and must not contain DB credentials.

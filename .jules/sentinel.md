## 2024-01-12 - Hardcoded Secrets in Assets
**Vulnerability:** The application was bundling a `.env` file containing the `X_API_KEY` directly into the application assets via `pubspec.yaml`. This makes the secret easily extractable by unzipping the APK/IPA.
**Learning:** `flutter_dotenv` requires the `.env` file to be an asset to load it at runtime, which is insecure for secrets that shouldn't be exposed.
**Prevention:** Use `--dart-define` to inject secrets at build time and access them using `String.fromEnvironment()`. This compiles the secret into the binary rather than leaving it as a plain text file.

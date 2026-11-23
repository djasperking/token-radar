# Parcel (Flutter)

A parcel delivery app UI: animated splash, login with a "signing in" overlay,
and a home screen showing the current delivery, services, active shipments,
weekly stats, recent updates, a drop-off map and a frosted floating tab bar.

## Run it in VS Code

1. Install the Flutter SDK and the **Flutter** extension in VS Code.
2. Get the code:
   ```sh
   git clone https://github.com/djasperking/token-radar.git
   cd token-radar && git checkout claude/adoring-lamport-ezqx1k
   cd parcel_app
   ```
3. Generate the platform folders (ios/, android/, ...) once:
   ```sh
   flutter create . --project-name parcel_app --org com.example
   flutter pub get
   ```
4. Open `parcel_app/` in VS Code (`code .`), pick a device in the status bar
   (for example the iOS Simulator) and press **F5** ("Parcel (debug)").

## Layout

- `lib/main.dart`: app entry point
- `lib/theme/app_theme.dart`: colors and theme
- `lib/pages/`: splash, login and home screens
- `lib/widgets/`: home sections, map, logo, entrance animation

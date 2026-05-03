# Taglow Admin

Flutter Web admin console for creating Taglow votes and questions.

## Run

Install dependencies:

```sh
flutter pub get
```

Run against the real server:

```sh
flutter run -d chrome \
  --dart-define=TAGLOW_API_BASE_URL=https://vote.newdawnsoi.site \
  --dart-define=TAGLOW_PARTICIPANT_BASE_URL=https://taglow-acca6.web.app \
  --dart-define=TAGLOW_PLAYER_BASE_URL=https://taglow-player.web.app
```

Run with the local mock service:

```sh
flutter run -d chrome \
  --dart-define=TAGLOW_USE_MOCK_SERVICE=true \
  --dart-define=TAGLOW_PARTICIPANT_BASE_URL=https://taglow-acca6.web.app \
  --dart-define=TAGLOW_PLAYER_BASE_URL=https://taglow-player.web.app
```

Use a browser URL instead of Chrome debugging:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

## Checks

```sh
dart format lib test web
flutter analyze lib test
flutter test
```

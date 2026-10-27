# ParkPing

iPhone app that notices when a car trip ends and reminds you to pay for parking.

## Features

- Detects drive → stop using location/speed
- Prompt: Driver / Passenger / Paid / Snooze / Put parking
- Area code → opens Messages with a prefilled SMS (template editable in settings)
- **Monitoring** toggle turns off location tracking to save battery (e.g. traveling abroad)

## Run on iPhone

```bash
cd ParkPing
flutter pub get
flutter run --release
```

In Xcode: open `ios/Runner.xcworkspace` → Signing → Team = your Apple ID.

## SMS template

Set the short code and message in **Settings**. Use `{code}` where the area code goes.

Example: number `12345`, body `PARK {code}`

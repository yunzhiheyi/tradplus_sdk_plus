# TradPlus Local Patches

This directory contains a locally managed copy of `tradplus_sdk`.

## Why this exists

The upstream plugin required local fixes to work reliably in this app:

1. iOS multi-engine callback routing
   - `TradplusSdkPlugin.m` used a static `FlutterMethodChannel *channel`.
   - In this app, `flutter_background_service` can cause plugin registration on more than one Flutter engine.
   - A later registration could overwrite the channel bound to the main UI engine, which caused native splash and init callbacks to be delivered to the wrong engine.
   - Fix: bind the primary method channel once and keep it for callback delivery.

2. iOS init callback success flag
   - `TradplusSdkManager.m` treated `error != nil` as success.
   - Fix: success is `error == nil`.

3. Splash optional callback safety
   - `tp_splash.dart` force-called optional listener callbacks with `!`.
   - If the app did not implement an optional callback, Dart threw before later splash callbacks could continue.
   - Fix: use nullable calls (`?.call(...)`) for optional splash callbacks.

4. iOS EventChannel compatibility
   - iOS does not implement `tradplus_sdk_events`, but Dart was subscribing to it unconditionally.
   - This caused `MissingPluginException(No implementation found for method listen on channel tradplus_sdk_events)`.
   - Fix: subscribe to the event stream on Android only; iOS uses `MethodChannel` callbacks.

5. Android multi-engine callback routing
   - `TradPlusSdk.java` is a singleton that stores the active `MethodChannel` and `EventSink`.
   - In this app, `flutter_background_service` can register plugins on an additional Flutter engine.
   - A later Android engine registration could overwrite the primary callback channel and cause reward callbacks to be delivered to the wrong engine.
   - Fix: bind Android plugin channels once for the primary engine and ignore later registrations.

## Logging policy

Temporary debugging logs added during callback tracing were reduced.

- Verbose Dart plugin logs are guarded by:
  - `modules/tradplus_sdk/lib/tp_listener.dart`
  - `modules/tradplus_sdk/lib/tp_splash.dart`
- Verbose iOS native logs are guarded by:
  - `TP_VERBOSE_LOGGING`
  - `TP_SPLASH_VERBOSE_LOGGING`

Default behavior is quiet. Only essential warning/error logs remain enabled.

## Dependency wiring

The app is intentionally pinned to this local copy:

- root `pubspec.yaml`
- `modules/tool_common/pubspec.yaml`

Do not switch back to the hosted package unless these patches are carried forward.

## Upgrade checklist

When updating upstream `tradplus_sdk`, re-check these files first:

- `ios/Classes/TradplusSdkPlugin.m`
- `ios/Classes/TradplusSdkManager.m`
- `lib/tp_listener.dart`
- `lib/tp_splash.dart`

If upstream has fixed these issues, prefer deleting local patches rather than carrying them forever.

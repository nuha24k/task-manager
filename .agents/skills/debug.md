# Debugging Guidelines (Senior Flutter Developer)

## Steps & Techniques

### 1. BLoC State Flow Inspection
- Utilize `BlocObserver` to trace event transitions, state updates, and unhandled errors globally across the app.
```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}
```

### 2. General App Diagnostics
- Inspect network requests using `Dio` interceptors or `Alice` / `Chucker` HTTP inspectors.
- Check platform-specific configurations (`AndroidManifest.xml`, `Info.plist`, build settings) when encountering platform channel or hardware integration failures.
- Log raw payloads or data stream events before parsing into domain entities.

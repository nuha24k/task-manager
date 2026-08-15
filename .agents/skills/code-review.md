# Code Review Guidelines (Senior Flutter Developer)

## Checklist

### 1. MVVM & BLoC Architecture Compliance
- [ ] UI elements (Widgets) strictly refrain from triggering business logic or direct API/DB calls without passing through BLoC.
- [ ] No `BuildContext` is passed into or stored inside BLoC or Repository classes.
- [ ] States are immutable and override `Equatable` or use `@freezed`.
- [ ] `buildWhen` or `BlocSelector` is used where necessary to avoid over-rebuilding UI.

### 2. Resource & Lifecycle Management
- [ ] Platform service listeners, web sockets, or hardware connections are cleanly stopped when the widget disposes or BLoC closes.
- [ ] StreamSubscriptions are stored and cancelled in `close()`.
- [ ] Controllers (`TextEditingController`, `AnimationController`, `ScrollController`) are disposed of properly.

### 3. Error Handling
- [ ] Failures and Exceptions are mapped using `Either<Failure, T>` or custom Failure classes.
- [ ] Errors emit explicit failure states to notify the UI instead of silently catching or failing.

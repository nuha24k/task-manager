# Flutter Tech Stack Guidelines

## Core Tech Stack & Dependencies

- **Framework**: Flutter (latest stable channel) with sound null-safety.
- **State Management**: `flutter_bloc` & `bloc` (MVVM pattern where BLoC acts as ViewModel).
- **Immutability & Equality**: `equatable` or `freezed` for immutable States, Events, Data Models, and Value Objects.
- **Dependency Injection & Service Locator**: `get_it` and `injectable`.
- **Functional Programming & Error Handling**: `fpdart` (`Either<Failure, Success>`, `TaskEither`).
- **Networking & API**: `dio` or `http` with custom interceptors and data source abstractions.
- **Local Storage / Persistence**: `shared_preferences`, `hive`, `flutter_secure_storage`, or `drift` wrapped in dedicated Data Sources.
- **Platform/Hardware Services**: Wrapped inside specialized Services / Data Sources (e.g. Location, Bluetooth, NFC, Camera, Push Notifications).

## Layer Responsibilities (MVVM Architecture)

```
       [ View Layer (UI) ]
       (Widgets, Pages, BlocBuilder)
                │
                ▼ (Events / User Actions)
     [ ViewModel / BLoC Layer ] ◄── Emits Immutable States
      (Business Logic, State Machine)
                │
                ▼ (Invokes UseCases / Repositories)
       [ Domain / Data Layer ]
     (Entities, Repositories, Data Sources, Platform Services)
```

### 1. View (UI Layer)
- Purely presentation components (`StatelessWidget` preferred).
- Never place business logic, direct API, database, or hardware calls inside Widgets.
- Use `BlocProvider` to inject BLoCs, and `BlocConsumer` / `BlocListener` / `BlocBuilder` to react to state changes.
- Use `select` or `buildWhen` to filter widget rebuilds only when specific state properties change.

### 2. ViewModel / BLoC Layer
- Holds UI state and maps incoming UI Events to target States.
- BLoC must be completely decoupled from `BuildContext` and Flutter UI elements.
- Always handle async operations safely (emit loading state -> process -> emit success or failure).
- Must override `close()` to cancel all active streams, Rx Dart subscriptions, or service listeners.

### 3. Model / Data & Domain Layer
- **Entities**: Pure Dart objects representing core business domain objects.
- **Repositories**: Interface definitions in domain layer, concrete implementations in data layer. Returns `Either<Failure, T>`.
- **Data Sources**: Low-level REST/GraphQL API calls, local storage operations, or device hardware controllers.

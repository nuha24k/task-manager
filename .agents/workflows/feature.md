# Feature Workflow (MVVM + BLoC)

## Standard Workflow Steps

1. **Requirements & Model Design**:
   - Define data entities and contracts in the `domain` layer.
   - Define failure & success outcome structures using `fpdart` (`Either<Failure, Success>`).

2. **Repository & Service Layer**:
   - Implement data sources (e.g. Remote REST APIs, Local Storage, Native Hardware Channels).
   - Implement repository pattern connecting data sources to domain interfaces.

3. **ViewModel / BLoC Layer**:
   - Define Events representing all possible user or platform actions (`FetchDataRequested`, `SubmitFormStarted`).
   - Define States covering all UI conditions (`Initial`, `Loading`, `Success`, `Failure`).
   - Write state transformation handlers in BLoC using `on<Event>`.

4. **UI Layer**:
   - Create stateless widgets for views and components.
   - Wire BLoC with `BlocProvider` and handle state updates using `BlocBuilder` / `BlocConsumer`.

5. **Testing & Verification**:
   - Write unit tests for BLoC transitions using `bloc_test`.
   - Verify UI widget responsiveness and state emission.

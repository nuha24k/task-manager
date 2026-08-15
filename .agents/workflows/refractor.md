# Refactoring Workflow (MVVM + BLoC)

## Refactoring Guidelines

1. **Isolate Changes**:
   - Refactor one layer at a time (Data Layer -> BLoC/ViewModel Layer -> View Layer).
   - Ensure existing unit tests for BLoCs pass before modifying UI structure.

2. **Decouple Legacy Code**:
   - Extract inline logic or `setState` calls from legacy widgets into BLoC Events/States.
   - Replace direct service/API calls inside Widgets with Repository dependency injection via `GetIt`.

3. **Verification**:
   - Execute `flutter test` after each layer refactor.
   - Verify zero regression in event handling and state emission lifecycle.

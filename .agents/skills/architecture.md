# Architecture Guidelines (MVVM + BLoC)

## Design Pattern Guidelines

### 1. Model-View-ViewModel (MVVM) with BLoC
- **View**: Listens to state streams emitted by the ViewModel (BLoC) and builds UI widgets accordingly.
- **ViewModel (BLoC)**: Receives actions from the View as **Events**, executes business/domain logic, and emits **States**.
- **Model**: Encapsulates data models, entities, API payloads, and domain logic.

### 2. Layered Project Structure
- **UI Code**: `lib/presentation/` (Pages, Widgets, Dialogs).
- **BLoC Code**: `lib/presentation/<feature>/bloc/` or `lib/application/<feature>/`.
- **Domain Code**: `lib/domain/` (Entities, Failures, Repository Interfaces, Use Cases).
- **Data Code**: `lib/infrastructure/` or `lib/data/` (Repository Implementations, Data Sources, DTOs).

### 3. State Management Best Practices
- Keep state classes small, predictable, and descriptive (`FeatureInitial`, `FeatureLoading`, `FeatureSuccess`, `FeatureFailure`).
- Avoid storing mutable fields in state classes. Use `copyWith` for immutable state updates.
- Prevent emitting state after BLoC has been closed.

### 4. Service & Repository Integration
- Encapsulate external services (APIs, Databases, Device Hardware/Sensors) inside dedicated Data Sources.
- Inject Data Sources into Repository implementations.
- The BLoC triggers operations via Repositories or Use Cases based on incoming Events and listens to streams or async results.

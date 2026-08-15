# Flutter Unit Testing Guidelines

A general and adaptable standard for writing, organizing, reviewing, and maintaining unit tests across Flutter and Dart projects.

These guidelines are intentionally framework-agnostic where possible, while supporting common Flutter testing tools such as `flutter_test`, `mocktail`, and `bloc_test`.

---

## 1. Testing Principles

Unit tests should focus on **behavior**, not implementation details.

Prioritize tests that verify:

* Expected behavior under normal conditions.
* Error and failure handling.
* Edge cases and boundary conditions.
* State transitions.
* Interactions with external dependencies.
* Business rules and data transformations.

A good unit test should be:

1. **Independent** — does not depend on another test.
2. **Deterministic** — produces the same result every time.
3. **Fast** — avoids unnecessary I/O, network calls, databases, or real services.
4. **Readable** — describes the expected behavior clearly.
5. **Maintainable** — does not unnecessarily depend on implementation details.
6. **Focused** — verifies one meaningful behavior per test.

---

## 2. Test Structure

Tests should generally mirror the structure of the `lib/` directory.

### Recommended Structure

```text
lib/
├── core/
├── features/
│   └── authentication/
│       ├── data/
│       ├── domain/
│       └── presentation/

test/
├── core/
└── features/
    └── authentication/
        ├── data/
        ├── domain/
        └── presentation/
```

### Naming Convention

Test files must end with:

```text
_test.dart
```

Examples:

```text
user_repository.dart
user_repository_test.dart
```

```text
login_bloc.dart
login_bloc_test.dart
```

```text
calculate_total.dart
calculate_total_test.dart
```

The test file should closely correspond to the source file being tested.

---

## 3. Test Naming

Test descriptions should describe **observable behavior**.

Prefer:

```dart
test(
  'should return the user when the repository call succeeds',
  () async {
    // ...
  },
);
```

```dart
test(
  'should return a failure when the network request throws an exception',
  () async {
    // ...
  },
);
```

```dart
test(
  'should emit loading and success states when authentication succeeds',
  () async {
    // ...
  },
);
```

Avoid vague descriptions:

```dart
test('works', () {});
test('test login', () {});
test('repository test', () {});
```

### Recommended Pattern

Use:

```text
should [expected behavior] when [condition]
```

Examples:

```text
should return cached data when the remote source is unavailable
should emit an error state when authentication fails
should reject invalid input when the value is empty
should calculate the correct total when multiple items are provided
```

---

## 4. Arrange - Act - Assert

Tests should generally follow the **AAA pattern**:

* **Arrange** — prepare dependencies, data, and conditions.
* **Act** — execute the behavior being tested.
* **Assert** — verify the result or interaction.

```dart
test('should return a user when the repository succeeds', () async {
  // Arrange
  when(() => mockRepository.getUser(userId))
      .thenAnswer((_) async => user);

  // Act
  final result = await useCase.execute(userId);

  // Assert
  expect(result, equals(user));
  verify(() => mockRepository.getUser(userId)).called(1);
});
```

Keep the three phases visually separated when the test becomes complex.

---

## 5. Setup and Teardown

Use `setUp()` for test-specific initialization.

```dart
void main() {
  late MockRepository mockRepository;
  late UserUseCase useCase;

  setUp(() {
    mockRepository = MockRepository();
    useCase = UserUseCase(mockRepository);
  });

  // tests...
}
```

Use `setUpAll()` only for initialization that can safely be shared across the entire test suite.

```dart
setUpAll(() {
  registerFallbackValue(FakeRequest());
});
```

Use `tearDown()` or `tearDownAll()` when resources need explicit cleanup.

Avoid sharing mutable state between tests.

Each test should be able to run independently.

---

## 6. Mocking with Mocktail

Use `mocktail` for mocking dependencies when real implementations are unnecessary or undesirable.

### Mock Classes

```dart
class MockUserRepository extends Mock implements UserRepository {}

class FakeUserRequest extends Fake implements UserRequest {}
```

### Fallback Values

When a mocked method accepts a custom object with `any()`, register an appropriate fallback.

```dart
setUpAll(() {
  registerFallbackValue(FakeUserRequest());
});
```

Then:

```dart
when(() => mockRepository.create(any()))
    .thenAnswer((_) async => const Right(null));
```

### Mocking Guidelines

Mock:

* Repositories.
* Data sources.
* API clients.
* External services.
* Platform services.
* File systems.
* Database interfaces.
* Other expensive or non-deterministic dependencies.

Avoid mocking the class being directly tested.

Prefer real simple value objects, entities, and pure functions when possible.

---

## 7. Mock Verification

Verify interactions when the interaction itself is part of the behavior being tested.

```dart
verify(() => mockRepository.getUser(userId)).called(1);
```

For important negative behavior:

```dart
verifyNever(() => mockRepository.deleteUser(any()));
```

Use:

```dart
verifyNoMoreInteractions(mockRepository);
```

when strict interaction verification provides meaningful protection.

Do not verify every implementation detail simply to increase test coverage.

Tests should primarily validate **what the system does**, not every internal method call.

---

## 8. Testing Success and Failure Paths

Every important behavior should consider both successful and unsuccessful scenarios.

### Success

```dart
test('should return data when the request succeeds', () async {
  // Arrange
  when(() => mockDataSource.fetch())
      .thenAnswer((_) async => testData);

  // Act
  final result = await repository.fetch();

  // Assert
  expect(result, equals(testData));
});
```

### Failure

```dart
test('should return failure when the request throws an exception', () async {
  // Arrange
  when(() => mockDataSource.fetch())
      .thenThrow(ServerException());

  // Act
  final result = await repository.fetch();

  // Assert
  expect(result, equals(const Left(ServerFailure())));
});
```

At minimum, consider:

* Happy path.
* Expected failure.
* Invalid input.
* Empty data.
* Null values where applicable.
* Boundary values.
* Unexpected dependency behavior.

---

## 9. Testing Either / Result Types

When a project uses `Either`, `Result`, or another functional error-handling pattern, test both sides explicitly.

For `dartz` or similar APIs:

```dart
expect(result, equals(const Right(expectedData)));
```

and:

```dart
expect(result, equals(const Left(expectedFailure)));
```

Example:

```dart
test('should return failure when the remote source fails', () async {
  // Arrange
  when(() => mockRemoteDataSource.fetch())
      .thenThrow(ServerException());

  // Act
  final result = await repository.fetch();

  // Assert
  expect(
    result,
    equals(const Left(ServerFailure())),
  );
});
```

Tests should verify that exceptions are correctly converted into the project's expected error representation.

---

## 10. Testing Use Cases

Use case tests should focus on business behavior and dependency interaction.

```dart
test('should return user when repository succeeds', () async {
  // Arrange
  when(() => mockRepository.getUser(userId))
      .thenAnswer((_) async => const Right(testUser));

  // Act
  final result = await useCase.execute(userId);

  // Assert
  expect(result, equals(const Right(testUser)));

  verify(() => mockRepository.getUser(userId)).called(1);
});
```

Test important business rules such as:

* Input validation.
* Data transformation.
* Conditional behavior.
* Authorization rules.
* Error propagation.
* Repository interaction.

---

## 11. Testing Repositories

Repository tests should verify the behavior of the repository abstraction between data sources and domain layers.

Typical scenarios:

```text
Remote source succeeds
Remote source fails
Local cache succeeds
Local cache fails
Fallback from remote to cache
Data conversion succeeds
Data conversion fails
```

Example:

```dart
test('should return model converted to entity when remote source succeeds',
    () async {
  // Arrange
  when(() => mockRemoteDataSource.fetch())
      .thenAnswer((_) async => testModel);

  // Act
  final result = await repository.fetch();

  // Assert
  expect(result, equals(Right(testModel.toEntity())));
});
```

Avoid testing the HTTP library itself. Test your application's behavior around it.

---

## 12. Testing BLoC and Cubit

Use `bloc_test` when testing BLoC or Cubit state transitions.

```dart
blocTest<AuthBloc, AuthState>(
  'should emit loading and success when login succeeds',
  build: () {
    when(() => mockRepository.login(any()))
        .thenAnswer((_) async => const Right(testUser));

    return AuthBloc(mockRepository);
  },
  act: (bloc) => bloc.add(
    const LoginRequested(
      email: testEmail,
      password: testPassword,
    ),
  ),
  expect: () => [
    const AuthLoading(),
    const AuthSuccess(testUser),
  ],
  verify: (_) {
    verify(() => mockRepository.login(any())).called(1);
  },
);
```

Test meaningful state transitions such as:

```text
Initial → Loading → Success
Initial → Loading → Failure
Initial → Loading → Empty
Authenticated → Loading → LoggedOut
```

Avoid testing private implementation details of the BLoC.

---

## 13. Testing Cubit

Cubit tests can be simpler because there are no events.

```dart
blocTest<CounterCubit, int>(
  'should increment the counter',
  build: () => CounterCubit(),
  act: (cubit) => cubit.increment(),
  expect: () => [1],
);
```

Test:

* Initial state.
* State changes.
* Invalid operations.
* Error states.
* Reset behavior.
* Business rules.

---

## 14. Testing Async Code

Always properly await asynchronous operations.

```dart
test('should fetch data asynchronously', () async {
  final result = await service.fetch();

  expect(result, isNotNull);
});
```

Avoid:

```dart
test('should fetch data', () {
  service.fetch().then((result) {
    expect(result, isNotNull);
  });
});
```

The second approach can finish the test before the assertion executes.

For streams, use appropriate asynchronous matchers or `bloc_test`.

---

## 15. Testing Exceptions

When a method is expected to throw:

```dart
test('should throw when input is invalid', () {
  expect(
    () => service.process(invalidInput),
    throwsA(isA<ValidationException>()),
  );
});
```

For asynchronous exceptions:

```dart
test('should throw when request fails', () async {
  expect(
    () => service.fetch(),
    throwsA(isA<ServerException>()),
  );
});
```

Prefer checking the exception type and relevant properties rather than relying on exact error messages unless the message itself is part of the contract.

---

## 16. Testing Edge Cases

Tests should include meaningful boundary conditions.

Examples:

```text
Empty list
Single item
Large list
Zero
Negative values
Maximum allowed value
Minimum allowed value
Null or missing optional values
Duplicate values
Invalid formats
Malformed responses
Timeouts
Network failures
Permission failures
```

Example:

```dart
test('should return zero when the item list is empty', () {
  final result = calculator.calculateTotal([]);

  expect(result, equals(0));
});
```

Do not add edge-case tests merely to increase the number of tests. Each test should protect meaningful behavior.

---

## 17. Testing Pure Functions

Pure functions should usually be tested without mocks.

```dart
test('should calculate the correct total', () {
  final result = calculateTotal([
    Item(price: 100),
    Item(price: 200),
  ]);

  expect(result, equals(300));
});
```

Pure logic is usually the easiest and most valuable code to unit test because it is:

* Fast.
* Deterministic.
* Independent.
* Easy to reason about.

---

## 18. Test Data and Fixtures

Use reusable test fixtures for complex objects.

```dart
const testUser = User(
  id: 'user-1',
  name: 'Test User',
  email: 'test@example.com',
);
```

For larger projects, consider:

```text
test/
└── fixtures/
    ├── user_fixture.dart
    ├── product_fixture.dart
    └── auth_fixture.dart
```

Fixtures should represent realistic but deterministic data.

Avoid unnecessarily huge test objects when only a few fields matter.

---

## 19. Avoid Over-Mocking

Do not mock everything.

Bad:

```text
UseCase
 ├── mocked Entity
 ├── mocked ValueObject
 ├── mocked Repository
 ├── mocked Request
 └── mocked Response
```

Prefer:

```text
UseCase
 ├── real Entity
 ├── real ValueObject
 └── mocked Repository
```

Mock external boundaries, not simple domain objects.

This keeps tests easier to understand and less coupled to implementation details.

---

## 20. Parameterized / Repetitive Tests

When multiple inputs verify the same behavior, consider parameterized testing or a data-driven approach supported by the project's testing tools.

Conceptually:

```text
Input      Expected
-------------------
1          2
2          4
5          10
10         20
```

This prevents duplicating nearly identical test cases.

Use separate tests when the scenarios represent substantially different behavior.

---

## 21. Flutter Widget Boundary

Unit tests should remain focused on Dart logic whenever possible.

Use:

```bash
flutter test
```

for unit and widget tests.

Use widget tests when behavior depends on:

* Flutter widgets.
* Build context.
* Rendering.
* User interaction.
* Navigation.
* Widget lifecycle.

Do not force widget behavior into pure unit tests.

A useful distinction is:

```text
Pure business logic     → Unit test
BLoC/Cubit              → Unit/state test
Repository              → Unit test
Widget behavior         → Widget test
Full application flow   → Integration test
```

---

## 22. What Should Not Be Unit Tested

Avoid unit testing framework or library behavior that your application does not own.

Examples:

* Whether Flutter's `Text` widget renders text.
* Whether `List.map()` works.
* Whether an HTTP library can make an HTTP request.
* Whether `Future` resolves correctly.
* Internal implementation of third-party packages.

Instead, test how your application uses those dependencies.

---

## 23. Test Independence

Tests must not depend on execution order.

Bad:

```text
Test A creates global state
Test B expects state from Test A
Test C modifies the state from Test B
```

Good:

```text
Test A → independent setup
Test B → independent setup
Test C → independent setup
```

Every test should establish the state it needs.

---

## 24. Avoid Flaky Tests

Avoid:

```dart
await Future.delayed(const Duration(seconds: 2));
```

unless the delay itself is the behavior under test.

Prefer:

* Controlled dependencies.
* Fake clocks when required.
* Mocked timers.
* Deterministic streams.
* Explicit async synchronization.
* Test utilities provided by the relevant framework.

A test that sometimes passes and sometimes fails should be treated as a defect in the test suite.

---

## 25. Coverage Guidelines

Coverage is useful, but **coverage percentage is not the primary goal**.

Prioritize coverage of:

* Business-critical logic.
* Authentication and authorization.
* Data transformation.
* Validation.
* Error handling.
* State management.
* Financial calculations.
* Security-sensitive behavior.
* Complex algorithms.

Avoid writing meaningless tests simply to reach a percentage target.

A smaller suite of meaningful tests is preferable to a large suite of superficial tests.

---

## 26. Running Tests

Run the complete test suite:

```bash
flutter test
```

Run a specific test file:

```bash
flutter test test/features/auth/login_bloc_test.dart
```

Run tests with coverage:

```bash
flutter test --coverage
```

Run tests matching a name:

```bash
flutter test --name "should return user"
```

Run static analysis:

```bash
flutter analyze
```

A recommended local validation flow is:

```bash
flutter analyze
flutter test
flutter test --coverage
```

---

## 27. CI Requirements

Tests should be executed automatically in CI.

A typical CI validation pipeline should include:

```text
1. Install dependencies
2. Run static analysis
3. Run unit tests
4. Run widget tests
5. Generate coverage
6. Fail the pipeline if required tests fail
```

Example:

```bash
flutter pub get
flutter analyze
flutter test
```

Coverage thresholds may be enforced when appropriate for the project.

---

## 28. Test Quality Checklist

Before committing tests, verify:

* [ ] Test file is inside `test/`.
* [ ] Test path mirrors the corresponding `lib/` path.
* [ ] File name ends with `_test.dart`.
* [ ] Test descriptions clearly describe expected behavior.
* [ ] Tests follow Arrange-Act-Assert where appropriate.
* [ ] Tests are independent.
* [ ] Mocks are reset or recreated per test when necessary.
* [ ] Fallback values are registered when required by `mocktail`.
* [ ] Happy paths are covered.
* [ ] Failure paths are covered.
* [ ] Important edge cases are covered.
* [ ] Async operations are properly awaited.
* [ ] Tests do not depend on network services.
* [ ] Tests do not depend on execution order.
* [ ] Tests avoid unnecessary mocking.
* [ ] Tests do not test third-party implementation details.
* [ ] Tests pass locally.
* [ ] `flutter analyze` passes.
* [ ] Coverage is appropriate for the importance of the code.

---

## 29. Definition of Done

A unit test implementation is considered complete when:

```text
Given
    The required dependencies and initial state are prepared.

When
    The behavior under test is executed.

Then
    The expected result, state, exception, or interaction is verified.
```

Additionally:

```text
✓ Tests are deterministic
✓ Tests are isolated
✓ Success scenarios are covered
✓ Failure scenarios are covered
✓ Important edge cases are covered
✓ Mocks are used only where appropriate
✓ No unnecessary implementation details are asserted
✓ flutter analyze passes
✓ flutter test passes
```

---

## 30. General Testing Philosophy

Follow this principle:

> **Test behavior, not implementation.**

Good tests should answer:

```text
"What should this component do?"
```

rather than:

```text
"How exactly is this component implemented?"
```

When implementation changes but behavior remains the same, well-designed tests should continue to pass.

The goal is not to create the maximum number of tests.

The goal is to create a **reliable safety net that gives developers confidence when changing the codebase**.

---

## 31. Recommended Test Priority

When adding tests to an existing project, prioritize in this order:

```text
1. Critical business logic
2. Error handling
3. State management
4. Data transformation
5. Repository behavior
6. Use cases
7. Validation
8. Edge cases
9. Utility functions
10. Less critical presentation logic
```

For new features, write tests alongside the implementation rather than postponing testing until the end.

---

## 32. Universal Rule

These guidelines should be adapted to the architecture and requirements of each Flutter project.

Do not blindly apply every rule.

The appropriate testing strategy depends on:

* Project architecture.
* Feature complexity.
* Risk level.
* Dependency boundaries.
* Performance requirements.
* Team conventions.
* Existing testing infrastructure.

The standard objective remains:

**Fast, deterministic, isolated, readable, behavior-focused tests that provide confidence without creating unnecessary maintenance cost.**

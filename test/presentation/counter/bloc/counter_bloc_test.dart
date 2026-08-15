import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/presentation/counter/bloc/counter_bloc.dart';
import 'package:task_management/presentation/counter/bloc/counter_event.dart';

void main() {
  group('CounterBloc Unit Tests', () {
    late CounterBloc counterBloc;

    setUp(() {
      counterBloc = CounterBloc();
    });

    tearDown(() {
      counterBloc.close();
    });

    test('initial state should be CounterInitialState with count = 0', () {
      expect(counterBloc.state, equals(const CounterInitialState()));
      expect(counterBloc.state.count, equals(0));
    });

    blocTest<CounterBloc, CounterState>(
      'should emit [CounterUpdatedState(1)] when IncrementCounterEvent is added',
      build: () => counterBloc,
      act: (bloc) => bloc.add(const IncrementCounterEvent()),
      expect: () => [
        const CounterUpdatedState(1),
      ],
    );

    blocTest<CounterBloc, CounterState>(
      'should emit [CounterUpdatedState(-1)] when DecrementCounterEvent is added',
      build: () => counterBloc,
      act: (bloc) => bloc.add(const DecrementCounterEvent()),
      expect: () => [
        const CounterUpdatedState(-1),
      ],
    );
  });
}

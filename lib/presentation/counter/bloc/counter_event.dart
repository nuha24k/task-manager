import 'package:equatable/equatable.dart';

abstract class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

class IncrementCounterEvent extends CounterEvent {
  const IncrementCounterEvent();
}

class DecrementCounterEvent extends CounterEvent {
  const DecrementCounterEvent();
}

abstract class CounterState extends Equatable {
  final int count;
  const CounterState(this.count);

  @override
  List<Object?> get props => [count];
}

class CounterInitialState extends CounterState {
  const CounterInitialState() : super(0);
}

class CounterUpdatedState extends CounterState {
  const CounterUpdatedState(super.count);
}

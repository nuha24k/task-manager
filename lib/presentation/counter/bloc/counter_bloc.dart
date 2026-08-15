import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterInitialState()) {
    on<IncrementCounterEvent>((event, emit) {
      emit(CounterUpdatedState(state.count + 1));
    });

    on<DecrementCounterEvent>((event, emit) {
      emit(CounterUpdatedState(state.count - 1));
    });
  }
}

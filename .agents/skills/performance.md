# Performance Optimization Guidelines

## Rules for Senior Flutter Developers

1. **Minimize Widget Rebuilds**:
   - Use `const` constructors aggressively across all static UI widgets.
   - Fine-tune `BlocBuilder` with `buildWhen` or use `BlocSelector` to restrict rebuilds to relevant state sub-trees.
2. **Stream & Listener Management**:
   - Pause or close streams when screens are not visible or app goes into background.
   - Avoid creating multiple BLoC instances dynamically inside ListView builders; pass data or IDs down instead.
3. **Memory Management**:
   - Ensure image, cache buffers, or large data collections are cleared when unneeded.
   - Use DevTools Memory Profiler to detect any un-disposed BLoCs or open stream channels.

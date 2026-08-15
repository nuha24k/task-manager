import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/main.dart';

void main() {
  testWidgets('TaskManagerApp smoke test', (WidgetTester tester) async {
    // Basic test stub
    await tester.pumpWidget(const TaskManagerApp());
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_wizard/main.dart';

void main() {
  testWidgets('WorkshopWizard app smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const WorkshopWizardApp());

    // The login screen should be visible on launch.
    expect(find.text('Workshop Wizard'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/agent/agent_router.dart';

void main() {
  group('AgentRouter', () {
    test('routes grocery input to grocery tool', () {
      expect(routeInput('I need potatoes'), Tool.grocery);
    });

    test('routes another grocery input to grocery tool', () {
      expect(routeInput('pick up milk and eggs'), Tool.grocery);
    });

    test('routes thought input to thoughts tool', () {
      expect(routeInput('I like the sunset today'), Tool.thoughts);
    });

    test('routes another thought input to thoughts tool', () {
      expect(routeInput('had an interesting idea about the app'), Tool.thoughts);
    });
  });
}

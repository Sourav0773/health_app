import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:health_tracker/data/health_connect_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHealth extends Mock implements Health {}

void main() {
  group('HealthConnectService Unit Tests', () {
    late MockHealth mockHealth;
    late HealthConnectService service;

    setUp(() {
      mockHealth = MockHealth();
      service = HealthConnectService(health: mockHealth);
    });

    tearDown(() {
      service.dispose();
    });

    test('currentPermissionState returns granted when Health API confirms permissions', () async {
      when(() => mockHealth.hasPermissions(any(), permissions: any(named: 'permissions')))
          .thenAnswer((_) async => true);

      final state = await service.currentPermissionState();
      expect(state, equals(PermissionState.granted));
    });

    test('currentPermissionState returns denied when permissions are missing', () async {
      when(() => mockHealth.hasPermissions(any(), permissions: any(named: 'permissions')))
          .thenAnswer((_) async => false);

      final state = await service.currentPermissionState();
      expect(state, equals(PermissionState.denied));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:progswitches/data/app_data.dart';

void main() {
  group('AppDataManager', () {
    test('modbusComPort can be set and retrieved', () {
      final manager = AppDataManager();
      const testComPort = 'COM1';

      // Set the COM port
      manager.modbusComPort = testComPort;

      // Verify it can be retrieved
      expect(manager.modbusComPort, testComPort);
    });

    test('modbusBaudRate can be set and retrieved', () {
      final manager = AppDataManager();
      const testBaudRate = '9600';

      manager.modbusBaudRate = testBaudRate;
      expect(manager.modbusBaudRate, testBaudRate);
    });

    test('modbusDataBit can be set and retrieved', () {
      final manager = AppDataManager();
      const testDataBit = '8';

      manager.modbusDataBit = testDataBit;
      expect(manager.modbusDataBit, testDataBit);
    });

    test('modbusStopBit can be set and retrieved', () {
      final manager = AppDataManager();
      const testStopBit = '1';

      manager.modbusStopBit = testStopBit;
      expect(manager.modbusStopBit, testStopBit);
    });

    test('modbusParity can be set and retrieved', () {
      final manager = AppDataManager();
      const testParity = 'None';

      manager.modbusParity = testParity;
      expect(manager.modbusParity, testParity);
    });

    test('Singleton instance always returns the same object', () {
      final manager1 = AppDataManager();
      final manager2 = AppDataManager();

      expect(manager1, same(manager2));
    });
  });
}

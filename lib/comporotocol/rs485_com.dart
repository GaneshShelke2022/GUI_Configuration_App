import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';

class RS485Com {
  /// Returns a list of available USB devices that can be used as serial ports.
  static Future<List<UsbDevice>> getAvailableDevices() async {
    return await UsbSerial.listDevices();
  }

  // Port of Python's calculate_crc
  static Uint8List _calculateCRC(Uint8List data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    // Pack as little-endian 16-bit integer
    return Uint8List(2)..buffer.asByteData().setInt16(0, crc, Endian.little);
  }

  // Port of Python's calculate_mod256
  static Uint8List _calculateMod256(Uint8List data) {
    int checksum = 0;
    for (int byte in data) {
      checksum = (checksum + byte) % 256;
    }
    return Uint8List.fromList([checksum]);
  }

  /// Sends the given HEX content to the specified USB device.
  static Future<bool> sendHex({
    required UsbDevice device,
    required String hexContent,
    required String baudRate,
    required String dataBits,
    required String parity,
    required String stopBits,
    required bool isBroadcast,
    String? panelNumber,
  }) async {
    UsbPort? port;
    try {
      port = await device.create();
      if (port == null) {
        print('Error: Could not create USB port.');
        return false;
      }

      bool opened = await port.open();
      if (!opened) {
        print('Error: Failed to open USB port.');
        return false;
      }

      await port.setPortParameters(
        int.parse(baudRate),
        _getDataBitsValue(dataBits),
        _getStopBitsValue(stopBits),
        _getParityValue(parity),
      );

      // Headers from Python script
      final header = Uint8List.fromList([0x15, 0x32, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x16]);
      final header1 = Uint8List.fromList([0x15, 0x12, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x06]);
      
      int slaveAdd;
      if (isBroadcast) {
        slaveAdd = 0;
      } else {
        slaveAdd = int.tryParse(panelNumber?.replaceAll('Panel-', '').trim() ?? '0') ?? 0;
      }

      final lines = hexContent.split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        final lineBytes = utf8.encode(trimmedLine);
        Uint8List finalPacket;

        if (slaveAdd == 256) {
          final List<int> dataBuilder;
          if (lineBytes.length == 43) {
            dataBuilder = [...header, ...lineBytes];
          } else if (lineBytes.length == 11) {
            dataBuilder = [...header1, ...lineBytes];
          } else {
            dataBuilder = [...header, ...lineBytes];
          }
          final checksumData = Uint8List.fromList(dataBuilder);
          final checksum = _calculateMod256(checksumData);
          finalPacket = Uint8List.fromList([...checksumData, ...checksum]);
        } else {
          final List<int> dataBuilder;
          if (lineBytes.length == 43) {
            dataBuilder = [slaveAdd, ...header, ...lineBytes];
          } else if (lineBytes.length == 11) {
            dataBuilder = [slaveAdd, ...header1, ...lineBytes];
          } else {
            dataBuilder = [slaveAdd, ...header, ...lineBytes];
          }
          final checksumData = Uint8List.fromList(dataBuilder);
          final checksum = _calculateCRC(checksumData);
          finalPacket = Uint8List.fromList([...checksumData, ...checksum]);
        }

        port.write(finalPacket);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await port.close();
      print('Successfully sent hex file to device ${device.deviceName}.');
      return true;

    } catch (e, s) {
      print('Error sending hex over USB: $e');
      print(s);
      if (port != null) {
        await port.close();
      }
      return false;
    }
  }

  // Helper methods to convert string config to int constants for usb_serial
  static int _getParityValue(String parity) {
    switch (parity.toLowerCase()) {
      case 'odd':
        return 1;
      case 'even':
        return 2;
      case 'mark':
        return 3;
      case 'space':
        return 4;
      default:
        return 0; // 0 for none
    }
  }

  static int _getStopBitsValue(String stopBits) {
    // The underlying usb_serial implementation on Android uses: 0 for 1 stop bit, 1 for 1.5 stop bits, 2 for 2 stop bits.
    double val = double.tryParse(stopBits) ?? 1.0;
    if (val == 2.0) {
      return 2;
    } else if (val == 1.5) {
      return 1;
    } else {
      return 0; // Default to 1 stop bit
    }
  }

  static int _getDataBitsValue(String dataBits) {
    return int.tryParse(dataBits) ?? 8;
  }
}
import 'dart:convert';
import 'dart:typed_data';

/// A class that encapsulates the logic for processing a hex file based on user configuration.
/// This is a Dart translation of the logic from the provided Python script.
class ProcessConfig {
  // Headers from the Python script
  final Uint8List _header =
      Uint8List.fromList([0x15, 0x32, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x16]);
  final Uint8List _header1 =
      Uint8List.fromList([0x15, 0x12, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x06]);

  // NOTE: In the Python script, `headerusb` and `headerusb1` are used but not defined.
  // We are assuming they are the same as the other headers for this translation.
  // The user should verify and update these values if they are different.
  final Uint8List _headerusb = 
      Uint8List.fromList([0x15, 0x32, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x16]);
  final Uint8List _headerusb1 = 
      Uint8List.fromList([0x15, 0x12, 0x06, 0x00, 0x01, 0x10, 0x00, 0x00, 0x06]);

  /// Generates a modified hex file content by prepending two configuration records.
  ///
  /// Takes the [originalHexContent] and various configuration parameters to generate
  /// the new content. Returns the complete modified hex content as a string.
  String generateModifiedHex({
    required String originalHexContent,
    required bool isBroadcast,
    required String panelText,
    required String boardText,
    // The following serial port parameters are accepted for compatibility with the UI,
    // but they are not used in the hex generation logic itself. This makes the
    // COM port details effectively optional for this function.//
    String? baudRateStr,
    String? parityStr,
    String? dataBitsStr,
    String? stopBitsStr,
  }) {
    int panelNum = 0;
    try {
      panelNum = int.parse(panelText.replaceAll('Panel-', '').trim());
    } catch (e) {
      panelNum = 0;
    }

    int boardByte;
    switch (boardText.toUpperCase()) {
      case "STANDALONE":
        boardByte = 0x01;
        break;
      case "RCU":
        boardByte = 0x02;
        break;
      default:
        boardByte = 0x00;
    }
 
  // this is updated configuration page  /////////////////////////////////////////////////////////////////////////////////////////ss
    // Determine Address based on broadcast
    // Python: if broadcast: 0x0000, else 0x0000
    final int address = isBroadcast ? 0x0000 : 0x0000; // Both cases use 0x0000 in the original code and both are with 00 address for hex file modification
    const int length = 0x10;
    const int recordType = 0x00;
    
    final builder = BytesBuilder();
    builder.addByte(panelNum & 0xFF);
    builder.addByte(0x00); // Reserved
    builder.addByte(0x00); // Reserved
    builder.addByte(boardByte & 0xFF);
    builder.add(List.filled(12, 0x00)); // Padding
    
    final dataBytes = builder.toBytes();
    final checksum = _intelHexChecksum(length, address, recordType, dataBytes);
    final dataHex = dataBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
    
    final configRecord = 
        ":${length.toRadixString(16).padLeft(2, '0').toUpperCase()}"
        "${address.toRadixString(16).padLeft(4, '0').toUpperCase()}"
        "${recordType.toRadixString(16).padLeft(2, '0').toUpperCase()}"
        "$dataHex"
        "${checksum.toRadixString(16).padLeft(2, '0').toUpperCase()}";
    
    final originalLines = originalHexContent.split('\n').where((line) => line.trim().isNotEmpty).join('\n');
    return "$configRecord\n$originalLines";
  }

  /// Prepares the data packets for serial transmission from the modified hex content.
  ///
  /// The Python script sends the file twice; this function prepares the data once.
  /// The calling code can decide if it needs to send the data multiple times.
  List<Uint8List> prepareDataForSerial({
    required String modifiedHexContent,
    required bool isBroadcast,
    required String panelText,
  }) {
    int slaveAdd;
    if (isBroadcast) {
      slaveAdd = 0;
    } else {
      slaveAdd = int.tryParse(panelText.replaceAll('Panel-', '').trim()) ?? 0;
    }

    final List<Uint8List> packets = [];
    final lines = modifiedHexContent.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final lineBytes = utf8.encode(trimmedLine);
      final data = BytesBuilder();
      Uint8List crc;

      if (slaveAdd == 256) { // Special USB case
        if (lineBytes.length == 43) {
          data.add(_headerusb);
        } else if (lineBytes.length == 11) {
          data.add(_headerusb1);
        } else {
          data.add(_headerusb);
        }
        data.add(lineBytes);
        crc = _calculateMod256(data.toBytes());
      } else {
        data.addByte(slaveAdd);
        if (lineBytes.length == 43) {
          data.add(_header);
        } else if (lineBytes.length == 11) {
          data.add(_header1);
        } else {
          data.add(_header);
        }
        data.add(lineBytes);
        crc = _calculateCrc(data.toBytes());
      }
      
      data.add(crc);
      packets.add(data.toBytes());
    }
    return packets;
  }

  /// Calculates the Intel HEX checksum for a given line's components.
  int _intelHexChecksum(int length, int address, int recordType, Uint8List dataBytes) {
    final int addrHigh = (address >> 8) & 0xFF;
    final int addrLow = address & 0xFF;
    int sum = length + addrHigh + addrLow + recordType;
    for (int byte in dataBytes) {
      sum += byte;
    }
    return (-sum) & 0xFF;
  }

  /// Calculates CRC-16/MODBUS.
  Uint8List _calculateCrc(Uint8List data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc = crc >> 1;
        }
      }
    }
    final crcBytes = ByteData(2)..setUint16(0, crc, Endian.little);
    return crcBytes.buffer.asUint8List();
  }

  /// Calculates a MOD256 checksum.
  Uint8List _calculateMod256(Uint8List data) {
    int checksum = 0;
    for (int byte in data) {
      checksum = (checksum + byte) % 256;
    }
    return Uint8List.fromList([checksum]);
  }
}

/// A helper function to extract Node ID and Board Type from a hex file.
/// This can be used to display information to the user before processing.
Map<String, String> getNodeInfoFromHex(String hexContent) {
  String? nodeId;
  String? boardTypeStr;

  final lines = hexContent.split('\n');
  for (var line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.startsWith(':10000000')) {
      try {
        final dataBytesHex = trimmedLine.substring(9, 25); // 16 bytes of data
        final nodeIdHex = dataBytesHex.substring(0, 4);
        final boardTypeHex = dataBytesHex.substring(4, 8);
        nodeId = int.parse(nodeIdHex, radix: 16).toString();

        switch (boardTypeHex.toUpperCase()) {
          case "0001":
            boardTypeStr = "Stand Alone";
            break;
          case "0002":
            boardTypeStr = "RCU";
            break;
          default:
            boardTypeStr = "Unknown";
            break;
        }
      } catch (e) {
        nodeId = "0";
        boardTypeStr = "Error parsing";
      }
      break; 
    }
  }

  if (nodeId != null && boardTypeStr != null) {
    return {'nodeId': nodeId, 'boardType': boardTypeStr};
  } else {
    return {'nodeId': 'Not found', 'boardType': 'Not found'};
  }
}
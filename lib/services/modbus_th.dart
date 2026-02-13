import 'dart:io';
import 'cal_checksum.dart';

class ModbusTH {
  static Future<void> modbusHex(File txtFile, File hexFile) async {
    try {
      List<String> content = await txtFile.readAsLines();

      int? startIdx;
      int? endIdx;

      // Find <Connectivity> block
      for (int i = 0; i < content.length; i++) {
        String row = content[i].trim();
        if (row == '<Connectivity>') {
          startIdx = i;
        } else if (startIdx != null && row == '</Connectivity>') {
          endIdx = i;
          break;
        }
      }

      if (startIdx == null || endIdx == null) {
        print("Info: No <Connectivity> section found for Modbus processing.");
        return;
      }

      // Extract parameters from within the block
      Map<String, String> modbusParams = {};
      for (int i = startIdx + 1; i < endIdx; i++) {
        var parts = content[i].split(',').map((p) => p.trim()).toList();
        if (parts.length == 2) {
          modbusParams[parts[0]] = parts[1];
        }
      }

      // If no relevant keys are found, it might not be a Modbus config.
      const modbusKeys = ['BaudRate', 'StopBit', 'Parity', 'DataBit'];
      if (!modbusParams.keys.any(modbusKeys.contains)) {
        print("Info: No Modbus parameters found in <Connectivity> block.");
        return;
      }

      // Assign parameters, using defaults from the Python script
      String baudRate = modbusParams['BaudRate'] ?? "9600";
      String stopBit = modbusParams['StopBit'] ?? "1";
      String parity = modbusParams['Parity'] ?? "None";
      String dataBit = modbusParams['DataBit'] ?? "8";

      // Prepare hex line (16 data bytes per line) at base address 0x8000
      List<String> mLine01 = List<String>.filled(21, '00');
      mLine01[0] = '10'; // Byte count
      mLine01[1] = '80'; // Address high
      mLine01[2] = '00'; // Address low
      mLine01[3] = '00'; // Record type

      // Index 4: Reserved (was Slave ID)
      mLine01[4] = '00';

      // Index 5 & 6: Baud Rate (LSB first)
      int baudVal = int.tryParse(baudRate) ?? 9600;
      mLine01[5] = (baudVal & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      mLine01[6] = ((baudVal >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();

      // Index 7: Stop Bit
      mLine01[7] = (int.tryParse(stopBit) ?? 1).toRadixString(16).padLeft(2, '0').toUpperCase();

      // Index 8: Parity
      String parityUpper = parity.toUpperCase();
      final String parityCode;
      switch (parityUpper) {
        case "ODD":
        case "O":
          parityCode = "01";
        case "EVEN":
        case "E":
          parityCode = "02";
        default: // Defaults to None
          parityCode = "00";
      }
      mLine01[8] = parityCode;

      // Index 9: Data Bit
      mLine01[9] = (int.tryParse(dataBit) ?? 8).toRadixString(16).padLeft(2, '0').toUpperCase();

      // Index 10: Reserved (was Panel number)
      mLine01[10] = '00';

      // Compute checksum (Index 20)
      mLine01[20] = CalChecksum.checksum(mLine01);

      // Write Intel HEX formatted line
      final sink = hexFile.openWrite(mode: FileMode.append);
      sink.writeln(':${mLine01.join()}');
      await sink.close();

      print('Finished processing ModbusTH. HEX data appended to: ${hexFile.path}');
    } catch (e) {
      print('An error occurred in modbusHex: $e');
    }
  }
}
import 'dart:io';
import 'cal_checksum.dart'; // Assumes cal_checksum.dart exists and is correct

class InMainTH {
  static Future<void> inmainHex(File txtFile, File hexFile) async {
    try {
      List<String> content = await txtFile.readAsLines();

      int? startIdx;
      int? endIdx;

      // Look for <InputAssign> or <Input-XX> blocks
      for (int i = 0; i < content.length; i++) {
        String row = content[i].trim();
        if ((row.startsWith("<Input") || row == "<InputAssign>") && !row.startsWith("</")) {
          startIdx = i;
        } else if ((row.startsWith("</Input") || row == "</InputAssign>") && startIdx != null) {
          endIdx = i;
          break;
        }
      }

      if (startIdx == null || endIdx == null) {
        print("Info: No Input block found in file.");
        return;
      }

      // Maps for converting text configuration to hex codes
      final addressMap = {
        for (var i = 1; i <= 4; i++) 'IP-${i.toString().padLeft(2, '0')}': (i - 1) * 32
      };

      const typeMap = {
        "DIGITAL-LATCH": ["0D", "11"],
        "DIGITAL-PULSE": ["0D", "22"],
        "DIGITAL-INTLOCK": ["0D", "33"],
        "ANALOG": ["0A", "00"],
      };

      const actionMap = {
        "LAMP": "01",
        "FAN-ON/OFF": "06",
        "CURTAIN-OPEN": "04",
        "CURTAIN-CLOSE": "05",
        "OCCUPANCY": "0C",
        "SCENE": "10",
      };

      const stateMap = {"HIGH": "FF", "LOW": "00", "TOGGLE": "11"};

      const paramMap = {
        "LAMP": "00",
        "FAN-ON/OFF": "51",
        "CURTAIN-OPEN": "41",
        "CURTAIN-CLOSE": "42",
        "OCCUPANCY": "03",
        "SCENE": "81",
      };

      final deviceStateMap = {
        "ON": "FF",
        "OFF": "00",
        "TOGGLE": "11",
        for (var i = 1; i <= 10; i++)
          'ON-L-${i.toString().padLeft(2, '0')}':
              i.toRadixString(16).padLeft(2, '0').toUpperCase()
      };

      // Initialize hex data lines with base address 0x4000
      List<List<String>> hexLines = List.generate(8, (i) {
        var line = List<String>.filled(21, '00');
        line[0] = '10'; // Byte count
        line[1] = '40'; // Address high byte
        line[2] = (i * 16).toRadixString(16).padLeft(2, '0').toUpperCase(); // Address low byte
        line[3] = '00'; // Record type
        return line;
      });

      // Process each line within the <Input...> block
      for (var i = startIdx + 1; i < endIdx; i++) {
        var row = content[i];
        if (row.trim().isEmpty) continue;
        
        var parts = row.split(",").map((p) => p.trim()).toList();
        if (parts.length < 8) {
          continue;
        }

        String device = parts[0];
        String devType = parts[1];
        String state = parts[2];
        String action = parts[3];
        String devNum = parts[4];
        String devState = parts[5];
        String timeout = parts[6];
        String defaultState = parts[7];

        int? address = addressMap[device];
        if (address == null) {
          continue;
        }

        // Convert parsed parts to hex data
        List<String> typeData = typeMap[devType] ?? ["00", "00"];
        String data1 = typeData[0];
        String data2 = typeData[1];
        
        String data3 = stateMap[state] ?? "00";
        String data5 = actionMap[action] ?? "00";
        
        int? devNumInt = int.tryParse(devNum);
        String data7 = devNumInt != null
            ? devNumInt.toRadixString(16).padLeft(2, '0').toUpperCase()
            : "00";

        String data8 = paramMap[action] ?? "00";
        String data9 = deviceStateMap[devState] ?? "00";

        int? timeoutInt = int.tryParse(timeout);
        String data11 = timeoutInt != null
            ? (timeoutInt & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()
            : "00";
        String data12 = timeoutInt != null
            ? ((timeoutInt >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()
            : "00";
        
        String data13 = deviceStateMap[defaultState] ?? "00";

        // Determine position in the hex buffer
        int rowIndex = address ~/ 16;
        int colIndex = (address % 16) + 4;

        if (rowIndex >= 0 && rowIndex < hexLines.length) {
            List<String> dataToWrite = [
                data1, data2, data3, "00", data5, "00",
                data7, data8, data9, "00",
                data11, data12, data13, "00"
            ];

            if (colIndex + dataToWrite.length <= hexLines[rowIndex].length -1) { // -1 for checksum
                 hexLines[rowIndex].setRange(colIndex, colIndex + dataToWrite.length, dataToWrite);
            }
        }
      }

      // Write the generated hex lines to the output file
      final sink = hexFile.openWrite(mode: FileMode.append);
      for (var hexLine in hexLines) {
        // Skip writing the line if the data part is all zeros.
        bool isDataEmpty = hexLine.getRange(4, 20).every((byte) => byte == '00');
        if (!isDataEmpty) {
          String checksum = CalChecksum.checksum(hexLine);
          hexLine[20] = checksum;
          sink.writeln(':${hexLine.join()}');
        }
      }
      await sink.close();
      print('Finished processing InMainTH. HEX data appended to: ${hexFile.path}');
    } catch (e) {
      print('An error occurred in inmainHex: $e');
    }
  }
}
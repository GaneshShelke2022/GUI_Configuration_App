import 'dart:io';
import 'cal_checksum.dart';

class PanelCombinedTH {
  static Future<void> panelOutHex(File inputFile, File outputFile) async {
    try {
      List<String> content = await inputFile.readAsLines();

      final panelAddressMap = {
        for (var i = 1; i < 49; i++)
          'Panel-${i.toString().padLeft(2, '0')}': (0x1000 + (i - 1) * 0x100)
      };

      int i = 0;
      while (i < content.length) {
        String row = content[i].trim();
        if (row.startsWith('<Panel-') && !row.startsWith('</')) {
          String panelName = row.substring(1, row.length - 1);
          int panelStart = i;

          int? panelEnd;
          for (int j = i + 1; j < content.length; j++) {
            if (content[j].trim() == '</$panelName>') {
              panelEnd = j;
              break;
            }
          }

          if (panelEnd == null) {
            print("Error: No closing tag for $panelName");
            i++;
            continue;
          }

          int? switchStart, switchEnd, outputStart, outputEnd;
          for (int k = panelStart + 1; k < panelEnd; k++) {
            String line = content[k].trim();
            if (line == '<Switch>') {
              switchStart = k;
            } else if (line == '</Switch>') {
              switchEnd = k;
            } else if (line == '<Output>') {
              outputStart = k;
            } else if (line == '</Output>') {
              outputEnd = k;
            }
          }

          int? baseAddr = panelAddressMap[panelName];
          if (baseAddr == null) {
            print("Skipping $panelName - no base address mapping found.");
            i = panelEnd + 1;
            continue;
          }

          final sink = outputFile.openWrite(mode: FileMode.append);

          if (switchStart != null && switchEnd != null) {
            await _generatePanelHex(
                content, switchStart, switchEnd, baseAddr, sink);
          }

          if (outputStart != null && outputEnd != null) {
            await _generateOutputHex(
                content, outputStart, outputEnd, baseAddr + 0x0050, sink);
          }

          await sink.close();

          i = panelEnd + 1;
        } else {
          i++;
        }
      }
    } catch (e) {
      print('An error occurred in panelOutHex: $e');
    }
  }

  static Future<void> _generatePanelHex(List<String> content, int start,
      int end, int baseAddr, IOSink sink) async {
    final switchMap = {
      for (var i = 1; i <= 20; i++) 'SW-${i.toString().padLeft(2, '0')}': (i - 1) * 4
    };
    const actionMap = {
       "LAMP": ["01", "00"], 
      "BELL": ["03", "00"], 
      "FAN-ON/OFF": ["06", "00"],
      "FAN-UP": ["07", "00"],
       "FAN-DOWN": ["08", "00"], 
       "CURTAIN-OPEN": ["04", "00"],
      "CURTAIN-CLOSE": ["05", "00"],
       "DIMMER-ON/OFF": ["15", "00"], 
       "DIMMER-UP": ["09", "00"],
      "DIMMER-DOWN": ["0A", "00"],
       "DIMMER-RLOVR": ["0B", "00"],
        "MASTER": ["02", "00"],
      "OCCUPANCY": ["0C", "00"], 
      "DND": ["0D", "00"],
       "MMR": ["0E", "00"],
      "LAUNDRY": ["0F", "00"],
       "SCENE": ["10", "00"],
        "SCENE-OFF": ["17", "00"],
      "SCENE-TOGGLE": ["18", "00"],
       "THERMOSTAT-ON/OFF": ["11", "00"],
      "THERMOSTAT-FAN": ["12", "00"],
       "THERMOSTAT-T-UP": ["13", "00"],
      "THERMOSTAT-T-DN": ["14", "00"],
       "THERMOSTAT-MODE": ["16", "00"],
      "DND-STATUS": ["0D", "01"],
      "MMR-STATUS": ["0E", "01"],
      "LAUNDRY-STATUS": ["0F", "01"],
      "OCCUPANCY-STATUS": ["0C", "01"],

    };
    const paramMap = {
    "LAMP": "00",
       "BELL": "03", 
       "FAN-ON/OFF": "51", 
       "FAN-UP": "52",
      "FAN-DOWN": "52", 
      "CURTAIN-OPEN": "41",
       "CURTAIN-CLOSE": "42",
      "DIMMER-ON/OFF": "61",
       "DIMMER-UP": "62", 
       "DIMMER-DOWN": "62",
      "DIMMER-RLOVR": "62",
       "MASTER": "02",
       "OCCUPANCY": "03", 
       "DND": "04",
      "MMR": "05",
      "LAUNDRY": "06", 
      "SCENE": "81", 
      "SCENE-OFF": "81",
      "SCENE-TOGGLE": "81",
      "THERMOSTAT-ON/OFF": "71",
      "THERMOSTAT-FAN": "72",
      "THERMOSTAT-T-UP": "73",
      "THERMOSTAT-T-DN": "73", 
      "THERMOSTAT-MODE": "75",
      "DND-STATUS": "08",
      "MMR-STATUS": "09",
      "LAUNDRY-STATUS": "0A",
      "OCCUPANCY-STATUS": "07",

    };

    List<List<String>> hexData = List.generate(5, (i) {
      var addr = baseAddr + i * 0x10;
      var line = List<String>.filled(21, '00');
      line[0] = '10';
      line[1] = ((addr >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      line[2] = (addr & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      line[3] = '00';
      return line;
    });

    for (int lineIndex = start + 1; lineIndex < end; lineIndex++) {
      var parts = content[lineIndex].trim().split(",");
      if (parts.length < 3) continue;

      String switchName = parts[0].trim();
      String action = parts[1].trim();
      String param = parts[2].trim();

      int? address = switchMap[switchName];
      if (address == null) continue;

      List<String> actionData = actionMap[action] ?? ["00", "00"];
      String data1 = actionData[0];
      String data2 = actionData[1];

      int? paramInt = int.tryParse(param);
      String data3 = paramInt != null
          ? paramInt.toRadixString(16).padLeft(2, '0').toUpperCase()
          : "00";

      String data4 = paramMap[action] ?? "00";

      if (address >= 0) {
        int row = address ~/ 16;
        int col = (address % 16) + 4;
        if (row < hexData.length) {
          hexData[row][col] = data1;
          hexData[row][col + 1] = data2;
          hexData[row][col + 2] = data3;
          hexData[row][col + 3] = data4;
        }
      }
    }

    for (var line in hexData) {
      // Skip writing the line if the data part is all zeros
      bool isDataEmpty = line.getRange(4, 20).every((byte) => byte == '00');
      if (!isDataEmpty) {
        line[20] = CalChecksum.checksum(line);
        sink.writeln(':${line.join()}');
      }
    }
  }

  static Future<void> _generateOutputHex(List<String> content, int start,
      int end, int baseAddr, IOSink sink) async {
    final addressMap = {
      for (var i = 1; i <= 16; i++)
        'OD-${i.toString().padLeft(2, '0')}': (i - 1) * 8
    };
    const typeMap = {"RLY": "11", "DIM": "22", "ANA": "33"};
    const actionMap = {
      "LAMP": "00",
       "BELL": "01", 
       "OCCUPANCY": "03", 
       "FAN-BLDC": "50",
      "FAN-LOW": "51", 
      "FAN-MID": "52", 
      "FAN-HIGH": "53",
       "CURTAIN-OPEN": "41",
      "CURTAIN-CLOSE": "42",
      "THERMOSTAT-LOW": "71",
      "THERMOSTAT-MID": "72",
      "THERMOSTAT-HIGH": "73",
       "THERMOSTAT-VALVE": "74", 
       "DIMMER": "61"
    };

    List<List<String>> hexLines = List.generate(8, (i) {
      var addr = baseAddr + i * 0x10;
      var line = List<String>.filled(21, '00');
      line[0] = '10';
      line[1] = ((addr >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      line[2] = (addr & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
      line[3] = '00';
      return line;
    });

    for (int lineIndex = start + 1; lineIndex < end; lineIndex++) {
      var row = content[lineIndex];
      if (row.trim().isEmpty) continue;
      var parts = row.trim().split(",");
      if (parts.length < 5) continue;

      String device = parts[0].trim();
      String devType = parts[1].trim();
      String action = parts[2].trim();
      String param = parts[3].trim();
      String timeout = parts[4].trim();

      int? address1 = addressMap[device];
      if (address1 == null) continue;

      String data1 = typeMap[devType] ?? "00";
      String data2 = "00";
      int? paramInt = int.tryParse(param);
      String data3 = paramInt != null
          ? paramInt.toRadixString(16).padLeft(2, '0').toUpperCase()
          : "00";
      String data4 = actionMap[action] ?? "00";

      int? timeoutInt = int.tryParse(timeout);
      String data5 = timeoutInt != null
          ? (timeoutInt & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()
          : "00";
      String data6 = timeoutInt != null
          ? ((timeoutInt >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase()
          : "00";

      int rowIndex = address1 ~/ 16;
      int colIndex = (address1 % 16) + 4;

      if (rowIndex >= 0 && rowIndex < hexLines.length) {
        hexLines[rowIndex].setRange(
            colIndex, colIndex + 6, [data1, data2, data3, data4, data5, data6]);
      }
    }

    for (var line in hexLines) {
      // Skip writing the line if the data part is all zeros
      bool isDataEmpty = line.getRange(4, 20).every((byte) => byte == '00');
      if (!isDataEmpty) {
        line[20] = CalChecksum.checksum(line);
        sink.writeln(':${line.join()}');
      }
    }
  }
}
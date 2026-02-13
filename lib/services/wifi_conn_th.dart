import 'dart:io';
import 'cal_checksum.dart';

class WIFIConnTH {
  static Future<void> wifiConnHex(File txtFile, File hexFile) async {
    try {
      final content = await txtFile.readAsLines();
      final sink = hexFile.openWrite(mode: FileMode.append);

      // Process ALL WiFiInfo-XX blocks (1-48)
      for (int panelNum = 1; panelNum <= 48; panelNum++) {
        final tagStart = '<WiFiInfo-${panelNum.toString().padLeft(2, '0')}>';
        final tagEnd = '</WiFiInfo-${panelNum.toString().padLeft(2, '0')}>';

        int? wifiInfoStart, wifiInfoEnd;
        for (int i = 0; i < content.length; i++) {
          if (content[i].trim() == tagStart) wifiInfoStart = i;
          if (content[i].trim() == tagEnd) {
            wifiInfoEnd = i;
            break;
          }
        }

        if (wifiInfoStart == null || wifiInfoEnd == null) continue;

        int? wifiParamStart, wifiParamEnd;
        for (int i = wifiInfoStart; i <= wifiInfoEnd; i++) {
          if (content[i].trim() == '<WiFi-parameter>') wifiParamStart = i;
          if (content[i].trim() == '</WiFi-parameter>') {
            wifiParamEnd = i;
            break;
          }
        }

        if (wifiParamStart == null || wifiParamEnd == null) continue;

        // ---- Address calculation (STRICT) ----
        final baseAddrHi = (0x70 + (panelNum - 1)).toRadixString(16).padLeft(2, '0').toUpperCase();
        final paramOffsets = ["A0", "B0", "C0", "D0", "E0", "F0"];

        // Create 6 lines for the 96 bytes of parameter space (0xA0–0xFF)
        List<List<String>> bLines = List.generate(6, (i) {
          var line = List<String>.filled(21, '00');
          line[0] = '10';
          line[1] = baseAddrHi;
          line[2] = paramOffsets[i];
          line[3] = '00';
          return line;
        });

        int linePos = 0;

        // ---- Parse WiFi parameters ----
        for (int i = wifiParamStart + 1; i < wifiParamEnd; i++) {
          final line = content[i].trim();
          if (line.isEmpty) continue;

          final parts = line.split(',');
          if (parts.length != 3) continue;

          final dev = parts[0].trim().toUpperCase();
          final idx = int.tryParse(parts[1].trim());
          final val = int.tryParse(parts[2].trim());

          if (idx == null || val == null) continue;

          // Data1: Device index
          final d1 = idx.toRadixString(16).padLeft(2, '0').toUpperCase();

          // Data2: Device type
          const devTypeMap = {
            'LAMP': '00',
                'BELL': '03',
                'FAN-ON-OFF': '51',
                'FAN-SPEED': '52',
                'CURTAIN': '41',
                'DIMMER-ON-OFF': '61',
                'DIMMER-BRIGHTNESS': '62',
                'MASTER': '02',
                'OCCUPANCY': '03',
                'DND': '04',
                'MMR': '05',
                'LAUNDRY': '06',
                'SCENE': '81',
                'SCENE-OFF': '80',
                'SCENE-TOGGLE': '82',
                'THERMOSTAT-ON-OFF': '71',
                'THERMOSTAT-FAN': '72',
                'THERMOSTAT-STEMP': '73',
                'THERMOSTAT-ATEMP': '74',
                'THERMOSTAT-MODE': '75',
                'PANEL-BACKLIGHTMIN': '91',
                'DEVICE-RESTART': 'A1',
                'CHILD-LOCK': 'A2',
                'PROXY-SWITCH': 'A3',
                'FAN-REG-LOCK': '53',
                'INPUT-TW': 'B1',
          };
          final d2 = devTypeMap[dev] ?? '00';

          // Data3 & Data4: DPID value (little-endian)
          final d3 = (val & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
          final d4 = ((val >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();

          // Calculate position in bLines array
          int lineIndex = linePos ~/ 16;  // Which line (0-5)
          int colIndex = (linePos % 16) + 4; // Offset within data bytes
          linePos += 4;

          if (lineIndex < bLines.length) {
            bLines[lineIndex].setRange(colIndex, colIndex + 4, [d1, d2, d3, d4]);
          }
        }

        // ---- Checksum + write ----
        for (final l in bLines) {
          // Skip writing the line if the data part is all zeros.
          bool isDataEmpty = l.getRange(4, 20).every((byte) => byte == '00');
          if (!isDataEmpty) {
            l[20] = CalChecksum.checksum(l);
            sink.writeln(':${l.join()}');
          }
        }
      }

      await sink.close();
      print('Finished processing BMSParamTH logic. HEX data appended to: ${hexFile.path}');
    } catch (e, st) {
      print('An error occurred in wifiConnHex (BMSParam logic): $e');
      print(st);
    }
  }
}
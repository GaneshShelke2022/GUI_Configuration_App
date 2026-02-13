import 'dart:io';
import 'cal_checksum.dart';

class SceneTH {
  static Future<void> sceneHex(File txtFile, File hexFile) async {
    try {
      List<String> content = await txtFile.readAsLines();

      const sSword = [
        '<Welcome>', '<NoOccupancy>', '<Scene-03>', '<Scene-04>',
        '<Scene-05>', '<Scene-06>', '<Scene-07>', '<Scene-08>',
        '<Scene-09>', '<Scene-10>', '<Scene-11>', '<Scene-12>',
        '<Scene-13>', '<Scene-14>', '<Scene-15>', '<Scene-16>'
      ];
      const sEword = [
        '</Welcome>', '</NoOccupancy>', '</Scene-03>', '</Scene-04>',
        '</Scene-05>', '</Scene-06>', '</Scene-07>', '</Scene-08>',
        '</Scene-09>', '</Scene-10>', '</Scene-11>', '</Scene-12>',
        '</Scene-13>', '</Scene-14>', '</Scene-15>', '</Scene-16>'
      ];

      List<int> sSnum = List<int>.filled(16, 0);
      List<int> sEnum = List<int>.filled(16, 0);

      // Find start and end tags for all scenes in a single pass
      for (int i = 0; i < content.length; i++) {
        String row = content[i].trim();
        for (int j = 0; j < 16; j++) {
          if (row == sSword[j]) {
            sSnum[j] = i;
          } else if (row == sEword[j]) {
            sEnum[j] = i;
          }
        }
      }

      final sink = hexFile.openWrite(mode: FileMode.append);

      // Process each of the 16 scenes
      for (int j = 0; j < 16; j++) {
        if (sSnum[j] == 0 && sEnum[j] == 0) {
          continue; // Skip if scene not found
        }

        List<List<String>> sLines = List.generate(4, (i) {
            var line = List<String>.filled(21, '00');
            line[0] = '10';
            // Address high byte will be set later
            line[2] = (i * 0x40).toRadixString(16).padLeft(2, '0').toUpperCase();
            line[3] = '00';
            return line;
        });

        // Maps for cleaner parsing logic
        final addressMap = { for(var i=1; i<=16; i++) 'OD-${i.toString().padLeft(2,'0')}': (i-1)*4 };
        const actionParamMap = {
            'LAMP': '00', 
            'FAN-ON/OFF': '51',
            'CURTAIN-OPEN': '41',
            'CURTAIN-CLOSE': '42',
            'DIMMER': '61', 
            'THERMOSTAT': '71',
        };
        final stateMap = {
            'ON': 'FF', 
            'OFF': '00',
            for(var i=1; i<=10; i++) 'ON-L-${i.toString().padLeft(2,'0')}': i.toRadixString(16).padLeft(2,'0').toUpperCase()
        };


        for (int lineIdx = sSnum[j] + 1; lineIdx < sEnum[j]; lineIdx++) {
          List<String> parts = content[lineIdx].split(',').map((e) => e.trim()).toList();
          if (parts.isEmpty || parts[0].isEmpty) continue;
          
          if (parts[0].startsWith("Panel No")) {
              parts.removeAt(0);
          }
          if (parts.length < 4) continue;

          String device = parts[0];
          String action = parts[1];
          String value = parts[2];
          String state = parts[3];
          String timeout = parts.length > 4 ? parts[4] : '';

          int? address1 = addressMap[device];
          if(address1 == null) continue;

          String data1 = (int.tryParse(value) ?? 0).toRadixString(16).padLeft(2,'0').toUpperCase();
          String data2 = actionParamMap[action] ?? '00';
          String data3 = stateMap[state] ?? '00';
          String data4 = '00';
          if (timeout.isNotEmpty) {
              data4 = (int.tryParse(timeout) ?? 0).toRadixString(16).padLeft(2, '0').toUpperCase();
          }

          // Load hex data into the appropriate line
          if (address1 < 16) {
              sLines[0].setRange(address1 + 4, address1 + 8, [data1, data2, data3, data4]);
          } else if (address1 < 32) {
              int offset = address1 - 16;
              sLines[1].setRange(offset + 4, offset + 8, [data1, data2, data3, data4]);
          } else if (address1 < 48) {
              int offset = address1 - 32;
              sLines[2].setRange(offset + 4, offset + 8, [data1, data2, data3, data4]);
          } else if (address1 < 64) {
              int offset = address1 - 48;
              sLines[3].setRange(offset + 4, offset + 8, [data1, data2, data3, data4]);
          }
        }
        
        // Set address high byte based on scene index
        String addrHigh;
        if (j < 2) { addrHigh = "60"; }
        else if (j < 6) { addrHigh = "61"; }
        else if (j < 10) { addrHigh = "62"; }
        else { addrHigh = "63"; }

        for(var line in sLines) {
            line[1] = addrHigh;
        }

        // Calculate checksum and write all 4 lines to file
        for (var line in sLines) {
          // Skip writing the line if the data part is all zeros
          bool isDataEmpty = line.getRange(4, 20).every((byte) => byte == '00');
          if (!isDataEmpty) {
            line[20] = CalChecksum.checksum(line);
            sink.writeln(':${line.join()}');
          }
        }
      }

      await sink.close();
      print('Finished processing SceneTH. HEX data appended to: ${hexFile.path}');

    } catch (e) {
      print('An error occurred in sceneHex: $e');
    }
  }
}

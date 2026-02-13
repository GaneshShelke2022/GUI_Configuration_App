import 'dart:io';
import 'dart:convert';
import 'cal_checksum.dart';

class BMSInfoTH {
  static Future<void> bmsInfoHex(File txtFile, File hexFile) async {
    try {
      if (!await txtFile.exists()) {
        print('Error: Input file does not exist at ${txtFile.path}');
        return;
      }
      final content = await txtFile.readAsLines();
      final sink = hexFile.openWrite(mode: FileMode.append);

      // Helper to convert string to a padded hex string
      String _stringToHex(String value, int totalHexChars) {
        final quotedValue = '"$value"';
        final hexAscii = utf8.encode(quotedValue)
            .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join('');
        return hexAscii.padRight(totalHexChars, '0');
      }

      // --- First, find the global Connectivity block (OUTSIDE WiFiInfo blocks) ---
      int? globalConnectivityStart;
      int? globalConnectivityEnd;
      for (int i = 0; i < content.length; i++) {
        final r = content[i].trim();
        if (r == '<Connectivity>') {
          globalConnectivityStart = i;
        } else if (r == '</Connectivity>') {
          globalConnectivityEnd = i;
          break;
        }
      }

      // --- Extract global connectivity data (broker, username, password) ---
      String? brokerHex, usernameHex, passwordHex;
      if (globalConnectivityStart != null && globalConnectivityEnd != null) {
        for (int i = globalConnectivityStart + 1; i < globalConnectivityEnd; i++) {
          final line = content[i].trim();
          final parts = line.split(',');
          if (parts.length < 2) continue;

          final key = parts[0].trim();
          final value = parts.sublist(1).join(',').trim();

          switch (key) {
            case "MQTTBrokerAddress":
              brokerHex = _stringToHex(value, 64);
              break;
            case "UserName":
              usernameHex = _stringToHex(value, 64);
              break;
            case "Password":
              passwordHex = _stringToHex(value, 64);
              break;
          }
        }
      }

      // --- Process ALL WiFiInfo-XX blocks (1-48) ---
      for (int panelNum = 1; panelNum <= 48; panelNum++) {
        final tagStart = '<WiFiInfo-${panelNum.toString().padLeft(2, '0')}>';
        final tagEnd = '</WiFiInfo-${panelNum.toString().padLeft(2, '0')}>';

        int? wifiInfoStart, wifiInfoEnd;
        for (int i = 0; i < content.length; i++) {
          final r = content[i].trim();
          if (r == tagStart) wifiInfoStart = i;
          if (r == tagEnd) {
            wifiInfoEnd = i;
            break;
          }
        }

        if (wifiInfoStart == null || wifiInfoEnd == null) {
          continue; // Skip if block not found
        }
        
        int? wifiConfigStart, wifiConfigEnd;
        // Find nested WiFi-config block within this WiFiInfo
        for (int i = wifiInfoStart; i <= wifiInfoEnd; i++) {
          final r = content[i].trim();
          if (r == '<WiFi-config>') wifiConfigStart = i;
          if (r == '</WiFi-config>') wifiConfigEnd = i;
        }

        // --- Base address: 0x7000 + (panel-1)*0x100 ---
        final baseAddrHi = (0x70 + (panelNum - 1)).toRadixString(16).padLeft(2, '0').toUpperCase();

        final biLines = List.generate(10, (i) {
          final line = List<String>.filled(21, '00');
          line[0] = '10'; // Byte count
          line[1] = baseAddrHi; // Address high
          line[2] = (i * 0x10).toRadixString(16).padLeft(2, '0').toUpperCase(); // Address low
          line[3] = '00'; // Record type
          return line;
        });

        // --- Apply global Connectivity data ---
        if (brokerHex != null) {
          for (int i=0; i<16; i++) biLines[1][i+4] = brokerHex.substring(i*2, i*2+2); // BIline02
          for (int i=0; i<16; i++) biLines[2][i+4] = brokerHex.substring(32 + i*2, 32 + i*2+2); // BIline03
        }
        if (usernameHex != null) {
          for (int i=0; i<16; i++) biLines[6][i+4] = usernameHex.substring(i*2, i*2+2); // BIline07
          for (int i=0; i<16; i++) biLines[7][i+4] = usernameHex.substring(32 + i*2, 32 + i*2+2); // BIline08
        }
        if (passwordHex != null) {
          for (int i=0; i<16; i++) biLines[8][i+4] = passwordHex.substring(i*2, i*2+2); // BIline09
          for (int i=0; i<16; i++) biLines[9][i+4] = passwordHex.substring(32 + i*2, 32 + i*2+2); // BIline10
        }

        // --- WiFi-config ---
        if (wifiConfigStart != null && wifiConfigEnd != null) {
          for (int i = wifiConfigStart + 1; i < wifiConfigEnd; i++) {
            final line = content[i].trim();
            final parts = line.split(',');
            if (parts.length < 2) continue;

            final key = parts[0].trim();
            final value = parts.sublist(1).join(',').trim();

            if (key == "Mode") {
              final m = value.toUpperCase();
              biLines[0][4] = {"MQTT-HA": "11", "TUYA-WIFI": "22", "TUYA-BLE": "33"}[m] ?? "00";
              biLines[0][5] = "00";
              biLines[0][6] = panelNum.toRadixString(16).padLeft(2, '0').toUpperCase();
            } else if (key == "MQTTPort") {
              final h = _stringToHex(value, 32);
              for (int j=0; j<16; j++) {
                  biLines[5][j+4] = h.substring(j*2, j*2+2); // BIline06
              }
            }
          }
        }

        // --- Calculate Checksums and Write to file ---
        for (final l in biLines) {
          l[20] = CalChecksum.checksum(l);
        }

        // Helper to check if data part is all zeros
        bool _isDataEmpty(List<String> line) {
          for (int i = 4; i < 20; i++) {
            if (line[i] != '00') return false;
          }
          return true;
        }

        for (int i = 0; i < biLines.length; i++) {
          final l = biLines[i];
          if (i == 0 || !_isDataEmpty(l)) {
            sink.writeln(':${l.join()}');
          }
        }
      }

      await sink.close();
      print('Finished processing BMSInfoTH. HEX data written to: ${hexFile.path}');

    } catch (e, st) {
      print('An error occurred in bmsInfoHex: $e');
      print(st);
    }
  }
}
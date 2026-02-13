import 'dart:io';

import 'panel_th.dart';
import 'in_main_th.dart';
import 'scene_th.dart';
// import 'modbus_th.dart';
import 'bms_info_th.dart';
import 'wifi_conn_th.dart';

class ConfigConverter {
  static Future<void> convert(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        print('Error: Input file not found at $inputPath');
        return;
      }

      final String outputPath = inputPath.replaceAll(RegExp(r'\.txt$'), '.hex');
      final outputFile = File(outputPath);

      // Create a new empty file for the Hex code, overwriting if it exists.
      if (await outputFile.exists()) {
        await outputFile.delete();
      }
      await outputFile.create();
      
      print('Starting conversion from $inputPath to $outputPath');

      // Call the conversion functions in the correct order.
      // These functions will append to the output file.
      await PanelCombinedTH.panelOutHex(inputFile, outputFile);
      await InMainTH.inmainHex(inputFile, outputFile);
      
      // The following modules will be implemented once the Python source is provided.
      await SceneTH.sceneHex(inputFile, outputFile);
      // await ModbusTH.modbusHex(inputFile, outputFile);
      await BMSInfoTH.bmsInfoHex(inputFile, outputFile);
      await WIFIConnTH.wifiConnHex(inputFile, outputFile);

      // Append the End-Of-File record to the hex file.
      final sink = outputFile.openWrite(mode: FileMode.append);
      sink.writeln(':00000001FF');
      await sink.close();

      print('File conversion complete: $outputPath');

    } catch (e) {
      print('An error occurred during conversion: $e');
    }
  }
}

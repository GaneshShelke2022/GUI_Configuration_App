import 'dart:io';
import '../utils/file_helper.dart';
import 'panel_th.dart';
import 'in_main_th.dart';
import 'scene_th.dart';
import 'modbus_th.dart';
import 'bms_info_th.dart';
import 'wifi_conn_th.dart';

class ConvertManager {

  // Main converter (Same as your SelectFile in Python)
  static Future<String> convertTxtToHex(String txtPath) async {
    print("Starting TXT to HEX conversion for: $txtPath");

    // 1. Create HEX file
    File hexFile = await FileHelper.createHexFile(txtPath);
    File txtFile = File(txtPath);

    // Ensure the hex file is empty before starting
    if (await hexFile.exists()) {
      await hexFile.writeAsString('');
    }

    // 2. Call all converter modules
    await PanelCombinedTH.panelOutHex(txtFile, hexFile);
    await InMainTH.inmainHex(txtFile, hexFile);
    await SceneTH.sceneHex(txtFile, hexFile);
    // await ModbusTH.modbusHex(txtFile, hexFile);
    await BMSInfoTH.bmsInfoHex(txtFile, hexFile);
    await WIFIConnTH.wifiConnHex(txtFile, hexFile);

    // 3. Add Footer (Same as Python)
    await hexFile.writeAsString(":00000001FF\n", mode: FileMode.append);
    print("Conversion complete. HEX file saved at: ${hexFile.path}");
    return hexFile.path; // final output location
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../comporotocol/ble_manager.dart';
import '../../data/app_data.dart';
import '../../permissions/textfile_saver.dart';
import '../../permissions/storage_permission.dart';
import '../../services/convert_manager.dart';
import '../../services/process_config.dart';
import '../../comporotocol/rs485_com.dart';

enum CommunicationMode { ble, rs485 }


class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  bool _isLoading = false;
  String? _selectedTxtFilePath;
  String? _generatedHexFilePath;
  String? _modifiedHexFilePath;
  CommunicationMode _selectedMode = CommunicationMode.ble;
  final BLEManager _bleManager = BLEManager();
  StreamSubscription<BluetoothDevice?>? _connectionSubscription;


  @override
  void initState() {
    super.initState();
    _connectionSubscription = _bleManager.connectedDeviceStream.listen((device) {
      if (device != null && mounted) {                                               // check if widget is still in the tree
        _showNotification("BLE Connected");
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _bleManager.stopScan();
    // _bleManager.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false, bool isWarning = false}) {
    final color = isError
        ? Colors.red
        : isWarning
            ? Colors.orange
            : const Color(0xFF27AE60);
    final icon = isError
        ? Icons.error_outline
        : isWarning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2, textAlign: TextAlign.center),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  void _showSuccessDialog(String title, String message, String path) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(path, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  child: const Text('OK', style: TextStyle(fontSize: 14)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
                const SizedBox(height: 24),
                Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF7F8C8D))),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndReadFile(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          if (p.extension(filePath).toLowerCase() != '.txt') {
            _showNotification("Invalid file type. Please select a .txt file.", isError: true);
            setState(() => _isLoading = false);
            return;
          }

          setState(() {
            _selectedTxtFilePath = filePath;
            _generatedHexFilePath = null;
            _isLoading = false;
          });

          _showNotification("File selected: ${p.basename(filePath)}");
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showNotification("Error picking file: $e", isError: true);
    }
  }

  Future<void> _generateAndSaveFile(BuildContext context) async {
    bool hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      _showNotification(
        "Storage Permission is required. Please grant 'All files access' in your phone's settings to save files.",
        isError: true,
      );
      return;
    }

    final data = AppDataManager();
    final StringBuffer content = StringBuffer();
    content.writeln('<PS configuration V0.7>');
    if (data.customerName != null && data.customerName!.isNotEmpty) {
      content.writeln('<ProjectInformation>');
      content.writeln(' CustomerName:${data.customerName ?? ""}');
      content.writeln(' Address:${data.customerAddress ?? ""}');
      content.writeln('</ProjectInformation>');
    }
    if (data.panelSwitchPanel != null && data.panelSwitchPanel!.isNotEmpty) {
      content.writeln('<${data.panelSwitchPanel}>');
      content.writeln(' Location: ${data.panelSwitchLocation ?? ""}');
      content.writeln(' Module: ${data.panelSwitchModule ?? ""}');
      if (data.panelSwitchRows.isNotEmpty) {
        final validRows = data.panelSwitchRows.where((row) {
          final function = row['function']?.toString().trim() ?? '';
          final number = row['number']?.toString().trim() ?? '';
          return function.isNotEmpty || number.isNotEmpty;
        }).toList();
        if (validRows.isNotEmpty) {
          content.writeln(' <Switch>');
          for (var row in data.panelSwitchRows) {
            final function = row['function'] ?? '';
            final number = row['number'] ?? '';
            if (function.toString().trim().isEmpty && number.toString().trim().isEmpty) {
              continue;
            }
            int index = data.panelSwitchRows.indexOf(row);
            String swLabel = 'SW-${(index + 1).toString().padLeft(2, '0')}';
            content.writeln('\t$swLabel,$function,$number');
          }
          content.writeln(' </Switch>');
        }
      }
      if (data.relayOutputRows.isNotEmpty) {
        final validRows = data.relayOutputRows.where((row) {
          final type = row['type']?.toString().trim() ?? '';
          final output = row['output']?.toString().trim() ?? '';
          final number = row['number']?.toString().trim() ?? '';
          final time = row['time']?.toString().trim() ?? '';
          return type.isNotEmpty || output.isNotEmpty || number.isNotEmpty || time.isNotEmpty;
        }).toList();
        if (validRows.isNotEmpty) {
          content.writeln(' <Output>');
          for (var row in validRows) {
            final serial = row['serialNumber'] ?? '';
            final type = row['type'] ?? '';
            final output = row['output'] ?? '';
            final number = row['number'] ?? '';
            final time = row['time'] ?? '';
            content.writeln('\t$serial,$type,$output,$number,$time');
          }
          content.writeln(' </Output>');
        }
      }
      content.writeln('</${data.panelSwitchPanel}>');
    }
    if (data.inputAssignPanel != null && data.inputAssignPanel!.isNotEmpty) {
      final panelNum = data.inputAssignPanel!.replaceAll('Panel-', '');
      content.writeln('<InputAssign-$panelNum>');
      for (var row in data.inputAssignRows) {
        final type = row['type']?.toString().trim() ?? '';
        final inputState = row['inputState']?.toString().trim() ?? '';
        final outputDevice = row['outputDevice']?.toString().trim() ?? '';
        final deviceNo = row['deviceNo']?.toString().trim() ?? '';
        final outputState = row['outputState']?.toString().trim() ?? '';
        final time = row['time']?.toString().trim() ?? '';
        final defaultState = row['defaultState']?.toString().trim() ?? '';
        if (type.isEmpty && inputState.isEmpty && outputDevice.isEmpty && deviceNo.isEmpty && outputState.isEmpty && time.isEmpty && defaultState.isEmpty) {
          continue;
        }
        final sr = row['sr'] ?? '';
        content.writeln('\t$sr,$type,$inputState,$outputDevice,$deviceNo,$outputState,$time,$defaultState');
      }
      content.writeln('</InputAssign-$panelNum>');
    }
    if (data.sceneAssignRows.isNotEmpty) {
      Map<String, List<Map<String, dynamic>>> scenesByType = {};
      for (var row in data.sceneAssignRows) {
        String type = row['type'] ?? 'Unknown';
        final output = row['output']?.toString().trim() ?? '';
        final number = row['number']?.toString().trim() ?? '';
        final state = row['state']?.toString().trim() ?? '';
        final temp = row['temp']?.toString().trim() ?? '';
        final panelNo = row['panel_no']?.toString().trim() ?? '';
        if (output.isEmpty && number.isEmpty && state.isEmpty && temp.isEmpty && panelNo.isEmpty) {
          continue;
        }
        if (!scenesByType.containsKey(type)) {
          scenesByType[type] = [];
        }
        scenesByType[type]!.add(row);
      }
      scenesByType.forEach((type, rows) {
        content.writeln('<$type>');
        for (var row in rows) {
          final sr = row['sr_no'] ?? '';
          final output = row['output'] ?? '';
          final number = row['number'] ?? '';
          final state = row['state'] ?? '';
          final temp = row['temp'] ?? '';
          final panelNo = row['panel_no'] ?? '';
          content.writeln('\t$sr,$output,$number,$state,$temp,$panelNo');
        }
        content.writeln('</$type>');
      });
    }
    content.writeln('<Connectivity>');
    if (data.connectivityType == 0) {
      if (data.modbusBaudRate != null && data.modbusBaudRate!.isNotEmpty) {
        content.writeln(' BaudRate,${data.modbusBaudRate}');
      }
      if (data.modbusDataBit != null && data.modbusDataBit!.isNotEmpty) {
        content.writeln(' DataBit,${data.modbusDataBit}');
      }
      if (data.modbusStopBit != null && data.modbusStopBit!.isNotEmpty) {
        content.writeln(' StopBit,${data.modbusStopBit}');
      }
      if (data.modbusParity != null && data.modbusParity!.isNotEmpty) {
        content.writeln(' Parity,${data.modbusParity}');
      }
    }
    if (data.mqttBroker != null && data.mqttBroker!.isNotEmpty) {
      content.writeln(' MQTTBrokerAddress,${data.mqttBroker}');
    }
    if (data.mqttUser != null && data.mqttUser!.isNotEmpty) {
      content.writeln(' UserName,${data.mqttUser}');
    }
    if (data.mqttPassword != null && data.mqttPassword!.isNotEmpty) {
      content.writeln(' Password,${data.mqttPassword}');
    }
    if (data.connectivityType == 1) {
      if (data.wifiPanel != null && data.wifiPanel!.isNotEmpty) {
        final panelNum = data.wifiPanel!.replaceAll('Panel-', '');
        content.writeln(' <WiFiInfo-$panelNum>');
        content.writeln('  <WiFi-config>');
        if (data.wifiMode != null) content.writeln('   Mode,${data.wifiMode}');
        if (data.mqttPort != null) content.writeln('   MQTTPort,${data.mqttPort}');
        content.writeln('  </WiFi-config>');
        List<Map<String, dynamic>> devices = [];
        if (data.wifiMode == 'Mqtt-HA') {
          devices = data.mqttDevices;
        } else {
          devices = data.tuyaDevices;
        }
        final validDevices = devices.where((d) {
          final param = d['parameter']?.toString().trim() ?? '';
          final devNo = d['deviceNo']?.toString().trim() ?? '';
          final dpId = d['dpId']?.toString().trim() ?? '';
          return param.isNotEmpty || devNo.isNotEmpty || dpId.isNotEmpty;
        }).toList();
        if (validDevices.isNotEmpty) {
          content.writeln('  <WiFi-parameter>');
          for (var device in validDevices) {
            final param = device['parameter'] ?? '';
            final devNo = device['deviceNo'] ?? '';
            final dpId = device['dpId'] ?? '';
            content.writeln('   $param,$devNo,$dpId');
          }
          content.writeln('  </WiFi-parameter>');
        }
        content.writeln(' </WiFiInfo-$panelNum>');
      }
    }
    content.writeln('</Connectivity>');
    final fileContent = content.toString();
    if (fileContent.isEmpty) return;
    final path = await saveTextFile(context, fileContent, showSnackBar: false);
    if (path != null) {
      _showSuccessDialog('Congratulations!', 'Text file saved successfully.', path);
    }
  }

  Future<void> _generateHexFile(BuildContext context) async {
    if (_selectedTxtFilePath == null) {
      _showWarningDialog("File Not Selected", "Please select a TXT file first using the 'Open TXT' button.");
      return;
    }

    // Request storage permission before proceeding
    bool hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      _showNotification(
        "Storage Permission is required. Please grant 'All files access' in your phone's settings to save files.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String outputFilePath = await ConvertManager.convertTxtToHex(_selectedTxtFilePath!);
      setState(() => _generatedHexFilePath = outputFilePath);
      _showSuccessDialog('Congratulations!', 'Hex file generated and saved.', outputFilePath);
    } catch (e) {
      _showNotification("Error generating hex: $e", isError: true);
    } finally { 
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processFile(BuildContext context) async {
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => const ProcessDialog(),
    );

    if (result != null) {
      final manager = AppDataManager();
      manager.modbusComPort = result['comPort'];
      manager.modbusBaudRate = result['baudRate']?.toString();
      manager.modbusDataBit = result['dataBit']?.toString();
      manager.modbusStopBit = result['stopBit']?.toString();
      manager.modbusParity = result['parity'];
      manager.isBroadcast = result['isBroadcast'] ?? false;
      manager.panelNumber = result['panelNumber'];

      if (_generatedHexFilePath == null) {
        try {
          FilePickerResult? fileResult = await FilePicker.platform.pickFiles(type: FileType.any);
          if (fileResult != null && fileResult.files.single.path != null) {
            String path = fileResult.files.single.path!;
            if (p.extension(path).toLowerCase() == '.hex') {
              setState(() {
                _generatedHexFilePath = path;
              });
            } else {
              _showNotification("Invalid file type. Please select a .hex file.", isError: true);
              return;
            }
          } else {
            return;
          }
        } catch (e) {
          _showNotification("Error picking file: $e", isError: true);
          return;
        }
      }

      setState(() => _isLoading = true);
      try {
        final originalHexContent = await File(_generatedHexFilePath!).readAsString();
        final processor = ProcessConfig();
        final modifiedHexContent = processor.generateModifiedHex(
          originalHexContent: originalHexContent,
          isBroadcast: result['isBroadcast'] ?? false,
          panelText: result['panelNumber'] ?? '',
          boardText: result['boardType'] ?? '',
          baudRateStr: (result['baudRate'] ?? '19200').toString(),
          parityStr: result['parity'] ?? 'None',
          dataBitsStr: (result['dataBit'] ?? '8').toString(),
          stopBitsStr: (result['stopBit'] ?? '1').toString(),
        );

        final dir = p.dirname(_generatedHexFilePath!);
        final filename = p.basenameWithoutExtension(_generatedHexFilePath!);
        final ext = p.extension(_generatedHexFilePath!);
        final newPath = p.join(dir, '${filename}_mod$ext');

        final modifiedFile = File(newPath);
        await modifiedFile.writeAsString(modifiedHexContent);

        _showSuccessDialog('Success!', 'Processed hex file saved successfully.', newPath);
      } catch (e) {
        _showNotification("Error processing file: $e", isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickModifiedHexFile(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          if (p.extension(filePath).toLowerCase() != '.hex') {
            _showNotification("Invalid file type. Please select a .hex file.", isError: true);
            setState(() => _isLoading = false);
            return;
          }

          setState(() {
            _modifiedHexFilePath = filePath;
            _isLoading = false;
          });

          _showNotification("Modified HEX file selected: ${p.basename(filePath)}");
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showNotification("Error picking file: $e", isError: true);
    }
  }

  Future<void> _flashHexFile(BuildContext context) async {
    if (_modifiedHexFilePath == null) {
      _showWarningDialog("File Not Selected", "Please select a modified HEX file first.");
      return;
    }

    setState(() => _isLoading = true);

    final manager = AppDataManager();
    if (manager.modbusComPort == null) {
      _showWarningDialog("COM Port Missing", "COM Port not selected. Please process a file first.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      List<UsbDevice> devices = await RS485Com.getAvailableDevices();
      UsbDevice? targetDevice;
      try {
        targetDevice = devices.firstWhere((d) => d.deviceName == manager.modbusComPort);
      } on StateError {
        targetDevice = null;
      }

      if (targetDevice == null) {
        throw Exception("Device ${manager.modbusComPort} not found or not connected.");
      }

      final fileContent = await File(_modifiedHexFilePath!).readAsString();
      final success = await RS485Com.sendHex(
        device: targetDevice,
        hexContent: fileContent,
        baudRate: manager.modbusBaudRate ?? '19200',
        dataBits: manager.modbusDataBit ?? '8',
        parity: manager.modbusParity ?? 'None',
        stopBits: manager.modbusStopBit ?? '1',
        isBroadcast: manager.isBroadcast,
        panelNumber: manager.panelNumber,
      );

      if (success) {
        _showSuccessDialog('Success!', 'HEX file flashed successfully.', _modifiedHexFilePath!);
      } else {
        _showNotification("Failed to flash HEX file.", isError: true);
      }
    } catch (e) {
      _showNotification("Error flashing file: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestBlePermissions() async {
    // Request all required BLE permissions
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if permissions were granted
    if (results[Permission.bluetoothScan] != PermissionStatus.granted ||
        results[Permission.bluetoothConnect] != PermissionStatus.granted ||
        results[Permission.location] != PermissionStatus.granted) {
      if (mounted) {
        _showNotification("BLE and Location permissions are required to scan for devices", isWarning: true);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EEF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: const Text(
                  "Generate Configuration",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Processing...', style: TextStyle(color: Color(0xFF7F8C8D))),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Row 1: Generate TXT (Centered)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionButton(
                                  onPressed: () => _generateAndSaveFile(context),
                                  label: 'Generate TXT',
                                  icon: Icons.description_outlined,
                                  color: const Color.fromARGB(255, 233, 148, 49)
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Row 2: Open TXT + File Info + Generate HEX
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildActionButton(
                                  onPressed: () => _pickAndReadFile(context),
                                  label: 'Open TXT',
                                  icon: Icons.folder_open_outlined,
                                  color:Color.fromARGB(255, 139, 135, 135),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 4,
                                    child: _buildFileInfo(
                                      _selectedTxtFilePath,
                                      'No TXT file selected',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: _buildActionButton(
                                  onPressed: () => _generateHexFile(context),
                                  label: 'Generate HEX',
                                  icon: Icons.build_outlined,
                                  color: const Color(0xFF1ABC9C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Process Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionButton(
                                    onPressed: () => _processFile(context),
                                    label: 'Process',
                                    icon: Icons.settings_outlined,
                                    color: const Color.fromARGB(255, 233, 148, 49),
                                    isSmall: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Communication Mode Toggle
                              Center(
                                child: ToggleButtons(
                                  isSelected: [
                                    _selectedMode == CommunicationMode.ble,
                                    _selectedMode == CommunicationMode.rs485,
                                  ],
                                  onPressed: (index) {
                                    setState(() {
                                      _selectedMode = CommunicationMode.values[index];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8.0),
                                  selectedBorderColor: Colors.orange,

                                  selectedColor: const Color.fromARGB(255, 248, 246, 246),
                                  fillColor: Colors.orange,
                                  color: const Color.fromARGB(255, 95, 95, 93),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text('BLE'),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text('RS485'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Conditional UI
                              _selectedMode == CommunicationMode.ble
                                  ? _buildBleUI()
                                  : _buildRs485UI(),
                            ],
                          ),
                  ),
                ),
              ),

              // Footer with Back button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width:  100,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  const Color.fromARGB(255, 138, 134, 134),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: isSmall ? 120 : 150, minHeight: 48),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildBleUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildActionButton(
                onPressed: () => _bleManager.pickBleHexFile(context),
                label: 'Open HEX',
                icon: Icons.folder_open_outlined,
                color:  const Color.fromARGB(255, 233, 148, 49),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: StreamBuilder<String?>(
                stream: _bleManager.hexFilePathStream,
                builder: (context, snapshot) {
                  return _buildFileInfo(
                    snapshot.data,
                    'No HEX file selected',
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              onPressed: () async {
                await _requestBlePermissions();
                _bleManager.startScan();
              },
              label: 'Scan',
              icon: Icons.bluetooth_searching,
              color: const Color(0xFF3498DB),
            ),
            const SizedBox(width: 24),
            _buildActionButton(
              onPressed: _flashBleHexFile,
              label: 'Flash',
              icon: Icons.flash_on,
              color: const Color.fromARGB(255, 46, 121, 46),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Display scan errors
        StreamBuilder<String?>(
          stream: _bleManager.scanErrorStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  snapshot.data!,
                  style: TextStyle(color: Colors.red[800], fontSize: 13),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const Text(
          "Available Devices:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ScanResult>>(
          stream: _bleManager.scanResults,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final devices = snapshot.data ?? [];
            
            if (devices.isEmpty) {
              return Container(
                height: 300,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No devices found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure Bluetooth is enabled and devices are nearby',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            
            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index].device;
                  return Card(
                    child: ListTile(
                      title: Text(device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'),
                      subtitle: Text(device.remoteId.toString()),
                      trailing: StreamBuilder<BluetoothDevice?>(
                        stream: _bleManager.connectedDeviceStream,
                        builder: (context, snapshot) {
                          final isConnected = snapshot.data?.remoteId == device.remoteId;
                          return ElevatedButton(
                            style: isConnected
                                ? ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white)
                                : null,
                            child: Text(isConnected ? 'Connected' : 'Connect'),
                            onPressed: () => _bleManager.selectDevice(device),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRs485UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildActionButton(
                onPressed: () => _pickModifiedHexFile(context),
                label: 'Open Mod_HEX',
                icon: Icons.folder_open_outlined,
                color: const Color.fromARGB(255, 233, 148, 49),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _buildFileInfo(
                _modifiedHexFilePath,
                'No HEX file selected',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildActionButton(
                onPressed: () => _flashHexFile(context),
                label: 'Flash',
                icon: Icons.flash_on_outlined,
                color: const Color.fromARGB(255, 46, 121, 46),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileInfo(String? filePath, String placeholder) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            filePath != null ? Icons.insert_drive_file : Icons.info_outline,
            size: 16,
            color: filePath != null ? const Color(0xFF27AE60) : const Color(0xFF95A5A6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              filePath != null ? p.basename(filePath) : placeholder,
              style: TextStyle(
                fontSize: 11,
                color: filePath != null ? const Color(0xFF2C3E50) : const Color(0xFF95A5A6),
                fontWeight: filePath != null ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _flashBleHexFile() async {
    // Validate preconditions before attempting transfer
    if (_bleManager.bleHexFilePath == null) {
      _showWarningDialog("File Not Selected", "Please select a HEX file first using 'Open HEX' button.");
      return;
    }

    if (_bleManager.connectedDevice == null) {
      _showWarningDialog("Bluetooth Device Not Connected", "Please connect to an ESP32 device first.");
      return;
    }

    setState(() => _isLoading = true);
    
    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BLE File Transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              StreamBuilder<int>(
                stream: _bleManager.progressStream,
                initialData: 0,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? 0;
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$progress%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<String>(
                stream: _bleManager.transferStatusStream,
                builder: (context, snapshot) {
                  final status = snapshot.data ?? 'Initializing...';
                  return Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: status.toLowerCase().contains('error')
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    final success = await _bleManager.flashHexFile();
    
    setState(() => _isLoading = false);
    Navigator.of(context).pop(); // Close progress dialog

    if (success) {
      _showSuccessDialog(
        'Success!',
        'HEX file transferred successfully.',
        _bleManager.bleHexFilePath!,
      );
    } else {
      _showNotification("Transfer Failed", isError: true);
    }
  }
}

class ProcessDialog extends StatefulWidget {
  const ProcessDialog({super.key});

  @override
  State<ProcessDialog> createState() => _ProcessDialogState();
}

class _ProcessDialogState extends State<ProcessDialog> {
  String? _selectedComPort;
  String? _selectedPanelNumber;
  String? _selectedBoardType;
  int _selectedBaudRate = 19200;
  int _selectedDataBit = 8;
  String _selectedParity = 'None';
  int _selectedStopBit = 1;
  bool _isBroadcast = false;

  List<String> _availablePorts = [];
  final List<String> _panelNumbers =
      List.generate(48, (i) => 'Panel-${(i + 1).toString().padLeft(2, '0')}');
  final List<String> _boardTypes = ['STANDALONE', 'RCU'];
  final List<int> _baudRates = [300, 600, 1200, 2400, 4800, 9600, 19200, 38400];
  final List<int> _dataBits = [7, 8];
  final List<String> _parities = ['None', 'Odd', 'Even'];
  final List<int> _stopBits = [1, 2];

  @override
  void initState() {
    super.initState();
    _selectedComPort = AppDataManager().modbusComPort;
    _initPorts();
  }

  Future<void> _initPorts() async {
    setState(() {
      _availablePorts = List.generate(10, (i) => 'COM${i + 1}');
    });
    try {
      final devices = await RS485Com.getAvailableDevices();
      setState(() {
        _availablePorts = devices.map((d) => d.deviceName ?? 'Unknown').toList();
      });
    } catch (e) {
      print("Error fetching serial ports: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Process Configuration',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text("Broadcast", style: TextStyle(fontWeight: FontWeight.w500)),
                value: _isBroadcast,
                onChanged: (newValue) {
                  setState(() {
                    _isBroadcast = newValue!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF3498DB),
              ),
              const Divider(height: 20, thickness: 1),
              _buildDropdownRow(
                _buildDialogDropdown('Board Type', _boardTypes, _selectedBoardType,
                    (String? val) => setState(() => _selectedBoardType = val)),
                _buildDialogDropdown('Panel Number', _panelNumbers, _selectedPanelNumber,
                    (String? val) => setState(() => _selectedPanelNumber = val)),
              ),
              _buildDropdownRow(
                _buildDialogDropdown('COM Port', _availablePorts, _selectedComPort,
                    (String? val) => setState(() => _selectedComPort = val)),
                _buildDialogDropdown('Baud Rate', _baudRates, _selectedBaudRate,
                    (val) => setState(() => _selectedBaudRate = val!)),
              ),
              _buildDropdownRow(
                _buildDialogDropdown('Data Bit', _dataBits, _selectedDataBit,
                    (val) => setState(() => _selectedDataBit = val!)),
                _buildDialogDropdown('Parity', _parities, _selectedParity,
                    (String? val) => setState(() => _selectedParity = val!)),
              ),
              _buildDropdownRow(
                _buildDialogDropdown('Stop Bit', _stopBits, _selectedStopBit,
                    (val) => setState(() => _selectedStopBit = val!)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF95A5A6), fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Done', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (_selectedPanelNumber == null || _selectedBoardType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Flexible(child: Text("Board Type and Panel Number are required.", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
                            duration: const Duration(seconds: 2),
                            elevation: 4,
                          ),
                        );
                        return;
                      }

                      final Map<String, dynamic> result = {
                        'isBroadcast': _isBroadcast,
                        'panelNumber': _selectedPanelNumber,
                        'boardType': _selectedBoardType,
                        'baudRate': _selectedBaudRate,
                        'dataBit': _selectedDataBit,
                        'parity': _selectedParity,
                        'stopBit': _selectedStopBit,
                        'comPort': _selectedComPort,
                      };

                      Navigator.of(context).pop(result);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(Widget left, [Widget? right]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          if (right != null) ...[
            const SizedBox(width: 16),
            Expanded(child: right),
          ] else ...[
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _buildDialogDropdown<T>(
      String label, List<T> items, T? value, ValueChanged<T?>? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          onChanged: onChanged,
          menuMaxHeight: 300,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2),
            ),
            filled: true,
            fillColor: onChanged == null ? const Color(0xFFF5F5F5) : Colors.white,
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(value: item, child: Text(item.toString(), style: const TextStyle(fontSize: 14)));
          }).toList(),
        ),
      ],
    );
  }
}
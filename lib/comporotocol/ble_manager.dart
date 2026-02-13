import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class BLEManager {
  // ================= UUIDs (MUST MATCH ESP32) =================
  static const String serviceUUID = "12345678-1234-1234-1234-1234567890ab"; // Service UUID to scan for ESP32 devices 
  static const String rxUUID = "12345678-1234-1234-1234-1234567890ac"; // Characteristic UUID for receiving data (RX) 
  static const String txUUID = "12345678-1234-1234-1234-1234567890ad"; // Characteristic UUID for transmitting data (TX)
  
// ================= State Variables =================
// Selected HEX file path
  String? bleHexFilePath; // Path to the selected .hex file

// Stream controller for HEX file path updates 
  final StreamController<String?> _hexFilePathController =
      StreamController.broadcast();
  Stream<String?> get hexFilePathStream => _hexFilePathController.stream; 

// Currently connected device and characteristics 
// (set after connection and discovery)
  BluetoothDevice? connectedDevice; // Currently connected BLE device 
  BluetoothCharacteristic? rxChar; // RX characteristic for writing data
  BluetoothCharacteristic? txChar; // TX characteristic for receiving data

// Stream controller for connected device updates 
// (notifies when device connects/disconnects)
// Used to update UI accordingly
  final StreamController<BluetoothDevice?> _connectedDeviceController =
      StreamController.broadcast();
  Stream<BluetoothDevice?> get connectedDeviceStream =>
      _connectedDeviceController.stream;
// Stream controller for scan errors
// (e.g., Bluetooth disabled, permissions issues)
// Notifies UI to show error messages
  final StreamController<String?> _scanErrorController =
      StreamController.broadcast();
  Stream<String?> get scanErrorStream => _scanErrorController.stream;

// Stream controller for ACK responses from peripheral
// (notifies when "OK" or "ACK" received)
// Used to update UI accordingly
// Though not strictly necessary with write-with-response, kept for potential future use
  final StreamController<bool> _ackController =
      StreamController.broadcast();
// Stream of ACK responses
// (true when ACK received)
  final StreamController<String> _transferStatusController =
      StreamController.broadcast();
  Stream<String> get transferStatusStream => _transferStatusController.stream;

// Stream controller for transfer progress (0-100%)
// Notifies UI to update progress bar
// during file transfer
  final StreamController<int> _progressController =
      StreamController.broadcast();
  Stream<int> get progressStream => _progressController.stream;

/* MTU size negotiated with peripheral (or default) 
Used to optimize chunk sizes during transfer
Default to 23 bytes (minimum ATT MTU)
Adjusted after connection if possible to improve transfer efficiency.
Note: Many devices support up to 247 bytes, but we use a conservative default negotiate after connection.
This helps avoid issues with devices that do not support larger MTUs. */
  int mtuSize = 23; // Default ATT MTU (23) — safe conservative default (MTU – Maximum Transmission Unit)

  // ================= Scan =================
  // Stream of scan results from FlutterBluePlus
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

// Subscription to scan results for logging/debugging
  StreamSubscription<List<ScanResult>>? _scanSubscription;

// Check if Bluetooth is enabled on the device 
// Returns true if enabled, false otherwise
// Used before starting scans to ensure Bluetooth is active
  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

// Check and request necessary BLE permissions
// Returns true if all permissions are granted, otherwise false
// Handles Android and iOS permission models differently
  Future<bool> _checkAndRequestBlePermissions() async {
    if (Platform.isAndroid) {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.location.request();

      return scanStatus.isGranted && connectStatus.isGranted && locationStatus.isGranted;
    } else if (Platform.isIOS) {
      // iOS handles BLE permissions automatically
      return true;
    }
    return true;
  }


// Start scanning for BLE devices
// Applies necessary permission checks and error handling
// Logs discovered devices for debugging purposes
  Future<void> startScan() async {
    if (!await isBluetoothEnabled()) {
      _scanErrorController.add("Bluetooth disabled");
      return;
    }

    // Check and request permissions before scanning
    final hasPermissions = await _checkAndRequestBlePermissions();
    if (!hasPermissions) {
      _scanErrorController.add("BLE and Location permissions required. Please enable in settings.");
      print("BLE permissions not granted");
      return;
    }
    
    // Cancel previous subscription if any
    await _scanSubscription?.cancel();

    // IMPORTANT: Scan without filters first to see ALL devices.
    // If ESP32 isn't showing up, it may not be advertising the service UUID properly
    // or there may be a permission/BLE state issue
    print("Starting BLE scan for all devices...");
    
    try {
      FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 6),
        // Remove service UUID filter to catch all BLE devices
        // If this still doesn't find your ESP32, the issue is likely:
        // 1. ESP32 firmware not advertising correctly
        // 2. BLE not actually enabled on device
        // 3. Permissions not fully granted
      );
    } catch (e) {
      print("Error starting scan: $e");
      _scanErrorController.add("Failed to start BLE scan: $e");
      return;
    }
// ================= Logging =================
// Log discovered devices to console for debugging purposes
// This helps identify if the ESP32 is advertising correctly
// and what services it offers
    // Debug: log discovered devices to console to help troubleshooting
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      print("=== Scan Results: ${results.length} device(s) found ===");
      for (final r in results) {
        try {
          final serviceUuids = r.advertisementData.serviceUuids.map((s) => s.toString()).toList();
          final serviceList = serviceUuids.join(", ");

          print('Device: ${r.device.platformName} | '
              'ID: ${r.device.remoteId} | '
              'RSSI: ${r.rssi} | '
              'Services: $serviceList');

          // Check if this device matches your ESP32 service UUID
          final hasOurService = serviceUuids.any((service) => service.toLowerCase() == serviceUUID.toLowerCase());

          if (hasOurService) {
            print('✓ FOUND MATCHING SERVICE UUID!');
          }
        } catch (e) {
          print('Scan result log error: $e');
        }
      }
    });
  }

// Stop scanning for BLE devices 
// Calls FlutterBluePlus stopScan method to stop scanning
  void stopScan() => FlutterBluePlus.stopScan();

  // ================= Diagnostics =================
  /// Run this to get detailed diagnostics about Bluetooth state
  Future<String> runDiagnostics() async {
    final buffer = StringBuffer();
    buffer.writeln("=== BLE DIAGNOSTICS ===");
    
    try {
      // Check Bluetooth state
      // and whether it's enabled or not 
      final state = await FlutterBluePlus.adapterState.first; // Get current Bluetooth adapter state 
      buffer.writeln("Bluetooth State: $state"); // Log the state 
      buffer.writeln("Bluetooth Enabled: ${state == BluetoothAdapterState.on}");// Check if Bluetooth is enabled 
      
      // Check permissions
      final scanPerm = await Permission.bluetoothScan.status; // Check Bluetooth scan permission status 
      final connectPerm = await Permission.bluetoothConnect.status; // Check Bluetooth connect permission status
      final locPerm = await Permission.location.status; // Check location permission status
      
      // Log permission statuses for BLE scanning, connection and location access
      buffer.writeln("\nPermissions:"); 
      buffer.writeln("  BLUETOOTH_SCAN: ${scanPerm.name}");
      buffer.writeln("  BLUETOOTH_CONNECT: ${connectPerm.name}");
      buffer.writeln("  LOCATION: ${locPerm.name}");
      
      // Check if any devices are already known (previously paired)
      try {
        final connectedDevices = await FlutterBluePlus.connectedDevices;
        buffer.writeln("\nConnected Devices: ${connectedDevices.length}");
        for (final device in connectedDevices) {
          buffer.writeln("  - ${device.platformName} (${device.remoteId})");
        }
      } catch (e) {
        buffer.writeln("\nError getting connected devices: $e");
      }

      // Log expected UUIDs for verification 
      // Helps ensure app and ESP32c3 firmware are aligned
      buffer.writeln("\nUUIDs Expected:"); // Log expected service and characteristic UUIDs for verification  
      buffer.writeln("  Service: $serviceUUID"); // Expected service UUID for ESP32c3
      buffer.writeln("  RX: $rxUUID"); // Expected RX characteristic UUID for ESP32c3
      buffer.writeln("  TX: $txUUID"); // Expected TX characteristic UUID for ESP32c3
      
    } catch (e) {
      buffer.writeln("Error during diagnostics: $e"); // Log any errors encountered during diagnostics 
    }

    // Return the compiled diagnostics string
    // Also print to console for immediate visibility
    final result = buffer.toString();  // Compile diagnostics into a single string, buffer for efficiency
    print(result);
    return result;
  }

  // ================= File Picker =================
  // Open file picker to select a .hex file
  // Validates file extension and updates state accordingly
  // Shows a SnackBar if the selected file is not a .hex file 
  Future<void> pickBleHexFile(BuildContext context) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);

    if (result?.files.single.path == null) return;
// Validate .hex extension and update state accordingly
    String filePath = result!.files.single.path!;
    if (p.extension(filePath).toLowerCase() != '.hex') { // Validate .hex extension
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Select .hex file", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          width: 200,
        ),
      );
      return;
    }
// Update selected HEX file path and notify listeners 
// via stream controller
    bleHexFilePath = filePath;
    _hexFilePathController.add(filePath);
  }

  // ================= Save Files =================
  Future<void> saveFilesToDocuments(String fileName, String txtContent, String hexContent) async {
    if (!Platform.isAndroid) {
      _transferStatusController.add("File saving is only supported on Android.");
      return;
    }

    // Request storage permissions
    // Try standard storage first, then manageExternalStorage (Android 11+)
    if (!await Permission.storage.request().isGranted) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        _transferStatusController.add("Storage permissions denied.");
        return;
      }
    }

    try {
      // Target path: /storage/emulated/0/Documents
      // Create Documents directory if it doesn't exist
      // Note: Accessing external storage directly may require MANAGE_EXTERNAL_STORAGE permission on Android 11+
      final directory = Directory('/storage/emulated/0/Documents');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
// Write files to Documents folder with specified names
// Notify user of success or failure
      await File('${directory.path}/$fileName.txt').writeAsString(txtContent);
      await File('${directory.path}/$fileName.hex').writeAsString(hexContent);

      _transferStatusController.add("Files saved to Documents folder.");
    } catch (e) {
      _transferStatusController.add("Error saving files: $e");
      print("Save error: $e");
    }
  }

  // ================= Connect =================
  // Connect to the selected BLE device
  // Discovers services and characteristics after connection
  // Listens for disconnection events to update state
  // Notifies listeners via stream controller
  Future<void> selectDevice(BluetoothDevice device) async {
    await disconnect();

    connectedDevice = device;
    _connectedDeviceController.add(device);

    await device.connect(autoConnect: false);
    await _discoverCharacteristics();

    device.connectionState.listen((state) {
      print('Device connection state changed: $state');
      if (state == BluetoothConnectionState.disconnected) {
        print('Device disconnected');
        connectedDevice = null;
        _connectedDeviceController.add(null);
      }
    });
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      _connectedDeviceController.add(null);
    }
  }

  // ================= Discover =================
  // Discover services and characteristics on the connected device
  // Sets up RX and TX characteristics for data transfer
  // Negotiates MTU size for optimized transfer
  // Enables notifications on TX characteristic to listen for ACKs
  Future<void> _discoverCharacteristics() async {
    final services = await connectedDevice!.discoverServices();

    final service = services.firstWhere(
      (s) => s.uuid.toString().toLowerCase() == serviceUUID.toLowerCase(),
    );

    rxChar = service.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == rxUUID.toLowerCase(),
    );

    txChar = service.characteristics.firstWhere(
      (c) => c.uuid.toString().toLowerCase() == txUUID.toLowerCase(),
    );

    // Request MTU negotiation (Android/iOS). Keep conservative defaults
    try {
      if (connectedDevice != null) {
        // Request a larger MTU and use the negotiated value if provided.
        // Many devices cap at 247; capture the result when available.
        try {
          final negotiated = await connectedDevice!.requestMtu(247);
          mtuSize = negotiated;
          print('Negotiated MTU: $mtuSize');
        } catch (e) {
          print('requestMtu() error: $e');
        }
      }
    } catch (e) {
      print("MTU negotiation failed: $e, using default MTU");
      mtuSize = 23; // keep conservative fallback
    }

    // Enable notifications
    // Listen for ACKs on TX characteristic
    // This allows us to know when the peripheral has received data 
    await txChar!.setNotifyValue(true);
    txChar!.onValueReceived.listen((data) {
      final response = String.fromCharCodes(data).trim();
      if (response == "OK" || response == "ACK") {
        _ackController.add(true);
      }
    });
  }

  Future<bool> _waitForAck() async {
    try {
      // Wait for ACK signalled by the notification listener
      // Use the internal _ackController stream which the listener populates.
      final ok = await _ackController.stream.first.timeout(
        const Duration(seconds: 5),
      );
      return ok == true;
    } catch (_) {
      return false; // timeout or error
    }
  }


  // ================= Flash HEX =================
  // Flash the selected HEX file to the connected device
  // Splits the file into chunks based on negotiated MTU size
  // Sends each chunk sequentially, waiting for ACKs
  // Provides detailed progress updates via stream controller
  // Implements granular error handling with specific messages
  Future<bool> flashHexFile({int maxRetries = 3}) async {
  if (bleHexFilePath == null) {
    _transferStatusController.add("Error: HEX file not selected.");
    return false;
  }

  if (connectedDevice == null || txChar == null || rxChar == null) {
    _transferStatusController.add("Error: Device not ready.");
    return false;
  }

  try {
    final file = File(bleHexFilePath!);

    // 🔴 CRITICAL: Read as LINES, not bytes
    final lines = await file.readAsLines();

    int totalRecords = lines.where((l) => l.trim().startsWith(":")).length;
    int sentRecords = 0;

    _transferStatusController.add("Starting HEX record transfer...");

    for (String rawLine in lines) {
      String line = rawLine.trim();

      if (line.isEmpty || !line.startsWith(":")) continue;

      sentRecords++;

      // 🟢 Add framing markers so ESP can parse safely
      String packet = "<$line>\n";  // Start '<'  End '>'
      List<int> data = utf8.encode(packet);

      _transferStatusController.add(
          "Sending record $sentRecords / $totalRecords");
      _progressController
          .add((sentRecords / totalRecords * 100).toInt());

// Start waiting for ACK before the write (avoids missed ACK)
      final ackFuture = _waitForAck();

// BLE write WITH response
      await rxChar!.write(data, withoutResponse: false);

// 🟢 WAIT FOR ACK FROM ESP
      final ok = await ackFuture;

    
      if (!ok) {
        _transferStatusController.add("ESP rejected record $sentRecords");
        return false;
      }
    }

    _transferStatusController.add("HEX transfer completed successfully.");
    _progressController.add(100);
    return true;

  } catch (e) {
    _transferStatusController.add("Transfer error: $e");
    return false;
  }
}
}
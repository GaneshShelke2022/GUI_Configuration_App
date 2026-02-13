import 'package:flutter/material.dart' hide CarouselController;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'panel_switch_assign_page.dart';
import 'configuration_page.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../data/app_data.dart';

class CustomerInfoPage extends StatefulWidget {
  const CustomerInfoPage({super.key});

  @override
  State<CustomerInfoPage> createState() => _CustomerInfoPageState();
}

class _CustomerInfoPageState extends State<CustomerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? selectedFile;
  int _currentCarouselIndex = 0;

  // final List<String> _carouselImages = [
  //   'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1471&q=80',
  //   'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1632&q=80',
  //   'https://images.unsplash.com/photo-1600585152225-3579fe9d9ae9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
  //   'https://images.unsplash.com/photo-1580587771525-78d9dba3b914?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1374&q=80',
  //   'https://images.unsplash.com/photo-1600577916048-804c9191e36c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
  // ];

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();
    if (data.customerName != null) _nameCtrl.text = data.customerName!;
    if (data.customerAddress != null) _addressCtrl.text = data.customerAddress!;
    if (data.selectedFile != null) selectedFile = data.selectedFile;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;
        File file = File(filePath);
        String content = await file.readAsString();

        _parseAndLoadData(content, '/storage/emulated/0/Documents/$fileName');
      }
    } catch (e) {
      debugPrint("Error opening file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening file: $e")),
        );
      }
    }
  }

  void _parseAndLoadData(String content, String filePath) {
    final data = AppDataManager();

    // Clear existing data
    data.panelSwitchRows = [];
    data.relayOutputRows = [];
    data.inputAssignRows = [];
    data.sceneAssignRows = [];
    data.mqttDevices = [];
    data.tuyaDevices = [];

    // Reset scalar values
    data.panelSwitchPanel = null;
    data.panelSwitchLocation = null;
    data.panelSwitchModule = null;
    data.inputAssignPanel = null;
    data.wifiPanel = null;
    data.wifiMode = null;
    data.mqttBroker = null;
    data.mqttPort = null;
    data.mqttUser = null;
    data.mqttPassword = null;
    data.modbusBaudRate = null;
    data.modbusDataBit = null;
    data.modbusStopBit = null;
    data.modbusParity = null;
    data.connectivityType = 0;

    List<String> lines = content.split('\n');
    String? currentSection;
    String? currentSubSection;

    final tagRegex = RegExp(r'^<(/)?([^>]+)>$');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = tagRegex.firstMatch(line);
      if (match != null) {
        bool isEndTag = match.group(1) == '/';
        String tagName = match.group(2)!;

        if (isEndTag) {
          if (currentSubSection != null) {
            if (tagName == currentSubSection ||
                (currentSubSection!.startsWith('WiFiInfo') && tagName.startsWith('WiFiInfo'))) {
              currentSubSection = null;
            } else if (['Switch', 'Output', 'WiFi-config', 'WiFi-parameter'].contains(tagName)) {
              if (currentSubSection == tagName) currentSubSection = null;
            }
          } else if (currentSection != null) {
            if (tagName == currentSection ||
                (currentSection!.startsWith('Panel-') && tagName.startsWith('Panel-')) ||
                (currentSection!.startsWith('InputAssign-') && tagName.startsWith('InputAssign-'))) {
              currentSection = null;
            }
          }
        } else {
          if (tagName.contains('PS configuration')) continue;

          if (tagName == 'ProjectInformation') {
            currentSection = tagName;
          } else if (tagName.startsWith('Panel-')) {
            currentSection = tagName;
            data.panelSwitchPanel = tagName;
          } else if (tagName.startsWith('InputAssign-')) {
            currentSection = tagName;
            data.inputAssignPanel = 'Panel-${tagName.split('-')[1]}';
          } else if (tagName == 'Connectivity') {
            currentSection = tagName;
          } else if (['Welcome', 'NoOccupancy', 'Scene-03', 'Scene-04', 'Scene-05', 'Scene-06'].contains(tagName)) {
            currentSection = tagName;
          } else if (tagName == 'Switch' || tagName == 'Output') {
            currentSubSection = tagName;
          } else if (tagName.startsWith('WiFiInfo-')) {
            currentSubSection = tagName;
            data.wifiPanel = 'Panel-${tagName.split('-')[1]}';
            data.connectivityType = 1;
          } else if (tagName == 'WiFi-config' || tagName == 'WiFi-parameter') {
            currentSubSection = tagName;
          }
        }
        continue;
      }

      if (currentSection == 'ProjectInformation') {
        if (line.startsWith('CustomerName:')) {
          data.customerName = line.substring('CustomerName:'.length).trim();
        } else if (line.startsWith('Address:')) {
          data.customerAddress = line.substring('Address:'.length).trim();
        }
      } else if (currentSection != null && currentSection!.startsWith('Panel-')) {
        if (currentSubSection == 'Switch') {
          List<String> parts = line.split(',');
          if (parts.length >= 3) {
            data.panelSwitchRows.add({
              'function': parts[1].trim().isEmpty ? null : parts[1].trim(),
              'number': parts[2].trim(),
            });
          }
        } else if (currentSubSection == 'Output') {
          List<String> parts = line.split(',');
          if (parts.length >= 5) {
            data.relayOutputRows.add({
              'serialNumber': parts[0].trim(),
              'type': parts[1].trim().isEmpty ? null : parts[1].trim(),
              'output': parts[2].trim().isEmpty ? null : parts[2].trim(),
              'number': parts[3].trim(),
              'time': parts[4].trim(),
            });
          }
        } else {
          if (line.startsWith('Location:')) {
            data.panelSwitchLocation = line.substring('Location:'.length).trim();
          } else if (line.startsWith('Module:')) {
            data.panelSwitchModule = line.substring('Module:'.length).trim();
          }
        }
      } else if (currentSection != null && currentSection!.startsWith('InputAssign-')) {
        List<String> parts = line.split(',');
        if (parts.length >= 8) {
          data.inputAssignRows.add({
            'sr': parts[0].trim(),
            'type': parts[1].trim().isEmpty ? null : parts[1].trim(),
            'inputState': parts[2].trim().isEmpty ? null : parts[2].trim(),
            'outputDevice': parts[3].trim().isEmpty ? null : parts[3].trim(),
            'deviceNo': parts[4].trim(),
            'outputState': parts[5].trim().isEmpty ? null : parts[5].trim(),
            'time': parts[6].trim(),
            'defaultState': parts[7].trim().isEmpty ? null : parts[7].trim(),
          });
        }
      } else if (currentSection != null && ['Welcome', 'NoOccupancy', 'Scene-03', 'Scene-04', 'Scene-05', 'Scene-06'].contains(currentSection)) {
        List<String> parts = line.split(',');
        if (parts.length >= 6) {
          data.sceneAssignRows.add({
            'type': currentSection,
            'sr_no': parts[0].trim(),
            'output': parts[1].trim().isEmpty ? null : parts[1].trim(),
            'number': parts[2].trim(),
            'state': parts[3].trim().isEmpty ? null : parts[3].trim(),
            'temp': parts[4].trim(),
            'panel_no': parts[5].trim().isEmpty ? null : parts[5].trim(),
          });
        }
      } else if (currentSection == 'Connectivity') {
        if (currentSubSection == 'WiFi-config') {
          List<String> parts = line.split(',');
          if (parts.length >= 2) {
            if (parts[0].trim() == 'Mode') data.wifiMode = parts[1].trim();
            if (parts[0].trim() == 'MQTTPort') data.mqttPort = parts[1].trim();
          }
        } else if (currentSubSection == 'WiFi-parameter') {
          List<String> parts = line.split(',');
          if (parts.length >= 3) {
            Map<String, dynamic> device = {
              'parameter': parts[0].trim(),
              'deviceNo': parts[1].trim(),
              'dpId': parts[2].trim(),
            };
            if (data.wifiMode == 'Mqtt-HA') {
              data.mqttDevices.add(device);
            } else {
              data.tuyaDevices.add(device);
            }
          }
        } else {
          List<String> parts = line.split(',');
          if (parts.length >= 2) {
            String key = parts[0].trim();
            String value = parts[1].trim();
            if (key == 'BaudRate') {
              data.modbusBaudRate = value;
              data.connectivityType = 0;
            }
            if (key == 'DataBit') data.modbusDataBit = value;
            if (key == 'StopBit') data.modbusStopBit = value;
            if (key == 'Parity') data.modbusParity = value;
            if (key == 'MQTTBrokerAddress') {
              data.mqttBroker = value;
              data.connectivityType = 1;
            }
            if (key == 'UserName') data.mqttUser = value;
            if (key == 'Password') data.mqttPassword = value;
          }
        }
      }
    }

    setState(() {
      _nameCtrl.text = data.customerName ?? '';
      _addressCtrl.text = data.customerAddress ?? '';
      selectedFile = filePath;
      data.selectedFile = filePath;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("File Loaded Successfully", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          width: MediaQuery.of(context).size.width > 600 ? 400 : 280,
        ),
      );
    }
  }

  void _next() {
    // Validation is removed as per request to make fields optional.
    // The validate call is commented out.
    // if (!_formKey.currentState!.validate()) return;

    AppDataManager().customerName = _nameCtrl.text;
    AppDataManager().customerAddress = _addressCtrl.text;
    AppDataManager().selectedFile = selectedFile;

    _saveFiles();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PanelSwitchAssignPage()));
  }

  Future<void> _saveFiles() async {
    const String path = '/storage/emulated/0/Documents';
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        final File txtFile = File('$path/customer_info.txt');
        await txtFile.writeAsString(
            "Name: ${_nameCtrl.text}\nAddress: ${_addressCtrl.text}\nFile: $selectedFile");

        final File hexFile = File('$path/config.hex');
        await hexFile.writeAsString("00000000"); // Placeholder hex content
      }
    } catch (e) {
      debugPrint("Error saving files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient( 
            colors: [Color(0xffdfe9f3), Color(0xffeef2ff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 110, // Reduced from 120 to make content appear higher
            left: 10,
            right: 10,
            bottom: 30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 900 : 530),
              child: Card(
                elevation: 20,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---------------- HEADER ----------------
                      Row( 
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 124, 120, 120),
                                  const Color.fromARGB(255, 133, 128, 128),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_circle,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Customer Information",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Fill the details below to continue",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20), // Reduced from 25

                      // ---------------- FIELDS ----------------
                      Form(
                        key: _formKey,
                        child: LayoutBuilder(
                          builder: (context, c) {
                            bool wide = c.maxWidth > 600;
                            return wide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildNameField()),
                                      const SizedBox(width: 14),
                                      Expanded(child: _buildAddressField()),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildNameField(),
                                      const SizedBox(height: 14),
                                      _buildAddressField(),
                                    ],
                                  );
                          },
                        ),
                      ),

                      const SizedBox(height: 8), // Reduced from 10

                      // ---------------- FILE NAME DISPLAY ----------------
                      if (selectedFile != null)
                        Text(
                          "Selected File: $selectedFile",
                          style: const TextStyle(
                            fontSize: 14,
                            color:Color.fromARGB(255, 44, 44, 44),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 15), // Reduced from 20

                      // ---------------- BOTTOM BUTTONS ----------------
                      Row(
                        children: [
                          // OPEN BUTTON
                          ElevatedButton.icon(
                            onPressed: _openFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 128, 124, 124),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.folder_open,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Open",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const Spacer(),

                          // NEXT BUTTON
                          ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 233, 148, 49),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
 
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ConfigurationPage()));
                          },
                          child: const Text(
                            "Already have a HEX file? Skip this step.",
                            style: TextStyle(
                              color: Colors.black54,
                              decoration: TextDecoration.underline,
                              
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(height: 25), // Reduced from 30

                      // // ---------------- CAROUSEL ----------------
                      // const Text(
                      //   "Our Experience Center",
                      //   textAlign: TextAlign.left,
                      //   style: TextStyle(
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.bold,
                      //     color: Color.fromARGB(225, 5, 4, 4),
                      //   ),
                      // ),
                      // const SizedBox(height: 15),
                      // Column(
                      //   children: [
                      //     CarouselSlider(
                      //       options: CarouselOptions(
                      //         height: 250, // Set a fixed height for better control
                      //         autoPlay: true, // Keep auto-play for dynamic feel
                      //         enlargeCenterPage: true,
                      //         viewportFraction: 1.0, // Set to 1.0 for full width
                      //         onPageChanged: (index, reason) {
                      //           setState(() {
                      //             _currentCarouselIndex = index;
                      //           });
                      //         },
                      //       ),
                      //       items: _carouselImages.map((item) => Container(
                      //         margin: const EdgeInsets.symmetric(vertical: 5.0), // Removed horizontal margin
                      //         child: ClipRRect(
                      //           borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                      //           child: Image.network(item, fit: BoxFit.cover, width: 1000.0),
                      //         ),
                      //       )).toList(),
                      //     ),
                      //     Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: _carouselImages.asMap().entries.map((entry) {
                      //         return GestureDetector(
                      //           // onTap: () => _controller.animateToPage(entry.key),
                      //           child: Container(
                      //             width: 8.0,
                      //             height: 8.0,
                      //             margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                      //             decoration: BoxDecoration(
                      //               shape: BoxShape.circle,
                      //               color: (Theme.of(context).brightness == Brightness.dark
                      //                       ? Colors.white
                      //                       : Colors.black)
                      //                   .withOpacity(_currentCarouselIndex == entry.key ? 0.9 : 0.4),
                      //             ),
                      //           ),
                      //         );
                      //       }).toList(),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      // Validator removed to make the field optional.
      decoration: InputDecoration(
        labelText: "Customer Name",
        prefixIcon: const Icon(Icons.person),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressCtrl,
      maxLines: 3,
      // Validator removed to make the field optional.
      decoration: InputDecoration(
        labelText: "Address",
        prefixIcon: const Icon(Icons.location_on),
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'preview_page.dart';
import '../../data/app_data.dart';

class MqttDeviceRow {
  String? parameter;
  final TextEditingController deviceNoController = TextEditingController();
  final TextEditingController dpIdController = TextEditingController();

  MqttDeviceRow({this.parameter});
}

class TuyaDeviceRow {
  String? parameter;
  final TextEditingController deviceNoController = TextEditingController();
  final TextEditingController dpIdController = TextEditingController();

  TuyaDeviceRow({this.parameter});
}

class ConnectivityPage extends StatefulWidget {
  const ConnectivityPage({super.key});

  @override
  State<ConnectivityPage> createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends State<ConnectivityPage> {
  int _selectedConnectivity = 0;
  String? _selectedBaudRate;
  String? _selectedDataBit;
  String? _selectedStopBit;
  String? _selectedParity;

  String? _selectedPanel;
  String? _selectedWifiMode;

  final _mqttBrokerAddressController = TextEditingController();
  final _mqttPortController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  List<MqttDeviceRow> _mqttDeviceRows = [];

  final _pidController = TextEditingController();
  List<TuyaDeviceRow> _tuyaDeviceRows = [];

  final List<bool> _connectivitySelection = <bool>[true, false];

  // Unified Design System Constants
  static const Color accentColor =  const Color.fromARGB(255, 233, 148, 49);
  static const Color backgroundColor = Color(0xFFFDFDFD);
  static const Color headerColor = Color(0xFF37474F);
  static const Color greyShade100 = Color(0xFFF5F5F5);
  static const Color greyShade300 = Color(0xFFE0E0E0);
  static const Color greyShade600 = Color(0xFF757575);
  static const Color tableHeaderBg = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();
    _selectedConnectivity = data.connectivityType;
    _connectivitySelection[0] = _selectedConnectivity == 0;
    _connectivitySelection[1] = _selectedConnectivity == 1;
    if (_selectedConnectivity == 0) {
      _selectedBaudRate = data.modbusBaudRate;
      _selectedDataBit = data.modbusDataBit;
      _selectedStopBit = data.modbusStopBit;
      _selectedParity = data.modbusParity;
    } else { 
      _selectedPanel = data.wifiPanel;
      _selectedWifiMode = data.wifiMode;
      if (_selectedWifiMode == 'Mqtt-HA') {
        _mqttBrokerAddressController.text = data.mqttBroker ?? '';
        _mqttPortController.text = data.mqttPort ?? '';
        _userNameController.text = data.mqttUser ?? '';
        _passwordController.text = data.mqttPassword ?? '';
        if (data.mqttDevices.isNotEmpty) {
          _mqttDeviceRows = data.mqttDevices.map((r) {
            final row = MqttDeviceRow(parameter: r['parameter']);
            row.deviceNoController.text = r['deviceNo'] ?? '';
            row.dpIdController.text = r['dpId'] ?? '';
            return row;
          }).toList();
        } else {
          _mqttDeviceRows = [MqttDeviceRow(), MqttDeviceRow()];
        }
      } else {
        _pidController.text = data.tuyaPid ?? '';
        if (data.tuyaDevices.isNotEmpty) {
          _tuyaDeviceRows = data.tuyaDevices.map((r) {
            final row = TuyaDeviceRow(parameter: r['parameter']);
            row.deviceNoController.text = r['deviceNo'] ?? '';
            row.dpIdController.text = r['dpId'] ?? '';
            return row;
          }).toList();
        } else {
          _tuyaDeviceRows = [TuyaDeviceRow(), TuyaDeviceRow()];
        }
      }
    }
    }

  @override
  void dispose() {
    _mqttBrokerAddressController.dispose();
    _mqttPortController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    for (var row in _mqttDeviceRows) {
      row.deviceNoController.dispose();
      row.dpIdController.dispose();
    }
    _pidController.dispose();
    for (var row in _tuyaDeviceRows) {
      row.deviceNoController.dispose();
      row.dpIdController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top padding for scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 60, 10, 16),
                child: Column(
                  children: [
                    // Page Title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Center(
                        child: Text(
                          'Connectivity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: greyShade300, thickness: 1),
                    const SizedBox(height: 20.0),
                    ToggleButtons(
                      isSelected: _connectivitySelection,
                      onPressed: (int index) {
                        setState(() {
                          _selectedConnectivity = index;
                          for (
                            int i = 0;
                            i < _connectivitySelection.length;
                            i++
                          ) {
                            _connectivitySelection[i] = i == index;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(5.0),
                      selectedBorderColor:  const Color.fromARGB(255, 233, 148, 49),
                      selectedColor: Colors.white,
                      fillColor:  const Color.fromARGB(255, 233, 148, 49),
                      color: headerColor,
                      constraints: const BoxConstraints(
                        minHeight: 40.0,
                        minWidth: 120.0,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Modbus'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('WiFi/BLE'),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedConnectivity == 0 ? _buildModbusSettings() : _buildWifiBleSettings(),
                    ),
                  ],
                ),
              ),
            ),
            // Non-scrollable bottom navigation bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greyShade300,
                      foregroundColor: headerColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 25,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Back",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  const Color.fromARGB(255, 233, 148, 49),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 25,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      // Save data
                      final manager = AppDataManager();
                      manager.connectivityType = _selectedConnectivity;
                      if (_selectedConnectivity == 0) {
                        manager.modbusBaudRate = _selectedBaudRate;
                        manager.modbusDataBit = _selectedDataBit;
                        manager.modbusStopBit = _selectedStopBit;
                        manager.modbusParity = _selectedParity;
                      } else {
                        manager.wifiPanel = _selectedPanel;
                        manager.wifiMode = _selectedWifiMode;
                        if (_selectedWifiMode == 'Mqtt-HA') {
                          manager.mqttBroker =
                              _mqttBrokerAddressController.text;
                          manager.mqttPort = _mqttPortController.text;
                          manager.mqttUser = _userNameController.text;
                          manager.mqttPassword = _passwordController.text;
                          manager.mqttDevices = _mqttDeviceRows
                              .map(
                                (r) => {
                                  'parameter': r.parameter,
                                  'deviceNo': r.deviceNoController.text,
                                  'dpId': r.dpIdController.text,
                                },
                              )
                              .toList();
                        } else {
                          manager.tuyaPid = _pidController.text;
                          manager.tuyaDevices = _tuyaDeviceRows
                              .map(
                                (r) => {
                                  'parameter': r.parameter,
                                  'deviceNo': r.deviceNoController.text,
                                  'dpId': r.dpIdController.text,
                                },
                              )
                              .toList();
                        }
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OverviewPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiBleSettings() {
    return _buildSettingsCard(
      key: const ValueKey('wifi'),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Select Panel',
                  value: _selectedPanel,
                  items: List<String>.generate(
                    48,
                    (i) => 'Panel-${(i + 1).toString().padLeft(2, '0')}',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedPanel = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 58, // Match the approximate height of the dropdown
                child: VerticalDivider(
                  color: greyShade300,
                  thickness: 1,
                ),
              ),
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Select Mode',
                  value: _selectedWifiMode,
                  items: const ['Mqtt-HA', 'Tuya-wifi', 'Tuya-BLE'],
                  onChanged: (value) {
                    setState(() {
                      _selectedWifiMode = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          if (_selectedWifiMode == 'Mqtt-HA') ...[
            const SizedBox(height: 20),
            _buildMqttHaSettings(),
          ],
          if (_selectedWifiMode == 'Tuya-wifi' ||
              _selectedWifiMode == 'Tuya-BLE') ...[
            const SizedBox(height: 20),
            _buildTuyaSettings(),
          ],
        ],
      ),
    );
  }
  Widget _buildMqttHaSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                label: 'MQTT Broker Address',
                controller: _mqttBrokerAddressController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStyledTextField(
                label: 'MQTT Port',
                controller: _mqttPortController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                label: 'User Name',
                controller: _userNameController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStyledTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDeviceTable(
          title: 'Device Configuration',
          rows: _mqttDeviceRows,
          onAddRow: () {
            setState(() {
              _mqttDeviceRows.add(MqttDeviceRow());
            });
          },
          onDeleteRow: (index) {
            setState(() {
              _mqttDeviceRows[index].deviceNoController.dispose();
              _mqttDeviceRows[index].dpIdController.dispose();
              _mqttDeviceRows.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  Widget _buildTuyaSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStyledTextField(label: 'PID', controller: _pidController),
        const SizedBox(height: 24),
        _buildDeviceTable(
          title: 'Device Configuration',
          rows: _tuyaDeviceRows,
          onAddRow: () {
            setState(() {
              _tuyaDeviceRows.add(TuyaDeviceRow());
            });
          },
          onDeleteRow: (index) {
            setState(() {
              _tuyaDeviceRows[index].deviceNoController.dispose();
              _tuyaDeviceRows[index].dpIdController.dispose();
              _tuyaDeviceRows.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDeviceTable({
    required String title,
    required List<dynamic> rows,
    required VoidCallback onAddRow,
    required Function(int) onDeleteRow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: greyShade300),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: tableHeaderBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'S.No',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: Text(
                    'Parameter',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Device No.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DP ID',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 32), // Space for delete button
              ],
            ),
          ),
          // Table Rows
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index < rows.length - 1
                        ? greyShade300
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: greyShade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _buildStyledTableDropdown(
                      value: row.parameter,
                      items: ['LAMP', 'FAN-ON-OFF', 'FAN-SPEED', 'FAN-REG-LOCK', 'DIMMER-ON-OFF', 'DIMMER-BRIGHTNESS', 'CURTAIN', 'PROXY-SWITCH', 'CHILD-LOCK', 'DEVICE-RESTART', 'PANEL-BACKLIGHTMIN'],
                      onChanged: (value) {
                        setState(() {
                          row.parameter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildStyledTableTextField(
                      controller: row.deviceNoController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildStyledTableTextField(controller: row.dpIdController),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      onPressed: () => onDeleteRow(index),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Add New Row Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddRow,
                icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 18),
                label: const Text(
                  'Add New Row',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTableDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: headerColor),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      decoration: _styledInputDecoration(null).copyWith(
        hintText: 'Select',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.arrow_drop_down, size: 20, color: headerColor), // Added comma
      menuMaxHeight: 250,
      style: const TextStyle(
        fontSize: 14,
        color: headerColor,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: backgroundColor,
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: headerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildStyledTableTextField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: _styledInputDecoration(null).copyWith(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: _styledInputDecoration(label),
    );
  }

  Widget _buildModbusSettings() {
    return _buildSettingsCard(
      key: const ValueKey('modbus'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Baud Rate',
                  value: _selectedBaudRate,
                  items: ['300', '600', '1200', '2400', '4800', '9600', '14400', '19200', '38400', '56000', '57600', '115200', '128000', '230400', '256000', '460800', '921600'],
                  onChanged: (value) =>
                      setState(() => _selectedBaudRate = value),
                ),
              ),
              const SizedBox(
                height: 58,
                child: VerticalDivider(
                  color: greyShade300,
                  thickness: 1,
                ),
              ),
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Data Bit',
                  value: _selectedDataBit,
                  items: const ['5', '8'],
                  onChanged: (value) =>
                      setState(() => _selectedDataBit = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Stop Bit',
                  value: _selectedStopBit,
                  items: const ['1', '2'],
                  onChanged: (value) =>
                      setState(() => _selectedStopBit = value),
                ),
              ),
              const SizedBox(
                height: 58,
                child: VerticalDivider(
                  color: greyShade300,
                  thickness: 1,
                ),
              ),
              Expanded(
                child: _buildStyledDropdown(
                  label: 'Parity',
                  value: _selectedParity,
                  items: const ['None', 'Odd', 'Even'],
                  onChanged: (value) => setState(() => _selectedParity = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: greyShade300),
      ),
      child: child,
    );
  }

  Widget _buildStyledDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: headerColor),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: _styledInputDecoration(label),
      icon: const Icon(Icons.arrow_drop_down, size: 20, color: headerColor), // Added comma
      menuMaxHeight: 250,
      style: const TextStyle(
        fontSize: 14,
        color: headerColor,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: backgroundColor,
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Text(
            item,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: headerColor,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList();
      },
    );
  }
  
  InputDecoration _styledInputDecoration(String? label) {
    return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: greyShade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: greyShade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: greyShade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color:  const Color.fromARGB(255, 233, 148, 49), width: 2),
        ),
        filled: true,
        fillColor: greyShade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      );
  }
}

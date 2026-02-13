import 'package:flutter/material.dart';
import 'relay_output_page.dart';
import '../../data/app_data.dart';

class PanelSwitchAssignPage extends StatefulWidget {
  const PanelSwitchAssignPage({super.key});

  @override
  State<PanelSwitchAssignPage> createState() => _PanelSwitchAssignPageState();
}

class _PanelSwitchAssignPageState extends State<PanelSwitchAssignPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPanel;
  String? _selectedModule;
  final _boardLocationCtrl = TextEditingController();

  final List<Map<String, dynamic>> _rows = [];

  static const int _maxSwitches = 20;
  static const List<String> _functions = [
    'LAMP',
    'BELL',
    'FAN-ON/OFF',
    'FAN-UP',
    'FAN-DOWN',
    'CURTAIN-OPEN',
    'CURTAIN-CLOSE',
    'DIMMER-ON/OFF',
    'DIMMER-UP',
    'DIMMER-DOWN',
    'DIMMER-RLOVR',
    'MASTER',
    'OCCUPANCY',
    'DND',
    'MMR',
    'MMR',
    'LAUNDRY',
    'SCENE',
    'SCENE OFF',
    'SCENE TOGGLE',
    'THERMOSTAT-ON/OFF',
    'THERMOSTAT-FAN',
    'THERMOSTAT-T-UP',
    'THERMOSTAT-T-DN',
    'THERMOSTAT-MODE',
  ];

  // Unified color scheme
  static const accentColor = Color.fromARGB(255, 233, 148, 49);
  static const backgroundColor = Color(0xFFFDFDFD);
  static const headerColor = Color(0xFF37474F);

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();
    if (data.panelSwitchPanel != null) {
      _selectedPanel = data.panelSwitchPanel;
      _boardLocationCtrl.text = data.panelSwitchLocation ?? '';
      _selectedModule = data.panelSwitchModule;

      if (data.panelSwitchRows.isNotEmpty) {
        for (var r in data.panelSwitchRows) {
          _rows.add({
            'function': r['function'],
            'numberCtrl': TextEditingController(text: r['number']),
          });
        }
      } else {
        _addRow();
        _addRow();
        _addRow();
        _addRow();
      }
    } else {
      _addRow();
      _addRow();
      _addRow();
      _addRow();
    }
  }

  void _addRow() {
    if (_rows.length >= _maxSwitches) return;
    _rows.add({'function': null, 'numberCtrl': TextEditingController()});
    setState(() {});
  }

  void _removeRow(int index) {
    if (index < 0 || index >= _rows.length) return;
    final ctrl = _rows[index]['numberCtrl'] as TextEditingController;
    ctrl.dispose();
    _rows.removeAt(index);
    setState(() {});
  }

  String _swLabel(int index) => 'SW-${(index + 1).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    for (final r in _rows) {
      (r['numberCtrl'] as TextEditingController).dispose();
    }
    _boardLocationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panels = List.generate(
      48,
      (i) => 'Panel-${(i + 1).toString().padLeft(2, '0')}',
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 60, 10, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE
                      const Padding(
                        padding: EdgeInsets.only(bottom: 15.0),
                        child: Center(
                          child: Text(
                            "Panel Switch Assign",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: headerColor,
                            ),
                          ),
                        ),
                      ),

                      // PANEL SECTION
                      _buildPanelCard(panels),

                      const SizedBox(height: 20),

                      // TABLE SECTION
                      _buildSwitchesTable(),

                      const SizedBox(height: 10),

                      // Add Row Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.deepPurple,
                          ),
                          label: const Text(
                            "Add New Row",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Navigation
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// PANEL + MODULE + LOCATION card
  Widget _buildPanelCard(List<String> panels) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStyledDropdownField(
                  label: "Select Panel",
                  value: _selectedPanel,
                  items: panels,
                  onChanged: (v) => setState(() => _selectedPanel = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStyledInputField(
                  controller: _boardLocationCtrl,
                  label: "Board Location",
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStyledDropdownField(
            label: "Select Module",
            value: _selectedModule,
            items: ['2M', '4M', '6M', '8M'],
            onChanged: (v) => setState(() => _selectedModule = v),
          ),
        ],
      ),
    );
  }

  /// TABLE UI
  Widget _buildSwitchesTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // TABLE HEADER
          _buildTableHeader(),

          // TABLE ROWS
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              final row = _rows[index];
              final numberCtrl = row['numberCtrl'] as TextEditingController;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        _swLabel(index),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildStyledTableDropdown(
                        value: row['function'] as String?,
                        items: _functions,
                        onChanged: (v) => setState(() => row['function'] = v),
                        hint: "Select",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: _buildStyledTableTextField(numberCtrl)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: () => _removeRow(index),
                          tooltip: 'Delete Row',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final headerTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: headerColor,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('SW.NO', style: headerTextStyle)),
          Expanded(flex: 5, child: Text('FUNCTIONS', style: headerTextStyle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text('NUMBER', style: headerTextStyle)),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              'Del',
              style: headerTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _styledInputDecoration(label),
      isExpanded: true,
      isDense: true,
      menuMaxHeight: 300,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: headerColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Text(item, overflow: TextOverflow.ellipsis);
        }).toList();
      },
    );
  }

  Widget _buildStyledInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _styledInputDecoration(label),
    );
  }

  Widget _buildStyledTableDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _styledInputDecoration(null).copyWith(hintText: hint),
      isExpanded: true,
      isDense: true,
      menuMaxHeight: 300,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: headerColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Text(item, overflow: TextOverflow.ellipsis);
        }).toList();
      },
    );
  }

  Widget _buildStyledTableTextField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _styledInputDecoration(null),
    );
  }

  InputDecoration _styledInputDecoration(String? label) {
    return InputDecoration(
      hintText: label,
      labelText: label,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accentColor, width: 1.5),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;

              // Save data
              final manager = AppDataManager();
              manager.panelSwitchPanel = _selectedPanel;
              manager.panelSwitchLocation = _boardLocationCtrl.text;
              manager.panelSwitchModule = _selectedModule;
              manager.panelSwitchRows = _rows
                  .map(
                    (r) => {
                      'function': r['function'],
                      'number': (r['numberCtrl'] as TextEditingController).text,
                    },
                  )
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelayOutputPage(),
                ),
              );
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

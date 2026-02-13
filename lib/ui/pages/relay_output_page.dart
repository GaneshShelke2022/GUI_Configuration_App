import 'package:flutter/material.dart';
import 'input_assign_page.dart';
import '../../data/app_data.dart';

class RelayOutputPage extends StatefulWidget {
  const RelayOutputPage({super.key});

  @override
  State<RelayOutputPage> createState() => _RelayOutputPageState();
}

class _RelayOutputPageState extends State<RelayOutputPage> {
  late List<Map<String, dynamic>> _rows;

  // Unified color scheme
  static const accentColor = Color.fromARGB(255, 192, 22, 22);
  static const backgroundColor = Color(0xFFFDFDFD);
  static const headerColor = Color(0xFF37474F);

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();
    if (data.relayOutputRows.isNotEmpty) {
      _rows = data.relayOutputRows
          .map(
            (r) => {
              'serialNumber': r['serialNumber'],
              'type': r['type'],
              'output': r['output'],
              'numberController': TextEditingController(text: r['number']),
              'timeController': TextEditingController(text: r['time']),
            },
          )
          .toList();
    } else {
      _rows = List.generate(4, (index) => _createNewRow(index + 1));
    }
  }

  Map<String, dynamic> _createNewRow(int serial) {
    return {
      'serialNumber': 'OD-${serial.toString().padLeft(2, '0')}',
      'type': null,
      'output': null,
      'numberController': TextEditingController(),
      'timeController': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row['numberController'].dispose();
      row['timeController'].dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_createNewRow(_rows.length + 1));
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _rows[index]['numberController'].dispose();
      _rows[index]['timeController'].dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 55, 10, 16),
                child: Column(
                  children: [
                    // Page Title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Center(
                        child: Text(
                          'Relay Output',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ),

                    // Table Container
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          _buildHeader(),

                          // Table Body
                          ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              return _buildDataRow(_rows[index], index);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Add Row Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.deepPurple,
                        ),
                        label: const Text(
                          'Add New Row',
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

            // Fixed Bottom Navigation
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          Expanded(flex: 3, child: Text('Sr.No.', style: headerTextStyle)),
          Expanded(flex: 4, child: Text('Type', style: headerTextStyle)),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: Text('Output', style: headerTextStyle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text('Number', style: headerTextStyle)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text('Time', style: headerTextStyle)),
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

  Widget _buildDataRow(Map<String, dynamic> row, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
              row['serialNumber'],
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _buildDropdown(
              value: row['type'],
              items: ['RLY', 'DIM'],
              onChanged: (value) => setState(() => row['type'] = value),
              hint: "Select",
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 7,
            child: _buildDropdown(
              value: row['output'],
              items: [
                'LAMP',
                'BELL',
                'OCCUPANCY',
                'FAN-LOW',
                'FAN-MID',
                'FAN-HIGH',
                'CURTAIN-OPEN',
                'CURTAIN-CLOSE',
                'THERMOSTAT-LOW',
                'THERMOSTAT-MID',
                'THERMOSTAT-HIGH',
                'THERMOSTAT-VALV',
                'DIMMER'
              ],
              onChanged: (value) => setState(() => row['output'] = value),
              hint: "Select",
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _buildTextField(row['numberController'])),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _buildTextField(row['timeController'])),
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
                onPressed: () => _deleteRow(index),
                tooltip: 'Delete Row',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 300,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: accentColor, width: 2),
          ),
        ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:  const Color.fromARGB(255, 233, 148, 49),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            onPressed: () {
              // Save data
              AppDataManager().relayOutputRows = _rows
                  .map(
                    (r) => {
                      'serialNumber': r['serialNumber'],
                      'type': r['type'],
                      'output': r['output'],
                      'number':
                          (r['numberController'] as TextEditingController).text,
                      'time':
                          (r['timeController'] as TextEditingController).text,
                    },
                  )
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const InputAssignPage()),
              );
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

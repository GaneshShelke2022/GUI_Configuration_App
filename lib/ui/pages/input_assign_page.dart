import 'package:flutter/material.dart';
import 'scene_assign_page.dart';
import '../../data/app_data.dart';

class InputAssignPage extends StatefulWidget {
  const InputAssignPage({super.key});

  @override
  State<InputAssignPage> createState() => _InputAssignPageState();
}

class _InputAssignPageState extends State<InputAssignPage> {
  String? selectedPanel;

  List<Map<String, dynamic>> rows = [];

  // Unified design colors
  static const Color accentColor =  const Color.fromARGB(255, 233, 148, 49);
  static const Color backgroundColor = Color(0xFFFDFDFD);
  static const Color headerColor = Color(0xFF37474F);
  static const Color greyShade100 = Color(0xFFF5F5F5);
  static const Color greyShade300 = Color(0xFFE0E0E0);
  static const Color greyShade600 = Color(0xFF757575);
  static const Color greyShade700 = Color(0xFF616161);

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();
    selectedPanel = data.inputAssignPanel;

    if (data.inputAssignRows.isNotEmpty) {
      rows = data.inputAssignRows
          .map(
            (r) => {
              'sr': r['sr'],
              'type': r['type'],
              'inputState': r['inputState'],
              'outputDevice': r['outputDevice'],
              'deviceNoController': TextEditingController(text: r['deviceNo']),
              'outputState': r['outputState'],
              'timeController': TextEditingController(text: r['time']),
              'defaultState': r['defaultState'],
            },
          )
          .toList();
    } else {
      rows = List.generate(4, (index) {
        return {
          'sr': 'IP-${(index + 1).toString().padLeft(2, '0')}',
          'type': null,
          'inputState': null,
          'outputDevice': null,
          'deviceNoController': TextEditingController(),
          'outputState': null,
          'timeController': TextEditingController(),
          'defaultState': null,
        };
      });
    }
  }

  @override
  void dispose() {
    for (var r in rows) {
      r['deviceNoController'].dispose();
      r['timeController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // To make it more compact and avoid scrolling, reduce vertical padding/margins
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
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
                          "Input Assign",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ),

                    /// PANEL DROPDOWN
                    DropdownButtonFormField<String>(
                      initialValue: selectedPanel,
                      decoration: _styledDecoration().copyWith(
                        labelText: "Select Panel",
                        labelStyle:
                            const TextStyle(fontSize: 16, color: headerColor),
                      ),
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 200,
                      icon: const Icon(Icons.arrow_drop_down, color: headerColor),
                      iconSize: 20,
                      style: const TextStyle(
                        fontSize: 14,
                        color: headerColor,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: backgroundColor,
                      items: List.generate(
                        48,
                        (i) => "Panel-${(i + 1).toString().padLeft(2, '0')}",
                      ).map((v) {
                        return DropdownMenuItem(
                          value: v,
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
                              v,
                              style: const TextStyle(
                                  fontSize: 14, color: headerColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedPanel = v),
                      selectedItemBuilder: (BuildContext context) {
                        return List.generate(
                          48,
                          (i) => "Panel-${(i + 1).toString().padLeft(2, '0')}",
                        ).map<Widget>((String item) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: headerColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),

                    const SizedBox(height: 15), // Keep this spacing

                    /// IP SECTIONS
                    Column( // Removed Expanded here as it's within SingleChildScrollView
                      mainAxisAlignment: MainAxisAlignment.start, // Changed to start, as spaceAround won't work well within a non-expanded column
                      children: rows.map((row) => _buildIpSection(row)).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR
            Container(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greyShade300,
                      foregroundColor: headerColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
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
                      AppDataManager().inputAssignPanel = selectedPanel;
                      AppDataManager().inputAssignRows = rows
                          .map(
                            (r) => {
                              'sr': r['sr'],
                              'type': r['type'],
                              'inputState': r['inputState'],
                              'outputDevice': r['outputDevice'],
                              'deviceNo': (r['deviceNoController']
                                      as TextEditingController)
                                  .text,
                              'outputState': r['outputState'],
                              'time': (r['timeController']
                                      as TextEditingController)
                                  .text,
                              'defaultState': r['defaultState'],
                            },
                          )
                          .toList();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SceneAssignPage(),
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

  // ---------------- NEW IP SECTION BUILDER ----------------

  Widget _buildIpSection(Map<String, dynamic> row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // Reduced
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // IP Title
          SizedBox(
            width: 45, // Reduced width
            child: Center(
              child: Text(
                row['sr'],
                style: const TextStyle(
                  fontSize: 12, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 6), // Reduced spacing

          // Fields
          Expanded(
            child: Column(
              children: [
                // First row of fields
                Row(
                  children: [
                    Expanded(
                      child: _buildStyledDropdownField(
                        "Type",
                        row,
                        "type",
                        ["DIGITAL-LATCH", "DIGITAL-PULSE"],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStyledDropdownField(
                        "InputState",
                        row,
                        "inputState",
                        ["LOW", "HIGH"],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStyledDropdownField(
                        "OutputDevice",
                        row,
                        "outputDevice",
                        ["LAMP", "FAN-ON/OFF", "CURTAIN-OPEN", "CURTAIN-CLOSE","DIMMER","OCCUPANCY","SCENE"],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStyledTextField(
                        "Device No",
                        row,
                        "deviceNoController",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Second row of fields
                Row(
                  children: [
                    Expanded(
                      child: _buildStyledDropdownField(
                        "Output State",
                        row,
                        "outputState",
                        [
                          "ON",
                          "OFF",
                          ...List.generate(10, (i) => "ON-L-${i + 1}")
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStyledTextField("Time", row, "timeController"),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStyledDropdownField(
                        "Default State",
                        row,
                        "defaultState",
                        [
                          "ON",
                          "OFF",
                          "TOGGLE",
                          ...List.generate(10, (i) => "ON-L-${i + 1}")
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: const SizedBox()), // Placeholder
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdownField(
    String label,
    Map<String, dynamic> row,
    String key,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: greyShade700, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: row[key],
          decoration: _styledDecoration(),
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 200,
          icon: const Icon(Icons.arrow_drop_down, color: headerColor),
          iconSize: 20,
          style: const TextStyle(
            fontSize: 14,
            color: headerColor,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: backgroundColor,
          items: items.map((v) {
            return DropdownMenuItem(
              value: v,
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
                  v,
                  style: const TextStyle(fontSize: 14, color: headerColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => row[key] = v),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: headerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  Widget _buildStyledTextField(
    String label,
    Map<String, dynamic> row,
    String key,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: greyShade700, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: row[key],
          keyboardType: TextInputType.number,
          decoration: _styledDecoration(),
          style: const TextStyle(
              fontSize: 14, color: headerColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  InputDecoration _styledDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: greyShade100,
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'connectivity_page.dart';
import '../../data/app_data.dart';

class SceneAssignPage extends StatefulWidget {
  const SceneAssignPage({super.key});

  @override
  State<SceneAssignPage> createState() => _SceneAssignPageState();
}

class _SceneAssignPageState extends State<SceneAssignPage> {
  // Unified design colors
  static const Color accentColor =  const Color.fromARGB(255, 233, 148, 49);
  static const Color backgroundColor = Color(0xFFFDFDFD);
  static const Color headerColor = Color(0xFF37474F);

  String? _selectedSceneType;
  final List<String> _scenes = [
    'Welcome',
    'NoOccupancy',
    'Scene-03',
    'Scene-04',
    'Scene-05',
    'Scene-06',
  ];

  final Map<String, List<Map<String, dynamic>>> _sceneRows = {};

  @override
  void initState() {
    super.initState();
    final data = AppDataManager();

    for (var sceneType in _scenes) {
      // Initialize the list for this sceneType
      _sceneRows[sceneType] = [];

      // Filter existing rows from AppDataManager for the current sceneType
      var existingRowsForScene = data.sceneAssignRows
          .where((r) => r['type'] == sceneType)
          .where((r) {
            final type = r['type'];
            if (type == sceneType) return true;
            if (sceneType == 'Welcome' && type == 'Scene-01') return true;
            if (sceneType == 'NoOccupancy' && type == 'Scene-02') return true;
            return false;
          })
          .toList();

      if (existingRowsForScene.isNotEmpty) {
        // If existing rows are found, add them to _sceneRows
        for (var r in existingRowsForScene) {
          _sceneRows[sceneType]!.add({
            'sr_no': r['sr_no'],
            'output': r['output'],
            'number': TextEditingController(text: r['number']),
            'state': r['state'],
            'temp': TextEditingController(text: r['temp']),
            'panel_no': r['panel_no'],
          });
        }
      }

      // If, after checking existing data, the list for this sceneType is still empty,
      // then add the default two rows (OD-01 and OD-02).
      if (_sceneRows[sceneType]!.isEmpty) {
        _sceneRows[sceneType]!.add({
          'sr_no': 'OD-01',
          'output': null,
          'number': TextEditingController(),
          'state': null,
          'temp': TextEditingController(),
          'panel_no': null,
        });
        _sceneRows[sceneType]!.add({
          'sr_no': 'OD-02',
          'output': null,
          'number': TextEditingController(),
          'state': null,
          'temp': TextEditingController(),
          'panel_no': null,
        });
      }
    }

    // Set a default selected scene if none is selected on initial load
    if (_selectedSceneType == null && _scenes.isNotEmpty) {
      _selectedSceneType = _scenes.first;
    }
  }

  final List<String> _outputOptions = [
    'LAMP',
    'FAN',
    'CURTAIN',
    'DIMMER-OPEN',
    'DIMMER-CLOSE',
    'DIMMER',
    'THERMOSTAT',
    
  ];
  final List<String> _stateOptions = [
    'ON',
    'OFF',
    ...List.generate(10, (i) => 'ON-L-${(i + 1).toString().padLeft(2, '0')}'),
  ];
  final List<String> _panelNoOptions = List.generate(
    48,
    (i) => 'Panel-${(i + 1).toString().padLeft(2, '0')}',
  );

  void _addNewRow({bool isDefault = false}) {
    if (_selectedSceneType == null) return;

    void add() {
      int nextSrNo = _sceneRows[_selectedSceneType]!.length + 1;
      _sceneRows[_selectedSceneType]!.add({
        'sr_no': 'OD-${nextSrNo.toString().padLeft(2, '0')}',
        'output': null,
        'number': TextEditingController(),
        'state': null,
        'temp': TextEditingController(),
        'panel_no': null,
      });
    }

    if (isDefault) {
      add();
    } else {
      setState(() {
        add();
      });
    }
  }

  void _deleteRow(int index) {
    if (_selectedSceneType == null) return;
    setState(() {
      _sceneRows[_selectedSceneType]![index]['number'].dispose();
      _sceneRows[_selectedSceneType]![index]['temp'].dispose();
      _sceneRows[_selectedSceneType]!.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var sceneType in _scenes) {
      for (var data in _sceneRows[sceneType]!) {
        data['number'].dispose();
        data['temp'].dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 110),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: <Widget>[
                    const Center(
                      child: Text(
                        "Scene Assign",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                      itemCount: _scenes.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return _buildSceneButton(_scenes[index]);
                      },
                    ),
                    const SizedBox(height: 5),
                    if (_selectedSceneType != null) _buildSceneDetails(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildSceneButton(String type) {
    final isSelected = _selectedSceneType == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ?  const Color.fromARGB(255, 233, 148, 49): Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: () {
        setState(() {
          _selectedSceneType = type;
          if (_sceneRows[type]!.isEmpty) {
            _addNewRow(isDefault: true);
            _addNewRow(isDefault: true);
          }
        });
      },
      child: Text(
        type,
        style: TextStyle(
          color: isSelected ? Colors.white : headerColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSceneDetails() {
    final rows = _sceneRows[_selectedSceneType]!;
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            var data = rows[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildHeaderCell('Sr No.', flex: 1),
                      _buildHeaderCell('Output', flex: 2),
                      _buildHeaderCell('Number', flex: 2),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataCell(
                        Center(
                          child: Text(
                            data['sr_no'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        flex: 1,
                      ),
                      _buildDataCell(
                        _buildStyledDropdown(data, 'output', _outputOptions),
                        flex: 2,
                      ),
                      _buildDataCell(
                        _buildTextFormField(data, 'number'),
                        flex: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildHeaderCell('State', flex: 2),
                      _buildHeaderCell('Temp', flex: 2),
                      _buildHeaderCell('Panel No', flex: 3),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataCell(
                        _buildStyledDropdown(data, 'state', _stateOptions),
                        flex: 2,
                      ),
                      _buildDataCell(
                        _buildTextFormField(data, 'temp'),
                        flex: 2,
                      ),
                      _buildDataCell(
                        _buildStyledDropdown(data, 'panel_no', _panelNoOptions),
                        flex: 3,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline,
                       color: Color.fromARGB(255, 212, 75, 75)),
                      //  color: Colors.red.shade400,
                      onPressed: () => _deleteRow(index),
                    ),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _addNewRow,
          icon: const Icon(Icons.add, color: Colors.deepPurple),
          label: const Text(
            'Add New Row',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
             
            ),
          
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: headerColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(Widget child, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }

  Widget _buildStyledDropdown(
      Map<String, dynamic> data, String key, List<String> options) {
    return DropdownButtonFormField<String>(
      value: data[key],
      decoration: _styledInputDecoration(),
      isDense: true,
      isExpanded: true,
      menuMaxHeight: 200,
      icon: const Icon(Icons.arrow_drop_down, color: headerColor),
      style: const TextStyle(
        fontSize: 14,
        color: headerColor,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: backgroundColor,
      items: options.map((v) {
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
      onChanged: (val) => setState(() => data[key] = val),
      selectedItemBuilder: (BuildContext context) {
        return options.map<Widget>((String item) {
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

  TextFormField _buildTextFormField(Map<String, dynamic> data, String key) {
    return TextFormField(
      controller: data[key],
      keyboardType: TextInputType.number,
      decoration: _styledInputDecoration(),
      style: const TextStyle(
          fontSize: 14, color: headerColor, fontWeight: FontWeight.w500),
      textAlign: TextAlign.center,
    );
  }

  InputDecoration _styledInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
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
        borderSide: const BorderSide(color:  const Color.fromARGB(255, 233, 148, 49), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Back",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:  const Color.fromARGB(255, 233, 148, 49),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
              elevation: 2,
              shadowColor: accentColor.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              List<Map<String, dynamic>> allRows = [];
              _sceneRows.forEach((sceneType, rows) {
                for (var row in rows) {
                  allRows.add({
                    'type': sceneType,
                    'sr_no': row['sr_no'],
                    'output': row['output'],
                    'number': (row['number'] as TextEditingController).text,
                    'state': row['state'],
                    'temp': (row['temp'] as TextEditingController).text,
                    'panel_no': row['panel_no'],
                  });
                }
              });
              AppDataManager().sceneAssignRows = allRows;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConnectivityPage(),
                ),
              );
            },
            child: const Text(
              "Next",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

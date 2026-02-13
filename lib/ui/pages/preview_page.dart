import 'package:flutter/material.dart';
import '../../data/app_data.dart';
import 'configuration_page.dart';
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  static const Color accentColor =  const Color.fromARGB(255, 233, 148, 49);
  static const Color backgroundColor = Color.fromARGB(255, 247, 245, 245);
  static const Color headerColor = Color(0xFF37474F);
  static const Color greyShade300 = Color.fromARGB(255, 253, 253, 253);
  // static const Color greyShade600 = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final data = AppDataManager();
    return Scaffold(
      // backgroundColor: const Color.fromARGB(255, 247, 245, 245),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 60, 10, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Page Title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Center(
                        child: Text(
                          "Project Preview",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ),
                    // Project Information
                    if (data.customerName != null &&
                        data.customerName!.isNotEmpty)
                      _buildSectionCard(
                        title: "Project Information",
                        children: [
                          _buildDetailRow("CustomerName", data.customerName),
                          _buildDetailRow("Address", data.customerAddress),
                        ],
                      ),

                    // Panel (Location, Module, Switch, Output)
                    if (data.panelSwitchPanel != null)
                      _buildSectionCard(
                        title: data.panelSwitchPanel ?? "Panel",
                        children: [
                          _buildDetailRow("Location", data.panelSwitchLocation),
                          _buildDetailRow("Module", data.panelSwitchModule),
                          // Switches
                          if (data.panelSwitchRows.any(
                            (r) =>
                                r['number'] != null &&
                                r['number'].toString().isNotEmpty,
                          )) ...[
                            const SizedBox(height: 12),
                            const Text(
                              "Switch",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 59, 59, 59),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 12,
                                top: 4,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: greyShade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: data.panelSwitchRows
                                    .where(
                                      (r) =>
                                          r['number'] != null &&
                                          r['number'].toString().isNotEmpty,
                                    )
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) {
                                        final index = entry.key;
                                        final r = entry.value;
                                        final swLabel =
                                            'SW-${(index + 1).toString().padLeft(2, '0')}';
                                        return Text(
                                          "$swLabel,${r['function']},${r['number']}",
                                          style: const TextStyle(fontSize: 14),
                                        );
                                      },
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          // Outputs
                          if (data.relayOutputRows.any(
                            (r) =>
                                r['number'] != null &&
                                r['number'].toString().isNotEmpty,
                          )) ...[
                            const SizedBox(height: 12),
                            const Text(
                              "Output",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 59, 59, 59),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 12,
                                top: 4,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: greyShade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: data.relayOutputRows
                                    .where(
                                      (r) =>
                                          r['number'] != null &&
                                          r['number'].toString().isNotEmpty,
                                    )
                                    .map(
                                      (r) => Text(
                                        "${r['serialNumber']},${r['type']},${r['output']},${r['number']},${r['time']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),

                    // Input Assign
                    if (data.inputAssignPanel != null)
                      _buildSectionCard(
                        title: "${data.inputAssignPanel}",
                        children: data.inputAssignRows
                            .where(
                              (r) =>
                                  r['deviceNo'] != null &&
                                  r['deviceNo'].toString().isNotEmpty,
                            )
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  "${r['sr']},${r['type']},${r['inputState']},${r['outputDevice']},${r['deviceNo']},${r['outputState']},${r['time']},${r['defaultState']}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                    // Scene Assign
                    if (data.sceneAssignRows.any(
                      (r) =>
                          r['number'] != null &&
                          r['number'].toString().isNotEmpty,
                    ))
                      ..._buildSceneSections(data.sceneAssignRows),

                    // Connectivity
                    _buildSectionCard(
                      title: "Connectivity",
                      children: [
                        if (data.connectivityType == 0) ...[
                          _buildDetailRow("Type", "Modbus"),
                          _buildDetailRow("BaudRate", data.modbusBaudRate),
                          _buildDetailRow("DataBit", data.modbusDataBit),
                          _buildDetailRow("StopBit", data.modbusStopBit),
                          _buildDetailRow("Parity", data.modbusParity),
                        ] else ...[
                          _buildDetailRow(
                            "MQTTBrokerAddress",
                            data.mqttBroker,
                          ),
                          _buildDetailRow("UserName", data.mqttUser),
                          _buildDetailRow("Password", data.mqttPassword),
                          if (data.wifiPanel != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              "WiFiInfo-${data.wifiPanel?.split('-').last}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 59, 59, 59),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.only(
                                left: 12,
                                top: 4,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: greyShade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "WiFi-config",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Mode,${data.wifiMode}"),
                                        if (data.wifiMode == 'Mqtt-HA')
                                          Text("MQTTPort,${data.mqttPort}"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "WiFi-parameter",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          (data.wifiMode == 'Mqtt-HA'
                                                  ? data.mqttDevices
                                                  : data.tuyaDevices)
                                              .where(
                                                (r) =>
                                                    r['deviceNo'] != null &&
                                                    r['deviceNo']
                                                        .toString()
                                                        .isNotEmpty,
                                              )
                                              .map(
                                                (r) => Text(
                                                  "${r['parameter']},${r['deviceNo']},${r['dpId']}",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
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
                      // backgroundColor: greyShade300,
                      foregroundColor: headerColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
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
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 30,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfigurationPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
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

  List<Widget> _buildSceneSections(List<Map<String, dynamic>> rows) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in rows) {
      if (row['number'] != null && row['number'].toString().isNotEmpty) {
        final type = row['type'] as String;
        grouped.putIfAbsent(type, () => []).add(row);
      }
    }
    return grouped.entries
        .map(
          (e) => _buildSectionCard(
            title: e.key,
            children: e.value
                .map(
                  (r) => Text(
                    "${r['sr_no']},${r['output']},${r['number']},${r['state']},${r['temp']},${r['panel_no']}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 56, 54, 54),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: headerColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

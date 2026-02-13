import 'package:flutter/material.dart';
import 'panel_switch_assign_page.dart';

class DeviceSetupPage extends StatelessWidget {
  const DeviceSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Setup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 72, color: Colors.deepPurple),
              const SizedBox(height: 18),
              const Text('This is the next step in the configuration flow.', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanelSwitchAssignPage()));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                  child: Text('Next: Panel Assign', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

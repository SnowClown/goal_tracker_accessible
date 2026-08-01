import 'package:flutter/material.dart';
import '../../shared/interface_config.dart';

/// Lets the user toggle between Global controls and Dynamically
/// displayed controls for acting on Goals, Tasks, and Steps. The
/// setting is app-wide (shared across all three screens).
class InterfaceConfigurationScreen extends StatefulWidget {
  const InterfaceConfigurationScreen({super.key});

  @override
  State<InterfaceConfigurationScreen> createState() => _InterfaceConfigurationScreenState();
}

class _InterfaceConfigurationScreenState extends State<InterfaceConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    final isGlobal = interfaceConfig.useGlobalControls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Interface Configuration', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item action controls',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Semantics(
              toggled: isGlobal,
              label: isGlobal
                  ? 'Global controls. On. Double tap to switch to dynamically displayed controls.'
                  : 'Global controls. Off, using dynamically displayed controls. Double tap to switch to global controls.',
              excludeSemantics: true,
              child: SwitchListTile(
                value: isGlobal,
                activeColor: Colors.greenAccent,
                tileColor: Colors.grey[900],
                onChanged: (value) {
                  setState(() => interfaceConfig.setUseGlobalControls(value));
                },
                title: const Text('Global controls', style: TextStyle(color: Colors.white, fontSize: 18)),
                subtitle: Text(
                  isGlobal
                      ? 'Action buttons at the top of each screen; select items with checkboxes.'
                      : 'Dynamically displayed controls: tap More on an item to see its actions.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/settings_service.dart';
import '../services/sms_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;

  const HomeScreen({super.key, required this.settingsService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _smsService = SmsService();

  Future<void> _ensurePermissions() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
  }

  Future<void> _sendCommand(String commandText, String commandName) async {
    final phone = widget.settingsService.phoneNumber;
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a phone number in settings first.'),
        ),
      );
      return;
    }

    await _ensurePermissions();

    if (Platform.isAndroid) {
      final status = await Permission.sms.status;
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission is required.')),
        );
        return;
      }
    }

    final success = await _smsService.sendSms(
      phoneNumber: phone,
      message: commandText,
      subscriptionId: widget.settingsService.subscriptionId,
    );

    if (!mounted) return;

    if (Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$commandName command sent!'
                : 'Failed to send $commandName command.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relay Control'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SettingsScreen(settingsService: widget.settingsService),
                  ),
                );
                setState(() {});
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Relay 1'),
              Tab(text: 'Relay 2'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommandsTab(
              restartText: widget.settingsService.restartText,
              stopText: widget.settingsService.swapCommands1
                  ? widget.settingsService.startText
                  : widget.settingsService.stopText,
              startText: widget.settingsService.swapCommands1
                  ? widget.settingsService.stopText
                  : widget.settingsService.startText,
            ),
            _buildCommandsTab(
              restartText: widget.settingsService.restartText2,
              stopText: widget.settingsService.swapCommands2
                  ? widget.settingsService.startText2
                  : widget.settingsService.stopText2,
              startText: widget.settingsService.swapCommands2
                  ? widget.settingsService.stopText2
                  : widget.settingsService.startText2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandsTab({
    required String restartText,
    required String stopText,
    required String startText,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommandButton(
            label: 'RESTART',
            color: Colors.orange,
            icon: Icons.refresh,
            onPressed: () => _sendCommand(restartText, 'Restart'),
          ),
          const SizedBox(height: 24),
          _CommandButton(
            label: 'STOP',
            color: Colors.red,
            icon: Icons.stop,
            onPressed: () => _sendCommand(stopText, 'Stop'),
          ),
          const SizedBox(height: 24),
          _CommandButton(
            label: 'START',
            color: Colors.green,
            icon: Icons.play_arrow,
            onPressed: () => _sendCommand(startText, 'Start'),
          ),
        ],
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _CommandButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 36),
        label: Text(label, style: const TextStyle(fontSize: 28)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

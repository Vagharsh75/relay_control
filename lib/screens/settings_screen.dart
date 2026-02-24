import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/sim_card_info.dart';
import '../services/settings_service.dart';
import '../services/sms_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsScreen({super.key, required this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _adminPasswordController;
  late final TextEditingController _user1PhoneController;
  late final TextEditingController _user2PhoneController;
  late final TextEditingController _user3PhoneController;
  // Relay 1 controllers
  late final TextEditingController _restartController;
  late final TextEditingController _stopController;
  late final TextEditingController _startController;
  // Relay 2 controllers
  late final TextEditingController _restartController2;
  late final TextEditingController _stopController2;
  late final TextEditingController _startController2;

  final _smsService = SmsService();
  List<SimCardInfo> _sims = [];
  int _selectedSubscriptionId = -1;
  bool _loadingSims = false;
  bool _swapCommands1 = false;
  bool _swapCommands2 = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settingsService;
    _phoneController = TextEditingController(text: s.phoneNumber);
    _adminPasswordController = TextEditingController(text: s.adminPassword);
    _user1PhoneController = TextEditingController(text: s.user1Phone);
    _user2PhoneController = TextEditingController(text: s.user2Phone);
    _user3PhoneController = TextEditingController(text: s.user3Phone);
    _restartController = TextEditingController(text: s.restartText);
    _stopController = TextEditingController(text: s.stopText);
    _startController = TextEditingController(text: s.startText);
    _restartController2 = TextEditingController(text: s.restartText2);
    _stopController2 = TextEditingController(text: s.stopText2);
    _startController2 = TextEditingController(text: s.startText2);
    _selectedSubscriptionId = s.subscriptionId;
    _swapCommands1 = s.swapCommands1;
    _swapCommands2 = s.swapCommands2;

    if (Platform.isAndroid) {
      _loadSims();
    }
  }

  Future<void> _loadSims() async {
    setState(() => _loadingSims = true);

    final phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      await Permission.phone.request();
    }

    final sims = await _smsService.getAvailableSims();
    setState(() {
      _sims = sims;
      _loadingSims = false;
    });
  }

  Future<void> _saveMainCommands() async {
    final s = widget.settingsService;
    await s.setSubscriptionId(_selectedSubscriptionId);
    await s.setRestartText(_restartController.text.trim());
    await s.setStopText(_stopController.text.trim());
    await s.setStartText(_startController.text.trim());
    await s.setRestartText2(_restartController2.text.trim());
    await s.setStopText2(_stopController2.text.trim());
    await s.setStartText2(_startController2.text.trim());
    await s.setSwapCommands1(_swapCommands1);
    await s.setSwapCommands2(_swapCommands2);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Main commands saved!')),
    );
    Navigator.pop(context);
  }

  Future<void> _sendUserPhoneSms(int userNumber, String userPhone) async {
    final s = widget.settingsService;
    final devicePhone = _phoneController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (devicePhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter device phone number')),
      );
      return;
    }
    if (userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter User$userNumber phone number')),
      );
      return;
    }

    final phoneWithout0 = userPhone.startsWith('0') ? userPhone.substring(1) : userPhone;
    final message = '*$password*#$userNumber$phoneWithout0#';
    final success = await _smsService.sendSms(
      phoneNumber: devicePhone,
      message: message,
      subscriptionId: s.subscriptionId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'SMS sent: $message'
            : 'Failed to send SMS'),
      ),
    );

    if (!success) return;

    // Listen for incoming SMS from device phone for up to 30 seconds
    StreamSubscription<Map<String, String>>? subscription;
    Timer? timeout;
    bool responded = false;

    timeout = Timer(const Duration(seconds: 30), () {
      if (!responded) {
        subscription?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No response from device (timeout)')),
          );
        }
      }
    });

    subscription = _smsService.onSmsReceived.listen((sms) {
      final sender = sms['sender'] ?? '';
      if (sender.contains(devicePhone) || devicePhone.contains(sender)) {
        responded = true;
        timeout?.cancel();
        subscription?.cancel();
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('User$userNumber Phone'),
            content: Text(sms['body'] ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _sendDeviceStatus() async {
    final s = widget.settingsService;
    final devicePhone = _phoneController.text.trim();

    if (devicePhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter device phone number')),
      );
      return;
    }

    // Request SMS permission if needed
    final smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      await Permission.sms.request();
    }

    // Set up listener BEFORE sending SMS to avoid missing the response
    StreamSubscription<Map<String, String>>? subscription;
    Timer? timeout;
    bool responded = false;

    timeout = Timer(const Duration(seconds: 30), () {
      if (!responded) {
        subscription?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No response from device (timeout)')),
          );
        }
      }
    });

    subscription = _smsService.onSmsReceived.listen((sms) {
      final sender = sms['sender'] ?? '';
      if (sender.contains(devicePhone) || devicePhone.contains(sender)) {
        responded = true;
        timeout?.cancel();
        subscription?.cancel();
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Device Status'),
            content: Text(sms['body'] ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    final success = await _smsService.sendSms(
      phoneNumber: devicePhone,
      message: 'STA',
      subscriptionId: s.subscriptionId,
    );

    if (!success) {
      timeout.cancel();
      subscription.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send SMS')),
      );
      return;
    }
  }

  Future<void> _saveDeviceConfig() async {
    final s = widget.settingsService;
    await s.setPhoneNumber(_phoneController.text.trim());
    await s.setAdminPassword(_adminPasswordController.text.trim());
    await s.setUser1Phone(_user1PhoneController.text.trim());
    await s.setUser2Phone(_user2PhoneController.text.trim());
    await s.setUser3Phone(_user3PhoneController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device configuration saved!')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _adminPasswordController.dispose();
    _user1PhoneController.dispose();
    _user2PhoneController.dispose();
    _user3PhoneController.dispose();
    _restartController.dispose();
    _stopController.dispose();
    _startController.dispose();
    _restartController2.dispose();
    _stopController2.dispose();
    _startController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Main commands'),
              Tab(text: 'Device configuration'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMainCommandsTab(),
            _buildDeviceConfigTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCommandsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (Platform.isAndroid) ...[
          if (_loadingSims)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<int>(
              initialValue: _selectedSubscriptionId,
              decoration: const InputDecoration(
                labelText: 'SIM Card',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sim_card),
              ),
              items: [
                const DropdownMenuItem(
                  value: -1,
                  child: Text('Default SIM'),
                ),
                ..._sims.map(
                  (sim) => DropdownMenuItem(
                    value: sim.subscriptionId,
                    child: Text(sim.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedSubscriptionId = value ?? -1);
              },
            ),
          const SizedBox(height: 24),
        ],
        const Text(
          'SMS Command Texts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLiftColumn(
              'Relay 1', _restartController, _stopController, _startController,
              swapValue: _swapCommands1,
              onSwapChanged: (v) => setState(() => _swapCommands1 = v ?? false),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildLiftColumn(
              'Relay 2', _restartController2, _stopController2, _startController2,
              swapValue: _swapCommands2,
              onSwapChanged: (v) => setState(() => _swapCommands2 = v ?? false),
            )),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saveMainCommands,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Save', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          color: Color(0xFFFFF3E0),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If Relay connect to NC connector, check Swap Stop/Start checkbox',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiftColumn(
    String title,
    TextEditingController restartCtrl,
    TextEditingController stopCtrl,
    TextEditingController startCtrl, {
    required bool swapValue,
    required ValueChanged<bool?> onSwapChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: restartCtrl,
          decoration: const InputDecoration(
            labelText: 'Restart',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.refresh, color: Colors.orange),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: stopCtrl,
          decoration: const InputDecoration(
            labelText: 'Stop',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.stop, color: Colors.red),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: startCtrl,
          decoration: const InputDecoration(
            labelText: 'Start',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.play_arrow, color: Colors.green),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Checkbox(value: swapValue, onChanged: onSwapChanged),
            const Expanded(child: Text('Swap Stop/Start', style: TextStyle(fontSize: 13))),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordController,
          decoration: const InputDecoration(
            labelText: 'Admin Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saveDeviceConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Save', style: TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _user1PhoneController,
                decoration: const InputDecoration(
                  labelText: 'User1 Phone',
                  hintText: '0XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _sendUserPhoneSms(1, _user1PhoneController.text.trim()),
              child: const Text('Set'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _user2PhoneController,
                decoration: const InputDecoration(
                  labelText: 'User2 Phone',
                  hintText: '0XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _sendUserPhoneSms(2, _user2PhoneController.text.trim()),
              child: const Text('Set'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _user3PhoneController,
                decoration: const InputDecoration(
                  labelText: 'User3 Phone',
                  hintText: '0XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _sendUserPhoneSms(3, _user3PhoneController.text.trim()),
              child: const Text('Set'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _sendDeviceStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
            child: const Text('Device Status', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

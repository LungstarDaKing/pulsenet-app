import 'package:flutter/material.dart';
import 'package:pulsenet/services/storage_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlockSuccess;

  const AppLockScreen({super.key, required this.onUnlockSuccess});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorText = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkPin() async {
    final pin = _pinController.text;
    if (pin.isEmpty) {
      setState(() {
        _errorText = 'Please enter your PIN';
      });
      return;
    }

    final isCorrect = await StorageService().checkAppLockPin(pin);
    if (isCorrect) {
      // Clear the field and notify success
      _pinController.clear();
      if (mounted) {
        widget.onUnlockSuccess();
      }
    } else {
      setState(() {
        _errorText = 'Incorrect PIN';
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/pulsenet_logo.png',
                height: 80,
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter your PIN to unlock PulseNet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
              if (_errorText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorText,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _checkPin,
                  child: const Text('Unlock'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Option to disable PIN (could go to settings)
                  // For now, just clear it (in real app, you'd confirm)
                  StorageService().clearAppLock();
                  if (mounted) {
                    widget.onUnlockSuccess();
                  }
                },
                child: const Text(
                  'Forgot PIN? Disable lock',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
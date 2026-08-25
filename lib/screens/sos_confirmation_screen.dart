import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pulsenet/services/sos_service.dart';

class SosConfirmationScreen extends StatefulWidget {
  const SosConfirmationScreen({super.key});

  @override
  State<SosConfirmationScreen> createState() => _SosConfirmationScreenState();
}

class _SosConfirmationScreenState extends State<SosConfirmationScreen> {
  // Countdown states
  bool _isCountingDown = true;
  int _countdown = 5;
  Timer? _countdownTimer;

  // Post-countdown wait state
  bool _isWaiting = false;
  int _waitSeconds = 10;
  Timer? _waitTimer;

  // SOS service
  final SosService _sosService = SosService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        }

        if (_countdown == 0) {
          _countdownTimer?.cancel();
          _startWaiting();
        }
      });
    });
  }

  void _startWaiting() {
    setState(() {
      _isCountingDown = false;
      _isWaiting = true;
      _waitSeconds = 10;
    });

    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_waitSeconds > 0) {
          _waitSeconds--;
        }

        if (_waitSeconds == 0) {
          _waitTimer?.cancel();
          _autoPlaceEmergencyCall();
        }
      });
    });
  }

  void _cancelSos() {
    _countdownTimer?.cancel();
    _waitTimer?.cancel();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _callNow() {
    _countdownTimer?.cancel();
    _waitTimer?.cancel();
    _placeEmergencyCallNow();
  }

  Future<void> _placeEmergencyCallNow() async {
    try {
      await _sosService.triggerSos(); // Prepare payload (location, medical info)
      await _sosService.dialEmergencyNumber('112'); // Universal emergency number

      // Navigate back to dashboard after call is placed
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place emergency call: $e')),
        );
      }
      _cancelSos();
    }
  }

  Future<void> _autoPlaceEmergencyCall() async {
    // Auto-place the call after waiting period
    await _placeEmergencyCallNow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 120,
              color: Colors.red,
            ),
            const SizedBox(height: 32),
            const Text(
              'EMERGENCY SOS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            if (_isCountingDown)
              Text(
                'Emergency call in $_countdown...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              )
            else if (_isWaiting)
              Text(
                'Calling automatically in $_waitSeconds...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 32),
            if (_isCountingDown)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _cancelSos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: _callNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Call Now'),
                  ),
                ],
              )
            else if (_isWaiting)
              const Text(
                'Stand by for emergency services...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
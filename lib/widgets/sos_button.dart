import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sos_service.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  // Countdown states
  bool _isCountingDown = false;
  int _countdown = 5;
  Timer? _countdownTimer;

  // Post-countdown wait state
  bool _isWaitingForConfirmation = false;
  int _waitSeconds = 10;
  Timer? _waitTimer;

  // SOS service
  final SosService _sosService = SosService();

  void _startSosFlow() {
    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _startCountdown();
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
          _startConfirmationWait();
        }
      });
    });
  }

  void _startConfirmationWait() {
    setState(() {
      _isCountingDown = false;
      _isWaitingForConfirmation = true;
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
    setState(() {
      _isCountingDown = false;
      _isWaitingForConfirmation = false;
    });
  }

  Future<void> _placeEmergencyCallImmediately() async {
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
    await _placeEmergencyCallImmediately();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _waitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: _isCountingDown || _isWaitingForConfirmation ? null : _startSosFlow,
          child: const Icon(Icons.warning_amber_rounded),
        ),
        if (_isCountingDown || _isWaitingForConfirmation)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: _isCountingDown
                    ? Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        'Call in $_waitSeconds...\nCancel or Call Now',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
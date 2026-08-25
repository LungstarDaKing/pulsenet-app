import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pulsenet/services/bluetooth_heart_rate_service.dart';
import 'package:pulsenet/services/camera_pulse_service.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  final BluetoothHeartRateService _bluetoothService = BluetoothHeartRateService();
  final CameraPulseService _cameraService = CameraPulseService();
  bool _isScanning = false;
  bool _isConnected = false;
  int? _heartRate;
  bool _isUsingDevice = false;
  String _statusMessage = 'Ready to connect';
  List<dynamic> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<double>? _cameraBpmSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _initCamera();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _bluetoothService.dispose();
    _cameraBpmSubscription?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    final isSupported = await _bluetoothService.isBluetoothAvailable();
    if (!isSupported) {
      setState(() {
        _statusMessage = 'Bluetooth not supported on this device';
      });
      return;
    }

    final isOn = await _bluetoothService.isBluetoothOn();
    if (!isOn) {
      setState(() {
        _statusMessage = 'Bluetooth is turned off';
      });
      return;
    }

    // Start listening to heart rate updates
    _bluetoothService.heartRateStream.listen((hr) {
      if (hr != null && mounted) {
        setState(() {
          _heartRate = hr;
          _isUsingDevice = true;
          _statusMessage = 'Heart rate: $hr bpm';
        });
      }
    });
  }

  Future<void> _initCamera() async {
    // Listen for BPM updates from camera
    _cameraBpmSubscription = _cameraService.bpmStream.listen((bpm) {
      if (mounted && _cameraService.isMeasuring) {
        setState(() {
          _heartRate = bpm.round();
          _isUsingDevice = true;
          _statusMessage = 'Measuring... ${_cameraService.remainingTime}s remaining';
        });
      }
    });
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for devices...';
      _discoveredDevices = []; // Clear previous results
    });

    try {
      // Scan for devices for 13 seconds (in the middle of 10-15 second range)
      final devices = await _bluetoothService.scanForDevices(
        duration: const Duration(seconds: 13),
        onDeviceFound: (device) {
          // Update UI when a new device is discovered
          if (mounted) {
            setState(() {
              // Check if we already have this device
              final existingIndex = _discoveredDevices.indexWhere(
                (d) => (d as dynamic).remoteId == device.remoteId,
              );
              if (existingIndex == -1) {
                // New device, add to list
                _discoveredDevices.add(device);
              }
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      if (devices.isEmpty) {
        setState(() {
          _statusMessage = 'No devices found';
        });
        return;
      }

      // For demo, connect to the first device
      final success = await _bluetoothService.connectToDevice(devices.first);
      if (!mounted) return;

      setState(() {
        _isConnected = success;
        _statusMessage = success
            ? 'Connected to ${devices.first.platformName.isNotEmpty ? devices.first.platformName : 'Unknown Device'}'
            : 'Connection failed';
        if (success) {
          _isUsingDevice = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _startCameraMeasurement() async {
    setState(() {
      _statusMessage = 'Place fingertip on camera lens...';
    });

    bool success = await _cameraService.startMeasurement();
    if (!success) {
      setState(() {
        _statusMessage = 'Failed to initialize camera';
      });
      return;
    }

    setState(() {
      _isUsingDevice = false;
      _statusMessage = 'Measuring... ${_cameraService.remainingTime}s remaining';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart rate display
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_heartRate != null ? Colors.red : Colors.grey, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _heartRate == null
                      ? const Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.white54,
                        )
                      : Text(
                          '$_heartRate',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            // Show discovered devices
            if (_isScanning || _discoveredDevices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return ListTile(
                      leading: const Icon(Icons.device_hub, color: Colors.blue),
                      title: Text(
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(device.remoteId.toString()),
                      trailing: ElevatedButton(
                        onPressed: _isConnected ? null : () async {
                          // Connect to this specific device
                          setState(() {
                            _isScanning = true;
                            _statusMessage = 'Connecting...';
                          });
                          try {
                            final success = await _bluetoothService.connectToDevice(device);
                            if (!mounted) return;
                            setState(() {
                              _isScanning = false;
                              _isConnected = success;
                            });
                            if (success) {
                              _isUsingDevice = true;
                            }
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _isScanning = false;
                              _statusMessage = 'Connection error: $e';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConnected
                              ? Colors.grey
                              : (_isScanning ? Colors.blue : Colors.green),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isConnected
                            ? 'Connected'
                            : (_isScanning ? 'Connecting...' : 'Connect')),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? null : _connectToDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isConnected ? 'Disconnect' : 'Connect Device'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isUsingDevice ? null : _startCameraMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUsingDevice ? Colors.orange : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isUsingDevice ? 'Stop Measurement' : 'Camera Measurement'),
                ),
              ],
            ),
            if (_cameraService.isMeasuring)
              Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _cameraService.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_cameraService.remainingTime}s remaining',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
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
}
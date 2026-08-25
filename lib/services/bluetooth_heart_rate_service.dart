import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothHeartRateService {
  // Heart rate measurement characteristic UUID (standard Heart Rate Measurement characteristic)
  static const String heartRateMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';

  // Heart Rate Service UUID
  static const String heartRateServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';

  // Stream controller for heart rate updates
  final _heartRateController = StreamController<int?>.broadcast();

  Stream<int?> get heartRateStream => _heartRateController.stream;

  BluetoothHeartRateService();

  Future<bool> isBluetoothAvailable() async {
    // For desktop platforms, we'll assume it's available
    // For mobile, we'd check properly
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    // For now, we'll assume it's available on mobile too
    // A more complete implementation would check actual availability
    return true;
  }

  Future<bool> isBluetoothOn() async {
    // Check if Bluetooth is available and turned on
    if (!Platform.isAndroid && !Platform.isIOS) {
      // On desktop platforms, we can't reliably check Bluetooth state with FlutterBluePlus
      // Return true to allow the app to proceed (user can manually enable BT if needed)
      return true;
    }

    // For mobile platforms, check actual Bluetooth state
    try {
      final state = await FlutterBluePlus.adapterState.firstWhere(
        (state) => state == BluetoothAdapterState.on,
        orElse: () => BluetoothAdapterState.off,
      );
      return state == BluetoothAdapterState.on;
    } catch (e) {
      // If we can't determine the state, assume it's on to avoid blocking the UI
      return true;
    }
  }

  Future<bool> requestBluetoothEnable() async {
    if (!await isBluetoothAvailable()) return false;
    if (await isBluetoothOn()) return true;

    // On desktop, we can't really request enabling Bluetooth from the app
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Can't request BT enable on desktop
    }

    // For mobile platforms, we'll return false as we can't programmatically enable Bluetooth
    // In a real app, we would guide the user to enable it manually
    return false;
  }

  /// Scan for Bluetooth devices for the specified duration
  /// Returns a list of discovered devices, updating in real-time via callbacks
  Future<List<BluetoothDevice>> scanForDevices({
    required Duration duration,
    Function(BluetoothDevice)? onDeviceFound,
  }) async {
    // Check if we're on a supported platform
    if (!Platform.isAndroid && !Platform.isIOS) {
      // For desktop platforms (Windows, macOS, Linux), BLE scanning may not work as expected
      // with flutter_blue_plus. For now, we'll return an empty list and note this limitation.
      //
      // NOTE: NFC and USB are not used for fitness/health devices like heart rate monitors
      // because:
      // - NFC is designed for short-range, tap-to-pair interactions (like payments), not continuous data streaming
      // - USB requires physical tethering which defeats the purpose of wearable fitness devices
      // - Bluetooth LE (BLE) is the standard protocol for wearable health/fitness devices
      //   (heart rate straps, watches, bands) as it provides low-power, continuous connectivity
      return [];
    }

    // Ensure Bluetooth is turned on
    if (!await isBluetoothOn()) {
      bool enabled = await requestBluetoothEnable();
      if (!enabled) {
        throw Exception('Failed to enable Bluetooth');
      }
    }

    final List<BluetoothDevice> discoveredDevices = [];
    final Set<String> deviceIds = {}; // Track discovered device IDs to avoid duplicates

    // Start scanning
    FlutterBluePlus.startScan(timeout: duration);

    // Listen for scan results
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        // Skip if we've already seen this device
        if (deviceIds.contains(result.device.remoteId.toString())) {
          continue;
        }

        // Add to our tracking set
        deviceIds.add(result.device.remoteId.toString());

        // Add to discovered devices list
        discoveredDevices.add(result.device);

        // Call the callback if provided
        if (onDeviceFound != null) {
          onDeviceFound(result.device);
        }
      }
    });

    // Wait for the scan duration
    await Future.delayed(duration);

    // Stop scanning
    await subscription.cancel();

    return discoveredDevices;
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    // For desktop platforms, BLE client mode may not be fully supported
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    try {
      // Connect to the device
      await device.connect();

      // Discover services
      await device.discoverServices();

      // Find the Heart Rate Service
      // Note: In newer flutter_blue_plus, services is a Stream<List<BluetoothService>>
      final List<BluetoothService> services = await device.services.first;
      BluetoothService? hrService;
      for (final service in services) {
        if (service.uuid.toString() == heartRateServiceUuid) {
          hrService = service;
          break;
        }
      }

      if (hrService == null) {
        await device.disconnect();
        return false;
      }

      // Find the Heart Rate Measurement Characteristic
      // Note: In newer flutter_blue_plus, characteristics is a Stream<BluetoothCharacteristic>
      final List<BluetoothCharacteristic> characteristicList = await hrService.characteristics.toList();
      BluetoothCharacteristic? hrChar;
      for (final characteristic in characteristicList) {
        if (characteristic.uuid.toString() == heartRateMeasurementUuid) {
          hrChar = characteristic;
          break;
        }
      }

      if (hrChar == null) {
        await device.disconnect();
        return false;
      }

      // Listen for heart rate measurements
      // Note: In newer flutter_blue_plus, value is deprecated, use lastValueStream
      hrChar.lastValueStream.listen((value) {
        // Parse the heart rate value from the characteristic value
        // Heart Rate Measurement format:
        // Flags (1 byte) + Heart Rate Value (1 or 2 bytes) + ... (optional fields)
        if (value.length >= 2) {
          bool isUint16 = (value[0] & 0x01) != 0; // Check if HR value is 16-bit
          int hrValue = isUint16
              ? (value[1] | (value[2] << 8))     // 16-bit value
              : value[1];                        // 8-bit value

          _heartRateController.add(hrValue);
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    // Disconnect implementation would go here
    // For now, we'll leave it empty as we don't track connections
    // In a full implementation, we'd track connected devices and disconnect them
  }

  bool get isConnected => false; // Simplified for now - would track actual connection state

  void dispose() {
    _heartRateController.close();
  }
}
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';

class SosService {
  final StorageService _storage = StorageService();

  // Emergency numbers for South Africa (can be made configurable)
  static const Map<String, String> emergencyNumbers = {
    'police': '10111',
    'ambulance': '10177',
    'general': '112', // Universal emergency number
  };

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // app to enable the location services.
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> prepareSosPayload() async {
    final position = await _getCurrentLocation();
    final medicalProfile = await _storage.getMedicalProfile();
    final locationSharingEnabled = await _storage.getLocationSharingEnabled();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'location': locationSharingEnabled && position != null
          ? {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'timestamp': position.timestamp.toIso8601String(),
            }
          : null,
      'medicalProfile': medicalProfile,
    };
  }

  Future<void> triggerSos() async {
    // In a real app, we might log the SOS event or trigger other actions.
    // For now, we just prepare the payload (which gets location and medical info)
    // and the UI will handle showing the confirmation screen and making the call.
    await prepareSosPayload();
  }

  Future<void> dialEmergencyNumber(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    await launchUrl(launchUri);
  }
}
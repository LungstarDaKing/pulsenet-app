import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  static const String _medicalProfileKey = 'medical_profile';
  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _locationSharingEnabledKey = 'location_sharing_enabled';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _appLockPinKey = 'app_lock_pin';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> saveMedicalProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medicalProfileKey, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> getMedicalProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_medicalProfileKey);
    return json != null ? jsonDecode(json) : null;
  }

  Future<void> saveEmergencyContacts(List<Map<String, dynamic>> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emergencyContactsKey, jsonEncode(contacts));
  }

  Future<List<Map<String, dynamic>>?> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_emergencyContactsKey);
    return json != null ? jsonDecode(json) : null;
  }

  Future<void> setLocationSharingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationSharingEnabledKey, enabled);
  }

  Future<bool> getLocationSharingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationSharingEnabledKey) ?? false;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  Future<bool> getAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  Future<void> setAppLockPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    await prefs.setString(_appLockPinKey, hashedPin);
  }

  Future<bool> checkAppLockPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedHash = prefs.getString(_appLockPinKey);
    if (storedHash == null) return false;
    final String inputHash = sha256.convert(utf8.encode(pin)).toString();
    return storedHash == inputHash;
  }

  Future<void> clearAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appLockPinKey);
    await prefs.setBool(_appLockEnabledKey, false);
  }

  // Generic getter and setter for boolean values
  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
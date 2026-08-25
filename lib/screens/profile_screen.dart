import 'package:flutter/material.dart';
import 'package:pulsenet/services/storage_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StorageService _storageService;
  bool _isLoading = true;
  Map<String, dynamic> _medicalProfile = {};
  bool _locationSharingEnabled = false;
  bool _appLockEnabled = false;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final StorageService ss = context.read<StorageService>();
    _storageService = ss;
    final Map<String, dynamic>? profile = await ss.getMedicalProfile();
    final bool locationSharing = await ss.getLocationSharingEnabled();
    final bool appLockEnabled = await ss.getAppLockEnabled();

    if (mounted) {
      setState(() {
        _medicalProfile = profile ?? {};
        _nameController.text = _medicalProfile['name'] ?? '';
        _ageController.text = _medicalProfile['age']?.toString() ?? '';
        _bloodTypeController.text = _medicalProfile['bloodType'] ?? '';
        _allergiesController.text = _medicalProfile['allergies'] ?? '';
        _conditionsController.text = _medicalProfile['conditions'] ?? '';
        _medicationsController.text = _medicalProfile['medications'] ?? '';
        _locationSharingEnabled = locationSharing;
        _appLockEnabled = appLockEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final Map<String, dynamic> profile = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 0,
      'bloodType': _bloodTypeController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'conditions': _conditionsController.text.trim(),
      'medications': _medicationsController.text.trim(),
    };
    await _storageService.saveMedicalProfile(profile);
    await _storageService.setLocationSharingEnabled(_locationSharingEnabled);
    await _storageService.setAppLockEnabled(_appLockEnabled);
    if (mounted) {
      setState(() {
        _medicalProfile = profile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_locationSharingEnabled ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() {
                _locationSharingEnabled = !_locationSharingEnabled;
              });
            },
            tooltip: _locationSharingEnabled ? 'Disable location sharing' : 'Enable location sharing',
          ),
          IconButton(
            icon: Icon(_appLockEnabled ? Icons.lock : Icons.lock_open),
            onPressed: () {
              setState(() {
                _appLockEnabled = !_appLockEnabled;
              });
            },
            tooltip: _appLockEnabled ? 'Disable app lock' : 'Enable app lock',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile picture placeholder
                  Center(
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form fields
                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Age',
                    controller: _ageController,
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Blood Type',
                    controller: _bloodTypeController,
                    icon: Icons.favorite,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Allergies',
                    controller: _allergiesController,
                    icon: Icons.health_and_safety,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Medical Conditions',
                    controller: _conditionsController,
                    icon: Icons.medical_services,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Medications',
                    controller: _medicationsController,
                    icon: Icons.medication,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  // Save button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _saveProfile,
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Divider
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  // Privacy info
                  const Text(
                    'Privacy Notice',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your medical profile, emergency contacts, and location sharing preferences are stored only on this device. '
                    'No data is transmitted to any server without your explicit consent.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Onboarding info (re-readable)
                  const Text(
                    'About PulseNet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PulseNet is an emergency health and safety app designed to provide quick access to emergency services, '
                    'first aid guidance, vital monitoring, and emergency contacts. It works entirely offline by default.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.red),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
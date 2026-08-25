import 'package:flutter/material.dart';
import 'package:pulsenet/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late StorageService _storageService;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _editContactId; // Index of contact being edited

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final StorageService ss = context.read<StorageService>();
    _storageService = ss;
    final List<dynamic>? contacts = await ss.getEmergencyContacts();
    if (mounted) {
      setState(() {
        _contacts = (contacts ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContacts() async {
    await _storageService.saveEmergencyContacts(_contacts);
  }

  void _addOrUpdateContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and phone number')),
      );
      return;
    }
    final newContact = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'phone': phone,
    };
    if (_editContactId == null) {
      // Adding new
      setState(() {
        _contacts.add(newContact);
      });
    } else {
      // Updating existing
      final index = _contacts.indexWhere((c) => c['id'] == _editContactId);
      if (index != -1) {
        setState(() {
          _contacts[index] = newContact;
        });
      }
    }
    _saveContacts();
    _clearForm();
    Navigator.of(context).pop(); // Close dialog
  }

  void _showAddEditDialog({Map<String, dynamic>? contact}) {
    if (contact != null) {
      _editContactId = contact['id'];
      _nameController.text = contact['name'];
      _phoneController.text = contact['phone'];
    } else {
      _editContactId = null;
      _nameController.clear();
      _phoneController.clear();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editContactId == null ? 'Add Emergency Contact' : 'Edit Contact'),
        backgroundColor: Colors.grey[900],
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g., Mom, Doctor)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.red,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                ),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: _addOrUpdateContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _editContactId = null;
  }

  Future<void> _deleteContact(int index) async {
    final String id = _contacts[index]['id'];
    setState(() {
      _contacts.removeAt(index);
    });
    await _saveContacts();
    // If we were editing this item, cancel edit
    if (_editContactId == id) {
      _clearForm();
    }
  }

  Future<void> _callContact(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        centerTitle: true,
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEditDialog,
            tooltip: 'Add new contact',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.contacts,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No emergency contacts added yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showAddEditDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add First Contact'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Dismissible(
                      key: Key(contact['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Delete Contact'),
                            content: Text('Delete "${contact['name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) => _deleteContact(index),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.red,
                          size: 32,
                        ),
                        title: Text(
                          contact['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        subtitle: Text(
                          contact['phone'],
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () => _callContact(contact['phone']),
                        ),
                        onTap: () => _showAddEditDialog(contact: contact),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
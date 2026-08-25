import 'package:flutter/material.dart';
import 'package:pulsenet/widgets/sos_button.dart';
import 'package:pulsenet/screens/vitals_screen.dart';
import 'package:pulsenet/screens/first_aid_screen.dart';
import 'package:pulsenet/screens/contacts_screen.dart';
import 'package:pulsenet/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PulseNet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about the app
              showAboutDialog(
                context: context,
                applicationName: 'PulseNet',
                applicationVersion: '1.0.0',
                applicationIcon: const Image(
                  image: AssetImage('assets/images/pulsenet_logo.png'),
                  height: 50,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardTile(
              context,
              title: 'Vitals',
              icon: Icons.favorite,
              color: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VitalsScreen()),
                );
              },
            ),
            _buildDashboardTile(
              context,
              title: 'First Aid',
              icon: Icons.medical_services,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FirstAidScreen()),
                );
              },
            ),
            _buildDashboardTile(
              context,
              title: 'Contacts',
              icon: Icons.contacts,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactsScreen()),
                );
              },
            ),
            _buildDashboardTile(
              context,
              title: 'Profile',
              icon: Icons.person,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: const SosButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
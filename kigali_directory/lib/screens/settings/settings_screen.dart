import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = false;
  bool _locationNotifs = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifs = prefs.getBool('notifs') ?? false;
      _locationNotifs = prefs.getBool('locationNotifs') ?? false;
    });
  }

  Future<void> _toggleNotifs(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifs', v);
    setState(() => _notifs = v);
  }

  Future<void> _toggleLocationNotifs(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationNotifs', v);
    setState(() => _locationNotifs = v);
  }

  @override
  Widget build(BuildContext ctx) {
    final auth = ctx.watch<AuthProvider>();
    final user = auth.user;
    final profile = auth.profile;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2D42),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color.fromARGB(51, 245, 166, 35),
                    child: Text(
                      (profile?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFF5A623), fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: user?.emailVerified == true
                                ? const Color.fromARGB(38, 76, 175, 80)
                                : const Color.fromARGB(38, 255, 152, 0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.emailVerified == true ? '✓ Verified' : '⚠ Unverified',
                            style: TextStyle(
                              color: user?.emailVerified == true ? Colors.green : Colors.orange,
                              fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('NOTIFICATIONS',
              style: TextStyle(color: Colors.white38, fontSize: 11,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            _toggle('Push Notifications', 'Receive app notifications', _notifs, _toggleNotifs),
            const SizedBox(height: 10),
            _toggle('Location-Based Alerts', 'Get notified about nearby services',
              _locationNotifs, _toggleLocationNotifs),
            const SizedBox(height: 24),
            const Text('ACCOUNT',
              style: TextStyle(color: Colors.white38, fontSize: 11,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            _tile(Icons.info_outline, 'App Version', '1.0.0'),
            const SizedBox(height: 10),
            _tile(Icons.person_outline, 'UID', user?.uid.substring(0, 12) ?? 'N/A'),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(String title, String subtitle, bool val, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFF5A623),
            activeTrackColor: const Color(0xFFF5A623).withAlpha(90),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
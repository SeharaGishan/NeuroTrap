import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/top_bar.dart';

const Color _navy = Color(0xFF0A1628);
const Color _card = Color(0xFF0F2340);
const Color _cyan = Color(0xFF00E5FF);
const Color _white = Colors.white;

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(children: [
        SafeArea(child: Column(children: [
          NeuroTrapTopBar(parentContext: context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contacts',
                    style: TextStyle(color: _white, fontSize: 22,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Developer card
                  _contactCard(
                    icon: Icons.person_rounded,
                    title: 'Developer',
                    name: 'Bedde K Samarasinghe',
                    items: [
                      _ContactItem(Icons.chat_rounded, 'WhatsApp',
                        '+94 771112785',
                        () => _launch('https://wa.me/94771112785')),
                      _ContactItem(Icons.email_rounded, 'Email',
                        'sehara1027@gmail.com',
                        () => _launch('mailto:sehara1027@gmail.com')),
                      _ContactItem(Icons.phone_rounded, 'Mobile',
                        '+94 771112785',
                        () => _launch('tel:+94771112785')),
                      _ContactItem(Icons.location_on_rounded, 'Address',
                        '289/10 Jason Court, Beruketiya, Kiriwattuduwa',
                        null),
                      _ContactItem(Icons.language_rounded, 'Website',
                        'www.neurotrap.ai',
                        () => _launch('http://www.neurotrap.ai')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Supervisor card
                  _contactCard(
                    icon: Icons.school_rounded,
                    title: 'Supervisor',
                    name: 'Mr. Chamara Disanayake',
                    items: [
                      _ContactItem(Icons.business_rounded, 'Institution',
                        'University of Plymouth, UK', null),
                      _ContactItem(Icons.menu_book_rounded, 'Module',
                        'PUSL3190 Computing Project', null),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // University card
                  _contactCard(
                    icon: Icons.account_balance_rounded,
                    title: 'University',
                    name: 'University of Plymouth, UK',
                    items: [
                      _ContactItem(Icons.language_rounded, 'Website',
                        'www.nsbm.ac.lk',
                        () => _launch('https://www.nsbm.ac.lk')),
                      _ContactItem(Icons.location_on_rounded, 'Location',
                        'Pitipana, Homagama, Sri Lanka', null),
                      _ContactItem(Icons.school_rounded, 'Partner',
                        'NSBM Green University', null),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ])),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: NeuroTrapBottomNav(selectedIndex: -1)),
      ]),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String name,
    required List<_ContactItem> items,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _cyan, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          color: _cyan, fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      Text(name, style: const TextStyle(
        color: _white, fontSize: 15, fontWeight: FontWeight.w600)),
      const Divider(color: Colors.white12, height: 20),
      ...items.map((item) => _buildItem(item)),
    ]),
  );

  Widget _buildItem(_ContactItem item) => GestureDetector(
    onTap: item.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(item.icon, color: _cyan.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.label, style: const TextStyle(
              color: Colors.white38, fontSize: 10)),
            Text(item.value, style: TextStyle(
              color: item.onTap != null ? _cyan : _white,
              fontSize: 13,
              decoration: item.onTap != null
                  ? TextDecoration.underline : null)),
          ],
        )),
        if (item.onTap != null)
          Icon(Icons.open_in_new, color: _cyan.withValues(alpha: 0.4),
            size: 14),
      ]),
    ),
  );
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ContactItem(this.icon, this.label, this.value, this.onTap);
}

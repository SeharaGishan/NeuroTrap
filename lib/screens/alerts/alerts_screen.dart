import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const Color _navy      = Color(0xFF0A1628);
const Color _navyLight = Color(0xFF0D1F3C);
const Color _card      = Color(0xFF0F2340);
const Color _cyan      = Color(0xFF00E5FF);
const Color _white     = Colors.white;
const Color _botColor  = Color(0xFFFFFFFF);
const Color _skColor   = Color(0xFFFFEA00);
const Color _aptColor  = Color(0xFFFF4400);
const String _osBase   = 'http://10.0.2.20:9200';
const String _sessionIndex = 'neurotrap-sessions';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchSessions());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    try {
      final response = await http.post(
        Uri.parse('$_osBase/_plugins/_ppl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query':
            'source=$_sessionIndex | fields timestamp, src_ip, predicted_class, confidence, dqn_action, command_count | sort - timestamp | head 30'
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final schema = data['schema'] as List;
        final rows   = data['datarows'] as List;

        final keys = schema.map((s) => s['name'].toString()).toList();

        setState(() {
          _sessions = rows.map((row) {
            final m = <String, dynamic>{};
            for (int i = 0; i < keys.length; i++) {
              m[keys[i]] = row[i];
            }
            return m;
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _classColor(String? cls) {
    switch (cls) {
      case 'advanced_adversary': return _aptColor;
      case 'script_kiddie':      return _skColor;
      default:                   return _botColor;
    }
  }

  String _classLabel(String? cls) {
    switch (cls) {
      case 'advanced_adversary': return 'APT';
      case 'script_kiddie':      return 'Script Kiddie';
      case 'automated_bot':      return 'Bot';
      default:                   return cls ?? 'Unknown';
    }
  }

  String _classIcon(String? cls) {
    switch (cls) {
      case 'advanced_adversary': return '🚨';
      case 'script_kiddie':      return '🎭';
      default:                   return '🤖';
    }
  }

  String _formatTime(String? ts) {
    if (ts == null || ts.isEmpty) return '--';
    try {
      final cleaned = ts.trim().replaceFirst(' ', 'T').split('.')[0] + 'Z';
      final utc = DateTime.parse(cleaned);
      final slt = utc.add(const Duration(hours: 5, minutes: 30));
      return slt.day.toString().padLeft(2,'0') + '-' +
             slt.month.toString().padLeft(2,'0') + '-' +
             slt.year.toString() + ' ' +
             slt.hour.toString().padLeft(2,'0') + ':' +
             slt.minute.toString().padLeft(2,'0');
    } catch (e) {
      return ts;
    }
  }

  String _formatConf(dynamic conf) {
    if (conf == null) return '--';
    final v = (conf as num).toDouble();
    return '${(v * 100).toStringAsFixed(1)}%';
  }

  void _showAlertDetail(Map<String, dynamic> session) {
    final cls = session['predicted_class']?.toString();
    final isAPT = cls == 'advanced_adversary';

    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(_classIcon(cls), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  isAPT ? '🚨 CRITICAL THREAT DETECTED' : 'Alert Details',
                  style: TextStyle(
                    color: _classColor(cls),
                    fontSize: 18, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Class', _classLabel(cls), _classColor(cls)),
            _detailRow('Source IP', session['src_ip']?.toString() ?? '--', _white),
            _detailRow('Time', _formatTime(session['timestamp']?.toString()), Colors.white70),
            _detailRow('Confidence', _formatConf(session['confidence']), _cyan),
            _detailRow('DQN Action', session['dqn_action']?.toString() ?? '--', _cyan),
            _detailRow('Commands', session['command_count']?.toString() ?? '0', Colors.white70),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _classColor(cls),
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ACKNOWLEDGE', ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: _cyan))
                : _sessions.isEmpty
                  ? const Center(
                      child: Text('No sessions yet', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _sessions.length,
                      itemBuilder: (_, i) => _buildAlertCard(_sessions[i]),
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: _navyLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: _white, size: 20),
          ),
          const Spacer(),
          Column(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'NEURO', style: TextStyle(
                      color: _white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                    TextSpan(text: 'TRAP', style: TextStyle(
                      color: _cyan, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                  ],
                ),
              ),
              const Text('SECURITY THAT EVOLVES',
                style: TextStyle(color: _cyan, fontSize: 7, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          const Text('Hi Sehara',
            style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> session) {
    final cls   = session['predicted_class']?.toString();
    final color = _classColor(cls);
    final label = _classLabel(cls);
    final icon  = _classIcon(cls);
    final conf  = _formatConf(session['confidence']);
    final ip    = session['src_ip']?.toString() ?? '--';
    final time  = _formatTime(session['timestamp']?.toString());
    final action = session['dqn_action']?.toString() ?? '--';

    return GestureDetector(
      onTap: () => _showAlertDetail(session),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(time,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(ip, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(width: 12),
                const Icon(Icons.psychology, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(conf, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Action: $action',
              style: const TextStyle(color: _cyan, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.logout,        'label': 'Sign Out'},
      {'icon': Icons.settings,      'label': 'Settings'},
      {'icon': Icons.home,          'label': 'Home'},
      {'icon': Icons.notifications, 'label': 'Alerts'},
      {'icon': Icons.power_settings_new, 'label': 'Shutdown'},
    ];

    return Container(
      color: _navyLight,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final isHome    = i == 2;
          final isAlerts  = i == 3;

          return GestureDetector(
            onTap: () {
              if (i == 2) Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isHome
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
                      child: Icon(item['icon'] as IconData, color: _navy, size: 22),
                    )
                  : Icon(
                      item['icon'] as IconData,
                      color: isAlerts ? _cyan : Colors.white38,
                      size: 22,
                    ),
                const SizedBox(height: 3),
                Text(item['label'] as String,
                  style: TextStyle(
                    color: isAlerts ? _cyan : Colors.white38, fontSize: 9)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
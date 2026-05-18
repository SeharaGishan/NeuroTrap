import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _navy     = Color(0xFF0A1628);
const Color _card     = Color(0xFF0F2340);
const Color _cyan     = Color(0xFF00E5FF);
const Color _white    = Colors.white;
const Color _green    = Color(0xFF00E676);
const Color _aptColor = Color(0xFFFF4400);

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});
  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen>
    with SingleTickerProviderStateMixin {

  static const String _vpnSubnet = '10.8.0.';
  static const String _osHost    = '10.0.2.20';

  bool _vpnConnected  = false;
  bool _dataReachable = false;
  bool _checking      = false;
  bool _launching     = false;
  String _statusText  = 'Not Connected';
  String _vpnIp       = '';

  Timer? _pollTimer;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _checkVPN();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVPN());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkVPN() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      String vpnIp = '';
      bool connected = false;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.address.startsWith(_vpnSubnet)) {
            vpnIp = addr.address;
            connected = true;
            break;
          }
        }
        if (connected) break;
      }

      bool dataOk = false;
      if (connected) dataOk = await _pingOpenSearch();

      if (mounted) {
        setState(() {
          _vpnConnected  = connected;
          _dataReachable = dataOk;
          _vpnIp         = vpnIp;
          _statusText    = connected
              ? (dataOk ? 'Connected — Data Ready' : 'Connected — Reaching server...')
              : 'Not Connected';
        });
        if (connected && dataOk) {
          _pollTimer?.cancel();
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _statusText = 'Check failed');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<bool> _pingOpenSearch() async {
    try {
      final socket = await Socket.connect(_osHost, 9200,
        timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Extract .ovpn from assets → temp dir → open with OpenVPN Connect ──────

  Future<void> _connectVPN() async {
    setState(() { _launching = true; _statusText = 'Preparing VPN profile...'; });

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      // Read ovpn from assets
      final config = await rootBundle.loadString('assets/vpn/neurotrap.ovpn');

      // Write to public Downloads folder — accessible by all apps
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = File('${downloadsDir.path}/neurotrap.ovpn');
      await file.writeAsString(config);
      print('[VPN] File written to: ${file.path}');

      // Open the file directly — Android will show app chooser
      // OpenVPN Connect handles .ovpn files and will auto-import
      final fileUri = Uri.file(file.path);
      final opened = await launchUrl(
        fileUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        // Try intent with explicit MIME type
        final intentUri = Uri.parse(
          'intent://open#Intent;'
          'action=android.intent.action.VIEW;'
          'type=application/x-openvpn-profile;'
          'package=net.openvpn.openvpn;'
          'end'
        );
        final intentOpened = await launchUrl(
          intentUri, mode: LaunchMode.externalApplication);
        if (!intentOpened && mounted) {
          _showDownloadInstructions(file.path);
        }
      }

    } catch (e) {
      print('[VPN] Error: $e');
      if (mounted) {
        setState(() => _statusText = 'Error: ${e.toString()}');
        _showDownloadInstructions('/storage/emulated/0/Download/neurotrap.ovpn');
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _openWithIntentChooser(String filePath) async {
    // Try OpenVPN Connect package directly
    final uri = Uri(
      scheme: 'content',
      host: 'com.android.providers.downloads.documents',
    );
    final vpnUri = Uri.parse(
      'intent://$filePath#Intent;'
      'scheme=file;'
      'type=application/x-openvpn-profile;'
      'package=net.openvpn.openvpn;'
      'end'
    );
    try {
      await launchUrl(vpnUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Last resort — just open OpenVPN Connect
      await launchUrl(
        Uri.parse('package:net.openvpn.openvpn'),
        mode: LaunchMode.externalApplication,
      );
      if (mounted) _showDownloadInstructions('');
    }
  }

  void _showDownloadInstructions(String filePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual VPN Setup',
              style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _step('1', 'Open OpenVPN Connect app'),
            _step('2', 'Tap the + button → Upload File'),
            _step('3', 'Go to Downloads folder → select neurotrap.ovpn'),
            _step('4', 'Tap Add, then Connect'),
            _step('5', 'Return to NeuroTrap — it will detect VPN automatically'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan, foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await launchUrl(
                    Uri.parse('market://details?id=net.openvpn.openvpn'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open OpenVPN Connect',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22,
        decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
        child: Center(child: Text(num,
          style: const TextStyle(color: _navy, fontSize: 11, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4))),
    ]),
  );

  void _skip() => Navigator.pushReplacementNamed(context, '/home');

  @override
  Widget build(BuildContext context) {
    final color = _vpnConnected
        ? (_dataReachable ? _green : _cyan)
        : _aptColor;

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: Image.asset('assets/images/logo.png', height: 40,
                errorBuilder: (_, _, _) => RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: 'NEURO', style: TextStyle(color: _white,
                      fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                    TextSpan(text: 'TRAP', style: TextStyle(color: _cyan,
                      fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                  ]))),
            ),
          ),

          const Spacer(flex: 2),

          AnimatedBuilder(
            animation: !_vpnConnected
                ? _pulse
                : const AlwaysStoppedAnimation(1.0),
            builder: (_, _) => Transform.scale(
              scale: !_vpnConnected ? _pulse.value : 1.0,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  boxShadow: [BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 35, spreadRadius: 5)],
                ),
                child: Icon(
                  _vpnConnected
                      ? (_dataReachable ? Icons.vpn_lock_rounded : Icons.sync_rounded)
                      : Icons.vpn_key_rounded,
                  color: color, size: 55),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            _vpnConnected
                ? (_dataReachable ? 'Connected!' : 'VPN Active')
                : 'Secure VPN Required',
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            _vpnConnected
                ? (_dataReachable
                    ? 'Redirecting to dashboard...'
                    : 'Reaching NeuroTrap server...')
                : 'Tap below to connect via\nOpenVPN Connect',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 28),

          // status card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Status',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
                Text(_statusText,
                  style: TextStyle(color: color, fontSize: 12,
                    fontWeight: FontWeight.bold)),
              ]),
              if (_vpnIp.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 16),
                _infoRow('VPN IP',    _vpnIp),
                const SizedBox(height: 4),
                _infoRow('Server',    '54.179.35.12'),
                const SizedBox(height: 4),
                _infoRow('Data',      _dataReachable ? '✓ Reachable' : '⏳ Connecting...'),
              ] else ...[
                const Divider(color: Colors.white12, height: 16),
                _infoRow('Server',    '54.179.35.12:1194'),
                const SizedBox(height: 4),
                _infoRow('Protocol',  'OpenVPN / UDP'),
                const SizedBox(height: 4),
                _infoRow('Subnet',    '10.8.0.0/24'),
              ],
            ]),
          ),

          const Spacer(flex: 2),

          // main button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: (_vpnConnected || _launching) ? null : _connectVPN,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity, height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _vpnConnected
                        ? [_green.withValues(alpha: 0.3), _green.withValues(alpha: 0.15)]
                        : _launching
                            ? [_card, _card]
                            : [const Color(0xFF005F8A), _cyan],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: _vpnConnected
                      ? Border.all(color: _green.withValues(alpha: 0.5))
                      : null,
                  boxShadow: [BoxShadow(
                    color: (_vpnConnected ? _green : _cyan).withValues(alpha: 0.2),
                    blurRadius: 16)],
                ),
                child: Center(
                  child: _launching
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: _cyan, strokeWidth: 2))
                      : _vpnConnected
                          ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  color: _green, strokeWidth: 2)),
                              const SizedBox(width: 10),
                              Text('Loading Data...',
                                style: TextStyle(color: _green, fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                            ])
                          : const Row(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.vpn_lock_rounded, color: _white, size: 20),
                                SizedBox(width: 10),
                                Text('CONNECT TO VPN',
                                  style: TextStyle(color: _white, fontSize: 14,
                                    fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ]),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (!_vpnConnected)
            TextButton.icon(
              onPressed: _checkVPN,
              icon: const Icon(Icons.refresh_rounded, color: _cyan, size: 16),
              label: const Text('Check VPN Status',
                style: TextStyle(color: _cyan, fontSize: 12)),
            ),

          const SizedBox(height: 4),

          TextButton(
            onPressed: _skip,
            child: Text('Skip — use without live data',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
          ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(value,  style: const TextStyle(color: _white, fontSize: 12)),
      ]);
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

const Color _cyan     = Color(0xFF00E5FF);
const Color _aptColor = Color(0xFFFF4400);
const Color _skColor  = Color(0xFFFFEA00);

class ThreatAlertScreen extends StatefulWidget {
  final String classification;
  final String sourceIp;
  final double confidence;
  final String dqnAction;

  const ThreatAlertScreen({
    super.key,
    this.classification = 'script_kiddie',
    this.sourceIp = '--',
    this.confidence = 0.0,
    this.dqnAction = '--',
  });

  @override
  State<ThreatAlertScreen> createState() => _ThreatAlertScreenState();
}

class _ThreatAlertScreenState extends State<ThreatAlertScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _textCtrl;
  late Animation<double>   _textAnim;
  bool _isPaused = false;
  final AudioPlayer _player = AudioPlayer();

  // Use HapticFeedback for alarm effect (works without audio files)
  bool _vibratingActive = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _textAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeInOut));

    _startVibration();
  }

  Future<void> _startAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/alarm.mp3'));
    } catch (_) {}
    // Also vibrate
    _vibratingActive = true;
    _vibrateLoop();
  }

  Future<void> _vibrateLoop() async {
    while (_vibratingActive && !_isPaused) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> _startVibration() async {
    await _startAlarm();
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _pulseCtrl.stop();
      _textCtrl.stop();
      _vibratingActive = false;
      _player.pause();
    } else {
      _pulseCtrl.repeat(reverse: true);
      _textCtrl.repeat(reverse: true);
      _player.resume();
      _startVibration();
    }
  }

  void _openNeuroTrap() {
    _vibratingActive = false;
    _player.stop();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
  }

  @override
  void dispose() {
    _vibratingActive = false;
    _player.stop();
    _player.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Color get _alertColor => switch (widget.classification) {
    'advanced_adversary' => _aptColor,
    'script_kiddie'      => _skColor,
    _                    => Colors.white,
  };

  String get _classLabel => switch (widget.classification) {
    'advanced_adversary' => 'APT',
    'script_kiddie'      => 'Script Kiddie',
    _                    => 'Bot',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Pulsing background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              color: _alertColor.withValues(
                alpha: _isPaused ? 0.04 : 0.07 * _pulseAnim.value)),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),

            // Logo
            Image.asset('assets/images/logo.png', height: 60,
              errorBuilder: (_, __, ___) => Column(children: [
                RichText(text: const TextSpan(children: [
                  TextSpan(text: 'NEURO', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900,
                    fontSize: 20, letterSpacing: 3)),
                  TextSpan(text: 'TRAP', style: TextStyle(
                    color: Color(0xFF00E5FF), fontWeight: FontWeight.w900,
                    fontSize: 20, letterSpacing: 3)),
                ])),
                const Text('SECURITY THAT EVOLVES',
                  style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: 2)),
              ]),
            ),

            const Spacer(flex: 1),

            // THREAT ALERT text
            AnimatedBuilder(
              animation: _textAnim,
              builder: (_, __) => Opacity(
                opacity: _isPaused ? 1.0 : _textAnim.value,
                child: Text('THREAT ALERT!',
                  style: TextStyle(
                    color: _alertColor, fontSize: 38,
                    fontWeight: FontWeight.w900, letterSpacing: 3,
                    shadows: [Shadow(
                      color: _alertColor.withValues(alpha: 0.8),
                      blurRadius: 24)],
                  )),
              ),
            ),

            const SizedBox(height: 20),

            // Classification
            RichText(text: TextSpan(children: [
              const TextSpan(text: 'Classification :  ',
                style: TextStyle(color: Colors.white70, fontSize: 15,
                  fontWeight: FontWeight.w500)),
              TextSpan(text: _classLabel,
                style: TextStyle(color: _alertColor, fontSize: 15,
                  fontWeight: FontWeight.bold)),
            ])),

            if (widget.sourceIp != '--') ...[
              const SizedBox(height: 10),
              Text('Source: ${widget.sourceIp}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],

            if (widget.confidence > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Confidence: ${(widget.confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],

            if (widget.dqnAction != '--') ...[
              const SizedBox(height: 4),
              Text('Action: ${widget.dqnAction.replaceAll('_', ' ')}',
                style: TextStyle(
                  color: _cyan.withValues(alpha: 0.7), fontSize: 12)),
            ],

            const Spacer(flex: 2),

            // Pause button
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _isPaused ? 1.0 : _pulseAnim.value,
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: _alertColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: _alertColor.withValues(alpha: 0.6),
                        blurRadius: 28, spreadRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white, size: 36),
                        Text(_isPaused ? 'Resume' : 'Pause',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 10)),
                      ]),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Open NeuroTrap button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GestureDetector(
                onTap: _openNeuroTrap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _cyan, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                    color: _cyan.withValues(alpha: 0.05),
                  ),
                  child: const Text('OPEN NEUROTRAP',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cyan, fontSize: 14,
                      fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ]),
        ),
      ]),
    );
  }
}

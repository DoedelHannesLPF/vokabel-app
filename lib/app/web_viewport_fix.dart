import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// iOS PWA workaround: two-tap calibration overlay on every web cold start.
class WebTouchCalibrationGate extends StatefulWidget {
  final Widget child;

  const WebTouchCalibrationGate({super.key, required this.child});

  @override
  State<WebTouchCalibrationGate> createState() =>
      _WebTouchCalibrationGateState();
}

class _WebTouchCalibrationGateState extends State<WebTouchCalibrationGate> {
  static bool _needsCalibration() {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.endsWith('.local');
  }

  bool _done = !_needsCalibration();
  bool _synced = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus || _done || _synced) return;
    _focusNode.unfocus();
    _syncViewport();
    setState(() => _synced = true);
  }

  void _onFieldTap() {
    if (!_synced) {
      _focusNode.requestFocus();
      return;
    }
    _finish();
  }

  void _finish() {
    _focusNode.unfocus();
    _syncViewport();
    if (mounted) setState(() => _done = true);
  }

  void _syncViewport() {
    SchedulerBinding.instance.scheduleForcedFrame();
    for (final delayMs in [0, 50, 120, 250]) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        SchedulerBinding.instance.scheduleForcedFrame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AbsorbPointer(child: widget.child),
        Material(
          color: const Color(0xFF121212),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.touch_app_outlined, size: 44, color: cs.primary),
                  const SizedBox(height: 20),
                  Text(
                    _synced ? 'Fast geschafft' : 'Bildschirm kalibrieren',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _synced
                        ? 'Tippe jetzt in das Eingabefeld, um fortzufahren.'
                        : 'Tippe auf das Fadenkreuz, um den Touch-Bildschirm zu synchronisieren.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 168,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TextField(
                          focusNode: _focusNode,
                          readOnly: true,
                          showCursor: _synced,
                          expands: true,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: _synced
                                ? 'Hier tippen zum Schließen'
                                : 'Tippe in diesen Bereich…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                          onTap: _onFieldTap,
                        ),
                        Positioned(
                          bottom: 20,
                          child: IgnorePointer(
                            child: Icon(
                              Icons.gps_fixed,
                              size: 72,
                              color: cs.primary
                                  .withValues(alpha: _synced ? 0.45 : 1.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Re-syncs layout after auth transitions on web.
class WebViewportResync extends StatefulWidget {
  final Widget child;

  const WebViewportResync({super.key, required this.child});

  @override
  State<WebViewportResync> createState() => _WebViewportResyncState();
}

class _WebViewportResyncState extends State<WebViewportResync> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAfterFrame());
  }

  void _syncAfterFrame() {
    for (final delayMs in [0, 100, 250]) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;
        SchedulerBinding.instance.scheduleForcedFrame();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

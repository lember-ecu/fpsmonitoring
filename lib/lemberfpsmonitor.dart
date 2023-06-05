library lemberfpsmonitor;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FPSMonitor extends StatefulWidget {
  /// Toggle the stats on/off, there should be no performance cost when the widget is off.
  final bool isEnabled;

  /// Ceiling fps
  final int maxFps;

  /// A child to be displayed under the Stats
  final Widget? child;

  /// Where to align the stats relative to the child
  final Alignment? align;

  /// How long is the x-axis of the graph, in seconds
  final double totalTime;

  /// How long is the sample time for the fps avg in second (values of .3 to 1 work pretty well)
  final double sampleTime;

  /// Show Fps text values
  final bool showText;

  final Function(double fps) onFpsChanged;

  FPSMonitor(
      {Key? key,
      this.child,
      this.totalTime = 15,
      this.sampleTime = .5,
      this.maxFps = 60,
      this.isEnabled = true,
      required this.onFpsChanged,
      this.align,
      this.showText = true})
      : super(key: key) {
    assert(sampleTime > 0, "sampleTime must be > 0.");
    assert(totalTime >= sampleTime * 2,
        "totalTime must at least twice sampleTime");
  }

  @override
  State<FPSMonitor> createState() => _FPSMonitorState();
}

class _FPSMonitorState extends State<FPSMonitor> {
  final ValueNotifier<List<_FpsEntry>> _entries = ValueNotifier([]);
  int _lastCalcTime = 0;
  late Ticker _ticker;
  double _ticks = 0;
  double _fps = 0;
  bool _shouldRepaint = false;

  int get nowMs => DateTime.now().millisecondsSinceEpoch;

  double get totalTimeMs => (widget.totalTime) * 1000;

  double get sampleTimeMs => (widget.sampleTime) * 1000;

  double get fps => _fps;

  @override
  void initState() {
    super.initState();
    _fps = widget.maxFps.toDouble();
    _ticker = Ticker(_handleTick);
    if (widget.isEnabled) _ticker.start();
    _lastCalcTime = nowMs;
  }

  @override
  void didUpdateWidget(FPSMonitor oldWidget) {
    final isEnabled = widget.isEnabled;

    if (oldWidget.isEnabled != isEnabled) {
      isEnabled ? _ticker.start() : _ticker.stop();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTick(Duration d) {
    if (!widget.isEnabled) {
      _lastCalcTime = nowMs;
      return;
    }
    // Tick
    _ticks++;
    // Calculate
    if (nowMs - _lastCalcTime > sampleTimeMs) {
      _shouldRepaint = true;
      int remainder = (nowMs - _lastCalcTime - sampleTimeMs).round();
      _lastCalcTime = nowMs - remainder;
      _fps = min((_ticks * 1000 / sampleTimeMs).roundToDouble(),
          widget.maxFps.toDouble());
      _ticks = 0;
      //Add new entry, remove old ones
      widget.onFpsChanged(_fps);
      _entries.value.add(_FpsEntry(_lastCalcTime, _fps));
      _entries.value = List.from(_entries.value)
        ..removeWhere((e) => nowMs - e.time > totalTimeMs);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildStats() => IgnorePointer(
          child: SizedBox(
            height: 56,
            child: RepaintBoundary(
              child: ValueListenableBuilder<List<_FpsEntry>>(
                valueListenable: _entries,
                builder: (_, entries, ___) => _buildPainter(entries),
              ),
            ),
          ),
        );

    // Exit early if we're disabled
    if (widget.isEnabled == false) {
      return widget.child ?? const SizedBox.shrink();
    }
    // Exit early if there is no child
    final content = widget.child == null
        ? buildStats()
        : Stack(
            children: [
              widget.child!,
              Positioned.fill(
                child: Align(
                  alignment: widget.align ?? Alignment.topLeft,
                  child: buildStats(),
                ),
              )
            ],
          );

    // Wrap stats + child in a stack
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: content,
      ),
    );
  }

  Widget _buildPainter(List<_FpsEntry> entries) {
    String fToString(double value) => value.toStringAsPrecision(3);
    double minFps = 0, maxFps = 0;
    if (entries.isNotEmpty) {
      minFps = entries.reduce((prev, e) => e.fps < prev.fps ? e : prev).fps;
      maxFps = entries.reduce((prev, e) => e.fps > prev.fps ? e : prev).fps;
    }
    double lastFps = entries.isNotEmpty ? entries.last.fps : 60;
    return CustomPaint(
        foregroundPainter: _StatsPainter(state: this),
        child: Container(
          padding: const EdgeInsets.only(left: 4, top: 2),
          color: Colors.black54.withOpacity(.8),
          child: widget.showText
              ? Text(
                  "${fToString(_fps)} FPS (${fToString(minFps)}-${fToString(maxFps)})",
                  style: TextStyle(
                    color: _getColorForFps(lastFps),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                )
              : Container(),
        ));
  }

  Color _getColorForFps(double fps) {
    if (fps < widget.maxFps * .5) return Colors.redAccent;
    if (fps < widget.maxFps * .75) return Colors.orange;
    if (fps < widget.maxFps) return Colors.yellow;
    return Colors.green;
  }
}

class _FpsEntry {
  final double fps;
  final int time;

  _FpsEntry(this.time, this.fps);
}

class _StatsPainter extends CustomPainter {
  final _FPSMonitorState state;

  double get topPadding => state.widget.showText ? 20 : 4;

  _StatsPainter({required this.state});

  double getYForFps(double fps, double maxHeight) =>
      maxHeight - 2 - (min((fps / 60), 1) * (maxHeight - topPadding));

  @override
  void paint(Canvas canvas, Size size) {
    state._shouldRepaint = false;
    double maxXAxis = state.totalTimeMs;
    double colWidth = size.width / (maxXAxis / state.sampleTimeMs);
    for (var e in state._entries.value) {
      Color c = state._getColorForFps(e.fps);
      double x = size.width -
          colWidth -
          ((state.nowMs - e.time) / maxXAxis) * size.width;
      double y = getYForFps(e.fps, size.height);
      canvas.drawRect(
          Rect.fromLTWH(x, y, colWidth + .5, 2), Paint()..color = c);
      canvas.drawRect(
          Rect.fromLTWH(x, y + 3, colWidth + .5, size.height - y - 2),
          Paint()..color = c.withOpacity(.2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => state._shouldRepaint;
}

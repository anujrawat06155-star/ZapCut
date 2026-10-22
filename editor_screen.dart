import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:video_player/video_player.dart';

import '../main.dart';
import '../video_controller_factory.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.video});

  final XFile video;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final VideoPlayerController _controller;
  final VideoTrimmer _trimmer = VideoTrimmer();

  RangeValues? _trimRange;
  double _playheadMs = 0;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  String? _loadError;

  double get _durationMs => _controller.value.duration.inMilliseconds.toDouble();
  double get _safeDurationMs => math.max(1, _durationMs);

  @override
  void initState() {
    super.initState();
    _controller = createVideoController(widget.video.path);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _trimRange = RangeValues(0, _safeDurationMs);
        _loading = false;
      });
      _controller.addListener(_syncPlayback);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'This video could not be opened. Try a different clip.';
      });
    }
  }

  void _syncPlayback() {
    if (!mounted || !_controller.value.isInitialized) return;
    final position = _controller.value.position.inMilliseconds.toDouble();
    final range = _trimRange;
    if (_controller.value.isPlaying &&
        range != null &&
        position >= range.end) {
      _controller.pause();
      _controller.seekTo(Duration(milliseconds: range.start.round()));
    }
    setState(() => _playheadMs = position.clamp(0, _safeDurationMs));
  }

  Future<void> _togglePlayback() async {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }

    final range = _trimRange;
    final position = _controller.value.position.inMilliseconds.toDouble();
    if (range != null && (position < range.start || position >= range.end)) {
      await _controller.seekTo(Duration(milliseconds: range.start.round()));
    }
    await _controller.play();
  }

  void _changeRange(RangeValues nextRange) {
    final previous = _trimRange;
    final minimumGap = math.min(250.0, _safeDurationMs);
    var start = nextRange.start;
    var end = nextRange.end;

    if (end - start < minimumGap) {
      final movedStart = previous != null &&
          (start - previous.start).abs() > (end - previous.end).abs();
      if (movedStart) {
        start = math.max(0, end - minimumGap);
      } else {
        end = math.min(_safeDurationMs, start + minimumGap);
        if (end - start < minimumGap) {
          start = math.max(0, end - minimumGap);
        }
      }
    }

    setState(() {
      _trimRange = RangeValues(start, end);
      _saved = false;
    });
  }

  Future<void> _exportCut() async {
    if (kIsWeb) {
      _showMessage('Export your trimmed video from the Zapcut mobile app.');
      return;
    }
    if (_saving || _trimRange == null) return;

    setState(() => _saving = true);
    try {
      final range = _trimRange!;
      await _controller.pause();
      await _trimmer.loadVideo(widget.video.path);
      final trimmedPath = await _trimmer.trimVideo(
        startTimeMs: range.start.round(),
        endTimeMs: range.end.round(),
      );
      if (trimmedPath == null || trimmedPath.isEmpty) {
        throw StateError('The trimmer did not return an output file.');
      }

      await Gal.putVideo(trimmedPath, album: 'Zapcut');
      if (!mounted) return;
      setState(() => _saved = true);
      _showMessage('Your cut is saved in the Zapcut album.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not save this cut. Check photo access and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _timeLabel(double milliseconds) {
    final totalSeconds = (milliseconds / 1000).floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.removeListener(_syncPlayback);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _EditorHeader(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 18),
                _VideoPreview(
                  controller: _controller,
                  loading: _loading,
                  error: _loadError,
                  playing: _controller.value.isPlaying,
                  onToggle: _togglePlayback,
                ),
                const SizedBox(height: 19),
                _PlaybackRow(
                  position: _playheadMs,
                  duration: _durationMs,
                  playing: _controller.value.isPlaying,
                  onToggle: _togglePlayback,
                ),
                const SizedBox(height: 25),
                _TrimPanel(
                  range: _trimRange,
                  durationMs: _safeDurationMs,
                  timeLabel: _timeLabel,
                  onChanged: _changeRange,
                  onChangeEnd: (range) async {
                    final position = _controller.value.position.inMilliseconds;
                    if (position < range.start || position > range.end) {
                      await _controller.seekTo(
                        Duration(milliseconds: range.start.round()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    key: const ValueKey('export-video'),
                    onPressed: _loading || _loadError != null ? null : _exportCut,
                    style: FilledButton.styleFrom(
                      backgroundColor: _saved ? panelRaised : acid,
                      foregroundColor: _saved ? paper : ink,
                      disabledBackgroundColor: panelRaised,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ink,
                            ),
                          )
                        : Icon(
                            _saved
                                ? Icons.check_circle_outline_rounded
                                : Icons.file_download_outlined,
                            size: 21,
                          ),
                    label: Text(
                      _saving
                          ? 'Trimming your video…'
                          : _saved
                              ? 'Saved to gallery'
                              : kIsWeb
                                  ? 'Export on iOS or Android'
                                  : 'Trim & save to gallery',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    kIsWeb
                        ? 'Gallery export is available in the mobile app'
                        : 'Trimmed on your device · no upload',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('editor-back'),
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: panel,
            foregroundColor: paper,
            fixedSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New cut',
                style: TextStyle(
                  color: paper,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'PICK YOUR BEST MOMENT',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.movie_outlined, color: muted, size: 21),
      ],
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({
    required this.controller,
    required this.loading,
    required this.error,
    required this.playing,
    required this.onToggle,
  });

  final VideoPlayerController controller;
  final bool loading;
  final String? error;
  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(350.0, constraints.maxWidth * 0.72);
        return Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (loading)
                const CircularProgressIndicator(color: acid)
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                )
              else if (controller.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              if (!loading && error == null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggle,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: playing ? 48 : 62,
                        height: playing ? 48 : 62,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: paper,
                          size: playing ? 24 : 32,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 13,
                top: 13,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ORIGINAL',
                    style: TextStyle(
                      color: paper,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaybackRow extends StatelessWidget {
  const _PlaybackRow({
    required this.position,
    required this.duration,
    required this.playing,
    required this.onToggle,
  });

  final double position;
  final double duration;
  final bool playing;
  final VoidCallback onToggle;

  String _time(double milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration <= 0 ? 0.0 : (position / duration).clamp(0.0, 1.0);
    return Row(
      children: [
        IconButton(
          key: const ValueKey('play-pause'),
          onPressed: onToggle,
          style: IconButton.styleFrom(
            backgroundColor: panel,
            foregroundColor: acid,
            fixedSize: const Size(42, 42),
          ),
          icon: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _time(position),
          style: const TextStyle(
            color: paper,
            fontFeatures: [FontFeature.tabularFigures()],
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: panelRaised,
              color: acid,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _time(duration),
          style: const TextStyle(
            color: muted,
            fontFeatures: [FontFeature.tabularFigures()],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrimPanel extends StatelessWidget {
  const _TrimPanel({
    required this.range,
    required this.durationMs,
    required this.timeLabel,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final RangeValues? range;
  final double durationMs;
  final String Function(double milliseconds) timeLabel;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final activeRange = range;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 11),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TRIM CLIP',
                style: TextStyle(
                  color: paper,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (activeRange != null)
                Text(
                  '${timeLabel(activeRange.end - activeRange.start)} SELECTED',
                  style: const TextStyle(
                    color: acid,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeRange != null)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: acid,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.13),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                overlayColor: acid.withValues(alpha: 0.12),
                rangeValueIndicatorShape:
                    const PaddleRangeSliderValueIndicatorShape(),
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: RangeSlider(
                key: const ValueKey('trim-range'),
                values: activeRange,
                min: 0,
                max: durationMs,
                labels: RangeLabels(
                  timeLabel(activeRange.start),
                  timeLabel(activeRange.end),
                ),
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            )
          else
            const SizedBox(height: 34),
          Row(
            children: [
              _TimeChip(
                label: 'IN',
                value: activeRange == null ? '--:--' : timeLabel(activeRange.start),
              ),
              const Spacer(),
              Text(
                'Drag the handles to trim',
                style: TextStyle(
                  color: paper.withValues(alpha: 0.42),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              _TimeChip(
                label: 'OUT',
                value: activeRange == null ? '--:--' : timeLabel(activeRange.end),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: paper,
            fontFeatures: [FontFeature.tabularFigures()],
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

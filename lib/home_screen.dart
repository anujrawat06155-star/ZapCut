import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class _RatioOption {
  final String label;
  final String shortTag;
  final double ratio;
  final bool isQuick;

  const _RatioOption({
    required this.label,
    required this.shortTag,
    required this.ratio,
    this.isQuick = false,
  });
}

class _FilterPreset {
  final String name;
  final List<double>? matrix;

  const _FilterPreset({required this.name, this.matrix});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedVideo;
  VideoPlayerController? _controller;

  static const List<_RatioOption> _allRatios = [
    _RatioOption(label: '9:16 Reels', shortTag: '9:16', ratio: 9 / 16, isQuick: true),
    _RatioOption(label: '4:5 Feed', shortTag: '4:5', ratio: 4 / 5, isQuick: true),
    _RatioOption(label: '1:1 Square', shortTag: '1:1', ratio: 1 / 1, isQuick: true),
    _RatioOption(label: '16:9 YT', shortTag: '16:9', ratio: 16 / 9, isQuick: true),
    _RatioOption(label: '3:4 Portrait', shortTag: '3:4', ratio: 3 / 4),
    _RatioOption(label: '4:3 Classic', shortTag: '4:3', ratio: 4 / 3),
    _RatioOption(label: '2:3 Photo', shortTag: '2:3', ratio: 2 / 3),
    _RatioOption(label: '3:2 Camera', shortTag: '3:2', ratio: 3 / 2),
    _RatioOption(label: '2.35:1 Cinema', shortTag: '2.35:1', ratio: 2.35 / 1),
    _RatioOption(label: '2.1:1 Wide', shortTag: '2.1:1', ratio: 2.1 / 1),
    _RatioOption(label: '1:2 Tall', shortTag: '1:2', ratio: 1 / 2),
  ];

  static const List<_FilterPreset> _filters = [
    _FilterPreset(name: 'Clean', matrix: null),
    _FilterPreset(
      name: 'Crisp Pop',
      matrix: [
        1.18, 0, 0, 0, 6,
        0, 1.15, 0, 0, 6,
        0, 0, 1.18, 0, 6,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Warm Reel',
      matrix: [
        1.22, 0.04, 0, 0, 8,
        0, 1.06, 0, 0, 4,
        0, 0, 0.88, 0, -4,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Moody',
      matrix: [
        0.9, 0, 0, 0, -6,
        0, 0.92, 0, 0, -4,
        0, 0, 1.05, 0, 4,
        0, 0, 0, 1, 0,
      ],
    ),
  ];

  _RatioOption _selectedRatio = _allRatios.first;
  bool _fitMode = true;
  bool _showSafeZone = true;
  bool _isMuted = false;
  bool _isSaving = false;
  double _playbackSpeed = 1.0;
  int _selectedFilterIndex = 0;
  String _activeTool = 'Trim';

  double _trimStartMs = 0;
  double _trimEndMs = 0;

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    controller.setLooping(true);
    await controller.setVolume(_isMuted ? 0.0 : 1.0);
    await controller.setPlaybackSpeed(_playbackSpeed);
    await controller.play();

    final totalMs = controller.value.duration.inMilliseconds.toDouble();

    controller.addListener(() {
      if (!mounted || !_controller!.value.isInitialized) return;
      final currentMs = _controller!.value.position.inMilliseconds.toDouble();
      if (_trimEndMs > _trimStartMs && currentMs >= _trimEndMs) {
        _controller!.seekTo(Duration(milliseconds: _trimStartMs.round()));
      }
      setState(() {});
    });

    if (!mounted) return;
    setState(() {
      _selectedVideo = File(picked.path);
      _controller = controller;
      _trimStartMs = 0;
      _trimEndMs = totalMs > 0 ? totalMs : 1000;
    });
  }

  Future<void> _saveToGallery() async {
    if (_selectedVideo == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await Gal.putVideo(_selectedVideo!.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video gallery mein save ho gayi (No Watermark)!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save nahi ho paya: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleMute() async {
    final nextMute = !_isMuted;
    setState(() => _isMuted = nextMute);
    await _controller?.setVolume(nextMute ? 0.0 : 1.0);
  }

  void _cycleSpeed() async {
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextSpeed = speeds[(currentIndex + 1) % speeds.length];
    setState(() => _playbackSpeed = nextSpeed);
    await _controller?.setPlaybackSpeed(nextSpeed);
  }

  void _openMoreRatiosSheet() {
    final extraRatios = _allRatios.where((r) => !r.isQuick).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'More Aspect Ratios (Fit)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Extra aur cinematic ratios — zaroorat ke hisaab se chunein',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: extraRatios.map((item) {
                  final selected = _selectedRatio.label == item.label;
                  return ChoiceChip(
                    label: Text(item.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedRatio = item;
                        _fitMode = true;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _formatMs(double ms) {
    final d = Duration(milliseconds: ms.round().clamp(0, 86400000));
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildVideoWithFilter(Widget child) {
    final matrix = _filters[_selectedFilterIndex].matrix;
    if (matrix == null) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: child,
    );
  }

  Widget _buildSubToolPanel(bool hasVideo, double maxMs) {
    if (_activeTool == 'Trim') {
      final safeEnd = _trimEndMs.clamp(_trimStartMs + 100, maxMs);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatMs(_trimStartMs)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'End: ${_formatMs(safeEnd)}',
                style: const TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ],
          ),
          Slider(
            value: _trimStartMs.clamp(0.0, (safeEnd - 100).clamp(0.0, maxMs)),
            min: 0.0,
            max: (safeEnd - 100).clamp(100.0, maxMs),
            activeColor: Colors.amber,
            inactiveColor: Colors.white24,
            onChanged: hasVideo
                ? (val) {
                    setState(() => _trimStartMs = val);
                    _controller!.seekTo(Duration(milliseconds: val.round()));
                  }
                : null,
          ),
          Slider(
            value: safeEnd.clamp((_trimStartMs + 100).clamp(0.0, maxMs), maxMs),
            min: (_trimStartMs + 100).clamp(0.0, maxMs),
            max: maxMs.clamp(100.0, double.infinity),
            activeColor: Colors.greenAccent,
            inactiveColor: Colors.white24,
            onChanged: hasVideo
                ? (val) {
                    setState(() => _trimEndMs = val);
                  }
                : null,
          ),
        ],
      );
    }

    if (_activeTool == 'SafeZone') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Reels / Shorts Safe-Zone Guide (text cut hone se bachaye)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Switch(
            value: _showSafeZone,
            activeColor: Colors.amber,
            onChanged: (val) => setState(() => _showSafeZone = val),
          ),
        ],
      );
    }

    if (_activeTool == 'Filter') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (index) {
            final item = _filters[index];
            final selected = _selectedFilterIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item.name),
                selected: selected,
                onSelected: (_) => setState(() => _selectedFilterIndex = index),
              ),
            );
          }),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Speed: ${_playbackSpeed}x  •  Audio: ${_isMuted ? 'Muted' : 'On'}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _cycleSpeed,
              child: Text('${_playbackSpeed}x'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _toggleMute,
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, size: 16),
              label: Text(_isMuted ? 'Unmute' : 'Mute'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quickRatios = _allRatios.where((r) => r.isQuick).toList();
    final hasVideo = _controller != null && _controller!.value.isInitialized;
    final activeAspect = _fitMode
        ? _selectedRatio.ratio
        : (hasVideo ? _controller!.value.aspectRatio : _selectedRatio.ratio);

    final duration = hasVideo ? _controller!.value.duration : Duration.zero;
    final position = hasVideo ? _controller!.value.position : Duration.zero;
    final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1000.0;
    final posMs = position.inMilliseconds.clamp(0, maxMs.round()).toDouble();

    final tools = [
      ('Trim', Icons.content_cut),
      ('SafeZone', Icons.grid_on),
      ('Filter', Icons.auto_awesome),
      ('Speed', Icons.speed),
      ('Mute', _isMuted ? Icons.volume_off : Icons.volume_up),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E1015),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1015),
        foregroundColor: Colors.white,
        title: const Text(
          'ZapCut',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                SizedBox(width: 4),
                Text(
                  'No Watermark',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Canvas Fit & Size',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _fitMode = !_fitMode),
                  icon: Icon(
                    _fitMode ? Icons.fit_screen : Icons.aspect_ratio,
                    color: Colors.amber,
                    size: 18,
                  ),
                  label: Text(
                    _fitMode ? 'Fit: ON' : 'Original',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...quickRatios.map((item) {
                    final isSelected = _selectedRatio.label == item.label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedRatio = item;
                            _fitMode = true;
                          });
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.tune, size: 16),
                    label: Text(
                      !_selectedRatio.isQuick
                          ? 'More (${_selectedRatio.shortTag})'
                          : 'More',
                    ),
                    onPressed: _openMoreRatiosSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF171A22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: activeAspect.clamp(0.4, 2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: hasVideo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildVideoWithFilter(
                                    FittedBox(
                                      fit: _fitMode ? BoxFit.contain : BoxFit.cover,
                                      child: SizedBox(
                                        width: _controller!.value.size.width,
                                        height: _controller!.value.size.height,
                                        child: VideoPlayer(_controller!),
                                      ),
                                    ),
                                  ),
                                  if (_showSafeZone && _selectedRatio.shortTag == '9:16')
                                    IgnorePointer(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 46,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.amber.withValues(alpha: 0.45),
                                            width: 1.2,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_fitMode ? 'Fit ${_selectedRatio.shortTag}' : 'Original'} • ${_playbackSpeed}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: IconButton(
                                      iconSize: 52,
                                      color: Colors.white,
                                      onPressed: () {
                                        setState(() {
                                          _controller!.value.isPlaying
                                              ? _controller!.pause()
                                              : _controller!.play();
                                        });
                                      },
                                      icon: Icon(
                                        _controller!.value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.crop_free,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Frame: ${_selectedRatio.label}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedVideo == null
                                      ? 'Gallery se video pick karein'
                                      : _selectedVideo!.path.split('/').last,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Playback Timeline Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF171A22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Text(
                    _formatMs(posMs),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Expanded(
                    child: Slider(
                      value: posMs.clamp(0.0, maxMs),
                      min: 0.0,
                      max: maxMs,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.white24,
                      onChanged: hasVideo
                          ? (val) {
                              _controller!.seekTo(Duration(milliseconds: val.round()));
                            }
                          : null,
                    ),
                  ),
                  Text(
                    _formatMs(maxMs),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Active Tool Controls Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF171A22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: _buildSubToolPanel(hasVideo, maxMs),
            ),
            const SizedBox(height: 8),
            // Bottom Tool Icons Bar (No "Canvas" here)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF14171F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tools.map((t) {
                  final label = t.$1;
                  final icon = t.$2;
                  final isSelected = _activeTool == label;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (label == 'Mute') {
                        _toggleMute();
                      }
                      setState(() => _activeTool = label);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: isSelected ? Colors.amber : Colors.white70,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.amber : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.video_call_rounded),
                    label: const Text(
                      'Pick Video',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_selectedVideo != null && !_isSaving)
                        ? _saveToGallery
                        : null,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt_rounded),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Clean',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

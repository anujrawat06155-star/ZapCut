import 'dart:io';
import 'package:flutter/material.dart';
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

  _RatioOption _selectedRatio = _allRatios.first;
  bool _fitMode = true; // true = Fit frame, false = Original video ratio

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    controller.setLooping(true);
    await controller.play();

    if (!mounted) return;
    setState(() {
      _selectedVideo = File(picked.path);
      _controller = controller;
    });
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
        padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
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
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
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
                                  FittedBox(
                                    fit: _fitMode ? BoxFit.contain : BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!.value.size.width,
                                      height: _controller!.value.size.height,
                                      child: VideoPlayer(_controller!),
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
                                        _fitMode
                                            ? 'Fit ${_selectedRatio.shortTag}'
                                            : 'Original',
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
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_call_rounded),
              label: const Text(
                'Pick Video From Gallery',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

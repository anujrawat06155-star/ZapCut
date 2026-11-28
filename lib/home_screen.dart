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

class _StickerItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _StickerItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textInputController =
      TextEditingController(text: 'ZapCut Reel');

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

  static const List<String> _musicTracks = [
    'Lo-Fi Reel Beat',
    'Desi Energetic',
    'Emotional Kahani',
    'Upbeat Vlog Vibe',
    'Chill Groove',
    'Phonk Hook Drop',
    'Acoustic Morning',
    'Suspense Rise',
  ];

  static const List<Color> _textColors = [
    Colors.white,
    Colors.amber,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.black,
  ];

  static const List<_StickerItem> _stickersList = [
    _StickerItem(id: 'fire', label: 'Fire', icon: Icons.local_fire_department, color: Colors.deepOrange),
    _StickerItem(id: 'crown', label: 'Crown', icon: Icons.workspace_premium, color: Colors.amber),
    _StickerItem(id: 'share', label: 'Share', icon: Icons.share, color: Colors.greenAccent),
    _StickerItem(id: 'rec', label: 'REC', icon: Icons.fiber_manual_record, color: Colors.redAccent),
    _StickerItem(id: 'eyes', label: 'Eyes', icon: Icons.visibility, color: Colors.lightBlueAccent),
    _StickerItem(id: 'love', label: 'Love', icon: Icons.favorite, color: Colors.pinkAccent),
    _StickerItem(id: 'cam', label: 'Cam', icon: Icons.photo_camera, color: Colors.purpleAccent),
    _StickerItem(id: 'time', label: 'Time', icon: Icons.schedule, color: Colors.cyanAccent),
    _StickerItem(id: 'star', label: 'Star', icon: Icons.star, color: Colors.yellowAccent),
    _StickerItem(id: 'bolt', label: 'Bolt', icon: Icons.bolt, color: Colors.orangeAccent),
    _StickerItem(id: 'mic', label: 'Mic', icon: Icons.mic, color: Colors.tealAccent),
    _StickerItem(id: 'zap', label: 'ZapCut', icon: Icons.verified, color: Colors.greenAccent),
  ];

  _RatioOption _selectedRatio = _allRatios.first;
  bool _fitMode = true;
  bool _showSafeZone = true;
  bool _isMuted = false;
  bool _isSaving = false;
  bool _recordMarked = false;

  // Text customization states
  bool _showOverlayText = true;
  Color _selectedTextColor = Colors.white;
  bool _textHasBackground = true;
  double _textFontSize = 18.0;
  Offset _textOffset = Offset.zero;

  int _selectedFilterIndex = 0;
  double _brightnessOffset = 0.0;

  String? _selectedMusic;
  final Set<String> _addedStickers = {};

  String _mainTab = 'Text';
  String _subTool = 'Text';

  static const Map<String, List<String>> _tabSubTools = {
    'Audio': ['Music', 'Effect', 'Record', 'AI Speech'],
    'Sticker': ['Stickers', 'Text', 'Caption', 'AI Speech', 'Detail', 'Doodle'],
    'Text': ['Text', 'Caption', 'Stickers', 'AI Speech', 'Detail', 'Doodle'],
    'Effect': ['Filter', 'Adjust', 'AI Effect'],
  };

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    await _controller?.dispose();
    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    controller.setLooping(true);
    await controller.setVolume(_isMuted ? 0.0 : 1.0);
    await controller.play();

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    if (!mounted) return;
    setState(() {
      _selectedVideo = File(picked.path);
      _controller = controller;
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

  void _selectMainTab(String tab) {
    final subs = _tabSubTools[tab] ?? ['Text'];
    setState(() {
      _mainTab = tab;
      _subTool = subs.first;
    });
  }

  void _toggleSticker(String id) {
    setState(() {
      if (_addedStickers.contains(id)) {
        _addedStickers.remove(id);
      } else {
        _addedStickers.add(id);
      }
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

  Widget _applyColorAndAdjust(Widget child) {
    final base = _filters[_selectedFilterIndex].matrix ??
        const [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];

    final adjusted = List<double>.from(base);
    adjusted[4] = adjusted[4] + _brightnessOffset;
    adjusted[9] = adjusted[9] + _brightnessOffset;
    adjusted[14] = adjusted[14] + _brightnessOffset;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(adjusted),
      child: child,
    );
  }

  Widget _buildSubToolControls() {
    if (_subTool == 'Text' || _subTool == 'Caption') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textInputController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _subTool == 'Caption'
                        ? 'Reel caption likhein...'
                        : 'Video par likhne ke liye text type karein...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0E1015),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() => _showOverlayText = true),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Show/Hide Text',
                onPressed: () => setState(() => _showOverlayText = !_showOverlayText),
                icon: Icon(
                  _showOverlayText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Background Box',
                onPressed: () => setState(() => _textHasBackground = !_textHasBackground),
                icon: Icon(
                  _textHasBackground ? Icons.format_color_fill : Icons.text_format,
                  color: _textHasBackground ? Colors.greenAccent : Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _textColors.length,
                    itemBuilder: (context, idx) {
                      final col = _textColors[idx];
                      final isSelected = _selectedTextColor == col;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedTextColor = col;
                          _showOverlayText = true;
                        }),
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.amber : Colors.white54,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Text('Size', style: TextStyle(color: Colors.white60, fontSize: 11)),
              SizedBox(
                width: 95,
                child: Slider(
                  value: _textFontSize,
                  min: 12,
                  max: 30,
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setState(() => _textFontSize = v),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (_subTool == 'Music') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedMusic == null
                    ? 'Gaana / Music chunein:'
                    : 'Selected: $_selectedMusic',
                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (_selectedMusic != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                  ),
                  onPressed: () => setState(() => _selectedMusic = null),
                  child: const Text('Remove', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _musicTracks.map((track) {
                final isSelected = _selectedMusic == track;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: const Icon(Icons.music_note, size: 15),
                    label: Text(track),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedMusic = track);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    if (_subTool == 'Stickers') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stickers (${_addedStickers.length} lagaye gaye) — tap karke add/hatayein:',
                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (_addedStickers.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                  ),
                  onPressed: () => setState(() => _addedStickers.clear()),
                  child: const Text('Clear', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stickersList.length,
              itemBuilder: (context, index) {
                final st = _stickersList[index];
                final active = _addedStickers.contains(st.id);
                return GestureDetector(
                  onTap: () => _toggleSticker(st.id),
                  child: Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? Colors.amber.withValues(alpha: 0.22) : const Color(0xFF0E1015),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? Colors.amber : Colors.white12,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(st.icon, color: st.color, size: 22),
                        const SizedBox(height: 2),
                        Text(
                          st.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (_subTool == 'Filter') {
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

    if (_subTool == 'Adjust') {
      return Row(
        children: [
          const Text(
            'Light',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: _brightnessOffset,
              min: -35,
              max: 35,
              activeColor: Colors.amber,
              inactiveColor: Colors.white24,
              onChanged: (val) => setState(() => _brightnessOffset = val),
            ),
          ),
          Text(
            _brightnessOffset.round().toString(),
            style: const TextStyle(color: Colors.amber, fontSize: 12),
          ),
        ],
      );
    }

    if (_subTool == 'Detail') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              '9:16 Safe-Zone Guide (text/sticker cut na ho)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Switch(
            value: _showSafeZone,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _showSafeZone = v),
          ),
        ],
      );
    }

    if (_subTool == 'Doodle') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Highlight / Doodle Sticker',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Switch(
            value: _addedStickers.contains('bolt'),
            activeColor: Colors.amber,
            onChanged: (_) => _toggleSticker('bolt'),
          ),
        ],
      );
    }

    if (_subTool == 'Record') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _recordMarked ? 'Voiceover marker set' : 'Voiceover note ready',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _recordMarked ? Colors.greenAccent : Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () => setState(() => _recordMarked = !_recordMarked),
            icon: const Icon(Icons.mic, size: 16),
            label: Text(_recordMarked ? 'Marked' : 'Mark VO'),
          ),
        ],
      );
    }

    if (_subTool == 'AI Speech' || _subTool == 'AI Effect') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_subTool — Agle phase mein clean add hoga',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Icon(Icons.bolt, color: Colors.amber, size: 18),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Audio ${_isMuted ? 'Muted' : 'Active'}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        OutlinedButton.icon(
          onPressed: _toggleMute,
          icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, size: 16),
          label: Text(_isMuted ? 'Unmute' : 'Mute'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textInputController.dispose();
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

    final subTools = _tabSubTools[_mainTab] ?? const ['Text'];
    final mainTabs = [
      ('Audio', Icons.music_note),
      ('Sticker', Icons.emoji_emotions_outlined),
      ('Text', Icons.text_fields),
      ('Effect', Icons.auto_awesome),
    ];

    final activeStickerItems =
        _stickersList.where((s) => _addedStickers.contains(s.id)).toList();

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
                                  _applyColorAndAdjust(
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
                                        _selectedMusic == null
                                            ? '${_fitMode ? 'Fit ${_selectedRatio.shortTag}' : 'Original'} • ${_filters[_selectedFilterIndex].name}'
                                            : '♪ $_selectedMusic',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (activeStickerItems.isNotEmpty)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: activeStickerItems.map((st) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.72),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: st.color, width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(st.icon, color: st.color, size: 14),
                                                const SizedBox(width: 2),
                                                Text(
                                                  st.label,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  if (_showOverlayText &&
                                      _textInputController.text.trim().isNotEmpty)
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Transform.translate(
                                        offset: _textOffset,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              _textOffset += details.delta;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 58),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _textHasBackground
                                                  ? (_selectedTextColor == Colors.black
                                                      ? Colors.white.withValues(alpha: 0.85)
                                                      : Colors.black.withValues(alpha: 0.65))
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _textInputController.text.trim(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: _selectedTextColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: _textFontSize,
                                                shadows: _textHasBackground
                                                    ? null
                                                    : const [
                                                        Shadow(
                                                          color: Colors.black,
                                                          blurRadius: 6,
                                                          offset: Offset(1, 1),
                                                        ),
                                                      ],
                                              ),
                                            ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF171A22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subTools.map((item) {
                        final selected = _subTool == item;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: selected,
                            onSelected: (_) => setState(() => _subTool = item),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildSubToolControls(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF14171F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: mainTabs.map((t) {
                  final label = t.$1;
                  final icon = t.$2;
                  final isSelected = _mainTab == label;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _selectMainTab(label),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

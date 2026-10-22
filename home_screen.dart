import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _openingPicker = false;

  Future<void> _pickVideo() async {
    if (_openingPicker) return;
    setState(() => _openingPicker = true);

    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => EditorScreen(video: video),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          kIsWeb
              ? 'Could not open the video picker. Try another video file.'
              : 'Could not open your gallery. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingPicker = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BrandHeader(),
                      const SizedBox(height: 46),
                      const Text(
                        'Small edits.\nBig energy.',
                        style: TextStyle(
                          color: paper,
                          fontSize: 42,
                          height: 1.02,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Trim the moment. Keep the good part.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const _FilmCard(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          key: const ValueKey('choose-video'),
                          onPressed: _openingPicker ? null : _pickVideo,
                          style: FilledButton.styleFrom(
                            backgroundColor: acid,
                            foregroundColor: ink,
                            disabledBackgroundColor: acid.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: _openingPicker
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ink,
                                  ),
                                )
                              : const Icon(Icons.add_rounded, size: 23),
                          label: Text(
                            _openingPicker ? 'Opening gallery…' : 'Choose a video',
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: muted,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Your video stays on your device',
                              style: TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: acid,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: ink,
            size: 27,
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'zapcut',
          style: TextStyle(
            color: paper,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: const Text(
            'VIDEO EDITOR',
            style: TextStyle(
              color: muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmCard extends StatelessWidget {
  const _FilmCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252B31), Color(0xFF111418)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 26,
              left: 24,
              child: _StatusPill(
                icon: Icons.auto_awesome_rounded,
                label: 'MADE FOR THE MOMENT',
              ),
            ),
            Positioned(
              right: -16,
              top: 9,
              bottom: 6,
              child: Transform.rotate(
                angle: -0.25,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 210,
                  color: Color(0x0ED8FF52),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: acid,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: acid.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.content_cut_rounded,
                  color: ink,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your next favorite clip',
                    style: TextStyle(
                      color: paper,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a video to make it yours',
                    style: TextStyle(
                      color: paper.withValues(alpha: 0.56),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 21,
              bottom: 22,
              child: _FilmStrip(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: acid, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: paper,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilmStrip extends StatelessWidget {
  const _FilmStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (index) => Container(
          width: 11,
          height: 34,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
          decoration: BoxDecoration(
            color: index == 1
                ? acid.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

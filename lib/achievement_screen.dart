import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_settings.dart';
import 'achievement_system.dart';

const List<Shadow> comicShadows = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, 2), blurRadius: 0),
];

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late final VideoPlayerController _videoController;
  late AppSettings _settings;

  final List<AudioPlayer> _buttonSoundPlayers = [];

  bool get _isFilipino => _settings.isFilipino;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/GamePlay.mp4',
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setVolume(0.0);
      await _videoController.setLooping(true);
      await _videoController.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'GamePlay.mp4 failed to load in AchievementScreen: $e',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = SettingsScope.of(context);
  }

  Future<void> _playButtonSound() async {
    final player = AudioPlayer();

    _buttonSoundPlayers.add(player);

    player.onPlayerComplete.listen((_) async {
      if (_buttonSoundPlayers.remove(player)) {
        try {
          await player.dispose();
        } catch (error) {
          debugPrint(
            'Button sound dispose failed: $error',
          );
        }
      }
    });

    try {
      await player.setVolume(
        _settings.sfxVolume,
      );

      await player.setReleaseMode(
        ReleaseMode.release,
      );

      await player.play(
        AssetSource(
          'audio/buttons_sound.wav',
        ),
      );
    } catch (error) {
      _buttonSoundPlayers.remove(player);

      try {
        await player.dispose();
      } catch (_) {}

      debugPrint(
        'Button sound failed to load: $error',
      );
    }
  }

  @override
  void dispose() {
    for (final player in List<AudioPlayer>.from(
      _buttonSoundPlayers,
    )) {
      player.stop();
      player.dispose();
    }

    _buttonSoundPlayers.clear();

    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementManager.allAchievements;

    final unlockedCount = achievements
        .where(
          (a) => _settings.achievements.isUnlocked(a.id),
    )
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                const SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressCard(
                    unlockedCount,
                    achievements.length,
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isFilipino
                          ? 'LAHAT NG TAGUMPAY'
                          : 'ALL ACHIEVEMENTS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: comicShadows,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      20,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];

                      final bool unlocked = _settings
                          .achievements
                          .isUnlocked(achievement.id);

                      final Color color = achievement.color;

                      final progressStr = _settings
                          .achievements
                          .getProgressString(achievement.id);

                      return CustomPaint(
                        foregroundPainter: _ThickComicBorderPainter(
                          color: unlocked
                              ? color
                              : Colors.white24,
                          isCompleted: unlocked,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111126)
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  border: Border.all(
                                    color: unlocked
                                        ? color
                                        : Colors.white24,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  unlocked
                                      ? achievement.icon
                                      : Icons.lock_rounded,
                                  color: unlocked
                                      ? color
                                      : Colors.white38,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      achievement.name,
                                      style: TextStyle(
                                        color: unlocked
                                            ? color
                                            : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        shadows: comicShadows,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    if (achievement.isHidden &&
                                        !unlocked) ...[
                                      const Text(
                                        '??????????',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.bold,
                                          letterSpacing: 2,
                                          shadows: comicShadows,
                                        ),
                                      ),

                                      if (achievement.hint != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hint: ${achievement.hint}',
                                          style: const TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontStyle:
                                            FontStyle.italic,
                                            shadows: comicShadows,
                                          ),
                                        ),
                                      ],
                                    ] else ...[
                                      Text(
                                        achievement.task,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.bold,
                                          height: 1.4,
                                          shadows: comicShadows,
                                        ),
                                      ),

                                      if (achievement.isHidden &&
                                          achievement.hint != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Hint: ${achievement.hint}',
                                          style: const TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontStyle:
                                            FontStyle.italic,
                                            shadows: comicShadows,
                                          ),
                                        ),
                                      ],
                                    ],

                                    if (progressStr.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Progress: $progressStr',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.bold,
                                          shadows: comicShadows,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              Icon(
                                unlocked
                                    ? Icons.emoji_events_rounded
                                    : Icons.lock_outline_rounded,
                                color: unlocked
                                    ? const Color(0xFF39FF14)
                                    : Colors.white30,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    if (!_videoController.value.isInitialized) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Color(0xFF101014),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController.value.size.width,
        height: _videoController.value.size.height,
        child: VideoPlayer(_videoController),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: IconButton(
              onPressed: () {
                _playButtonSound();

                Navigator.pop(context);
              },
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black,
                    size: 56,
                  ),
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(0, 12),
              child: SizedBox(
                height: 40,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      _isFilipino
                          ? 'MGA TAGUMPAY'
                          : 'ACHIEVEMENTS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 9
                          ..strokeJoin = StrokeJoin.round
                          ..color = Colors.black,
                      ),
                    ),

                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFF00E6),
                            Color(0xFFFFF500),
                            Color(0xFF39FF14),
                            Color(0xFF00F5FF),
                            Color(0xFFC45CFF),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        _isFilipino
                            ? 'MGA TAGUMPAY'
                            : 'ACHIEVEMENTS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
      int unlockedCount,
      int totalCount,
      ) {
    return CustomPaint(
      foregroundPainter: _ThickComicBorderPainter(
        color: const Color(0xFFFF00E6),
        isCompleted: true,
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111126)
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFF500),
              size: 46,
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFilipino
                        ? 'IYONG PROGRESO'
                        : 'YOUR PROGRESS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      shadows: comicShadows,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '$unlockedCount / $totalCount '
                        '${_isFilipino ? 'NA-UNLOCKED' : 'UNLOCKED'}',
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      shadows: comicShadows,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: unlockedCount / totalCount,
                      minHeight: 8,
                      backgroundColor:
                      Colors.white.withValues(alpha: 0.1),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                        Color(0xFF39FF14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThickComicBorderPainter extends CustomPainter {
  final Color color;
  final bool isCompleted;

  _ThickComicBorderPainter({
    required this.color,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderRect = rect.deflate(2);

    final rrect = RRect.fromRectAndRadius(
      borderRect,
      const Radius.circular(20),
    );

    final blackOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.black;

    canvas.drawRRect(rrect, blackOutline);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(
      covariant _ThickComicBorderPainter oldDelegate,
      ) {
    return oldDelegate.color != color ||
        oldDelegate.isCompleted != isCompleted;
  }
}
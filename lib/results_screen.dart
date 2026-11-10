import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_settings.dart';
import 'game/game_session.dart';

const List<Shadow> comicShadows = [
  Shadow(
    color: Colors.black,
    offset: Offset(2, 2),
    blurRadius: 0,
  ),
  Shadow(
    color: Colors.black,
    offset: Offset(-2, -2),
    blurRadius: 0,
  ),
  Shadow(
    color: Colors.black,
    offset: Offset(2, -2),
    blurRadius: 0,
  ),
  Shadow(
    color: Colors.black,
    offset: Offset(-2, 2),
    blurRadius: 0,
  ),
];

// End-of-round summary with a review of the cards that were missed.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.session,
  });

  final GameSession session;

  static const Color neonPink = Color(0xFFFF00E6);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFFC45CFF);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final VideoPlayerController _videoController;

  // ============================================================
  // AUDIO
  // ============================================================

  final AudioPlayer _scoreSoundPlayer = AudioPlayer();

  // Every button sound gets its own player.
  //
  // This prevents a quick button press from
  // cutting off another button sound.
  final List<AudioPlayer> _buttonSoundPlayers = [];

  bool _scoreSoundPlayed = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/GamePlay.mp4',
    );

    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_scoreSoundPlayed) {
      _scoreSoundPlayed = true;
      _playScoreSound();
    }
  }

  // ============================================================
  // SCORE SOUND
  // ============================================================

  Future<void> _playScoreSound() async {
    try {
      final settings = SettingsScope.of(context);

      final accuracy = widget.session.accuracy;

      // Use the same rounded percentage that is displayed
      // on the Results screen.
      final displayedPercentage = (accuracy * 100).round();

      final sound = displayedPercentage >= 50
          ? 'audio/high_score.wav'
          : 'audio/low_score.wav';

      await _scoreSoundPlayer.setVolume(
        settings.sfxVolume,
      );

      await _scoreSoundPlayer.setReleaseMode(
        ReleaseMode.release,
      );

      await _scoreSoundPlayer.play(
        AssetSource(sound),
      );
    } catch (error) {
      debugPrint(
        'Score sound failed to load: $error',
      );
    }
  }

  // ============================================================
  // BUTTON SOUND
  // ============================================================

  Future<void> _playButtonSound() async {
    final player = AudioPlayer();

    _buttonSoundPlayers.add(player);

    // Listen before playing so even a short sound
    // can be cleaned up correctly.
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
      final settings = SettingsScope.of(context);

      await player.setVolume(
        settings.sfxVolume,
      );

      await player.setReleaseMode(
        ReleaseMode.release,
      );

      await player.play(
        AssetSource(
          'audio/button_sounds.wav',
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

  // ============================================================
  // VIDEO
  // ============================================================

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();

      await _videoController.setLooping(
        true,
      );

      await _videoController.play();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint(
        'GamePlay.mp4 failed to load in ResultsScreen: $e',
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _scoreSoundPlayer.stop();
    _scoreSoundPlayer.dispose();

    // Dispose every temporary button sound player.
    for (final player in List<AudioPlayer>.from(
      _buttonSoundPlayers,
    )) {
      try {
        player.stop();
      } catch (_) {}

      try {
        player.dispose();
      } catch (_) {}
    }

    _buttonSoundPlayers.clear();

    _videoController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final settings = SettingsScope.of(context);

    final isFilipino = settings.isFilipino;

    final missed = widget.session.missed;

    final accuracy = widget.session.accuracy;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    isFilipino
                        ? 'RESULTA'
                        : 'RESULTS',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ResultsScreen.neonPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: comicShadows,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _scoreCard(
                    isFilipino,
                    accuracy,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      missed.isEmpty
                          ? (isFilipino
                          ? 'WALANG MALI'
                          : 'NO MISTAKES')
                          : (isFilipino
                          ? 'MGA CARD NA BALIKAN'
                          : 'CARDS TO REVIEW'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: comicShadows,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Expanded(
                    child: missed.isEmpty
                        ? _perfectRound(
                      isFilipino,
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                      ),
                      itemCount: missed.length,
                      separatorBuilder:
                          (
                          context,
                          index,
                          ) =>
                      const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        return _MissedCard(
                          feedback: missed[index],
                          languageCode:
                          settings.languageCode,
                          isFilipino: isFilipino,
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'MENU',
                          color: ResultsScreen.neonPink,
                          onTap: () {
                            _playButtonSound();

                            Navigator.pop(
                              context,
                              false,
                            );
                          },
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: _ActionButton(
                          label: isFilipino
                              ? 'MAGLARO MULI'
                              : 'PLAY AGAIN',
                          color: ResultsScreen.neonGreen,
                          onTap: () {
                            _playButtonSound();

                            Navigator.pop(
                              context,
                              true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIDEO BACKGROUND
  // ============================================================

  Widget _buildVideoBackground() {
    if (!_videoController.value.isInitialized) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Color(0xFF080817),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController.value.size.width,
        height: _videoController.value.size.height,
        child: VideoPlayer(
          _videoController,
        ),
      ),
    );
  }

  // ============================================================
  // SCORE CARD
  // ============================================================

  Widget _scoreCard(
      bool isFilipino,
      double accuracy,
      ) {
    final percentage = (accuracy * 100).round();

    String message;

    if (percentage == 100) {
      message = isFilipino
          ? '100% RESPECT!'
          : '100% RESPECT!';
    } else if (percentage >= 90) {
      message = isFilipino
          ? 'Wow, gets na gets mo!'
          : 'Wow, you really get it!';
    } else if (percentage >= 80) {
      message = isFilipino
          ? 'Alam mo kung paano maging magalang!'
          : 'You know how to be respectful!';
    } else if (percentage >= 70) {
      message = isFilipino
          ? 'Ang galing mong humusga!'
          : 'Nice judging!';
    } else if (percentage >= 60) {
      message = isFilipino
          ? 'Gets mo na ang idea!'
          : 'You get the idea!';
    } else if (percentage >= 50) {
      message = isFilipino
          ? 'At least pumasa ka!'
          : 'At least you made it!';
    } else if (percentage >= 40) {
      message = isFilipino
          ? 'Konti na lang!'
          : 'Almost got it!';
    } else if (percentage >= 30) {
      message = isFilipino
          ? 'Malapit na!'
          : 'You\'re getting there!';
    } else if (percentage >= 20) {
      message = isFilipino
          ? 'Umiinit na!'
          : 'Getting the hang of it!';
    } else if (percentage >= 10) {
      message = isFilipino
          ? 'Tuloy lang!'
          : 'Still learning!';
    } else if (percentage >= 5) {
      message = isFilipino
          ? 'Nice try, pero kulang pa!'
          : 'Nice try, but nope!';
    } else {
      message = isFilipino
          ? 'Nang yan!'
          : 'Oof... Not quite respectful!';
    }

    return CustomPaint(
      foregroundPainter: _ThickComicBorderPainter(
        color: ResultsScreen.neonPurple,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0B4F).withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(
                24,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.session.correctCount} / ${widget.session.total}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    shadows: comicShadows,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  '$percentage% ${isFilipino ? 'TAMA' : 'CORRECT'}',
                  style: const TextStyle(
                    color: ResultsScreen.neonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: comicShadows,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE6B4FF),
                    fontSize: 15,
                    shadows: comicShadows,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PERFECT ROUND
  // ============================================================

  Widget _perfectRound(
      bool isFilipino,
      ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: ResultsScreen.neonGreen,
            size: 48,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            isFilipino
                ? 'Perpektong round!'
                : 'Perfect round!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: comicShadows,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MISSED CARD
// ================================================================

class _MissedCard extends StatelessWidget {
  const _MissedCard({
    required this.feedback,
    required this.languageCode,
    required this.isFilipino,
  });

  final GameFeedback feedback;
  final String languageCode;
  final bool isFilipino;

  String _sideLabel(
      SwipeSide side,
      ) {
    if (side == SwipeSide.left) {
      return isFilipino
          ? 'ISTERYOTIPO'
          : 'STEREOTYPE';
    }

    return isFilipino
        ? 'MAGALANG'
        : 'RESPECTFUL';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final correctSide = GameSession.expectedSide(
      feedback.card,
    );

    return CustomPaint(
      foregroundPainter: _ThickComicBorderPainter(
        color: ResultsScreen.neonPink,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3A0B4F).withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.card.textFor(
                    languageCode,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                    shadows: comicShadows,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  isFilipino
                      ? 'Pinili mo: ${_sideLabel(feedback.chosen)}  •  Tama: ${_sideLabel(correctSide)}'
                      : 'You chose: ${_sideLabel(feedback.chosen)}  •  Correct: ${_sideLabel(correctSide)}',
                  style: const TextStyle(
                    color: ResultsScreen.neonPink,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: comicShadows,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  feedback.card.explanationFor(
                    languageCode,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                    shadows: comicShadows,
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

// ================================================================
// THICK COMIC BORDER
// ================================================================

class _ThickComicBorderPainter extends CustomPainter {
  final Color color;

  _ThickComicBorderPainter({
    required this.color,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
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

    canvas.drawRRect(
      rrect,
      blackOutline,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;

    canvas.drawRRect(
      rrect,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _ThickComicBorderPainter oldDelegate,
      ) {
    return oldDelegate.color != color;
  }
}

// ================================================================
// ACTION BUTTON
// ================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color.withValues(
            alpha: 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: comicShadows,
        ),
      ),
    );
  }
}
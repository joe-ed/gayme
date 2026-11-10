import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'app_settings.dart';
import 'achievement_system.dart';
import 'content/situation.dart';
import 'content/situation_repository.dart';
import 'game/game_session.dart';
import 'results_screen.dart';

const List<Shadow> comicShadows = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(2, -2), blurRadius: 0),
  Shadow(color: Colors.black, offset: Offset(-2, 2), blurRadius: 0),
];

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.repository = const SituationRepository(),
  });

  final SituationRepository repository;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  bool _canPop = false;
  double _dragOffset = 0;
  double _dragY = 0;

  late AppSettings _settings;

  late VideoPlayerController _gameVideoController;

  // ============================================================
  // AUDIO
  // ============================================================

  final AudioPlayer _gameBgmPlayer = AudioPlayer();

  final AudioPlayer _cardSwipePlayer = AudioPlayer();

  final AudioPlayer _achievementNotifPlayer = AudioPlayer();

  final List<AudioPlayer> _answerSoundPlayers = [];

  final List<AudioPlayer> _buttonSoundPlayers = [];

  bool _gameBgmStarted = false;

  bool _audioConfigured = false;

  List<Situation> _cards = const [];
  GameSession? _session;
  bool _isLoading = true;
  Object? _loadError;

  bool _isDragging = false;
  bool _isAnimatingOut = false;
  bool _showFeedback = false;

  Timer? _resolveTimer;

  Timer? _achievementPopupTimer;
  bool _achievementPopupOpen = false;

  bool get _isFilipino => _settings.isFilipino;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _gameVideoController = VideoPlayerController.asset(
      'assets/videos/GamePlay.mp4',
    );

    _initializeGameVideo();
    _loadCards();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _settings = SettingsScope.of(context);

    _configureAudioAndStartBgm();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _pauseGameAudioAndVideo();
        break;

      case AppLifecycleState.resumed:
        _resumeGameAudioAndVideo();
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _pauseGameAudioAndVideo() async {
    try {
      if (_gameBgmStarted) {
        await _gameBgmPlayer.pause();
      }
    } catch (error) {
      debugPrint(
        'Game BGM pause failed: $error',
      );
    }

    try {
      await _cardSwipePlayer.pause();
    } catch (error) {
      debugPrint(
        'Card swipe pause failed: $error',
      );
    }

    try {
      await _achievementNotifPlayer.pause();
    } catch (error) {
      debugPrint(
        'Achievement notification pause failed: $error',
      );
    }

    for (final player in List<AudioPlayer>.from(
      _answerSoundPlayers,
    )) {
      try {
        await player.pause();
      } catch (error) {
        debugPrint(
          'Answer sound pause failed: $error',
        );
      }
    }

    for (final player in List<AudioPlayer>.from(
      _buttonSoundPlayers,
    )) {
      try {
        await player.pause();
      } catch (error) {
        debugPrint(
          'Button sound pause failed: $error',
        );
      }
    }

    try {
      if (_gameVideoController.value.isInitialized &&
          _gameVideoController.value.isPlaying) {
        await _gameVideoController.pause();
      }
    } catch (error) {
      debugPrint(
        'Game video pause failed: $error',
      );
    }
  }

  Future<void> _resumeGameAudioAndVideo() async {
    try {
      if (_gameBgmStarted) {
        await _gameBgmPlayer.resume();
      }
    } catch (error) {
      debugPrint(
        'Game BGM resume failed: $error',
      );
    }

    try {
      if (_achievementNotifPlayer.state ==
          PlayerState.paused) {
        await _achievementNotifPlayer.resume();
      }
    } catch (error) {
      debugPrint(
        'Achievement notification resume failed: $error',
      );
    }

    for (final player in List<AudioPlayer>.from(
      _answerSoundPlayers,
    )) {
      try {
        await player.resume();
      } catch (error) {
        debugPrint(
          'Answer sound resume failed: $error',
        );
      }
    }

    for (final player in List<AudioPlayer>.from(
      _buttonSoundPlayers,
    )) {
      try {
        await player.resume();
      } catch (error) {
        debugPrint(
          'Button sound resume failed: $error',
        );
      }
    }

    try {
      if (_cardSwipePlayer.state ==
          PlayerState.paused) {
        await _cardSwipePlayer.resume();
      }
    } catch (_) {}

    try {
      if (_gameVideoController.value.isInitialized) {
        await _gameVideoController.play();
      }
    } catch (error) {
      debugPrint(
        'Game video resume failed: $error',
      );
    }
  }

  // ============================================================
  // AUDIO CONFIGURATION
  // ============================================================

  Future<void> _configureAudioAndStartBgm() async {
    if (!_audioConfigured) {
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(
            focus: AudioContextConfigFocus.mixWithOthers,
          ).build(),
        );

        _audioConfigured = true;
      } catch (error) {
        debugPrint(
          'Audio configuration failed: $error',
        );
      }
    }

    if (!mounted) return;

    await _startGameBgm();
  }

  // ============================================================
  // GAME BGM
  // ============================================================

  Future<void> _startGameBgm() async {
    if (_gameBgmStarted) {
      return;
    }

    try {
      await _gameBgmPlayer.stop();

      await _gameBgmPlayer.setReleaseMode(
        ReleaseMode.loop,
      );

      await _gameBgmPlayer.setVolume(
        _settings.musicVolume,
      );

      await _gameBgmPlayer.play(
        AssetSource('audio/game_bgm.wav'),
      );

      _gameBgmStarted = true;
    } catch (error) {
      _gameBgmStarted = false;

      debugPrint(
        'Game BGM failed to load: $error',
      );
    }
  }

  Future<void> _stopGameBgm() async {
    try {
      await _gameBgmPlayer.stop();
    } catch (error) {
      debugPrint(
        'Game BGM stop failed: $error',
      );
    }

    _gameBgmStarted = false;
  }

  Future<void> _updateGameBgmVolume() async {
    try {
      await _gameBgmPlayer.setVolume(
        _settings.musicVolume,
      );
    } catch (error) {
      debugPrint(
        'Game BGM volume update failed: $error',
      );
    }
  }

  // ============================================================
  // CARD SWIPE SFX
  // ============================================================

  Future<void> _playCardSwipeSound() async {
    try {
      await _cardSwipePlayer.setVolume(
        _settings.sfxVolume,
      );

      await _cardSwipePlayer.play(
        AssetSource('audio/card_swipe.wav'),
      );
    } catch (error) {
      debugPrint(
        'Card swipe sound failed to load: $error',
      );
    }
  }

  // ============================================================
  // ANSWER SFX
  // ============================================================

  Future<void> _playAnswerSound(
      String assetPath,
      ) async {
    final player = AudioPlayer();

    _answerSoundPlayers.add(player);

    player.onPlayerComplete.listen((_) async {
      if (_answerSoundPlayers.remove(player)) {
        try {
          await player.dispose();
        } catch (error) {
          debugPrint(
            'Answer sound dispose failed: $error',
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
        AssetSource(assetPath),
      );
    } catch (error) {
      _answerSoundPlayers.remove(player);

      try {
        await player.dispose();
      } catch (_) {}

      debugPrint(
        'Answer sound failed to load: $error',
      );
    }
  }

  Future<void> _playRightAnswerSound() async {
    await _playAnswerSound(
      'audio/right_answer.wav',
    );
  }

  Future<void> _playWrongAnswerSound() async {
    await _playAnswerSound(
      'audio/wrong_answer.wav',
    );
  }

  // ============================================================
  // BUTTON SFX
  // ============================================================

  Future<void> _playButtonSound() async {
    if (_settings.sfxVolume <= 0) {
      return;
    }

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

  // ============================================================
  // ACHIEVEMENT NOTIFICATION SFX
  // ============================================================

  Future<void> _playAchievementNotificationSound() async {
    try {
      await _achievementNotifPlayer.setVolume(
        _settings.sfxVolume,
      );

      await _achievementNotifPlayer.setReleaseMode(
        ReleaseMode.release,
      );

      await _achievementNotifPlayer.stop();

      await _achievementNotifPlayer.play(
        AssetSource(
          'audio/achievement_notif.wav',
        ),
      );
    } catch (error) {
      debugPrint(
        'Achievement notification sound failed to load: $error',
      );
    }
  }

  // ============================================================
  // VIDEO
  // ============================================================

  Future<void> _initializeGameVideo() async {
    try {
      await _gameVideoController.initialize();

      await _gameVideoController.setLooping(
        true,
      );

      await _gameVideoController.play();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'GamePlay.mp4 failed to load: $error',
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _resolveTimer?.cancel();
    _achievementPopupTimer?.cancel();

    _gameBgmStarted = false;

    _gameBgmPlayer.stop();
    _gameBgmPlayer.dispose();

    _cardSwipePlayer.stop();
    _cardSwipePlayer.dispose();

    _achievementNotifPlayer.stop();
    _achievementNotifPlayer.dispose();

    for (final player in List<AudioPlayer>.from(
      _answerSoundPlayers,
    )) {
      try {
        player.stop();
      } catch (_) {}

      try {
        player.dispose();
      } catch (_) {}
    }

    _answerSoundPlayers.clear();

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

    _gameVideoController.dispose();

    super.dispose();
  }

  // ============================================================
  // GAME LOADING
  // ============================================================

  Future<void> _loadCards() async {
    try {
      final cards =
      await widget.repository.loadCards();

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _session = GameSession(cards: cards);
        _isLoading = false;
        _loadError = null;
        _showFeedback = false;
        _isAnimatingOut = false;
        _resetDrag();
      });

      _settings.achievements.recordGameStarted();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  void _retryLoad() {
    _playButtonSound();

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    _loadCards();
  }

  void _startNewRound() {
    _resolveTimer?.cancel();

    final cards = _cards;

    if (cards.isEmpty) {
      _retryLoad();
      return;
    }

    setState(() {
      _session = GameSession(cards: cards);
      _showFeedback = false;
      _isAnimatingOut = false;
      _resetDrag();
    });

    _settings.achievements.recordGameStarted();
  }

  void _resetDrag() {
    _dragOffset = 0;
    _dragY = 0;
    _isDragging = false;
  }

  // ============================================================
  // SWIPING
  // ============================================================

  void _handleSwipeEnd(
      DragEndDetails details,
      ) {
    final session = _session;

    if (session == null ||
        session.awaitingNext ||
        _isAnimatingOut) {
      return;
    }

    final velocity =
        details.velocity.pixelsPerSecond.dx;

    final shouldSwipe =
        _dragOffset.abs() > 100 ||
            velocity.abs() > 700;

    if (!shouldSwipe) {
      setState(_resetDrag);
      return;
    }

    final direction =
    _dragOffset.abs() > 100
        ? _dragOffset.sign
        : velocity.sign;

    if (direction == 0) return;

    _commitAnswer(
      direction < 0
          ? SwipeSide.left
          : SwipeSide.right,
    );
  }

  void _commitAnswer(SwipeSide side) {
    final session = _session;

    if (session == null ||
        session.awaitingNext) {
      return;
    }

    _playCardSwipeSound();

    final currentCard = session.current;

    final feedback = session.answer(side);

    if (feedback.isCorrect) {
      _playRightAnswerSound();
    } else {
      _playWrongAnswerSound();
    }

    final elapsed =
    _settings.achievements.cardStartTime != null
        ? DateTime.now()
        .difference(
      _settings
          .achievements
          .cardStartTime!,
    )
        .inMilliseconds /
        1000.0
        : 1.0;

    if (currentCard != null) {
      final unlocked =
      _settings.achievements.recordAnswer(
        situationId: currentCard.id,
        isStereotype:
        currentCard.kind ==
            SituationKind.stereotype,
        isCorrect: feedback.isCorrect,
        elapsedSeconds: elapsed,
        swipeDirection: side.name,
      );

      if (unlocked != null) {
        _showAchievementPopup(unlocked);
      }
    }

    final screenWidth =
        MediaQuery.of(context).size.width;

    final direction =
    side == SwipeSide.left
        ? -1.0
        : 1.0;

    setState(() {
      _isDragging = false;
      _isAnimatingOut = true;
      _dragOffset =
          direction * screenWidth * 1.5;
      _dragY = 0;
    });

    _resolveTimer?.cancel();

    _resolveTimer = Timer(
      const Duration(milliseconds: 300),
          () {
        if (!mounted) return;

        setState(() {
          _isAnimatingOut = false;
          _showFeedback = true;
          _dragOffset = 0;
          _dragY = 0;
        });

        _settings.achievements
            .incrementExplanationsRead();
      },
    );
  }

  void _nextCard() {
    final session = _session;

    if (session == null ||
        !session.awaitingNext) {
      return;
    }

    _playButtonSound();

    setState(() {
      session.next();
      _showFeedback = false;
      _resetDrag();
    });
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Future<void> _showResults() async {
    final session = _session;

    if (session == null) return;

    final newlyUnlocked =
    _settings.achievements
        .recordGameCompleted();

    final playAgain =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ResultsScreen(session: session),
      ),
    );

    if (!mounted) return;

    if (playAgain == true) {
      _startNewRound();

      if (newlyUnlocked != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) {
          if (mounted) {
            _showAchievementPopup(
              newlyUnlocked,
            );
          }
        });
      }
    } else if (playAgain == false) {
      setState(() {
        _canPop = true;
      });

      await _stopGameBgm();

      if (!mounted) return;

      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // ACHIEVEMENT POPUP
  // ============================================================

  void _showAchievementPopup(
      AchievementDefinition achievement,
      ) {
    if (!mounted) return;

    if (_achievementPopupOpen) {
      return;
    }

    _achievementPopupOpen = true;

    _playAchievementNotificationSound();

    _achievementPopupTimer?.cancel();
    _achievementPopupTimer = null;

    final title = achievement.name;
    final desc = achievement.task;

    BuildContext? popupContext;

    final dialogFuture =
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel:
      'Achievement Unlocked',
      barrierColor: Colors.transparent,
      transitionDuration:
      const Duration(milliseconds: 300),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        popupContext = dialogContext;

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: const Key(
                    'achievement_notification',
                  ),
                  direction:
                  DismissDirection.horizontal,
                  dismissThresholds: const {
                    DismissDirection.horizontal:
                    0.35,
                  },
                  onDismissed: (_) {
                    final currentContext =
                        popupContext;

                    if (currentContext != null &&
                        Navigator.of(
                          currentContext,
                        ).canPop()) {
                      Navigator.of(
                        currentContext,
                      ).pop();
                    }
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF111126,
                      ).withValues(
                        alpha: 0.95,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color:
                        achievement.color,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: achievement
                              .color
                              .withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration:
                          BoxDecoration(
                            color: achievement
                                .color
                                .withValues(
                              alpha: 0.2,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            border: Border.all(
                              color:
                              achievement
                                  .color,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            achievement.icon,
                            color:
                            achievement.color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                _isFilipino
                                    ? 'NA-UNLOCKED NA TAGUMPAY!'
                                    : 'ACHIEVEMENT UNLOCKED!',
                                style:
                                TextStyle(
                                  color:
                                  achievement
                                      .color,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                  letterSpacing:
                                  1.5,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                title,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                desc,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );

    _achievementPopupTimer = Timer(
      const Duration(seconds: 3),
          () {
        if (!_achievementPopupOpen) {
          return;
        }

        final currentContext =
            popupContext;

        if (currentContext != null &&
            Navigator.of(
              currentContext,
            ).canPop()) {
          Navigator.of(
            currentContext,
          ).pop();
        }
      },
    );

    dialogFuture.whenComplete(() {
      _achievementPopupTimer?.cancel();
      _achievementPopupTimer = null;
      _achievementPopupOpen = false;
      popupContext = null;
    });
  }

  // ============================================================
  // SETTINGS / RESTART / EXIT
  // ============================================================

  void _restartGame() {
    _playButtonSound();
    _startNewRound();
  }

  // ============================================================
  // RESTART CONFIRMATION
  // ============================================================

  void _confirmRestart() {
    _playButtonSound();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Restart',
      barrierColor:
      Colors.black.withValues(
        alpha: 0.25,
      ),
      transitionDuration:
      const Duration(milliseconds: 250),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return _GlassDialog(
          title: _isFilipino
              ? 'I-RESTART ANG GAME?'
              : 'RESTART GAME?',
          children: [
            Text(
              _isFilipino
                  ? 'Sigurado ka bang gusto mong i-restart ang game?'
                  : 'Are you sure you want to restart the game?',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: _isFilipino
                        ? 'KANSELAHIN'
                        : 'CANCEL',
                    color:
                    const Color(0xFF00A6C7),
                    onTap: () =>
                        Navigator.pop(
                          dialogContext,
                        ),
                    onButtonSound:
                    _playButtonSound,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: _isFilipino
                        ? 'I-RESTART'
                        : 'RESTART',
                    color:
                    const Color(0xFFC45CFF),
                    onTap: () {
                      Navigator.pop(
                        dialogContext,
                      );

                      _startNewRound();
                    },
                    onButtonSound:
                    _playButtonSound,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // EXIT CONFIRMATION
  // ============================================================

  void _confirmExit() {
    _playButtonSound();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit',
      barrierColor:
      Colors.black.withValues(
        alpha: 0.25,
      ),
      transitionDuration:
      const Duration(milliseconds: 250),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return _GlassDialog(
          title: _isFilipino
              ? 'BUMALIK SA MAIN MENU?'
              : 'BACK TO MAIN MENU?',
          children: [
            Text(
              _isFilipino
                  ? 'Sigurado ka bang gusto mong bumalik?'
                  : 'Are you sure you want to go back?',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: _isFilipino
                        ? 'KANSELAHIN'
                        : 'CANCEL',
                    color:
                    const Color(0xFF00A6C7),
                    onTap: () =>
                        Navigator.pop(
                          dialogContext,
                        ),
                    onButtonSound:
                    _playButtonSound,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: _isFilipino
                        ? 'BUMALIK'
                        : 'GO BACK',
                    color:
                    const Color(0xFFE53935),
                    onTap: () async {
                      Navigator.pop(
                        dialogContext,
                      );

                      await _stopGameBgm();

                      if (!mounted) return;

                      setState(() {
                        _canPop = true;
                      });

                      Navigator.pop(context);
                    },
                    onButtonSound:
                    _playButtonSound,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void _showSettings() {
    _playButtonSound();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor:
      Colors.black.withValues(
        alpha: 0.25,
      ),
      transitionDuration:
      const Duration(milliseconds: 250),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ListenableBuilder(
              listenable: _settings,
              builder: (context, _) {
                return Padding(
                  padding:
                  const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ),
                      child: Container(
                        width: 420,
                        constraints:
                        BoxConstraints(
                          maxHeight:
                          MediaQuery.of(
                            context,
                          )
                              .size
                              .height *
                              0.85,
                        ),
                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFF111126,
                          ).withValues(
                            alpha: 0.20,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            28,
                          ),
                          border: Border.all(
                            color: Colors.black,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(
                                0xFFC45CFF,
                              ).withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child:
                        SingleChildScrollView(
                          padding:
                          const EdgeInsets.all(
                            24,
                          ),
                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.settings,
                                    color:
                                    Color(
                                      0xFFC45CFF,
                                    ),
                                    size: 26,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: Text(
                                      _isFilipino
                                          ? 'MGA SETTING'
                                          : 'SETTINGS',
                                      style:
                                      const TextStyle(
                                        color:
                                        Colors
                                            .white,
                                        fontSize: 20,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        letterSpacing:
                                        2,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () {
                                      _playButtonSound();

                                      Navigator.pop(
                                        dialogContext,
                                      );
                                    },
                                    icon:
                                    const Icon(
                                      Icons.close,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              _sectionLabel(
                                'AUDIO',
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              _volumeControl(
                                icon: _settings
                                    .musicVolume ==
                                    0
                                    ? Icons.music_off
                                    : Icons.music_note,
                                title: _isFilipino
                                    ? 'Musika'
                                    : 'Music',
                                value: _settings
                                    .musicVolume,
                                onChanged: (value) {
                                  _settings
                                      .musicVolume =
                                      value;

                                  _updateGameBgmVolume();
                                },
                                onIconTap: () {
                                  _settings
                                      .toggleMusic();

                                  _updateGameBgmVolume();
                                },
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              _volumeControl(
                                icon: _settings
                                    .sfxVolume ==
                                    0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                title: _isFilipino
                                    ? 'Epekto ng Tunog'
                                    : 'Sound Effects',
                                value:
                                _settings.sfxVolume,
                                onChanged: (value) {
                                  _settings.sfxVolume =
                                      value;
                                },
                                onIconTap:
                                _settings.toggleSfx,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              _sectionLabel(
                                _isFilipino
                                    ? 'WIKA'
                                    : 'LANGUAGE',
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                    _languageButton(
                                      label:
                                      'English',
                                      selected:
                                      _settings
                                          .language ==
                                          AppSettings
                                              .english,
                                      onTap: () {
                                        _settings
                                            .language =
                                            AppSettings
                                                .english;
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child:
                                    _languageButton(
                                      label:
                                      'Filipino',
                                      selected:
                                      _settings
                                          .language ==
                                          AppSettings
                                              .filipino,
                                      onTap: () {
                                        _settings
                                            .language =
                                            AppSettings
                                                .filipino;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Divider(
                                color: Colors
                                    .white
                                    .withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              _menuButton(
                                icon:
                                Icons.restart_alt,
                                label: _isFilipino
                                    ? 'I-restart'
                                    : 'Restart',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.pop(
                                    dialogContext,
                                  );

                                  _confirmRestart();
                                },
                              ),
                              _menuButton(
                                icon: Icons
                                    .exit_to_app_rounded,
                                label: _isFilipino
                                    ? 'Lumabas'
                                    : 'Exit',
                                color:
                                const Color(
                                  0xFFE53935,
                                ),
                                onTap: () {
                                  Navigator.pop(
                                    dialogContext,
                                  );

                                  _confirmExit();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SETTINGS UI
  // ============================================================

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC45CFF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _volumeControl({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onIconTap,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(alpha: 0.06),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _playButtonSound();
                  onIconTap();
                },
                child: Icon(
                  icon,
                  color: value == 0
                      ? Colors.white54
                      : const Color(0xFF00F5FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style:
                const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context)
                .copyWith(
              trackHeight: 6,
              activeTrackColor:
              const Color(0xFFC45CFF),
              inactiveTrackColor:
              Colors.white24,
              thumbColor:
              const Color(0xFF39FF14),
              overlayColor:
              Colors.transparent,
              thumbShape:
              const RoundSliderThumbShape(
                enabledThumbRadius: 9,
              ),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _playButtonSound();
        onTap();
      },
      borderRadius:
      BorderRadius.circular(14),
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC45CFF)
              .withValues(alpha: 0.2)
              : Colors.white
              .withValues(alpha: 0.04),
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFC45CFF)
                : Colors.white
                .withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC45CFF),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        leading:
        Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight:
            FontWeight.w500,
          ),
        ),
        onTap: () {
          _playButtonSound();
          onTap();
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _gameHeader() {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Transform.translate(
              offset:
              const Offset(0, 19),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: Stack(
                  alignment:
                  Alignment.center,
                  children: [
                    Text(
                      'STEREOTYPICAL',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: 2,
                        foreground: Paint()
                          ..style =
                              PaintingStyle
                                  .stroke
                          ..strokeWidth = 7
                          ..strokeJoin =
                              StrokeJoin.round
                          ..color =
                              Colors.black,
                      ),
                    ),
                    ShaderMask(
                      blendMode:
                      BlendMode.srcIn,
                      shaderCallback:
                          (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(
                              0xFFFF00E6,
                            ),
                            Color(
                              0xFFFFF500,
                            ),
                            Color(
                              0xFF39FF14,
                            ),
                            Color(
                              0xFF00F5FF,
                            ),
                            Color(
                              0xFFC45CFF,
                            ),
                          ],
                        ).createShader(
                          bounds,
                        );
                      },
                      child: const Text(
                        'STEREOTYPICAL',
                        style: TextStyle(
                          color:
                          Colors.white,
                          fontSize: 26,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      right: 30,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child:
                        CustomPaint(
                          painter:
                          _RainbowStrikeThroughPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -12,
            top: -18,
            width: 58,
            height: 58,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _playButtonSound();
                _showSettings();
              },
              icon: Stack(
                alignment:
                Alignment.center,
                children: [
                  const Icon(
                    Icons.settings,
                    color: Colors.black,
                    size: 42,
                  ),
                  const Icon(
                    Icons.settings,
                    color:
                    Color(0xFFC45CFF),
                    size: 34,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) {
        if (didPop) return;

        _confirmExit();
      },
      child: Scaffold(
        backgroundColor:
        Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildGameVideoBackground(),
            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameVideoBackground() {
    if (!_gameVideoController
        .value
        .isInitialized) {
      return const SizedBox.expand();
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _gameVideoController
            .value
            .size
            .width,
        height: _gameVideoController
            .value
            .size
            .height,
        child: VideoPlayer(
          _gameVideoController,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_loadError != null) {
      return _buildLoadError();
    }

    final session = _session;

    if (session == null) {
      return _buildLoading();
    }

    if (session.isFinished &&
        !session.awaitingNext) {
      return _buildRoundComplete();
    }

    return Column(
      children: [
        _gameHeader(),
        const SizedBox(height: 10),
        _progressRow(session),
        const SizedBox(height: 10),
        if (!_showFeedback)
          Text(
            _isFilipino
                ? 'I-SWIPE ANG CARD SA PANIG NA SA TINGIN MO AY TAMA.'
                : 'SWIPE THE CARD TOWARD THE SIDE IT BELONGS TO.',
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight:
              FontWeight.w900,
              letterSpacing: 0.5,
              shadows:
              comicShadows,
            ),
          ),
        Expanded(
          child: _showFeedback
              ? _feedbackPanel(session)
              : _cardArea(session),
        ),
        if (!_showFeedback) ...[
          const SizedBox(height: 12),
          _sideHints(),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child:
            CircularProgressIndicator(
              strokeWidth: 3,
              color:
              Color(0xFFC45CFF),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            _isFilipino
                ? 'Nilo-load ang mga sitwasyon...'
                : 'Loading situations...',
            style: const TextStyle(
              color:
              Color(0xFFE6B4FF),
              fontSize: 14,
              shadows:
              comicShadows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
            Color(0xFFFF4DDB),
            size: 48,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            _isFilipino
                ? 'Hindi ma-load ang mga sitwasyon.'
                : 'Could not load the situations.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
              shadows:
              comicShadows,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            '$_loadError',
            textAlign:
            TextAlign.center,
            maxLines: 4,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              shadows:
              comicShadows,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          OutlinedButton(
            onPressed: () {
              _playButtonSound();
              _retryLoad();
            },
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              const Color(
                0xFF00E5FF,
              ),
              side:
              const BorderSide(
                color:
                Color(0xFF00E5FF),
              ),
            ),
            child: Text(
              _isFilipino
                  ? 'SUBUKAN MULI'
                  : 'RETRY',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundComplete() {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color:
            Color(0xFFFFD740),
            size: 52,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            _isFilipino
                ? 'Tapos na ang round!'
                : 'Round complete!',
            style:
            const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
              shadows:
              comicShadows,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          OutlinedButton(
            onPressed: () {
              _playButtonSound();
              _showResults();
            },
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              const Color(
                0xFF00E5FF,
              ),
              side:
              const BorderSide(
                color:
                Color(0xFF00E5FF),
              ),
            ),
            child: Text(
              _isFilipino
                  ? 'TINGNAN ANG RESULTA'
                  : 'SEE RESULTS',
            ),
          ),
          TextButton(
            onPressed: () {
              _playButtonSound();
              _confirmExit();
            },
            child: Text(
              _isFilipino
                  ? 'BUMALIK SA MENU'
                  : 'BACK TO MENU',
              style:
              const TextStyle(
                color:
                Color(0xFFFF4DDB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _progressRow(
      GameSession session,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment
          .spaceBetween,
      children: [
        _statPill(
          'CARD ${session.currentNumber} / ${session.total}',
          const Color(0xFF00E5FF),
        ),
        _statPill(
          '${_isFilipino ? 'ISKOR' : 'SCORE'} ${session.score}',
          const Color(0xFFFFD740),
        ),
      ],
    );
  }

  Widget _statPill(
      String label,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
          FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _cardArea(
      GameSession session,
      ) {
    final card = session.current;

    if (card == null) {
      return const SizedBox.shrink();
    }

    final screenWidth =
        MediaQuery.of(context)
            .size
            .width;

    final cardRotation =
    (_dragOffset / 1000)
        .clamp(-0.25, 0.25);

    final dx = _dragOffset.clamp(
      -screenWidth * 1.5,
      screenWidth * 1.5,
    );

    final dy = _dragY.clamp(
      -120.0,
      120.0,
    );

    final text = card.textFor(
      _settings.languageCode,
    );

    return Center(
      child: GestureDetector(
        behavior:
        HitTestBehavior.opaque,
        onPanStart: (_) {
          if (_isAnimatingOut ||
              session.awaitingNext) {
            return;
          }

          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          if (_isAnimatingOut ||
              session.awaitingNext) {
            return;
          }

          setState(() {
            _dragOffset +=
                details.delta.dx;
            _dragY +=
                details.delta.dy;
          });
        },
        onPanEnd: (details) {
          if (_isAnimatingOut ||
              session.awaitingNext) {
            return;
          }

          _handleSwipeEnd(details);
        },
        child: AnimatedContainer(
          duration: Duration(
            milliseconds:
            _isDragging ? 0 : 350,
          ),
          curve:
          Curves.easeOutCubic,
          transformAlignment:
          Alignment.center,
          transform:
          Matrix4.translationValues(
            dx,
            dy,
            0,
          )..rotateZ(
            cardRotation,
          ),
          width: double.infinity,
          height: double.infinity,
          constraints:
          const BoxConstraints(
            maxHeight: 600,
          ),
          padding:
          const EdgeInsets.all(14),
          child: CustomPaint(
            foregroundPainter:
            _NeonRainbowBorderPainter(),
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(
                24,
              ),
              child:
              BackdropFilter(
                filter:
                ImageFilter.blur(
                  sigmaX: 16,
                  sigmaY: 16,
                ),
                child: Container(
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFF111126,
                    ).withValues(
                      alpha: 0.45,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      24,
                    ),
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Text(
                      text,
                      textAlign:
                      TextAlign.center,
                      maxLines: 12,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style: TextStyle(
                        color:
                        Colors.white,
                        fontSize:
                        _cardFontSize(
                          text,
                        ),
                        fontWeight:
                        FontWeight
                            .bold,
                        height: 1.4,
                        shadows:
                        const [
                          Shadow(
                            color:
                            Color(
                              0xFFFF00E6,
                            ),
                            blurRadius:
                            12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _cardFontSize(
      String text,
      ) {
    if (text.length > 120) {
      return 18;
    }

    if (text.length > 80) {
      return 20;
    }

    return 23;
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  Widget _feedbackPanel(
      GameSession session,
      ) {
    final feedback =
        session.pendingFeedback;

    if (feedback == null) {
      return const SizedBox.shrink();
    }

    final correct =
        feedback.isCorrect;

    final color = correct
        ? const Color(0xFF39FF14)
        : const Color(0xFFFFD740);

    final isLast =
        session.answeredCount >=
            session.total;

    return SingleChildScrollView(
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18,
            sigmaY: 18,
          ),
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(22),
            decoration:
            BoxDecoration(
              color: Color.alphaBlend(
                const Color(
                  0xFF111126,
                ).withValues(
                  alpha: 0.55,
                ),
                color.withValues(
                  alpha: 0.16,
                ),
              ),
              borderRadius:
              BorderRadius.circular(
                24,
              ),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.75,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  color.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  correct
                      ? Icons
                      .check_circle_rounded
                      : Icons.info_rounded,
                  color: color,
                  size: 46,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  _isFilipino
                      ? (correct
                      ? 'TAMA!'
                      : 'HINDI TAMA.')
                      : (correct
                      ? 'EXACTLY!'
                      : 'NOT QUITE.'),
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  _thisWasLabel(
                    feedback.card.kind,
                    correct: correct,
                  ),
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFFE6B4FF),
                    fontSize: 14,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Text(
                  feedback.card
                      .explanationFor(
                    _settings
                        .languageCode,
                  ),
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                    FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width:
                  double.infinity,
                  child:
                  OutlinedButton(
                    onPressed: () {
                      _playButtonSound();
                      _nextCard();
                    },
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      color,
                      side:
                      BorderSide(
                        color: color
                            .withValues(
                          alpha: 0.85,
                        ),
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 14,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),
                    ),
                    child: Text(
                      isLast
                          ? (_isFilipino
                          ? 'TINGNAN ANG RESULTA'
                          : 'SEE RESULTS')
                          : (_isFilipino
                          ? 'SUSUNOD'
                          : 'NEXT'),
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        letterSpacing: 1,
                      ),
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

  String _thisWasLabel(
      SituationKind kind, {
        required bool correct,
      }) {
    final isStereotype =
        kind == SituationKind.stereotype;

    if (_isFilipino) {
      final label = isStereotype
          ? 'isang isteryotipo'
          : 'magalang';

      return correct
          ? 'Ito ay $label.'
          : 'Ito pala ay $label.';
    }

    final label =
    isStereotype
        ? 'a stereotype'
        : 'respectful';

    return correct
        ? 'This was $label.'
        : 'This was actually $label.';
  }

  // ============================================================
  // SIDE HINTS
  // ============================================================

  Widget _sideHints() {
    return Row(
      children: [
        Expanded(
          child: _SideHint(
            icon:
            Icons.arrow_back_rounded,
            title: _isFilipino
                ? 'ISTERYOTIPO'
                : 'STEREOTYPE',
            subtitle: _isFilipino
                ? 'I-swipe pakaliwa'
                : 'Swipe left',
            color:
            const Color(0xFF00E5FF),
            active:
            _dragOffset < -20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SideHint(
            icon:
            Icons.arrow_forward_rounded,
            title: _isFilipino
                ? 'MAGALANG'
                : 'RESPECTFUL',
            subtitle: _isFilipino
                ? 'I-swipe pakanan'
                : 'Swipe right',
            color:
            const Color(0xFFFF4DDB),
            active:
            _dragOffset > 20,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// NEON CARD BORDER
// ================================================================

class _NeonRainbowBorderPainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const colors = [
      Color(0xFFFF00E6),
      Color(0xFFFFF500),
      Color(0xFF39FF14),
      Color(0xFF00F5FF),
      Color(0xFFC45CFF),
      Color(0xFFFF00E6),
    ];

    final rect =
    Offset.zero & size;

    final borderRect =
    rect.deflate(4);

    final rrect =
    RRect.fromRectAndRadius(
      borderRect,
      const Radius.circular(24),
    );

    final blackOutlinePaint =
    Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.black;

    canvas.drawRRect(
      rrect,
      blackOutlinePaint,
    );

    const gradient =
    LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final glowPaint = Paint()
      ..shader =
      gradient.createShader(
        rect,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter =
      const MaskFilter.blur(
        BlurStyle.normal,
        10,
      );

    canvas.drawRRect(
      rrect,
      glowPaint,
    );

    final borderPaint = Paint()
      ..shader =
      gradient.createShader(
        rect,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      rrect,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

// ================================================================
// RAINBOW STRIKE
// ================================================================

class _RainbowStrikeThroughPainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const colors = [
      Color(0xFFFF00E6),
      Color(0xFFFFF500),
      Color(0xFF39FF14),
      Color(0xFF00F5FF),
      Color(0xFFC45CFF),
    ];

    final paint = Paint()
      ..shader =
      const LinearGradient(
        colors: colors,
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap =
          StrokeCap.round;

    final y =
        size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

// ================================================================
// SIDE HINT
// ================================================================

class _SideHint
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;

  const _SideHint({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 120,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha:
          active ? 0.22 : 0.06,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          color.withValues(
            alpha:
            active ? 0.95 : 0.35,
          ),
          width:
          active ? 2 : 1,
        ),
        boxShadow:
        active
            ? [
          BoxShadow(
            color:
            color.withValues(
              alpha: 0.35,
            ),
            blurRadius: 18,
          ),
        ]
            : const [],
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(
            height: 6,
          ),
          FittedBox(
            fit:
            BoxFit.scaleDown,
            child: Text(
              title,
              style:
              TextStyle(
                color: color,
                fontSize: 13,
                fontWeight:
                FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          FittedBox(
            fit:
            BoxFit.scaleDown,
            child: Text(
              subtitle,
              style:
              const TextStyle(
                color:
                Colors.white60,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// GLASS DIALOG
// ================================================================

class _GlassDialog
    extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassDialog({
    required this.title,
    required this.children,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding:
          const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius:
            BorderRadius.circular(28),
            child: BackdropFilter(
              filter:
              ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
              child: Container(
                width: 420,
                constraints:
                BoxConstraints(
                  maxHeight:
                  MediaQuery.of(
                    context,
                  )
                      .size
                      .height *
                      0.85,
                ),
                padding:
                const EdgeInsets.all(24),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF111126,
                  ).withValues(
                    alpha: 0.20,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    28,
                  ),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      const Color(
                        0xFFC45CFF,
                      ).withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child:
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 20,
                          fontWeight:
                          FontWeight
                              .w900,
                          letterSpacing:
                          1.5,
                          shadows: [
                            Shadow(
                              color:
                              Colors
                                  .black,
                              offset:
                              Offset(
                                2,
                                2,
                              ),
                              blurRadius:
                              0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// DIALOG BUTTON
// ================================================================

class _DialogButton
    extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onButtonSound;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.onButtonSound,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      width: double.infinity,
      child:
      OutlinedButton(
        onPressed: () {
          onButtonSound();
          onTap();
        },
        style:
        OutlinedButton.styleFrom(
          foregroundColor:
          color,
          side: BorderSide(
            color:
            color.withValues(
              alpha: 0.8,
            ),
          ),
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign:
          TextAlign.center,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
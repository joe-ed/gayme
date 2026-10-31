
import 'dart:ui';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double _dragOffset = 0;
  double _dragY = 0;

  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;

  double _previousMusicVolume = 0.7;
  double _previousSfxVolume = 0.8;

  double _titleOffsetX = 0;
  double _titleOffsetY = 0;

  String _language = 'English';
  String _swipeMessage = 'Swipe left or right';

  bool _isDragging = false;
  bool _isAnimatingOut = false;

  bool get _isFilipino => _language == 'Filipino';

  void _toggleMusic() {
    setState(() {
      if (_musicVolume > 0) {
        _previousMusicVolume = _musicVolume;
        _musicVolume = 0;
      } else {
        _musicVolume =
        _previousMusicVolume > 0 ? _previousMusicVolume : 0.7;
      }
    });
  }

  void _toggleSfx() {
    setState(() {
      if (_sfxVolume > 0) {
        _previousSfxVolume = _sfxVolume;
        _sfxVolume = 0;
      } else {
        _sfxVolume =
        _previousSfxVolume > 0 ? _previousSfxVolume : 0.8;
      }
    });
  }

  void _changeMusicVolume(double value) {
    setState(() {
      _musicVolume = value;

      if (value > 0) {
        _previousMusicVolume = value;
      }
    });
  }

  void _changeSfxVolume(double value) {
    setState(() {
      _sfxVolume = value;

      if (value > 0) {
        _previousSfxVolume = value;
      }
    });
  }

  void _handleSwipeEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldSwipe =
        _dragOffset.abs() > 100 || velocity.abs() > 700;

    if (shouldSwipe) {
      final direction = _dragOffset.abs() > 100
          ? _dragOffset.sign
          : velocity.sign;

      if (direction == 0) return;

      final screenWidth = MediaQuery.of(context).size.width;

      setState(() {
        _isDragging = false;
        _isAnimatingOut = true;
        _dragOffset = direction * screenWidth * 1.5;
        _dragY = 0;

        _swipeMessage = direction < 0
            ? (_isFilipino ? 'Nag-swipe pakaliwa' : 'Swiped left')
            : (_isFilipino ? 'Nag-swipe pakanan' : 'Swiped right');
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;

        setState(() {
          _dragOffset = 0;
          _dragY = 0;
          _isAnimatingOut = false;
        });
      });
    } else {
      setState(() {
        _isDragging = false;
        _dragOffset = 0;
        _dragY = 0;
        _swipeMessage = _isFilipino
            ? 'Mag-swipe nang mas malayo'
            : 'Swipe farther to choose';
      });
    }
  }

  void _restartGame() {
    setState(() {
      _dragOffset = 0;
      _dragY = 0;
      _isDragging = false;
      _isAnimatingOut = false;
      _swipeMessage = _isFilipino
          ? 'Mag-swipe pakaliwa o pakanan'
          : 'Swipe left or right';
    });
  }

  void _showSettings() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 20,
                        sigmaY: 20,
                      ),
                      child: Container(
                        width: 420,
                        constraints: BoxConstraints(
                          maxHeight:
                          MediaQuery.of(context).size.height * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111126)
                              .withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC45CFF)
                                  .withValues(alpha: 0.12),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.settings,
                                    color: Color(0xFFC45CFF),
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _isFilipino
                                          ? 'MGA SETTING'
                                          : 'SETTINGS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _sectionLabel('AUDIO'),
                              const SizedBox(height: 16),
                              _volumeControl(
                                icon: _musicVolume == 0
                                    ? Icons.music_off
                                    : Icons.music_note,
                                title: _isFilipino ? 'Musika' : 'Music',
                                value: _musicVolume,
                                onChanged: (value) {
                                  _changeMusicVolume(value);
                                  setModalState(() {});
                                },
                                onIconTap: () {
                                  _toggleMusic();
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 12),
                              _volumeControl(
                                icon: _sfxVolume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                title: _isFilipino
                                    ? 'Epekto ng Tunog'
                                    : 'Sound Effects',
                                value: _sfxVolume,
                                onChanged: (value) {
                                  _changeSfxVolume(value);
                                  setModalState(() {});
                                },
                                onIconTap: () {
                                  _toggleSfx();
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 24),
                              _sectionLabel(
                                _isFilipino ? 'WIKA' : 'LANGUAGE',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _languageButton(
                                      label: 'English',
                                      selected: _language == 'English',
                                      onTap: () {
                                        setState(() {
                                          _language = 'English';
                                          _swipeMessage =
                                          'Swipe left or right';
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _languageButton(
                                      label: 'Filipino',
                                      selected: _language == 'Filipino',
                                      onTap: () {
                                        setState(() {
                                          _language = 'Filipino';
                                          _swipeMessage =
                                          'Mag-swipe pakaliwa o pakanan';
                                        });
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 8),
                              _menuButton(
                                icon: Icons.restart_alt,
                                label: _isFilipino ? 'I-restart' : 'Restart',
                                color: Colors.white,
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  _restartGame();
                                },
                              ),
                              _menuButton(
                                icon: Icons.exit_to_app,
                                label: _isFilipino ? 'Lumabas' : 'Exit',
                                color: const Color(0xFFFF4DDB),
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  Navigator.pop(this.context);
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onIconTap,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF00F5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: const Color(0xFFC45CFF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF39FF14),
              overlayColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC45CFF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFC45CFF)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _gameHeader() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Transform.translate(
              offset: Offset(_titleOffsetX, _titleOffsetY + 35),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
                      child: const Text(
                        'STEREOTYPICAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
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
                        child: CustomPaint(
                          painter: _RainbowStrikeThroughPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _showSettings,
              icon: const Icon(
                Icons.settings,
                color: Color(0xFFC45CFF),
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardRotation = (_dragOffset / 1000).clamp(-0.25, 0.25);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/rainbow.gif',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Color(0xFF080817),
              );
            },
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _gameHeader(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) {
                          if (_isAnimatingOut) return;
                          setState(() {
                            _isDragging = true;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isAnimatingOut) return;
                          setState(() {
                            _dragOffset += details.delta.dx;
                            _dragY += details.delta.dy;
                          });
                        },
                        onPanEnd: (details) {
                          if (_isAnimatingOut) return;
                          _handleSwipeEnd(details);
                        },
                        child: AnimatedContainer(
                          duration: Duration(
                            milliseconds: _isDragging ? 0 : 350,
                          ),
                          curve: Curves.easeOutCubic,
                          transformAlignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(
                              _dragOffset.clamp(
                                -MediaQuery.of(context).size.width * 1.5,
                                MediaQuery.of(context).size.width * 1.5,
                              ),
                              _dragY.clamp(-120.0, 120.0),
                            )
                            ..rotateZ(cardRotation),
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            minHeight: 450,
                            maxHeight: 600,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: CustomPaint(
                            foregroundPainter: _NeonRainbowBorderPainter(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.025),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  _isFilipino
                                      ? 'Lalabas dito ang sitwasyon'
                                      : 'Situation will appear here',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _swipeMessage,
                    style: const TextStyle(
                      color: Color(0xFFE6B4FF),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SwipeHint(
                        icon: Icons.arrow_back_rounded,
                        label: _isFilipino ? 'PAKALIWA' : 'SWIPE LEFT',
                        color: const Color(0xFF00E5FF),
                      ),
                      _SwipeHint(
                        icon: Icons.arrow_forward_rounded,
                        label: _isFilipino ? 'PAKANAN' : 'SWIPE RIGHT',
                        color: const Color(0xFFFF4DDB),
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
}

class _NeonRainbowBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFF00E6),
      Color(0xFFFFF500),
      Color(0xFF39FF14),
      Color(0xFF00F5FF),
      Color(0xFFC45CFF),
      Color(0xFFFF00E6),
    ];

    final rect = Offset.zero & size;
    final borderRect = rect.deflate(2);
    final rrect = RRect.fromRectAndRadius(
      borderRect,
      const Radius.circular(24),
    );

    const gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawRRect(rrect, glowPaint);

    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RainbowStrikeThroughPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFF00E6),
      Color(0xFFFFF500),
      Color(0xFF39FF14),
      Color(0xFF00F5FF),
      Color(0xFFC45CFF),
    ];

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: colors,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SwipeHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SwipeHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

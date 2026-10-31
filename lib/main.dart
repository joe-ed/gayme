
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';
import 'achievement_screen.dart';

void main() {
  runApp(const StereotypicalApp());
}

const List<Color> rainbowColors = [
  Color(0xFFFF00E6),
  Color(0xFFFFF500),
  Color(0xFF39FF14),
  Color(0xFF00F5FF),
  Color(0xFF9D00FF),
  Color(0xFFFF00E6),
];

class StereotypicalApp extends StatelessWidget {
  const StereotypicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stereotypical',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const MainMenu(),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rainbowController;

  double musicVolume = 0.7;
  double sfxVolume = 0.8;

  double previousMusicVolume = 0.7;
  double previousSfxVolume = 0.8;

  String language = 'English';

  bool get isFilipino => language == 'Filipino';

  @override
  void initState() {
    super.initState();

    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _rainbowController.dispose();
    super.dispose();
  }

  void toggleMusic() {
    setState(() {
      if (musicVolume > 0) {
        previousMusicVolume = musicVolume;
        musicVolume = 0;
      } else {
        musicVolume =
        previousMusicVolume > 0 ? previousMusicVolume : 0.7;
      }
    });
  }

  void toggleSfx() {
    setState(() {
      if (sfxVolume > 0) {
        previousSfxVolume = sfxVolume;
        sfxVolume = 0;
      } else {
        sfxVolume =
        previousSfxVolume > 0 ? previousSfxVolume : 0.8;
      }
    });
  }

  void changeMusicVolume(double value) {
    setState(() {
      musicVolume = value;

      if (value > 0) {
        previousMusicVolume = value;
      }
    });
  }

  void changeSfxVolume(double value) {
    setState(() {
      sfxVolume = value;

      if (value > 0) {
        previousSfxVolume = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/rainbow.gif',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF170C63),
                      Color(0xFF4921A8),
                      Color(0xFF087EC2),
                      Color(0xFF771D9C),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final logoSize =
                (width * 0.70).clamp(210.0, 320.0);
                final iconSize = width < 380 ? 58.0 : 66.0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: height * 0.09,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: StereotypicalLogo(
                          size: logoSize,
                          rotation:
                          _rainbowController.value * 6.28318,
                          animation: _rainbowController,
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.45,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: NeonIcon(
                          icon: Icons.settings_rounded,
                          color: const Color(0xFFB76BFF),
                          onTap: showSettings,
                          size: iconSize,
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.51,
                      left: width * 0.20,
                      child: NeonIcon(
                        icon: Icons.help_outline_rounded,
                        color: const Color(0xFF00E5FF),
                        onTap: showHowToPlay,
                        size: iconSize,
                      ),
                    ),
                    Positioned(
                      top: height * 0.51,
                      right: width * 0.20,
                      child: NeonIcon(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD740),
                        onTap: showAchievements,
                        size: iconSize,
                      ),
                    ),
                    Positioned(
                      top: height * 0.60,
                      left: width * 0.08,
                      child: NeonIcon(
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFFFF4DDB),
                        onTap: showCredits,
                        size: iconSize,
                      ),
                    ),
                    Positioned(
                      top: height * 0.60,
                      right: width * 0.08,
                      child: NeonIcon(
                        icon: Icons.exit_to_app_rounded,
                        color: const Color(0xFFFF5252),
                        onTap: confirmExit,
                        size: iconSize,
                      ),
                    ),
                    Positioned(
                      top: height * 0.70,
                      left: width * 0.16,
                      right: width * 0.16,
                      child: AnimatedBuilder(
                        animation: _rainbowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(100),
                              gradient: SweepGradient(
                                transform: GradientRotation(
                                  _rainbowController.value *
                                      6.28318,
                                ),
                                colors: rainbowColors,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rainbowColors[
                                  (_rainbowController.value * 5)
                                      .floor() %
                                      5
                                  ].withValues(alpha: 0.65),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: _MenuButton(
                          icon: Icons.play_arrow_rounded,
                          label: isFilipino
                              ? 'SIMULAN ANG LARO'
                              : 'START GAME',
                          onTap: startGame,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  void showAchievements() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AchievementScreen(),
      ),
    );
  }

  void confirmExit() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _GlassDialog(
          title: isFilipino ? 'LUMABAS SA LARO?' : 'EXIT GAME?',
          children: [
            Text(
              isFilipino
                  ? 'Sigurado ka bang gusto mong lumabas?'
                  : 'Are you sure you want to exit?',
              textAlign: TextAlign.center,
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
                    label: isFilipino ? 'KANSELAHIN' : 'CANCEL',
                    color: const Color(0xFF00E5FF),
                    onTap: () => Navigator.pop(dialogContext),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogButton(
                    label: isFilipino ? 'LUMABAS' : 'EXIT',
                    color: const Color(0xFFFF4DDB),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      SystemNavigator.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
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

  void showSettings() {
    showGeneralDialog<void>(
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
              builder: (context, setDialogState) {
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
                          MediaQuery.of(context).size.height *
                              0.85,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111126)
                              .withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.28),
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
                                      isFilipino
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
                              _settingsSection('AUDIO'),
                              const SizedBox(height: 16),
                              _SettingsVolumeControl(
                                icon: musicVolume == 0
                                    ? Icons.music_off
                                    : Icons.music_note,
                                title:
                                isFilipino ? 'Musika' : 'Music',
                                value: musicVolume,
                                onChanged: (value) {
                                  changeMusicVolume(value);
                                  setDialogState(() {});
                                },
                                onIconTap: () {
                                  toggleMusic();
                                  setDialogState(() {});
                                },
                              ),
                              const SizedBox(height: 12),
                              _SettingsVolumeControl(
                                icon: sfxVolume == 0
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                title: isFilipino
                                    ? 'Epekto ng Tunog'
                                    : 'Sound Effects',
                                value: sfxVolume,
                                onChanged: (value) {
                                  changeSfxVolume(value);
                                  setDialogState(() {});
                                },
                                onIconTap: () {
                                  toggleSfx();
                                  setDialogState(() {});
                                },
                              ),
                              const SizedBox(height: 24),
                              _settingsSection(
                                isFilipino ? 'WIKA' : 'LANGUAGE',
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SettingsLanguageButton(
                                      label: 'English',
                                      selected:
                                      language == 'English',
                                      onTap: () {
                                        setState(() {
                                          language = 'English';
                                        });
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SettingsLanguageButton(
                                      label: 'Filipino',
                                      selected:
                                      language == 'Filipino',
                                      onTap: () {
                                        setState(() {
                                          language = 'Filipino';
                                        });
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Divider(
                                color: Colors.white
                                    .withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 8),
                              _DialogButton(
                                label:
                                isFilipino ? 'TAPOS NA' : 'DONE',
                                color: const Color(0xFF00E5FF),
                                onTap: () =>
                                    Navigator.pop(dialogContext),
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
            scale: Tween<double>(begin: 0.92, end: 1).animate(
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

  Widget _settingsSection(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFC45CFF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void showHowToPlay() {
    showInfoDialog(
      isFilipino ? 'PAANO MAGLARO' : 'HOW TO PLAY',
      isFilipino
          ? 'Basahing mabuti ang bawat sitwasyon.\n\n'
          'Mag-swipe pakaliwa o pakanan upang pumili ng sagot.\n\n'
          'Matutong umunawa at gumalang sa iba’t ibang pagkakakilanlan ng kasarian.'
          : 'Read each situation carefully.\n\n'
          'Swipe left or right to choose your answer.\n\n'
          'Learn how your choices can help promote understanding and respect for different gender identities.',
    );
  }

  void showCredits() {
    showInfoDialog(
      isFilipino ? 'MGA KREDITO' : 'CREDITS',
      isFilipino
          ? 'STEREOTYPICAL\n\n'
          'Binuo ng inyong pangkat.\n\n'
          'Idagdag dito ang mga miyembro ng pangkat at mga pagkilala.'
          : 'STEREOTYPICAL\n\n'
          'Developed by your project team.\n\n'
          'Add your team members and acknowledgments here.',
    );
  }

  void showInfoDialog(String title, String message) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _GlassDialog(
          title: title,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _DialogButton(
              label: isFilipino ? 'ISARA' : 'CLOSE',
              color: const Color(0xFF00E5FF),
              onTap: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
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
}

class _SettingsVolumeControl extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onIconTap;

  const _SettingsVolumeControl({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _SettingsLanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassDialog({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
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
                padding: const EdgeInsets.all(24),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE6B4FF),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
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

class StereotypicalLogo extends StatelessWidget {
  final double size;
  final double rotation;
  final Animation<double> animation;

  const StereotypicalLogo({
    super.key,
    required this.size,
    required this.rotation,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentRotation = animation.value * 6.28318;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.22,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: rainbowColors,
                    ).createShader(bounds);
                  },
                  child: Transform.translate(
                    offset: Offset(0, size * 0.08),
                    child: Text(
                      '⚧',
                      style: TextStyle(
                        fontSize: size * 0.65,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.07,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        'STEREOTYPICAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size * 0.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = const Color(0xFF240044),
                        ),
                      ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: rainbowColors,
                          ).createShader(bounds);
                        },
                        child: Text(
                          'STEREOTYPICAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size * 0.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color(0xFFFF00E6),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: Color(0xFF00F5FF),
                                blurRadius: 18,
                              ),
                              Shadow(
                                color: Color(0xFF9D00FF),
                                blurRadius: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -0.72,
                child: Container(
                  width: size * 1.08,
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      transform: GradientRotation(currentRotation),
                      colors: rainbowColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: rainbowColors[
                        (animation.value * 5).floor() % 5
                        ].withValues(alpha: 0.65),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                size: Size(size, size),
                painter: RainbowCirclePainter(
                  rotation: currentRotation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RainbowCirclePainter extends CustomPainter {
  final double rotation;

  RainbowCirclePainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width / 2 - 4;

    final shader = SweepGradient(
      transform: GradientRotation(rotation),
      colors: rainbowColors,
    ).createShader(rect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..shader = shader;

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..shader = shader;

    canvas.drawCircle(rect.center, radius, glowPaint);
    canvas.drawCircle(rect.center, radius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant RainbowCirclePainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

class NeonIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const NeonIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF21104D)
                .withValues(alpha: 0.82),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.7),
                blurRadius: 13,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.54,
            shadows: [
              Shadow(
                color: color,
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF241071),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5417D7),
                Color(0xFF25106E),
                Color(0xFF0759B9),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: Color(0xFFEA66FF),
                        blurRadius: 10,
                      ),
                    ],
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

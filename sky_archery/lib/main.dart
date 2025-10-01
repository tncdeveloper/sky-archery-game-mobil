import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);


  runApp(MaterialApp(
    home: MainMenuScreen(),
    debugShowCheckedModeBanner: false,
  ));
}





// 3. Bonus Teklif Overlay'i (GameOverOverlay içine eklenecek)
class BonusOfferOverlay extends PositionComponent with HasGameRef {
  final String offerType; // 'arrows' veya 'time'
  final int bonusAmount;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  late RectangleComponent background;
  late RectangleComponent mainPanel;
  List<Component> animatedComponents = [];

  BonusOfferOverlay({
    required this.offerType,
    required this.bonusAmount,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    await _createBackground();
    await _createMainPanel();
    await _createContent();
    await _startAnimations();
  }

  Future<void> _createBackground() async {
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.9),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );
    add(background);
  }

  Future<void> _createMainPanel() async {
    final panelWidth = size.x * 0.85;
    final panelHeight = size.y * 0.6;

    // Ana panel - glassmorphism tasarım
    mainPanel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e).withOpacity(0.95),
            Color(0xFF16213e).withOpacity(0.9),
            Color(0xFF0f3460).withOpacity(0.95),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth, panelHeight)),
    );

    // Glow efekti
    for (int i = 0; i < 3; i++) {
      final glowSize = panelWidth + (i * 6) + 8;
      final glowPanel = RectangleComponent(
        size: Vector2(glowSize, panelHeight + (i * 6) + 8),
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.orange.withOpacity(0.3 - i * 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 + i * 4),
      );
      add(glowPanel);
    }

    add(mainPanel);
    animatedComponents.add(mainPanel);
  }

  Future<void> _createContent() async {
    // Video icon ve başlık
    final iconComponent = TextComponent(
      text: '📹',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: _getResponsiveFontSize(48),
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.15),
    );
    add(iconComponent);
    animatedComponents.add(iconComponent);

    // Başlık
    final titleText = offerType == 'arrows' ? 'Out of Arrows!' : 'Time\'s Up!';
    final titleComponent = TextComponent(
      text: titleText,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: _getResponsiveFontSize(28),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.orange.withOpacity(0.8),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.08),
    );
    add(titleComponent);
    animatedComponents.add(titleComponent);

    // Teklif metni
    final offerText = offerType == 'arrows'
        ? 'Watch a video to get $bonusAmount more arrows!'
        : 'Watch a video to get $bonusAmount more seconds!';

    final offerComponent = TextComponent(
      text: offerText,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: _getResponsiveFontSize(18),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.02),
    );
    add(offerComponent);
    animatedComponents.add(offerComponent);

    // Butonlar
    await _createButtons();
  }

  Future<void> _createButtons() async {
    final buttonY = size.y / 2 + size.y * 0.12;

    // Watch Video butonu
    _createModernButton(
        'WATCH VIDEO',
        Vector2(size.x / 2 - 90, buttonY),
        Color(0xFF4CAF50),
        onAccept
    );

    // No Thanks butonu
    _createModernButton(
        'NO THANKS',
        Vector2(size.x / 2 + 90, buttonY),
        Color(0xFFFF5722),
        onDecline
    );
  }

  void _createModernButton(String text, Vector2 position, Color color, VoidCallback onPressed) {
    final buttonSize = Vector2(140, 50);

    // Button glow
    final glowButton = RectangleComponent(
      size: Vector2(buttonSize.x + 8, buttonSize.y + 8),
      position: position,
      anchor: Anchor.center,
      paint: Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0),
    );
    add(glowButton);

    // Main button
    final button = ButtonComponent(
      size: buttonSize,
      position: position,
      anchor: Anchor.center,
      onPressed: onPressed,
      button: RectangleComponent(
        size: buttonSize,
        paint: Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
            ],
          ).createShader(Rect.fromLTWH(0, 0, buttonSize.x, buttonSize.y)),
      ),
    );
    add(button);
    animatedComponents.add(button);

    // Button text
    final buttonText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: _getResponsiveFontSize(14),
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
      position: position,
    );
    add(buttonText);
  }

  Future<void> _startAnimations() async {
    // Panel entrance
    mainPanel.scale = Vector2.zero();
    mainPanel.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.6,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Staggered animations
    for (int i = 0; i < animatedComponents.length; i++) {
      final component = animatedComponents[i];
      component.add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(
            duration: 0.4,
            curve: Curves.easeOutBack,
            startDelay: i * 0.1,
          ),
        ),
      );
    }
  }

  double _getResponsiveFontSize(double baseSize) {
    final scale = (size.x / 400).clamp(0.8, 1.2);
    return baseSize * scale;
  }
}

class ChapterData {
  final int chapterNumber;
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final int requiredStars; // Bu bölümü açmak için gereken toplam yıldız
  final String theme; // 'spring', 'desert', 'ice'

  ChapterData({
    required this.chapterNumber,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.requiredStars,
    required this.theme,
  });
}

// Level veri yapısı
class LevelData {
  final int levelNumber;
  final int chapterNumber; // Hangi bölümde olduğu
  final int birdCount;
  final String objective;
  final int? maxArrows;
  final int? timeLimit; // saniye
  final bool headShotsOnly;
  final int? consecutiveHits;

  LevelData({
    required this.levelNumber,
    required this.chapterNumber,
    required this.birdCount,
    required this.objective,
    this.maxArrows,
    this.timeLimit,
    this.headShotsOnly = false,
    this.consecutiveHits,
  });
}

class GameChapters {
  static final List<ChapterData> chapters = [
    ChapterData(
      chapterNumber: 1,
      title: "🌸 Spring Meadows",
      description: "Fresh air and gentle winds",
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFF8BC34A),
      requiredStars: 0,
      theme: 'spring',
    ),
    ChapterData(
      chapterNumber: 2,
      title: "🏜️ Desert Sands",
      description: "Heat waves and challenging winds",
      primaryColor: Color(0xFFFF9800),
      secondaryColor: Color(0xFFFFC107),
      requiredStars: 70, // 1. bölümden 70 yıldız
      theme: 'desert',
    ),
    ChapterData(
      chapterNumber: 3,
      title: "❄️ Frozen Peaks",
      description: "Icy winds and crystal clear shots",
      primaryColor: Color(0xFF03A9F4),
      secondaryColor: Color(0xFF81D4FA),
      requiredStars: 150, // Toplam 150 yıldız
      theme: 'ice',
    ),
  ];
}

// Level verilerini tanımla
// Level verilerini tanımla - YENİ TASARIM
class GameLevels {
  static final List<LevelData> levels = [
    // BÖLÜM 1: Spring Meadows (1-30)
    LevelData(levelNumber: 1, chapterNumber: 1, birdCount: 1, objective: "Shoot 1 bird with unlimited arrows"),
    LevelData(levelNumber: 2, chapterNumber: 1, birdCount: 3, objective: "Shoot 3 birds with unlimited arrows"),
    LevelData(levelNumber: 3, chapterNumber: 1, birdCount: 6, objective: "Shoot 6 birds with unlimited arrows"),
    LevelData(levelNumber: 4, chapterNumber: 1, birdCount: 5, objective: "Get 1 headshot and shoot 5 birds with unlimited arrows", consecutiveHits: 1),
    LevelData(levelNumber: 5, chapterNumber: 1, birdCount: 4, objective: "Shoot 4 birds in 80 seconds with unlimited arrows", timeLimit: 80),
    LevelData(levelNumber: 6, chapterNumber: 1, birdCount: 5, objective: "Get 1 headshot and shoot 5 birds in 90 seconds with unlimited arrows", timeLimit: 90, consecutiveHits: 1),
    LevelData(levelNumber: 7, chapterNumber: 1, birdCount: 5, objective: "Make 1 combo and shoot 5 birds with unlimited arrows", consecutiveHits: 2),
    LevelData(levelNumber: 8, chapterNumber: 1, birdCount: 7, objective: "1 headshot and 7 birds with 50 arrows", maxArrows: 50, consecutiveHits: 1),
    LevelData(levelNumber: 9, chapterNumber: 1, birdCount: 8, objective: "1 combo and 1 headshot with 40 arrows", maxArrows: 40, consecutiveHits: 2),
    LevelData(levelNumber: 10, chapterNumber: 1, birdCount: 9, objective: "2 combos and 2 headshots with 30 arrows", maxArrows: 30, consecutiveHits: 4),
    LevelData(levelNumber: 11, chapterNumber: 1, birdCount: 8, objective: "Shoot 8 birds with unlimited arrows"),
    LevelData(levelNumber: 12, chapterNumber: 1, birdCount: 9, objective: "Shoot 9 birds with unlimited arrows"),
    LevelData(levelNumber: 13, chapterNumber: 1, birdCount: 10, objective: "Shoot 10 birds in 75 seconds", timeLimit: 75),
    LevelData(levelNumber: 14, chapterNumber: 1, birdCount: 11, objective: "Shoot 11 birds with unlimited arrows"),
    LevelData(levelNumber: 15, chapterNumber: 1, birdCount: 12, objective: "Shoot 12 birds with 60 arrows", maxArrows: 60),
    LevelData(levelNumber: 16, chapterNumber: 1, birdCount: 15, objective: "3 combos and 2 headshots with 25 arrows", maxArrows: 25, consecutiveHits: 5),
    LevelData(levelNumber: 17, chapterNumber: 1, birdCount: 13, objective: "Shoot 13 birds with unlimited arrows"),
    LevelData(levelNumber: 18, chapterNumber: 1, birdCount: 14, objective: "Shoot 14 birds in 70 seconds", timeLimit: 70),
    LevelData(levelNumber: 19, chapterNumber: 1, birdCount: 15, objective: "Shoot 15 birds with 80 arrows", maxArrows: 80),
    LevelData(levelNumber: 20, chapterNumber: 1, birdCount: 18, objective: "4 combos and 3 headshots with 20 arrows", maxArrows: 20, consecutiveHits: 7),
    LevelData(levelNumber: 21, chapterNumber: 1, birdCount: 16, objective: "Shoot 16 birds with unlimited arrows"),
    LevelData(levelNumber: 22, chapterNumber: 1, birdCount: 17, objective: "Shoot 17 birds in 65 seconds", timeLimit: 65),
    LevelData(levelNumber: 23, chapterNumber: 1, birdCount: 18, objective: "Shoot 18 birds with 90 arrows", maxArrows: 90),
    LevelData(levelNumber: 24, chapterNumber: 1, birdCount: 19, objective: "Shoot 19 birds with unlimited arrows"),
    LevelData(levelNumber: 25, chapterNumber: 1, birdCount: 20, objective: "Shoot 20 birds in 60 seconds", timeLimit: 60),
    LevelData(levelNumber: 26, chapterNumber: 1, birdCount: 21, objective: "Shoot 21 birds with 100 arrows", maxArrows: 100),
    LevelData(levelNumber: 27, chapterNumber: 1, birdCount: 22, objective: "Shoot 22 birds with unlimited arrows"),
    LevelData(levelNumber: 28, chapterNumber: 1, birdCount: 25, objective: "6 combos and 4 headshots with 15 arrows", maxArrows: 15, consecutiveHits: 10),
    LevelData(levelNumber: 29, chapterNumber: 1, birdCount: 23, objective: "Shoot 23 birds in 55 seconds", timeLimit: 55),
    LevelData(levelNumber: 30, chapterNumber: 1, birdCount: 30, objective: "FINAL SPRING! Shoot 30 birds with unlimited arrows"),

    // BÖLÜM 2: Desert Sands (31-60)
    LevelData(levelNumber: 31, chapterNumber: 2, birdCount: 5, objective: "Desert begins! Shoot 5 birds with unlimited arrows"),
    LevelData(levelNumber: 32, chapterNumber: 2, birdCount: 7, objective: "Shoot 7 birds with unlimited arrows"),
    LevelData(levelNumber: 33, chapterNumber: 2, birdCount: 8, objective: "Shoot 8 birds with unlimited arrows"),
    LevelData(levelNumber: 34, chapterNumber: 2, birdCount: 9, objective: "Shoot 9 birds with unlimited arrows"),
    LevelData(levelNumber: 35, chapterNumber: 2, birdCount: 10, objective: "Shoot 10 birds in 70 seconds", timeLimit: 70),
    LevelData(levelNumber: 36, chapterNumber: 2, birdCount: 11, objective: "Shoot 11 birds with unlimited arrows"),
    LevelData(levelNumber: 37, chapterNumber: 2, birdCount: 12, objective: "1 headshot and 12 birds with 60 arrows", maxArrows: 60, consecutiveHits: 1),
    LevelData(levelNumber: 38, chapterNumber: 2, birdCount: 13, objective: "Shoot 13 birds with unlimited arrows"),
    LevelData(levelNumber: 39, chapterNumber: 2, birdCount: 14, objective: "Shoot 14 birds in 65 seconds", timeLimit: 65),
    LevelData(levelNumber: 40, chapterNumber: 2, birdCount: 15, objective: "Shoot 15 birds with 75 arrows", maxArrows: 75),
    // ZOR LEVEL
    LevelData(levelNumber: 41, chapterNumber: 2, birdCount: 20, objective: "DESERT STORM! 5 combos and 3 headshots with 25 arrows", maxArrows: 25, consecutiveHits: 8),
    LevelData(levelNumber: 42, chapterNumber: 2, birdCount: 16, objective: "Shoot 16 birds with unlimited arrows"),
    LevelData(levelNumber: 43, chapterNumber: 2, birdCount: 17, objective: "Shoot 17 birds with unlimited arrows"),
    LevelData(levelNumber: 44, chapterNumber: 2, birdCount: 18, objective: "Shoot 18 birds in 60 seconds", timeLimit: 60),
    LevelData(levelNumber: 45, chapterNumber: 2, birdCount: 19, objective: "2 headshots and 19 birds with 80 arrows", maxArrows: 80, consecutiveHits: 2),
    LevelData(levelNumber: 46, chapterNumber: 2, birdCount: 20, objective: "Shoot 20 birds with unlimited arrows"),
    // ZOR LEVEL
    LevelData(levelNumber: 47, chapterNumber: 2, birdCount: 25, objective: "SANDSTORM! 6 combos and 4 headshots with 20 arrows", maxArrows: 20, consecutiveHits: 10),
    LevelData(levelNumber: 48, chapterNumber: 2, birdCount: 21, objective: "Shoot 21 birds with unlimited arrows"),
    LevelData(levelNumber: 49, chapterNumber: 2, birdCount: 22, objective: "Shoot 22 birds in 55 seconds", timeLimit: 55),
    LevelData(levelNumber: 50, chapterNumber: 2, birdCount: 23, objective: "3 headshots and 23 birds with 90 arrows", maxArrows: 90, consecutiveHits: 3),
    LevelData(levelNumber: 51, chapterNumber: 2, birdCount: 24, objective: "Shoot 24 birds with unlimited arrows"),
    LevelData(levelNumber: 52, chapterNumber: 2, birdCount: 25, objective: "Shoot 25 birds in 50 seconds", timeLimit: 50),
    LevelData(levelNumber: 53, chapterNumber: 2, birdCount: 26, objective: "Shoot 26 birds with unlimited arrows"),
    LevelData(levelNumber: 54, chapterNumber: 2, birdCount: 27, objective: "4 headshots and 27 birds with 100 arrows", maxArrows: 100, consecutiveHits: 4),
    LevelData(levelNumber: 55, chapterNumber: 2, birdCount: 28, objective: "Shoot 28 birds with unlimited arrows"),
    LevelData(levelNumber: 56, chapterNumber: 2, birdCount: 29, objective: "Shoot 29 birds in 45 seconds", timeLimit: 45),
    LevelData(levelNumber: 57, chapterNumber: 2, birdCount: 30, objective: "5 headshots and 30 birds with 120 arrows", maxArrows: 120, consecutiveHits: 5),
    LevelData(levelNumber: 58, chapterNumber: 2, birdCount: 32, objective: "Shoot 32 birds with unlimited arrows"),
    LevelData(levelNumber: 59, chapterNumber: 2, birdCount: 35, objective: "Shoot 35 birds in 40 seconds", timeLimit: 40),
    // ZOR LEVEL - FINAL DESERT
    LevelData(levelNumber: 60, chapterNumber: 2, birdCount: 40, objective: "DESERT FINALE! 8 combos and 6 headshots with 15 arrows", maxArrows: 15, consecutiveHits: 14),

    // BÖLÜM 3: Frozen Peaks (61-90)
    LevelData(levelNumber: 61, chapterNumber: 3, birdCount: 8, objective: "Ice age begins! Shoot 8 birds with unlimited arrows"),
    LevelData(levelNumber: 62, chapterNumber: 3, birdCount: 10, objective: "Shoot 10 birds with unlimited arrows"),
    LevelData(levelNumber: 63, chapterNumber: 3, birdCount: 12, objective: "Shoot 12 birds with unlimited arrows"),
    LevelData(levelNumber: 64, chapterNumber: 3, birdCount: 14, objective: "Shoot 14 birds with unlimited arrows"),
    LevelData(levelNumber: 65, chapterNumber: 3, birdCount: 16, objective: "Shoot 16 birds in 60 seconds", timeLimit: 60),
    LevelData(levelNumber: 66, chapterNumber: 3, birdCount: 18, objective: "2 headshots and 18 birds with 80 arrows", maxArrows: 80, consecutiveHits: 2),
    LevelData(levelNumber: 67, chapterNumber: 3, birdCount: 20, objective: "Shoot 20 birds with unlimited arrows"),
    LevelData(levelNumber: 68, chapterNumber: 3, birdCount: 22, objective: "Shoot 22 birds in 55 seconds", timeLimit: 55),
    LevelData(levelNumber: 69, chapterNumber: 3, birdCount: 24, objective: "3 headshots and 24 birds with 90 arrows", maxArrows: 90, consecutiveHits: 3),
    // ZOR LEVEL
    LevelData(levelNumber: 70, chapterNumber: 3, birdCount: 30, objective: "BLIZZARD! 7 combos and 5 headshots with 25 arrows", maxArrows: 25, consecutiveHits: 12),
    LevelData(levelNumber: 71, chapterNumber: 3, birdCount: 26, objective: "Shoot 26 birds with unlimited arrows"),
    LevelData(levelNumber: 72, chapterNumber: 3, birdCount: 28, objective: "Shoot 28 birds with unlimited arrows"),
    LevelData(levelNumber: 73, chapterNumber: 3, birdCount: 30, objective: "4 headshots and 30 birds with 100 arrows", maxArrows: 100, consecutiveHits: 4),
    LevelData(levelNumber: 74, chapterNumber: 3, birdCount: 32, objective: "Shoot 32 birds in 50 seconds", timeLimit: 50),
    LevelData(levelNumber: 75, chapterNumber: 3, birdCount: 34, objective: "Shoot 34 birds with unlimited arrows"),
    LevelData(levelNumber: 76, chapterNumber: 3, birdCount: 36, objective: "5 headshots and 36 birds with 120 arrows", maxArrows: 120, consecutiveHits: 5),
    LevelData(levelNumber: 77, chapterNumber: 3, birdCount: 38, objective: "Shoot 38 birds with unlimited arrows"),
    // ZOR LEVEL
    LevelData(levelNumber: 78, chapterNumber: 3, birdCount: 40, objective: "AVALANCHE! 8 combos and 6 headshots with 20 arrows", maxArrows: 20, consecutiveHits: 14),
    LevelData(levelNumber: 79, chapterNumber: 3, birdCount: 42, objective: "Shoot 42 birds in 45 seconds", timeLimit: 45),
    LevelData(levelNumber: 80, chapterNumber: 3, birdCount: 44, objective: "6 headshots and 44 birds with 140 arrows", maxArrows: 140, consecutiveHits: 6),
    LevelData(levelNumber: 81, chapterNumber: 3, birdCount: 46, objective: "Shoot 46 birds with unlimited arrows"),
    LevelData(levelNumber: 82, chapterNumber: 3, birdCount: 48, objective: "Shoot 48 birds in 40 seconds", timeLimit: 40),
    // ZOR LEVEL
    LevelData(levelNumber: 83, chapterNumber: 3, birdCount: 50, objective: "ICE STORM! 9 combos and 7 headshots with 18 arrows", maxArrows: 18, consecutiveHits: 16),
    LevelData(levelNumber: 84, chapterNumber: 3, birdCount: 52, objective: "7 headshots and 52 birds with 160 arrows", maxArrows: 160, consecutiveHits: 7),
    LevelData(levelNumber: 85, chapterNumber: 3, birdCount: 54, objective: "Shoot 54 birds with unlimited arrows"),
    LevelData(levelNumber: 86, chapterNumber: 3, birdCount: 56, objective: "Shoot 56 birds in 35 seconds", timeLimit: 35),
    LevelData(levelNumber: 87, chapterNumber: 3, birdCount: 58, objective: "8 headshots and 58 birds with 180 arrows", maxArrows: 180, consecutiveHits: 8),
    LevelData(levelNumber: 88, chapterNumber: 3, birdCount: 60, objective: "Shoot 60 birds with unlimited arrows"),
    // ZOR LEVEL
    LevelData(levelNumber: 89, chapterNumber: 3, birdCount: 65, objective: "ABSOLUTE ZERO! 10 combos and 8 headshots with 15 arrows", maxArrows: 15, consecutiveHits: 18),
    LevelData(levelNumber: 90, chapterNumber: 3, birdCount: 70, objective: "FROZEN FINALE! 12 combos and 10 headshots with unlimited arrows", consecutiveHits: 22),
  ];

  // Bölüm seviyelerini getir
  static List<LevelData> getLevelsForChapter(int chapterNumber) {
    return levels.where((level) => level.chapterNumber == chapterNumber).toList();
  }
}

class StarCalculator {
  static int calculateStars(int levelNumber, int score) {
    final level = GameLevels.levels[levelNumber - 1];
    final birdCount = level.birdCount;

    // Zor seviyeler (her bölümden)
    List<int> hardLevels = [
      // Bölüm 1
      10, 16, 20, 28,
      // Bölüm 2 - çöl zorları
      41, 47, 60,
      // Bölüm 3 - buz zorları
      70, 78, 83, 89
    ];

    bool isHardLevel = hardLevels.contains(levelNumber);

    // Base score calculation
    int baseScore = birdCount * 80;

    // Difficulty multipliers
    double multiplier = 1.0;

    if (level.timeLimit != null) {
      multiplier += 0.2;
    }

    if (level.maxArrows != null) {
      multiplier += 0.3;
    }

    if (level.consecutiveHits != null) {
      multiplier += (level.consecutiveHits! * 0.1);
    }

    if (isHardLevel) {
      multiplier += 0.5;
    }

    // Final level bonuses
    if ([30, 60, 90].contains(levelNumber)) {
      multiplier += 1.0;
    }

    // Star thresholds
    int oneStarThreshold = (baseScore * multiplier * 0.4).round();
    int twoStarThreshold = (baseScore * multiplier * 0.8).round();
    int threeStarThreshold = (baseScore * multiplier * 1.2).round();

    // Higher thresholds for hard levels
    if (isHardLevel) {
      oneStarThreshold = (baseScore * multiplier * 0.6).round();
      twoStarThreshold = (baseScore * multiplier * 1.0).round();
      threeStarThreshold = (baseScore * multiplier * 1.6).round();
    }

    if (score >= threeStarThreshold) return 3;
    if (score >= twoStarThreshold) return 2;
    if (score >= oneStarThreshold) return 1;
    return 0;
  }

  // Level kategorileri
  static String getLevelCategory(int levelNumber) {
    List<int> hardLevels = [10, 16, 20, 28, 41, 47, 60, 70, 78, 83, 89];

    if (hardLevels.contains(levelNumber)) {
      return "Extreme";
    }

    final level = GameLevels.levels[levelNumber - 1];

    if (level.chapterNumber == 1) return "Spring";
    if (level.chapterNumber == 2) return "Desert";
    if (level.chapterNumber == 3) return "Ice";

    return "Normal";
  }

  // Level renkleri - bölüm temasına göre
  static Color getLevelCategoryColor(int levelNumber) {
    List<int> hardLevels = [10, 16, 20, 28, 41, 47, 60, 70, 78, 83, 89];

    if (hardLevels.contains(levelNumber)) {
      return Colors.deepOrange; // Zor seviyeler kırmızı
    }

    final level = GameLevels.levels[levelNumber - 1];

    if (level.chapterNumber == 1) return Colors.green;     // Spring - yeşil
    if (level.chapterNumber == 2) return Colors.orange;    // Desert - turuncu
    if (level.chapterNumber == 3) return Colors.blue;      // Ice - mavi

    return Colors.grey;
  }

  // Zorluk skoru
  static double getDifficultyScore(int levelNumber) {
    final level = GameLevels.levels[levelNumber - 1];
    List<int> hardLevels = [10, 16, 20, 28, 41, 47, 60, 70, 78, 83, 89];

    if (hardLevels.contains(levelNumber)) {
      return 9.0; // Zor seviyeler
    }

    // Final level bonusu
    if ([30, 60, 90].contains(levelNumber)) {
      return 7.5;
    }

    // Bölüm bazlı zorluk
    double baseDifficulty = 2.0 + (level.chapterNumber * 0.5);
    baseDifficulty += (levelNumber * 0.05);

    if (level.timeLimit != null) baseDifficulty += 0.5;
    if (level.maxArrows != null) baseDifficulty += 0.5;
    if (level.consecutiveHits != null) baseDifficulty += level.consecutiveHits! * 0.15;

    return baseDifficulty.clamp(1.0, 8.5);
  }
}
// Oyun tercihleri sınıfını tamamen değiştirin
class GamePreferences {
  static int _highestUnlockedLevel = 1;
  static bool _isLoaded = false;
  static SharedPreferences? _prefs;

  static int get highestUnlockedLevel => _highestUnlockedLevel;
  static Map<int, int> _levelHighScores = {};
  static Map<int, int> _levelStars = {};

  // Sonsuz mod istatistikleri
  static int _infiniteHighScore = 0;
  static int _infiniteMostBirds = 0;
  static int _infiniteBestCombo = 0;
  static int _infiniteBestHeadshots = 0;

  static int get infiniteHighScore => _infiniteHighScore;
  static int get infiniteMostBirds => _infiniteMostBirds;
  static int get infiniteBestCombo => _infiniteBestCombo;
  static int get infiniteBestHeadshots => _infiniteBestHeadshots;

  static int getLevelHighScore(int level) {
    return _levelHighScores[level] ?? 0;
  }

  static int getLevelStars(int level) {
    return _levelStars[level] ?? 0;
  }

  static int getTotalStars() {
    int totalStars = 0;
    for (final level in GameLevels.levels) {
      totalStars += getLevelStars(level.levelNumber);
    }
    return totalStars;
  }

  // Bölüm açık mı kontrolü
  static bool isChapterUnlocked(int chapterNumber) {
    if (chapterNumber == 1) return true; // İlk bölüm her zaman açık

    final chapter = GameChapters.chapters[chapterNumber - 1];
    final totalStars = getTotalStars();

    return totalStars >= chapter.requiredStars;
  }

  // Bölümdeki toplam yıldız sayısı
  static int getChapterStars(int chapterNumber) {
    final chapterLevels = GameLevels.getLevelsForChapter(chapterNumber);
    int chapterStars = 0;

    for (final level in chapterLevels) {
      chapterStars += getLevelStars(level.levelNumber);
    }

    return chapterStars;
  }

  // Bölümdeki maksimum yıldız sayısı
  static int getChapterMaxStars(int chapterNumber) {
    final chapterLevels = GameLevels.getLevelsForChapter(chapterNumber);
    return chapterLevels.length * 3; // Her level 3 yıldız
  }
  // Tüm verileri sil
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Değişkenleri resetle
    _highestUnlockedLevel = 1;
    _levelHighScores.clear();
    _levelStars.clear();
    _infiniteHighScore = 0;
    _infiniteMostBirds = 0;
    _infiniteBestCombo = 0;
    _infiniteBestHeadshots = 0;
    _isLoaded = false;
  }

  static Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _highestUnlockedLevel = prefs.getInt('highest_unlocked_level') ?? 1;

    // Level yüksek skorları
    _levelHighScores = {};
    _levelStars = {};
    for (final level in GameLevels.levels) {
      final hs = prefs.getInt('level_high_score_${level.levelNumber}') ?? 0;
      _levelHighScores[level.levelNumber] = hs;

      // Yıldız verilerini yükle
      final stars = prefs.getInt('level_stars_${level.levelNumber}') ?? 0;
      _levelStars[level.levelNumber] = stars;
    }

    // Sonsuz mod istatistikleri
    _infiniteHighScore = prefs.getInt('infinite_high_score') ?? 0;
    _infiniteMostBirds = prefs.getInt('infinite_most_birds') ?? 0;
    _infiniteBestCombo = prefs.getInt('infinite_best_combo') ?? 0;
    _infiniteBestHeadshots = prefs.getInt('infinite_best_headshots') ?? 0;

    _isLoaded = true;
  }

  static Future<void> setLevelStars(int level, int stars) async {
    if (stars <= (_levelStars[level] ?? 0)) return;
    _levelStars[level] = stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_stars_$level', stars);
  }

  static Future<void> setLevelHighScore(int level, int score) async {
    if (score <= (_levelHighScores[level] ?? 0)) return;
    _levelHighScores[level] = score;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_high_score_$level', score);
  }





  // Bu metot, sonsuz mod istatistiklerini doğru şekilde güncelleyecektir.
  // Gelen değerlerin mevcut en yüksek değerlerden daha büyük olup olmadığını kontrol eder.
  static Future<void> updateInfiniteScores({
    required int score,
    required int birds,
    required int combo,
    required int headshots,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();

    if (score > _infiniteHighScore) {
      _infiniteHighScore = score;
      await _prefs!.setInt('infinite_high_score', _infiniteHighScore);
    }
    if (birds > _infiniteMostBirds) {
      _infiniteMostBirds = birds;
      await _prefs!.setInt('infinite_most_birds', _infiniteMostBirds);
    }
    if (combo > _infiniteBestCombo) {
      _infiniteBestCombo = combo;
      await _prefs!.setInt('infinite_best_combo', _infiniteBestCombo);
    }
    if (headshots > _infiniteBestHeadshots) {
      _infiniteBestHeadshots = headshots;
      await _prefs!.setInt('infinite_best_headshots', _infiniteBestHeadshots);
    }
  }

  // Tüm verileri sil


  static Future<void> updateInfiniteStats({
    required int score,
    required int birds,
    required int combo,
    required int headshots,
  }) async {
    bool changed = false;
    if (score > _infiniteHighScore) {
      _infiniteHighScore = score;
      changed = true;
    }
    if (birds > _infiniteMostBirds) {
      _infiniteMostBirds = birds;
      changed = true;
    }
    if (combo > _infiniteBestCombo) {
      _infiniteBestCombo = combo;
      changed = true;
    }
    if (headshots > _infiniteBestHeadshots) {
      _infiniteBestHeadshots = headshots;
      changed = true;
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('infinite_high_score', _infiniteHighScore);
      await prefs.setInt('infinite_most_birds', _infiniteMostBirds);
      await prefs.setInt('infinite_best_combo', _infiniteBestCombo);
      await prefs.setInt('infinite_best_headshots', _infiniteBestHeadshots);
    }
  }

  static Future<void> unlockLevel(int level) async {
    if (level > _highestUnlockedLevel) {
      _highestUnlockedLevel = level;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highest_unlocked_level', _highestUnlockedLevel);
    }
  }

  static bool isLevelUnlocked(int level) {
    return level <= _highestUnlockedLevel;
  }
}

// Ana menü ekranı
// Ana menü ekranı - Geliştirilmiş versiyon
class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bird1Controller;
  late AnimationController _bird2Controller;
  late AnimationController _titleController;
  late AnimationController _buttonController;

  late Animation<double> _bird1Animation;
  late Animation<double> _bird2Animation;
  late Animation<double> _titleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Kuş animasyonları - farklı hızlarda
    _bird1Controller = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    );
    _bird2Controller = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    );

    // UI animasyonları
    _titleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animasyon değerleri
    _bird1Animation = Tween<double>(begin: -100, end: 1.2).animate(
        CurvedAnimation(parent: _bird1Controller, curve: Curves.linear)
    );
    _bird2Animation = Tween<double>(begin: 1.2, end: -0.2).animate(
        CurvedAnimation(parent: _bird2Controller, curve: Curves.linear)
    );

    _titleAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _titleController, curve: Curves.elasticOut)
    );
    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack)
    );

    // Animasyonları başlat
    _bird1Controller.repeat();
    _bird2Controller.repeat();
    _titleController.forward();

    // Buton animasyonunu gecikmeyle başlat
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _bird1Controller.dispose();
    _bird2Controller.dispose();
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: FutureBuilder(
        future: GamePreferences.loadPreferences(),
        builder: (context, snapshot) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF87CEEB), // Açık mavi
                  Color(0xFF4682B4), // Koyu mavi
                  Color(0xFF2E5B8A), // Daha koyu mavi
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Arka plan bulutları
                _buildClouds(screenWidth, screenHeight),

                // Güneş efekti
                _buildSunEffect(screenWidth),

                // Animasyonlu kuşlar
                AnimatedBuilder(
                  animation: _bird1Animation,
                  builder: (context, child) {
                    return Positioned(
                      left: screenWidth * _bird1Animation.value,
                      top: screenHeight * 0.08,
                      child: _buildAnimatedBird(
                        isFlying: true,
                        scale: 1.2,
                        direction: 1,
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _bird2Animation,
                  builder: (context, child) {
                    return Positioned(
                      left: screenWidth * _bird2Animation.value,
                      top: screenHeight * 0.15,
                      child: _buildAnimatedBird(
                        isFlying: true,
                        scale: 1.0,
                        direction: -1,
                      ),
                    );
                  },
                ),

                // Ana içerik - Kaydırma olmadan
                Container(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Üst boşluk
                        SizedBox(height: 4.0),

                        // Animasyonlu başlık - Daha kompakt
                        AnimatedBuilder(
                          animation: _titleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _titleAnimation.value,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '🏹',
                                      style: TextStyle(fontSize: 30.0),
                                    ),
                                    SizedBox(height: 3.0),
                                    Text(
                                      'ARCHERY GAME',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2.0, 2.0),
                                            blurRadius: 4.0,
                                            color: Colors.black.withOpacity(0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 2.0),
                                    Text(
                                      'Aim Your Shot, Fire!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Animasyonlu butonlar - Daha kompakt
                        Expanded(
                          flex: 3,
                          child: AnimatedBuilder(
                            animation: _buttonAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _buttonAnimation.value,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildEnhancedMenuButton(
                                      context,
                                      '📋 LEVELS',
                                      'Action Games!',
                                      LinearGradient(
                                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                      ),
                                          () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LevelSelectScreen(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    _buildEnhancedMenuButton(
                                      context,
                                      '∞ INFINITE MODE',  // Standard game terminology
                                      'Push your limits!',
                                      LinearGradient(
                                        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                                      ),
                                          () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InfiniteGameScreen(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    _buildEnhancedMenuButton(
                                      context,
                                      'ℹ HOW TO PLAY',
                                      'Learn the rules!',
                                      LinearGradient(
                                        colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
                                      ),
                                          () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HowToPlayScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Alt kısım - Veri temizleme butonu
                        AnimatedBuilder(
                          animation: _buttonAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonAnimation.value,
                              child: _buildSmallEnhancedMenuButton(
                                context,
                                '🗑️ CLEAR DATA',
                                LinearGradient(
                                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                                ),
                                    () => _showClearDataDialog(context),
                              ),
                            );
                          },
                        ),

                        // Alt boşluk
                        SizedBox(height: 4.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClouds(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Bulut 1
        Positioned(
          right: screenWidth * 0.1,
          top: screenHeight * 0.05,
          child: _buildCloud(60, Colors.white.withOpacity(0.25)),
        ),
        // Bulut 2
        Positioned(
          left: screenWidth * 0.05,
          top: screenHeight * 0.12,
          child: _buildCloud(50, Colors.white.withOpacity(0.2)),
        ),
        // Bulut 3
        Positioned(
          right: screenWidth * 0.3,
          top: screenHeight * 0.04,
          child: _buildCloud(55, Colors.white.withOpacity(0.18)),
        ),
      ],
    );
  }

  Widget _buildCloud(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSunEffect(double screenWidth) {
    return Positioned(
      right: screenWidth * 0.08,
      top: 30,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.yellow.withOpacity(0.3),
              Colors.orange.withOpacity(0.15),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBird({
    required bool isFlying,
    required double scale,
    required int direction,
  }) {
    return Transform.scale(
      scale: scale,
      child: Transform.flip(
        flipX: direction < 0,
        child: CustomPaint(
          size: Size(22, 16),
          painter: MenuBirdPainter(
            animTime: direction > 0
                ? _bird1Controller.value * 20
                : _bird2Controller.value * 25,
            isFlying: isFlying,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMenuButton(
      BuildContext context,
      String title,
      String subtitle,
      Gradient gradient,
      VoidCallback onPressed,
      ) {
    return Container(
      width: 220.0,
      height: 50.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4.0,
                offset: Offset(0.0, 2.0),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallEnhancedMenuButton(
      BuildContext context,
      String text,
      Gradient gradient,
      VoidCallback onPressed,
      ) {
    return Container(
      width: 180.0,
      height: 35.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear Data',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            'WARNING! This will PERMANENTLY erase:\n\n- Campaign progress\n- Leaderboard entries\n- All achievements\n\nCONFIRM WIPE?',            style: TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'No',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await GamePreferences.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🗑️ All game data deleted!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.red.shade600,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Delete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Menü kuşu çizici sınıfı
class MenuBirdPainter extends CustomPainter {
  final double animTime;
  final bool isFlying;

  MenuBirdPainter({
    required this.animTime,
    required this.isFlying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Kanat çırpma animasyonu
    final double wingAngle = isFlying
        ? math.sin(animTime * 12.0) * 0.8
        : 0.2;

    // Ana vücut
    final bodyWidth = w * 0.85;
    final bodyHeight = h * 0.62;
    final bodyCenter = Offset(center.dx - w * 0.05, center.dy + h * 0.02);

    // Boyunlar
    final neckPos = Offset(bodyCenter.dx + bodyWidth * 0.32, bodyCenter.dy - bodyHeight * 0.10);
    final headRadius = h * 0.16;
    final beakLen = h * 0.22;

    // Renkler
    final fillBlack = Paint()..color = Colors.black87;
    final darkGrey = Paint()..color = Colors.grey.shade700;

    // Vücut çizimi
    canvas.drawOval(
      Rect.fromCenter(center: bodyCenter, width: bodyWidth, height: bodyHeight),
      fillBlack,
    );

    // Boyun
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(neckPos.dx - w * 0.02, neckPos.dy + h * 0.02),
        width: w * 0.20,
        height: h * 0.22,
      ),
      fillBlack,
    );

    // Kafa
    final headCenter = Offset(neckPos.dx + w * 0.05, neckPos.dy - h * 0.04);
    canvas.drawCircle(headCenter, headRadius, fillBlack);

    // Gaga
    final beakPath = Path()
      ..moveTo(headCenter.dx + headRadius, headCenter.dy)
      ..lineTo(headCenter.dx + headRadius + beakLen, headCenter.dy - h * 0.06)
      ..lineTo(headCenter.dx + headRadius + beakLen, headCenter.dy + h * 0.06)
      ..close();
    canvas.drawPath(beakPath, darkGrey);

    // Göz
    final eye = Offset(headCenter.dx + headRadius * 0.20, headCenter.dy - headRadius * 0.20);
    canvas.drawCircle(eye, 0.9, Paint()..color = Colors.white);
    canvas.drawCircle(eye, 0.5, Paint()..color = Colors.black);

    // Kuyruk
    final tailBase = Offset(bodyCenter.dx - bodyWidth * 0.50, bodyCenter.dy + bodyHeight * 0.04);
    final tailPath = Path()
      ..moveTo(tailBase.dx, tailBase.dy)
      ..lineTo(tailBase.dx - w * 0.18, tailBase.dy - h * 0.10)
      ..lineTo(tailBase.dx - w * 0.10, tailBase.dy + h * 0.12)
      ..close();
    canvas.drawPath(tailPath, fillBlack);

    // Kanatlar
    final leftShoulder = Offset(bodyCenter.dx - bodyWidth * 0.06, bodyCenter.dy - bodyHeight * 0.18);
    final rightShoulder = Offset(bodyCenter.dx + bodyWidth * 0.10, bodyCenter.dy - bodyHeight * 0.12);

    _drawWing(
      canvas: canvas,
      shoulder: rightShoulder,
      length: w * 0.52,
      span: h * 0.66,
      angle: -wingAngle * 0.9,
      fill: fillBlack,
    );
    _drawWing(
      canvas: canvas,
      shoulder: leftShoulder,
      length: w * 0.50,
      span: h * 0.64,
      angle: wingAngle,
      fill: Paint()..color = Colors.black.withOpacity(0.92),
    );
  }

  void _drawWing({
    required Canvas canvas,
    required Offset shoulder,
    required double length,
    required double span,
    required double angle,
    required Paint fill,
  }) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.25, -span * 0.75, length, -span * 0.10)
      ..quadraticBezierTo(length * 0.65, span * 0.65, 0, 0)
      ..close();

    canvas.drawPath(path, fill);

    // Kanat çizgileri
    final featherPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final px = length * (0.22 + 0.7 * t);
      final py = -span * (0.55 - 0.5 * t);
      canvas.drawLine(
        Offset(px, py),
        Offset(px - length * 0.16, py + span * 0.22),
        featherPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(MenuBirdPainter oldDelegate) {
    return oldDelegate.animTime != animTime || oldDelegate.isFlying != isFlying;
  }
}

// Level seçim ekranı
// Level seçim ekranı - MODERN VERSİYON
class LevelSelectScreen extends StatefulWidget {
  @override
  _LevelSelectScreenState createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with TickerProviderStateMixin {

  late TabController _tabController;

  int selectedChapter = 1;



  @override

  void initState() {

    super.initState();

    _tabController = TabController(length: GameChapters.chapters.length, vsync: this);

    _loadData();

  }



  @override

  void dispose() {

    _tabController.dispose();

    super.dispose();

  }



  void _loadData() async {

    await GamePreferences.loadPreferences();

    if (mounted) {

      setState(() {});

    }

  }



  // LevelSelectScreen sınıfının build metodunu güncelle

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalStars = GamePreferences.getTotalStars();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🏹 Adventures',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF4682B4),
        foregroundColor: Colors.white,
        elevation: 8,
        centerTitle: true,
        toolbarHeight: 50,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(90),
          child: Column(
            children: [
              // Toplam yıldız göstergesi
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Total Stars: $totalStars',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Bölüm sekmeleri
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontSize: 9),
                tabs: GameChapters.chapters.map((chapter) {
                  final isUnlocked = GamePreferences.isChapterUnlocked(chapter.chapterNumber);
                  final chapterStars = GamePreferences.getChapterStars(chapter.chapterNumber);
                  final maxStars = GamePreferences.getChapterMaxStars(chapter.chapterNumber);

                  return Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              chapter.title.split(' ')[0],
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(width: 3),
                            if (!isUnlocked)
                              Icon(Icons.lock, size: 12, color: Colors.white60),
                          ],
                        ),
                        SizedBox(height: 1),
                        Text(
                          chapter.title.split(' ').skip(1).join(' '),
                          style: TextStyle(fontSize: 8),
                        ),
                        if (isUnlocked)
                          Text(
                            '$chapterStars/$maxStars',
                            style: TextStyle(fontSize: 7, color: Color(0xFFFFD700)),
                          )
                        else
                          Text(
                            '${chapter.requiredStars} ⭐',
                            style: TextStyle(fontSize: 7, color: Colors.white60),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: GameChapters.chapters.map((chapter) {
          return _buildChapterView(chapter, screenWidth);
        }).toList(),
      ),
    );
  }
  Widget _buildChapterView(ChapterData chapter, double screenWidth) {
    final isUnlocked = GamePreferences.isChapterUnlocked(chapter.chapterNumber);

    if (!isUnlocked) {
      return _buildLockedChapterView(chapter);
    }

    final chapterLevels = GameLevels.getLevelsForChapter(chapter.chapterNumber);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            chapter.primaryColor.withOpacity(0.6),
            chapter.secondaryColor.withOpacity(0.4),
          ],
        ),
      ),
      child: Container(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            children: [
              _buildChapterHeader(chapter),
              SizedBox(height: 4),
              Expanded(
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(screenWidth),
                    childAspectRatio: _getChildAspectRatio(screenWidth, MediaQuery.of(context).size.height),
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: chapterLevels.length,
                  itemBuilder: (context, index) {
                    final level = chapterLevels[index];
                    final isLevelUnlocked = GamePreferences.isLevelUnlocked(level.levelNumber);
                    final highScore = GamePreferences.getLevelHighScore(level.levelNumber);
                    final stars = GamePreferences.getLevelStars(level.levelNumber);
                    final category = StarCalculator.getLevelCategory(level.levelNumber);
                    final categoryColor = StarCalculator.getLevelCategoryColor(level.levelNumber);

                    return _buildLevelCard(
                        context, level, isLevelUnlocked, highScore,
                        stars, category, categoryColor, chapter
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterHeader(ChapterData chapter) {
    final chapterStars = GamePreferences.getChapterStars(chapter.chapterNumber);
    final maxStars = GamePreferences.getChapterMaxStars(chapter.chapterNumber);
    final progressPercent = maxStars > 0 ? (chapterStars / maxStars) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            chapter.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Text(
            chapter.description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercent,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          SizedBox(height: 2),
          Text(
            '⭐ $chapterStars / $maxStars Stars',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedChapterView(ChapterData chapter) {
    final totalStars = GamePreferences.getTotalStars();
    final needed = chapter.requiredStars - totalStars;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade600,
            Colors.grey.shade800,
          ],
        ),
      ),
      child: SingleChildScrollView( // Kaydırma eklendi
        child: Center(
          child: Container(
            margin: EdgeInsets.all(6), // 12 -> 6 (1x6)
            padding: EdgeInsets.all(12), // 18 -> 12 (2x6)
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6), // 12 -> 6 (1x6)
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  size: 30, // 42 -> 30 (5x6)
                  color: Colors.white60,
                ),
                SizedBox(height: 6), // 12 -> 6 (1x6)
                Text(
                  chapter.title,
                  style: TextStyle(
                    fontSize: 18, // 20 -> 18 (3x6)
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6), // 6 -> 6 (1x6)
                Text(
                  'Chapter Locked',
                  style: TextStyle(
                    fontSize: 12, // 14 -> 12 (2x6)
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6), // 12 -> 6 (1x6)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6), // 12,6 -> 6,6 (1x6,1x6)
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6), // 6 -> 6 (1x6)
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Color(0xFFFFD700), size: 12), // 18 -> 12 (2x6)
                          SizedBox(width: 6), // 6 -> 6 (1x6)
                          Flexible(
                            child: Text(
                              'Need ${chapter.requiredStars} Stars',
                              style: TextStyle(
                                fontSize: 12, // 14 -> 12 (2x6)
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3), // 3 -> 3
                      Text(
                        '$needed more stars needed!',
                        style: TextStyle(
                          fontSize: 10, // 11 -> 10
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6), // 12 -> 6 (1x6)
                Text(
                  chapter.description,
                  style: TextStyle(
                    fontSize: 10, // 12 -> 10
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4, // 3 -> 4 (daha fazla satır göstermek için)
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, LevelData level, bool isUnlocked,
      int highScore, int stars, String category, Color categoryColor, ChapterData chapter) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    List<int> hardLevels = [10, 16, 20, 28, 41, 47, 60, 70, 78, 83, 89];
    bool isHardLevel = hardLevels.contains(level.levelNumber);

    final cardPadding = isLandscape ? 6.0 : 8.0;
    final fontSize = isLandscape ? 14.0 : 18.0;
    final iconSize = isLandscape ? 20.0 : 24.0;
    final circleSize = isLandscape ? 36.0 : 48.0;

    return GestureDetector(
      onTap: isUnlocked
          ? () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelGameScreen(levelData: level),
          ),
        );
        _loadData();
      }
          : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withOpacity(0.9),
              categoryColor.withOpacity(0.7),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? (isHardLevel ? Colors.red.withOpacity(0.8) : Colors.white.withOpacity(0.8))
                : Colors.grey.shade500,
            width: isHardLevel ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked ? categoryColor.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHardLevel ? Colors.red.withOpacity(0.8) : Colors.white.withOpacity(0.6),
                        width: isHardLevel ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${level.levelNumber}',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  if (isUnlocked && isHardLevel)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Icon(
                          Icons.whatshot,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              if (isUnlocked)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isHardLevel ? 'EXTREME' : category,
                    style: TextStyle(
                      fontSize: isLandscape ? 7.0 : 9.0,
                      fontWeight: FontWeight.w600,
                      color: isHardLevel ? Colors.red.shade100 : Colors.white,
                    ),
                  ),
                ),

              if (isUnlocked && stars > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStarsDisplay(stars),
                    style: TextStyle(
                      fontSize: isLandscape ? 10.0 : 14.0,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                )
              else if (isUnlocked)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '☆☆☆',
                    style: TextStyle(
                      fontSize: isLandscape ? 10.0 : 14.0,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),

              if (isUnlocked)
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: isLandscape ? 8.0 : 12.0,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        if (isLandscape) SizedBox(height: 0.5) else SizedBox(height: 1),
                        Flexible(
                          child: Text(
                            highScore > 0 ? '$highScore' : '0',
                            style: TextStyle(
                              fontSize: isLandscape ? 8.0 : 10.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LOCKED',
                      style: TextStyle(
                        fontSize: isLandscape ? 7.0 : 10.0,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 360) return 3;
    if (screenWidth < 480) return 4;
    if (screenWidth < 600) return 5;
    if (screenWidth < 800) return 6;
    if (screenWidth < 1000) return 7;
    return 8;
  }

  double _getChildAspectRatio(double screenWidth, double screenHeight) {
    final isLandscape = screenWidth > screenHeight;

    if (isLandscape) {
      if (screenWidth < 600) return 0.6;
      if (screenWidth < 800) return 0.65;
      return 0.7;
    } else {
      if (screenWidth < 360) return 0.7;
      if (screenWidth < 480) return 0.75;
      return 0.8;
    }
  }

  String _getStarsDisplay(int stars) {
    switch (stars) {
      case 3: return '⭐⭐⭐';
      case 2: return '⭐⭐☆';
      case 1: return '⭐☆☆';
      default: return '☆☆☆';
    }
  }

}




String _getStarsDisplay(int stars) {
  switch (stars) {
    case 3: return '⭐⭐⭐';
    case 2: return '⭐⭐☆';
    case 1: return '⭐☆☆';
    default: return '☆☆☆';
  }
}


double _getChildAspectRatio(double screenWidth, double screenHeight) {
  final isLandscape = screenWidth > screenHeight;

  if (isLandscape) {
    // Yatay ekranda daha geniş kartlar
    if (screenWidth < 600) return 0.6;
    if (screenWidth < 800) return 0.65;
    return 0.7;
  } else {
    // Dikey ekranda standart oranlar
    if (screenWidth < 360) return 0.7;
    if (screenWidth < 480) return 0.75;
    return 0.8;
  }
}

// Sonsuz mod ekranı
class InfiniteGameScreen extends StatefulWidget {
  @override
  State<InfiniteGameScreen> createState() => _InfiniteGameScreenState();
}


class _InfiniteGameScreenState extends State<InfiniteGameScreen> {
  // Filtreler
  bool unlimitedArrows = true;
  int arrows = 50;
  bool unlimitedBirds = false; // YENİ: Sonsuz kuş ayarı

  int birds = 16;

  bool unlimitedTime = true;
  int timeSeconds = 60;

  Key gameKey = UniqueKey();
  bool gameStarted = false; // Oyunun başlatılıp başlatılmadığını takip et

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async {
      if (gameStarted) {
        // Oyun başladıysa geri tuşu çalışmasın
        return false;
      } else {
        // Ayarlar ekranındaysa normal çıkış yap
        return true;
      }
    },
    child: Scaffold(
      body: Stack(
        children: [
          // Oyun (sadece başlatıldığında göster)
          if (gameStarted)
            Positioned.fill(
              child: GameWidget.controlled(
                key: gameKey,
                gameFactory: () => ArcheryGame(
                  isInfiniteMode: true,
                  infiniteArrowsLimit: unlimitedArrows ? null : arrows,
                  infiniteBirdCount: unlimitedBirds ? null : birds, // YENİ: Sonsuz kuş kontrolü
                  infiniteTimeLimit: unlimitedTime ? null : timeSeconds,
                ),
              ),
            ),

          // Başlangıç ekranı (oyun başlamadığında)
          if (!gameStarted)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF87CEEB),
                    Color(0xFF4682B4),
                  ],
                ),
              ),
              child: Container(
                child: SingleChildScrollView(
                  child: Container(
                    width: screenWidth,
                    height: screenHeight - MediaQuery.of(context).padding.top,
                    child: Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.9,
                          minWidth: screenWidth * 0.8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '∞ INFINITE MODE SETTINGS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            _buildFilterSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Oyun başladığında sağ altta geri dönüş kapısı
          if (gameStarted)
            Container(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () {
                      _saveAndExit();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  void _saveAndExit() {
    if (ArcheryGame.currentInfiniteGame != null) {
      ArcheryGame.currentInfiniteGame!.saveCurrentInfiniteScores();
    }

    setState(() {
      gameStarted = false;
    });
  }

  Widget _buildFilterSection() {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık bölümü
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.8), Colors.indigo.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Game Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Ok Ayarları Kartı
            _buildModernSettingCard(
              icon: Icons.arrow_forward,
              iconColor: Colors.orange,
              title: 'ARROW SETTİNGS',
              subtitle: unlimitedArrows ? 'You can use unlimited arrows' : 'You can use $arrows arrows',

              child: Column(
                children: [
                  // Switch ile başlık
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unlimitedArrows ? Colors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unlimitedArrows ? Colors.orange.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: unlimitedArrows ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            unlimitedArrows ? Icons.all_inclusive : Icons.casino,
                            color: unlimitedArrows ? Colors.orange : Colors.grey.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlimited Arrows',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                unlimitedArrows ? 'Never runs out!' : 'Limited arrows',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: unlimitedArrows,
                            onChanged: (v) => setState(() => unlimitedArrows = v),
                            activeColor: Colors.orange,
                            activeTrackColor: Colors.orange.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sayı seçimi (sadece sınırsız değilse)
                  if (!unlimitedArrows) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Arrows:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.4)),
                              ),
                              child: DropdownButton<int>(
                                value: arrows,
                                dropdownColor: Colors.black87,
                                underline: SizedBox.shrink(),
                                isExpanded: true,
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                icon: Icon(Icons.keyboard_arrow_down, color: Colors.orange),
                                items: [10, 20, 30, 40, 50, 80, 100, 150, 200]
                                    .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_forward, color: Colors.orange, size: 14),
                                        SizedBox(width: 8),
                                        Text('$v Arrow', style: TextStyle(color: Colors.white))
                                      ],
                                    )))
                                    .toList(),
                                onChanged: (v) => setState(() => arrows = v ?? 50),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 14),

            // Kuş Ayarları Kartı
            _buildModernSettingCard(
              icon: Icons.pets,
              iconColor: Colors.lightGreen,
              title: 'BIRD SETTİNGS',
              subtitle: unlimitedBirds ? 'Birds will keep spawning' : 'You need to hunt $birds birds',
              child: Column(
                children: [
                  // Switch ile başlık
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unlimitedBirds ? Colors.lightGreen.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unlimitedBirds ? Colors.lightGreen.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: unlimitedBirds ? Colors.lightGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            unlimitedBirds ? Icons.all_inclusive : Icons.pets,
                            color: unlimitedBirds ? Colors.lightGreen : Colors.grey.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Infinite Birds',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                unlimitedBirds ? 'Continuous spawning!' : 'Fixed number of birds',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: unlimitedBirds,
                            onChanged: (v) => setState(() => unlimitedBirds = v),
                            activeColor: Colors.lightGreen,
                            activeTrackColor: Colors.lightGreen.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sayı seçimi (sadece sınırsız değilse)
                  if (!unlimitedBirds) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.lightGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: Colors.lightGreen, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Bird Count:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.lightGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.lightGreen.withOpacity(0.4)),
                              ),
                              child: DropdownButton<int>(
                                value: birds,
                                dropdownColor: Colors.black87,
                                underline: SizedBox.shrink(),
                                isExpanded: true,
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                icon: Icon(Icons.keyboard_arrow_down, color: Colors.lightGreen),
                                items: [8, 12, 16, 20, 24, 28, 32, 40, 50, 64, 80, 100]
                                    .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      children: [
                                        Icon(Icons.pets, color: Colors.lightGreen, size: 14),
                                        SizedBox(width: 8),
                                        Text('$v Bird', style: TextStyle(color: Colors.white))
                                      ],
                                    )))
                                    .toList(),
                                onChanged: (v) => setState(() => birds = v ?? 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 14),

            // Süre Ayarları Kartı
            _buildModernSettingCard(
              icon: Icons.timer,
              iconColor: Colors.lightBlueAccent,
              title: 'TIME SETTINGS',
              subtitle: unlimitedTime ? 'Play as long as you want!' : 'Time limit: ${timeSeconds}s',
              child: Column(
                children: [
                  // Switch ile başlık
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unlimitedTime ? Colors.lightBlueAccent.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unlimitedTime ? Colors.lightBlueAccent.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: unlimitedTime ? Colors.lightBlueAccent.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            unlimitedTime ? Icons.all_inclusive : Icons.timer,
                            color: unlimitedTime ? Colors.lightBlueAccent : Colors.grey.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlimited Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                unlimitedTime ? 'No time pressure!' : 'Fixed time limit',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: unlimitedTime,
                            onChanged: (v) => setState(() => unlimitedTime = v),
                            activeColor: Colors.lightBlueAccent,
                            activeTrackColor: Colors.lightBlueAccent.withOpacity(0.3),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sayı seçimi (sadece sınırsız değilse)
                  if (!unlimitedTime) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.lightBlueAccent, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Time Limit:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.4)),
                              ),
                              child: DropdownButton<int>(
                                value: timeSeconds,
                                dropdownColor: Colors.black87,
                                underline: SizedBox.shrink(),
                                isExpanded: true,
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                icon: Icon(Icons.keyboard_arrow_down, color: Colors.lightBlueAccent),
                                items: [30, 45, 60, 90, 120, 180, 300]
                                    .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer, color: Colors.lightBlueAccent, size: 14),
                                        SizedBox(width: 8),
                                        Text('${v}s', style: TextStyle(color: Colors.white))
                                      ],
                                    )))
                                    .toList(),
                                onChanged: (v) => setState(() => timeSeconds = v ?? 60),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons
            Column(
              children: [
                // Ana Oyun Başlatma Butonu
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        gameKey = UniqueKey();
                        gameStarted = true;
                      });
                    },
                    icon: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.play_arrow, size: 22, color: Colors.white),
                    ),
                    label: Text(
                      'START GAME',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Skor Tablosu Butonu
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => InfiniteScoresScreen()),
                      );
                    },
                    icon: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.leaderboard, size: 18, color: Colors.white),
                    ),
                    label: Text(
                      'HIGH SCORES',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildModernSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withOpacity(0.4)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Kart içeriği
          child,
        ],
      ),
    );
  }
}
// Level bazlı oyun ekranı
// Level bazlı oyun ekranı - GÜNCELLENMİŞ VERSİYON
class LevelGameScreen extends StatefulWidget {
  final LevelData levelData;

  LevelGameScreen({required this.levelData});

  @override
  _LevelGameScreenState createState() => _LevelGameScreenState();
}

class _LevelGameScreenState extends State<LevelGameScreen> {
  late ArcheryGame game;
  bool showExitDialog = false;

  @override
  void initState() {
    super.initState();
    game = ArcheryGame(
      isInfiniteMode: false,
      levelData: widget.levelData,
    );
  }

  void _showExitConfirmation() {
    setState(() {
      showExitDialog = true;
    });
  }

  void _hideExitDialog() {
    setState(() {
      showExitDialog = false;
    });
  }

  // LevelGameScreen sınıfında _confirmExit metodunu değiştir

  void _confirmExit() {
    Navigator.of(context).pop(); // Level seçim ekranına dön
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
        onWillPop: () async {
      // Oyun sırasında geri tuşu çalışmasın
      return false;
    },
    child: Scaffold(
      body: Stack(
        children: [
          // Ana oyun ekranı
          Positioned.fill(
            child: GameWidget.controlled(
              gameFactory: () => game,
            ),
          ),

          // Sağ alt köşede çıkış butonu
          Container(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _showExitConfirmation,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white70, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Çıkış onay dialogu
          if (showExitDialog)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 32),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Exit Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Are you sure you want to quit Level ${widget.levelData.levelNumber}?\n\nYour progress will be lost!',                        style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _hideExitDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmExit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Exit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class ArcheryGame extends FlameGame with PanDetector {
  final bool isInfiniteMode;
  final LevelData? levelData;
  static ArcheryGame? currentInfiniteGame;
  String? currentTheme; // Tema bilgisi için eklendi
  static int levelGamesPlayed = 0;

  late StickmanArcher archer;
  late Ground ground;
  final List<Bird> birds = [];
  Vector2? dragStart;
  Vector2? currentDrag;
  bool isDragging = false;
  late AimingSystem aimingSystem;

  // Level istatistikleri
  int arrowsUsed = 0;
  int birdsHit = 0;
  int consecutiveHits = 0;
  int maxConsecutiveHits = 0;
  int headShots = 0;
  bool isGameOver = false;
  bool isLevelCompleted = false;
  double gameTime = 0.0;

  // Skor ve combo
  int score = 0;
  int comboCount = 0;
  int bestCombo = 0;
  int headshotComboCount = 0;
  int bestHeadshotCombo = 0;
  int currentShotId = 0;
  final Map<int, int> shotKillCounts = {};

  // UI bileşenleri
  late LevelUI levelUI;

  final int? infiniteArrowsLimit;   // null => sınırsız
  final int? infiniteBirdCount;     // null => varsayılan 16
  final int? infiniteTimeLimit;     // saniye, null => sınırsız

  ArcheryGame({
    this.isInfiniteMode = true,
    this.levelData,
    this.infiniteArrowsLimit,
    this.infiniteBirdCount,
    this.infiniteTimeLimit,
  }) {
    // Tema belirleme
    if (levelData != null) {
      final chapter = GameChapters.chapters.firstWhere(
            (c) => c.chapterNumber == levelData!.chapterNumber,
      );
      currentTheme = chapter.theme;
    }
  }

  @override
  Color backgroundColor() {
    if (currentTheme == null) return const Color(0xFF87CEEB); // Varsayılan mavi

    switch (currentTheme) {
      case 'spring':
        return const Color(0xFF87CEEB); // Açık mavi gökyüzü
      case 'desert':
        return const Color(0xFFDAA520); // Altın sarısı çöl gökyüzü
      case 'ice':
        return const Color(0xFFB0E0E6); // Buz mavisi
      default:
        return const Color(0xFF87CEEB);
    }
  }

  void _saveLevelHighScoreIfNeeded() {
    if (isInfiniteMode || levelData == null) return;
    GamePreferences.setLevelHighScore(levelData!.levelNumber, score);
  }

  void _saveInfiniteStatsIfNeeded() {
    GamePreferences.updateInfiniteStats(
      score: score,
      birds: birdsHit,
      combo: bestCombo,
      headshots: headShots,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Zemin
    ground = Ground(size.y * 0.8, theme: currentTheme);
    add(ground);

    // Okçu
    archer = StickmanArcher();
    archer.position = Vector2(120, ground.position.y - 110);

    if (currentTheme != null) {
      add(BackgroundEffects(theme: currentTheme!));
    }

    if (isInfiniteMode) {
      // Sonsuz mod filtrelerine göre ok sayısı
      if (infiniteArrowsLimit != null && infiniteArrowsLimit! > 0) {
        archer.arrowsLeft = infiniteArrowsLimit!;
      } else {
        archer.arrowsLeft = 999999; // pratikte sınırsız
      }
    } else {
      if (levelData?.maxArrows != null) {
        archer.arrowsLeft = levelData!.maxArrows!;
      }
    }
    add(archer);

    // Kuşlar
    _spawnBirds();

    // Nişan alma
    aimingSystem = AimingSystem();
    add(aimingSystem);

    if (isInfiniteMode) {
      currentInfiniteGame = this;
    }

    // UI
    if (!isInfiniteMode) {
      levelUI = LevelUI(levelData: levelData!);
      add(levelUI);
    } else {
      // Sonsuz mod UI'sını ekle
      add(InfiniteGameUI(gameRef: this));
    }

    // Skor UI (sağ üst)
    add(ScoreUI());
  }

  @override
  void onRemove() {
    if (isInfiniteMode) {
      currentInfiniteGame = null;
    }
    super.onRemove();
  }

  void saveCurrentInfiniteScores() {
    if (isInfiniteMode) {
      GamePreferences.updateInfiniteStats( // Metodun adını GamePreferences'taki doğru isimle değiştir.
        score: score,
        birds: birdsHit,
        combo: comboCount,
        headshots: headShots,
      );
    }
  }

  @override
  void gameOver() {
    if (isInfiniteMode) {
      saveCurrentInfiniteScores();
    }
  }

  void _spawnBirds() {
    birds.clear();
    final rand = math.Random();

    if (isInfiniteMode) {
      // Sonsuz mod için kuş spawn sistemi
      if (infiniteBirdCount == null) {
        // Sınırsız kuş modu: başlangıçta 16 kuş, sonra dinamik spawn
        _initialBirdSpawn(16, rand);
      } else {
        // Belirli sayıda kuş
        _initialBirdSpawn(infiniteBirdCount!, rand);
      }
    } else {
      // Level modu (değişiklik yok)
      _initialBirdSpawn(levelData!.birdCount, rand);
    }
  }

  void _initialBirdSpawn(int count, math.Random rand) {
    for (int i = 0; i < count; i++) {
      final x = size.x * (0.25 + 0.60 * rand.nextDouble());
      final minY = 80.0;
      final maxY = ground.position.y - 200.0;
      final y = minY + rand.nextDouble() * (maxY - minY);

      final bird = Bird()..position = Vector2(x, y);
      birds.add(bird);
      add(bird);
    }
  }
  int _multiKillBonusForCount(int killsThisShot) {
    if (killsThisShot >= 5) return 3000; // Beşli
    switch (killsThisShot) {
      case 4:
        return 1800;
      case 3:
        return 900;
      case 2:
        return 300;
      default:
        return 0;
    }
  }
  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) return;

    gameTime += dt;

    if (!isInfiniteMode) {
      // Level modu - süre kontrolü
      if (levelData?.timeLimit != null && gameTime >= levelData!.timeLimit!) {
        _showBonusOfferOrGameOver('time');
        return;
      }
      _checkLevelCompletion();
    } else {
      // Sonsuz mod

      // Sınırsız kuş modu için yeni kuş spawn
      if (infiniteBirdCount == null) {
        _spawnNewBirdsIfNeeded();
      }

      // Oyun bitiş kontrolleri
      bool shouldEndGame = false;

      // 1. Süre limiti kontrolü
      if (infiniteTimeLimit != null && gameTime >= infiniteTimeLimit!) {
        shouldEndGame = true;
      }

      // 2. Ok limiti kontrolü
      if (infiniteArrowsLimit != null && archer.arrowsLeft <= 0 && !_hasActiveArrows()) {
        shouldEndGame = true;
      }

      // 3. Kuş kontrolü (sadece sınırlı kuş modunda)
      if (infiniteBirdCount != null) {
        final aliveBirds = birds.where((bird) => bird.isAlive).length;
        if (aliveBirds == 0) {
          shouldEndGame = true;
        }
      }

      if (shouldEndGame) {
        _gameOver(true);
      }
    }
  }


  void _spawnNewBirdsIfNeeded() {
    // Sınırsız kuş modunda: canlı kuş sayısı 8'in altına düşerse yeni kuşlar spawn et
    final aliveBirds = birds.where((bird) => bird.isAlive).length;

    if (aliveBirds < 8) {
      final rand = math.Random();
      final spawnCount = math.min(6, 16 - aliveBirds); // Max 16 kuş aynı anda

      for (int i = 0; i < spawnCount; i++) {
        final x = size.x * (0.25 + 0.60 * rand.nextDouble());
        final minY = 80.0;
        final maxY = ground.position.y - 200.0;
        final y = minY + rand.nextDouble() * (maxY - minY);

        final bird = Bird()..position = Vector2(x, y);
        birds.add(bird);
        add(bird);
      }
    }
  }
  bool _hasActiveArrows() {
    for (final c in children) {
      if (c is Arrow && !c.stuck && c.attachedBird == null) return true;
    }
    return false;
  }

  void _checkLevelCompletion() {
    if (isLevelCompleted || isGameOver) return;

    final aliveBirds = birds.where((bird) => bird.isAlive).length;

    if (aliveBirds == 0) {
      bool objectiveCompleted = true;

      if (levelData!.consecutiveHits != null && maxConsecutiveHits < levelData!.consecutiveHits!) {
        objectiveCompleted = false;
      }

      if (levelData!.headShotsOnly && headShots < birdsHit) {
        objectiveCompleted = false;
      }

      if (objectiveCompleted) {
        _levelCompleted();
      } else {
        _gameOver(false);
      }
    } else if (!isInfiniteMode && archer.arrowsLeft <= 0 && !_hasActiveArrows()) {
      // Ok bittiğinde bonus teklifi göster
      _showBonusOfferOrGameOver('arrows');
    }
  }
  void _showBonusOfferOrGameOver(String reason) {
    if (isGameOver) return;

    // Video reklamı kontrol etmek yerine direkt game over
    _gameOver(false);
  }

  void _showTimeBonusOffer() {
    // Video reklam özelliği olmadığı için direkt Mission Failed göster
    _showMissionFailedScreen();
  }
  void _showArrowBonusOffer() {
    // Video reklam özelliği olmadığı için direkt Mission Failed göster
    _showMissionFailedScreen();
  }
  void _showMissionFailedScreen() {
    // Game over durumunu zorla ayarla
    if (!isGameOver) {
      isGameOver = true;
    }

    // Level modu için sayacı arttır
    if (!isInfiniteMode) {
      levelGamesPlayed++;
    }

    // High score kaydet (level) veya sonsuz istatistik güncelle
    if (isInfiniteMode) {
      _saveInfiniteStatsIfNeeded();
    } else {
      _saveLevelHighScoreIfNeeded();
    }

    // Mission Failed ekranını göster
    add(GameOverOverlay(
      isSuccess: false,
      levelNumber: levelData?.levelNumber,
      gameRef: this,
    ));
  }
  void _removeBonusOverlay() {
    // Bonus overlay'ini kaldır
    children.whereType<BonusOfferOverlay>().forEach((overlay) {
      overlay.removeFromParent();
    });
  }
  void _levelCompleted() {
    isLevelCompleted = true;
    isGameOver = true;

    // Level modu için sayacı arttır
    levelGamesPlayed++;

    // High score kaydet
    _saveLevelHighScoreIfNeeded();

    // Yıldız hesapla ve kaydet
    if (levelData != null) {
      final stars = StarCalculator.calculateStars(levelData!.levelNumber, score);
      GamePreferences.setLevelStars(levelData!.levelNumber, stars);
    }

    // Sonraki seviyeyi aç
    if (levelData!.levelNumber < GameLevels.levels.length) {
      GamePreferences.unlockLevel(levelData!.levelNumber + 1);
    }

    add(GameOverOverlay(
      isSuccess: true,
      levelNumber: levelData!.levelNumber,
      gameRef: this,
    ));
  }
  void _gameOver(bool isSuccess) {
    if (isGameOver) return;
    isGameOver = true;

    // Level modu için sayacı arttır
    if (!isInfiniteMode) {
      levelGamesPlayed++;
    }

    // High score kaydet (level) veya sonsuz istatistik güncelle
    if (isInfiniteMode) {
      _saveInfiniteStatsIfNeeded();
    } else {
      _saveLevelHighScoreIfNeeded();
    }

    add(GameOverOverlay(
      isSuccess: isSuccess,
      levelNumber: levelData?.levelNumber,
      gameRef: this,
    ));
  }

  // Skor/Kombo: Kuş öldüğünde çağrılır
  void onBirdKilled({
    required bool isHeadShot,
    required int? shotId,
    required Vector2 at,
  }) {
    // Level sayaçları
    birdsHit++;
    consecutiveHits++;
    if (consecutiveHits > maxConsecutiveHits) {
      maxConsecutiveHits = consecutiveHits;
    }
    if (isHeadShot) headShots++;

    // Kombolar
    comboCount++;
    if (comboCount > bestCombo) bestCombo = comboCount;

    if (isHeadShot) {
      headshotComboCount++;
      if (headshotComboCount > bestHeadshotCombo) bestHeadshotCombo = headshotComboCount;
    } else {
      headshotComboCount = 0;
    }

    // Bu atışın kill sayısı
    final int sid = shotId ?? currentShotId;
    final int newKillsForShot = (shotKillCounts[sid] ?? 0) + 1;
    shotKillCounts[sid] = newKillsForShot;

    // Puan hesaplama (yeni kurallar)
    // Temel: Normal 100, Headshot +150 (toplam 250)
    final int base = 100 + (isHeadShot ? 150 : 0);

    // Kombo çarpanları (step)
    final double comboMul = _comboMultiplier(comboCount);

    // Kafa vuruşu kombo çarpanı (yalnız headshot'ta uygulanır, normal kombo ile çarpılır)
    final double headshotMul = isHeadShot ? _headshotComboMultiplier(headshotComboCount) : 1.0;

    // Kill puanı (çarpanlar uygulanır)
    final int killPoints = (base * comboMul * headshotMul).round();

    // Multi-kill bonusu (tek seferlik ek puan, eşik yakalandığı anda)
    final int multiBonus = _multiKillBonusForCount(newKillsForShot);

    // Toplam kazanç
    final int gain = killPoints + multiBonus;
    score += gain;

    // Uçan bildirimler
    showFloatingText('+$killPoints', at + Vector2(0, -15), Colors.yellowAccent);
    if (isHeadShot) {
      showFloatingText('Headshot!', at + Vector2(0, -30), Colors.redAccent);
    }
    if (multiBonus > 0) {
      // Multi-kill labels
      final labels = {2: 'Double Kill!', 3: 'Triple Kill!', 4: 'Quad Kill!', 5: 'Penta Kill!'};
      final String mkText = labels[newKillsForShot] ?? 'Multi Kill!';
      showFloatingText(mkText, at + Vector2(0, -60), Colors.cyanAccent);
      showFloatingText('+$multiBonus', at + Vector2(0, -75), Colors.cyanAccent);
    }

// Normal combo threshold messages
    if (comboCount >= 10) {
      showFloatingText('Monster Kill!', at, Colors.purpleAccent);
    } else if (comboCount >= 5) {
      showFloatingText('Killing Spree!', at, Colors.deepOrange);
    } else if (comboCount >= 3) {
      showFloatingText('Nice Combo!', at, Colors.orange);
    }

// Headshot combo threshold messages (only shown for headshots)
    if (isHeadShot) {
      if (headshotComboCount >= 10) {
        showFloatingText('Godlike!', at + Vector2(0, -45), Colors.purple);
      } else if (headshotComboCount >= 5) {
        showFloatingText('Legendary Accuracy!', at + Vector2(0, -45), Colors.pinkAccent);
      } else if (headshotComboCount >= 3) {
        showFloatingText('Sharpshooter!', at + Vector2(0, -45), Colors.red);
      }
    }

    if (!isInfiniteMode) {
      _checkLevelCompletion();
    }
  }

  // Miss: ok sonuçsuz kalınca
  void onArrowMissed() {
    consecutiveHits = 0;
    comboCount = 0;
    headshotComboCount = 0;
  }

  double _comboMultiplier(int combo) {
    if (combo >= 10) return 5.0;   // 10x → 5.0
    if (combo >= 5) return 2.2;    // 5x → 2.2
    if (combo >= 3) return 1.5;    // 3x → 1.5
    if (combo >= 2) return 1.2;    // 2x → 1.2
    return 1.0;                    // 1x → 1.0
  }

  double _headshotComboMultiplier(int hsCombo) {
    if (hsCombo >= 10) return 12.0;  // 10x → 12.0
    if (hsCombo >= 5) return 3.8;    // 5x → 3.8
    if (hsCombo >= 3) return 2.0;    // 3x → 2.0
    return 1.0;                      // <3 → 1.0
  }

  double _multiKillMultiplier(int killsThisShot) {
    if (killsThisShot >= 5) return 3.0;
    if (killsThisShot == 4) return 2.5;
    if (killsThisShot == 3) return 2.0;
    if (killsThisShot == 2) return 1.5;
    return 1.0;
  }

  void showFloatingText(String text, Vector2 at, Color color, {double duration = 1.1}) {
    add(FloatingText(
      text: text,
      position: at.clone(),
      color: color,
      duration: duration,
    ));
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (archer.arrowsLeft <= 0 || isGameOver) return;

    dragStart = Vector2(info.eventPosition.global.x, info.eventPosition.global.y);
    currentDrag = dragStart!.clone();
    isDragging = true;

    archer.startAiming();
    aimingSystem.startAiming(dragStart!);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isDragging && archer.arrowsLeft > 0 && !isGameOver) {
      currentDrag = Vector2(info.eventPosition.global.x, info.eventPosition.global.y);
      aimingSystem.updateAiming(dragStart!, currentDrag!);

      if (dragStart != null && currentDrag != null) {
        final aimDirection = (dragStart! - currentDrag!).normalized();
        archer.updateAimDirection(aimDirection);
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (isDragging && dragStart != null && currentDrag != null && archer.arrowsLeft > 0 && !isGameOver) {
      final pullVector = dragStart! - currentDrag!;
      if (pullVector.length > 5) {
        _shootArrow();
      } else {
        archer.cancelAiming();
      }
      aimingSystem.stopAiming();
    }
    _resetDrag();
  }

  void _resetDrag() {
    isDragging = false;
    dragStart = null;
    currentDrag = null;
  }

  void _shootArrow() {
    if (dragStart == null || currentDrag == null) return;

    // Sadece temel kontroller - ok sayısı ve oyun durumu
    if (archer.arrowsLeft <= 0 || isGameOver) {
      return;
    }

    final pullVector = dragStart! - currentDrag!;
    final direction = pullVector.normalized();
    final power = math.min(pullVector.length / 60, 8.0);

    // Ok sayısını hemen azalt - çakışmayı önlemek için
    archer.arrowsLeft--;
    arrowsUsed++;

    final bowDrawAmount = archer.bowDrawAmount;
    const double bowStringCenterLocalX = 65.0;
    final double localPullX = bowStringCenterLocalX - (bowDrawAmount * 35.0);
    final bool facingRightNow = archer.aimDirection.x >= 0;

    final double startX = facingRightNow
        ? (archer.position.x + localPullX)
        : (archer.position.x + archer.size.x - localPullX);
    final double startY = archer.position.y + 35.0;

    final exactArrowPosition = Vector2(startX, startY);

    // Her atış için yeni shotId
    currentShotId++;
    shotKillCounts[currentShotId] = 0;

    final arrow = Arrow(
      startPos: exactArrowPosition,
      direction: direction,
      power: power,
      gameRef: this,
      shotId: currentShotId,
    );

    add(arrow);

    // Okçu animasyonunu başlat - hızlı atıma izin ver
    archer.triggerShoot();
  }
}




// ArcheryGame sınıfına eklenecek dinamik bilgi UI bileşeni

// Level UI bileşeni
class LevelUI extends PositionComponent {
  final LevelData levelData;
  late TextComponent levelNumberText;
  late TextComponent objectiveText;
  late TextComponent timeText;
  late TextComponent arrowsText;
  late TextComponent birdsText;

  // Animasyon için
  double pulseTimer = 0.0;
  bool isWarningTime = false;
  bool isLowArrows = false;

  LevelUI({required this.levelData});

  @override
  Future<void> onLoad() async {
    position = Vector2(16, 16);

    // Level number with enhanced styling
    levelNumberText = TextComponent(
      text: '🎯 Level ${levelData.levelNumber}',
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [Color(0xFF4A90E2), Colors.white, Color(0xFF4A90E2)],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, 200, 25)),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            Shadow(
              color: Color(0xFF4A90E2).withOpacity(0.6),
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      position: Vector2(0, 0),
    );
    add(levelNumberText);

    // Animated objective with icon
    objectiveText = TextComponent(
      text: '🎪 ${levelData.objective}',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
            Shadow(
              color: Color(0xFFFFD700).withOpacity(0.4),
              blurRadius: 6,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      position: Vector2(0, 22),
    );
    add(objectiveText);

    // Time display with warning animation
    timeText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      position: Vector2(0, 44),
    );
    add(timeText);

    // Arrows display with low warning
    arrowsText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      position: Vector2(0, 66),
    );
    add(arrowsText);

    // Birds display
    birdsText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      position: Vector2(0, 88),
    );
    add(birdsText);

    // Entrance animation
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.8,
          curve: Curves.elasticOut,
          startDelay: 0.2,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    pulseTimer += dt;

    final game = parent as ArcheryGame;

    // Time display with critical warning
    if (levelData.timeLimit != null) {
      final remainingTime = math.max(0, levelData.timeLimit! - game.gameTime.toInt());
      timeText.text = '⏰ Süre: ${remainingTime}s';

      final newWarningState = remainingTime <= 10;
      if (newWarningState != isWarningTime) {
        isWarningTime = newWarningState;
        _updateTimeWarningStyle();
      }
    }

    // Arrows display with low warning
    if (levelData.maxArrows != null) {
      arrowsText.text = '🏹 Arrows: ${game.archer.arrowsLeft}/${levelData.maxArrows}';

      final newLowArrowState = game.archer.arrowsLeft <= 3;
      if (newLowArrowState != isLowArrows) {
        isLowArrows = newLowArrowState;
        _updateArrowWarningStyle();
      }
    }

    // Birds display with animated count
    final aliveBirds = game.birds.where((bird) => bird.isAlive).length;
    birdsText.text = '🦅 Birds: $aliveBirds/${levelData.birdCount}';

    // Dynamic color based on remaining birds
    final progressRatio = aliveBirds / levelData.birdCount;
    Color birdColor = Colors.white;
    if (progressRatio <= 0.3) {
      birdColor = Color(0xFF7ED321); // Yeşil - başarıya yakın
    } else if (progressRatio <= 0.6) {
      birdColor = Color(0xFFFFD700); // Sarı - orta
    }

    birdsText.textRenderer = TextPaint(
      style: TextStyle(
        color: birdColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(
            color: birdColor.withOpacity(0.4),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }

  void _updateTimeWarningStyle() {
    if (isWarningTime) {
      timeText.textRenderer = TextPaint(
        style: TextStyle(
          color: Color(0xFFFF4444),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            Shadow(
              color: Color(0xFFFF4444).withOpacity(0.8),
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
          ],
        ),
      );

      // Critical time pulse animation
      timeText.add(
        ScaleEffect.by(
          Vector2.all(1.15),
          EffectController(
            duration: 0.5,
            curve: Curves.easeInOut,
            reverseDuration: 0.5,
            infinite: true,
          ),
        ),
      );
    }
  }

  void _updateArrowWarningStyle() {
    if (isLowArrows) {
      arrowsText.textRenderer = TextPaint(
        style: TextStyle(
          color: Color(0xFFFF9500),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            Shadow(
              color: Color(0xFFFF9500).withOpacity(0.6),
              blurRadius: 6,
              offset: Offset(0, 0),
            ),
          ],
        ),
      );

      // Low arrows warning pulse
      arrowsText.add(
        ScaleEffect.by(
          Vector2.all(1.1),
          EffectController(
            duration: 0.8,
            curve: Curves.easeInOut,
            reverseDuration: 0.8,
            infinite: true,
          ),
        ),
      );
    }
  }
}
// Skor HUD
class ScoreUI extends PositionComponent {
  late TextComponent scoreText;
  late TextComponent comboText;

  // Combo efektleri için
  int lastComboCount = 0;
  int lastHeadshotCombo = 0;
  double animationTimer = 0.0;

  @override
  Future<void> onLoad() async {
    // Sağ üst köşe
    anchor = Anchor.topRight;
    position = Vector2((parent as ArcheryGame).size.x - 16, 16);

    // Score display with enhanced gradient text
    scoreText = TextComponent(
      text: '💎 Score: 0',
      anchor: Anchor.topRight,
      position: Vector2(0, 0),
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFA500),
                Color(0xFFFFD700),
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, 150, 20)),
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            Shadow(
              color: Color(0xFFFFD700).withOpacity(0.6),
              blurRadius: 8,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
    );
    add(scoreText);

    // Combo display with dynamic styling
    comboText = TextComponent(
      text: '🔥 Combo: x0  |  💀 Headshot: x0',
      position: Vector2(0, 24),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
    add(comboText);

    // Entrance animation
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.6,
          curve: Curves.elasticOut,
          startDelay: 0.5,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    animationTimer += dt;

    final game = parent as ArcheryGame;

    // Score update with number animation effect
    scoreText.text = '💎 Score: ${_formatScore(game.score)}';

    // Dynamic combo display with emoji based on performance
    final comboEmoji = _getComboEmoji(game.comboCount);
    final headshotEmoji = _getHeadshotEmoji(game.headshotComboCount);

    comboText.text = '$comboEmoji Combo: x${game.comboCount}  |  $headshotEmoji Headshot: x${game.headshotComboCount}';

    // Combo breakthrough animations
    if (game.comboCount != lastComboCount) {
      _triggerComboAnimation(game.comboCount);
      lastComboCount = game.comboCount;
    }

    if (game.headshotComboCount != lastHeadshotCombo) {
      _triggerHeadshotAnimation(game.headshotComboCount);
      lastHeadshotCombo = game.headshotComboCount;
    }

    // Dynamic styling based on performance
    _updateStyling(game);
  }

  String _formatScore(int score) {
    // Add thousand separators for better readability
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  String _getComboEmoji(int combo) {
    if (combo >= 15) return '💥';
    if (combo >= 10) return '🔥';
    if (combo >= 5) return '⚡';
    if (combo >= 3) return '🌟';
    if (combo >= 2) return '✨';
    return '🎯';
  }

  String _getHeadshotEmoji(int headshot) {
    if (headshot >= 15) return '👑';
    if (headshot >= 10) return '💀';
    if (headshot >= 5) return '🎯';
    if (headshot >= 3) return '🔴';
    return '○';
  }

  void _triggerComboAnimation(int newCombo) {
    // Combo milestone animations
    if (newCombo >= 10 && newCombo % 5 == 0) {
      // Epic combo animation
      add(
        ScaleEffect.by(
          Vector2.all(1.3),
          EffectController(
            duration: 0.3,
            curve: Curves.elasticOut,
            reverseDuration: 0.3,
          ),
        ),
      );
    } else if (newCombo >= 5) {
      // Good combo pulse
      add(
        ScaleEffect.by(
          Vector2.all(1.15),
          EffectController(
            duration: 0.2,
            curve: Curves.easeOut,
            reverseDuration: 0.2,
          ),
        ),
      );
    }
  }

  void _triggerHeadshotAnimation(int newHeadshot) {
    if (newHeadshot >= 10 && newHeadshot % 3 == 0) {
      // Epic headshot streak
      comboText.add(
        ScaleEffect.by(
          Vector2.all(1.4),
          EffectController(
            duration: 0.4,
            curve: Curves.elasticOut,
            reverseDuration: 0.4,
          ),
        ),
      );
    }
  }

  void _updateStyling(ArcheryGame game) {
    // Dynamic color based on combo performance
    Color primaryColor = Color(0xFFFFD700);
    Color comboColor = Colors.white70;
    Color headshotColor = Colors.white70;

    // Combo color progression
    if (game.comboCount >= 15) {
      comboColor = Color(0xFFFF1744); // Red - Insane
    } else if (game.comboCount >= 10) {
      comboColor = Color(0xFFFF5722); // Deep Orange - Amazing
    } else if (game.comboCount >= 5) {
      comboColor = Color(0xFFFF9800); // Orange - Great
    } else if (game.comboCount >= 3) {
      comboColor = Color(0xFFFFC107); // Amber - Good
    }

    // Headshot combo color progression
    if (game.headshotComboCount >= 10) {
      headshotColor = Color(0xFF8A2BE2); // Purple - Legendary
    } else if (game.headshotComboCount >= 5) {
      headshotColor = Color(0xFFE91E63); // Pink - Incredible
    } else if (game.headshotComboCount >= 3) {
      headshotColor = Color(0xFFF44336); // Red - Excellent
    }

    // High score glow effect
    if (game.score >= 50000) {
      primaryColor = Color(0xFFFFD700); // Gold
    } else if (game.score >= 25000) {
      primaryColor = Color(0xFFC0C0C0); // Silver
    } else if (game.score >= 10000) {
      primaryColor = Color(0xFFCD7F32); // Bronze
    }

    // Update combo text styling
    comboText.textRenderer = TextPaint(
      style: TextStyle(
        color: comboColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: comboColor.withOpacity(0.4),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );

    // Update score text styling for high scores
    scoreText.textRenderer = TextPaint(
      style: TextStyle(
        foreground: Paint()
          ..shader = LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
              primaryColor,
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, 150, 20)),
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        shadows: [
          Shadow(
            color: primaryColor.withOpacity(0.6),
            blurRadius: 8,
            offset: Offset(0, 0),
          ),
        ],
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 16, 16);
  }
}



// Uçan yazı
class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  final double duration;
  double t = 0.0;
  late final TextComponent label;

  FloatingText({
    required this.text,
    required this.color,
    this.duration = 1.1,
    Vector2? position,
  }) {
    this.position = position ?? Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    label = TextComponent(
      text: text,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    position.add(Vector2(0, -30.0 * dt));
    final double alpha = (1.0 - (t / duration)).clamp(0.0, 1.0);
    label.textRenderer = TextPaint(
      style: TextStyle(
        color: color.withOpacity(alpha),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    if (t >= duration) {
      removeFromParent();
    }
  }
}

// Oyun bitti overlay'i


class GameOverOverlay extends PositionComponent with HasGameRef {
  final bool isSuccess;
  final int? levelNumber;
  final ArcheryGame gameRef;

  // Animasyon değişkenleri
  late RectangleComponent background;
  late RectangleComponent mainPanel;
  late TextComponent titleComponent;
  late List<Component> animatedComponents;

  GameOverOverlay({
    required this.isSuccess,
    required this.levelNumber,
    required this.gameRef,
  });

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    animatedComponents = [];

    await _createBackground();
    await _createMainPanel();
    await _createContent();
    await _startAnimations();
  }

  Future<void> _createMainPanel() async {
    final panelWidth = size.x * 0.92;
    final panelHeight = size.y * 0.78;

    // Glassmorphism efekti için blur arka plan
    final blurBackground = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20),
    );
    add(blurBackground);

    // Ana panel - glassmorphism tasarım
    mainPanel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e).withOpacity(0.9),
            Color(0xFF16213e).withOpacity(0.8),
            Color(0xFF0f3460).withOpacity(0.9),
          ],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth, panelHeight)),
    );

    // Çoklu glow efektleri
    for (int i = 0; i < 3; i++) {
      final glowSize = panelWidth + (i * 4) + 8;
      final glowPanel = RectangleComponent(
        size: Vector2(glowSize, panelHeight + (i * 4) + 8),
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        paint: Paint()
          ..color = _getThemeColor().withOpacity(0.3 - i * 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 + i * 4),
      );
      add(glowPanel);
    }

    add(mainPanel);
    animatedComponents.add(mainPanel);

    // Animasyonlu border
    final borderPanel = RectangleComponent(
      size: Vector2(panelWidth + 6, panelHeight + 6),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = SweepGradient(
          colors: [
            _getThemeColor(),
            _getThemeColor().withOpacity(0.3),
            Colors.transparent,
            _getThemeColor().withOpacity(0.3),
            _getThemeColor(),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, panelWidth + 6, panelHeight + 6)),
    );
    add(borderPanel);

    // Border rotate animasyonu
    borderPanel.add(
      RotateEffect.by(
        2 * pi,
        EffectController(duration: 8.0, infinite: true),
      ),
    );
  }

  Future<void> _createBackground() async {
    // Animasyonlu gradient background
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.95),
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );
    add(background);

    // Parçacık sistemi arka planı
    await _createParticleBackground();

    // Dinamik glow efekti
    final glowBackground = RectangleComponent(
      size: size,
      paint: Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            _getThemeColor().withOpacity(0.2),
            _getThemeColor().withOpacity(0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );
    add(glowBackground);

    // Glow pulse animasyonu
    glowBackground.add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(duration: 2.0, curve: Curves.easeInOut, reverseDuration: 2.0, infinite: true),
      ),
    );
  }

  Future<void> _createContent() async {
    // Title bölümü
    await _createTitle();

    // Level ve yıldız bilgisi
    if (levelNumber != null && !gameRef.isInfiniteMode) {
      await _createLevelInfo();
    }

    // İstatistikler
    await _createStats();

    // Butonlar
    await _createButtons();
  }

  Future<void> _createParticleBackground() async {
    // Arka plan parçacık sistemi
    final particleContainer = PositionComponent();
    add(particleContainer);

    for (int i = 0; i < 30; i++) {
      final particle = CircleComponent(
        radius: Random().nextDouble() * 3 + 1,
        position: Vector2(
          Random().nextDouble() * size.x,
          Random().nextDouble() * size.y,
        ),
        paint: Paint()..color = _getThemeColor().withOpacity(0.1),
      );

      // Parçacık animasyonları
      particle.add(
        MoveEffect.by(
          Vector2(
            (Random().nextDouble() - 0.5) * 100,
            (Random().nextDouble() - 0.5) * 100,
          ),
          EffectController(
            duration: 3.0 + Random().nextDouble() * 2.0,
            curve: Curves.easeInOut,
            reverseDuration: 3.0 + Random().nextDouble() * 2.0,
            infinite: true,
          ),
        ),
      );

      particle.add(
        OpacityEffect.to(
          0.05,
          EffectController(
            duration: 2.0,
            curve: Curves.easeInOut,
            reverseDuration: 2.0,
            infinite: true,
          ),
        ),
      );

      particleContainer.add(particle);
    }
  }


  Future<void> _createTitle() async {
    String titleText = '🎯 GAME OVER';
    String emoji = '🎯';

    if (!gameRef.isInfiniteMode) {
      if (isSuccess) {
        titleText = 'VICTORY!';
        emoji = '🏆';  // Trophy for wins
      } else {
        titleText = 'MISSION FAILED';
        emoji = '💀';  // Skull for failure
      }
    }

    // Emoji ile ana title ayrı ayrı
    final emojiComponent = TextComponent(
      text: emoji,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: _getResponsiveFontSize(42),
          shadows: [
            Shadow(
              color: _getThemeColor().withOpacity(0.8),
              blurRadius: 15,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.3),
    );
    add(emojiComponent);
    animatedComponents.add(emojiComponent);

    // Emoji pulse animasyonu
    emojiComponent.add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(
          duration: 1.0,
          curve: Curves.easeInOut,
          reverseDuration: 1.0,
          infinite: true,
        ),
      ),
    );

    // Ana title - gradient text efekti
    titleComponent = TextComponent(
      text: titleText,
      textRenderer: TextPaint(
        style: TextStyle(
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                _getThemeColor(),
                _getThemeColor().withOpacity(0.7),
                Colors.white,
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(Rect.fromLTWH(0, 0, 300, 50)),
          fontSize: _getResponsiveFontSize(38),
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          shadows: [
            Shadow(
              color: _getThemeColor().withOpacity(0.8),
              blurRadius: 20,
              offset: Offset(0, 3),
            ),
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.22),
    );
    add(titleComponent);
    animatedComponents.add(titleComponent);

    // Title glow efekti - OpacityEffect kaldırıldı
    final titleGlow = TextComponent(
      text: titleText,
      textRenderer: TextPaint(
        style: TextStyle(
          color: _getThemeColor().withOpacity(0.2), // Sabit opacity
          fontSize: _getResponsiveFontSize(42),
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.22),
    );
    add(titleGlow);

    // Scale pulse ile glow efekti
    titleGlow.add(
      ScaleEffect.by(
        Vector2.all(1.05),
        EffectController(
          duration: 1.5,
          curve: Curves.easeInOut,
          reverseDuration: 1.5,
          infinite: true,
        ),
      ),
    );
  }
  Future<void> _createStarAnimation() async {
    final stars = StarCalculator.calculateStars(levelNumber!, gameRef.score);

    // Yıldız container
    final starContainer = PositionComponent(
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.12),
      anchor: Anchor.center,
    );
    add(starContainer);

    for (int i = 0; i < 3; i++) {
      final isEarned = i < stars;

      // Yıldız arka plan (glow)
      if (isEarned) {
        final starBg = CircleComponent(
          radius: 25,
          position: Vector2((i - 1) * 45.0, 0),
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.amber.withOpacity(0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15),
        );
        starContainer.add(starBg);
      }

      // Ana yıldız
      final star = TextComponent(
        text: isEarned ? '⭐' : '☆',
        textRenderer: TextPaint(
          style: TextStyle(
            color: isEarned ? Colors.amber : Colors.grey.withOpacity(0.4),
            fontSize: _getResponsiveFontSize(32),
            shadows: isEarned ? [
              Shadow(
                color: Colors.amber.withOpacity(0.8),
                blurRadius: 12,
                offset: Offset(0, 0),
              ),
              Shadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2((i - 1) * 45.0, 0),
      );
      starContainer.add(star);
      animatedComponents.add(star);

      if (isEarned) {
        // Yıldız spawn animasyonu
        star.scale = Vector2.zero();
        star.add(
          ScaleEffect.by(
            Vector2.all(1.0),
            EffectController(
              duration: 0.5,
              curve: Curves.elasticOut,
              startDelay: i * 0.3,
            ),
          ),
        );

        // Sürekli pulse
        star.add(
          ScaleEffect.by(
            Vector2.all(1.1),
            EffectController(
              duration: 2.0,
              curve: Curves.easeInOut,
              reverseDuration: 2.0,
              infinite: true,
              startDelay: i * 0.5,
            ),
          ),
        );

        // Gelişmiş sparkle efekti
        final sparkle = _createAdvancedSparkleEffect(star.position);
        starContainer.add(sparkle);
      }
    }
  }

  Component _createAdvancedSparkleEffect(Vector2 position) {
    final sparkleContainer = PositionComponent(position: position);

    // Ana sparkle
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (pi / 180);
      final distance = 25.0 + Random().nextDouble() * 15;

      final sparkle = CircleComponent(
        radius: 1.5 + Random().nextDouble() * 1.5,
        position: Vector2.zero(),
        anchor: Anchor.center,
        paint: Paint()
          ..shader = RadialGradient(
            colors: [Colors.amber, Colors.orange, Colors.transparent],
            stops: [0.0, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 3)),
      );

      sparkle.add(
        MoveEffect.by(
          Vector2(distance * cos(angle), distance * sin(angle)),
          EffectController(
            duration: 1.0 + Random().nextDouble() * 0.5,
            curve: Curves.easeOut,
          ),
        ),
      );

      // Opacity yerine Scale efekti kullan
      sparkle.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 1.0 + Random().nextDouble() * 0.5),
        ),
      );

      // Otomatik kaldırma
      sparkle.add(
        RemoveEffect(
          delay: 1.5 + Random().nextDouble() * 0.5,
        ),
      );

      sparkleContainer.add(sparkle);
    }

    return sparkleContainer;
  }
  // cos ve sin fonksiyonları için import gerekli
  double cos(double radians) => math.cos(radians);
  double sin(double radians) => math.sin(radians);

  Future<void> _createStats() async {
    final statsContainer = PositionComponent(
      position: Vector2(size.x / 2, size.y / 2 + size.y * 0.05),
      anchor: Anchor.center,
    );

    final stats = [
      'Score: ${gameRef.score}',
      'Arrows Fired: ${gameRef.arrowsUsed}',
      'Birds Hit: ${gameRef.birdsHit}',
      'Longest Streak: ${gameRef.maxConsecutiveHits}',
      'Best Combo: x${gameRef.bestCombo}',
      'Best Headshot Combo: x${gameRef.bestHeadshotCombo}',
      'Headshots: ${gameRef.headShots}',
    ];

    for (int i = 0; i < stats.length; i++) {
      final statComponent = TextComponent(
        text: stats[i],
        textRenderer: TextPaint(
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: _getResponsiveFontSize(14),
            fontWeight: FontWeight.w400,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(0, (i - 3) * 22),
      );
      statsContainer.add(statComponent);
    }

    add(statsContainer);
    animatedComponents.add(statsContainer);
  }

  Future<void> _createButtons() async {
    final buttonY = size.y / 2 + size.y * 0.28;

    if (gameRef.isInfiniteMode) {
      _createModernButton('Main Menu', Vector2(size.x / 2 - 80, buttonY),
          Color(0xFF4A90E2), _goToMainMenu);
      _createModernButton('Retry', Vector2(size.x / 2 + 80, buttonY),
          Color(0xFF7ED321), _restartInfiniteMode);
    } else {
      if (isSuccess && levelNumber != null && levelNumber! < GameLevels.levels.length) {
        _createModernButton('Main Menu', Vector2(size.x / 2 - 120, buttonY),
            Color(0xFF4A90E2), _goToMainMenu);
        _createModernButton('Retry', Vector2(size.x / 2, buttonY),
            Color(0xFF7ED321), _restartLevel);
        _createModernButton('Next Level', Vector2(size.x / 2 + 120, buttonY),
            Color(0xFFFF9500), _nextLevel);
      } else {
        _createModernButton('Main Menu', Vector2(size.x / 2 - 80, buttonY),
            Color(0xFF4A90E2), _goToMainMenu);
        _createModernButton('Retry', Vector2(size.x / 2 + 80, buttonY),
            Color(0xFF7ED321), _restartLevel);
      }
    }
  }
  void _modernButtonPressAnimation(Vector2 position, Color color) {
    // Gelişmiş ripple efekti
    final ripple = CircleComponent(
      radius: 0,
      position: position,
      anchor: Anchor.center,
      paint: Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.6),
            color.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 50)),
    );
    add(ripple);

    ripple.add(
      ScaleEffect.by(
        Vector2.all(50),
        EffectController(duration: 0.5, curve: Curves.easeOut),
      ),
    );

    // OpacityEffect yerine RemoveEffect kullan
    ripple.add(
      RemoveEffect(
        delay: 0.5,
      ),
    );

    // Particle burst
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final particle = CircleComponent(
        radius: 2,
        position: position,
        anchor: Anchor.center,
        paint: Paint()..color = color,
      );
      add(particle);

      particle.add(
        MoveEffect.by(
          Vector2(30 * cos(angle), 30 * sin(angle)),
          EffectController(duration: 0.6, curve: Curves.easeOut),
        ),
      );

      // OpacityEffect yerine ScaleEffect + RemoveEffect
      particle.add(
        ScaleEffect.by(
          Vector2.all(-1.8), // Küçülterek kaybolma
          EffectController(duration: 0.6),
        ),
      );

      particle.add(
        RemoveEffect(
          delay: 0.6,
        ),
      );
    }
  }
  void _createModernButton(String text, Vector2 position, Color color, VoidCallback onPressed) {
    final buttonSize = Vector2(120, 50);

    // Button glow layers
    for (int i = 0; i < 3; i++) {
      final glowSize = Vector2(buttonSize.x + (i * 6) + 8, buttonSize.y + (i * 6) + 8);
      final glowButton = RectangleComponent(
        size: glowSize,
        position: position,
        anchor: Anchor.center,
        paint: Paint()
          ..color = color.withOpacity(0.4 - i * 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + i * 3),
      );
      add(glowButton);
    }

    // Glassmorphism button background
    final buttonBg = RectangleComponent(
      size: Vector2(buttonSize.x + 4, buttonSize.y + 4),
      position: position,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10),
    );
    add(buttonBg);

    // Main button
    final button = ButtonComponent(
      size: buttonSize,
      position: position,
      anchor: Anchor.center,
      onPressed: () {
        HapticFeedback.heavyImpact();
        _modernButtonPressAnimation(position, color);
        onPressed();
      },
      button: RectangleComponent(
        size: buttonSize,
        paint: Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, buttonSize.x, buttonSize.y)),
      ),
    );
    add(button);
    animatedComponents.add(button);

    // Button border
    final buttonBorder = RectangleComponent(
      size: buttonSize,
      position: position,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.6), Colors.transparent],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, buttonSize.x, buttonSize.y)),
    );
    add(buttonBorder);

    // Button text
    final buttonText = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: _getResponsiveFontSize(14),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: position,
    );
    add(buttonText);

    // Hover efekti
    button.add(
      ScaleEffect.by(
        Vector2.all(1.05),
        EffectController(
          duration: 2.0,
          curve: Curves.easeInOut,
          reverseDuration: 2.0,
          infinite: true,
        ),
      ),
    );
  }


  void _buttonPressAnimation(Vector2 position) {
    final ripple = CircleComponent(
      radius: 0,
      position: position,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withOpacity(0.3),
    );
    add(ripple);

    ripple.add(
      ScaleEffect.by(
        Vector2.all(30),
        EffectController(duration: 0.3, curve: Curves.easeOut),
      ),
    );

    ripple.add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.3),
      ),
    );
  }
  Future<void> _createLevelInfo() async {
    final levelTextComponent = TextComponent(
      text: 'Level $levelNumber ${isSuccess ? "Completed!" : "Failed"}',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: _getResponsiveFontSize(18),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - size.y * 0.15),
    );
    add(levelTextComponent);
    animatedComponents.add(levelTextComponent);

    // Yıldız animasyonu
    if (isSuccess) {
      await _createStarAnimation();
    }
  }
  Future<void> _startAnimations() async {
    // Panel dramatic entrance
    if (mainPanel is PositionComponent) {
      (mainPanel as PositionComponent).scale = Vector2.zero();
    }
    mainPanel.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.8,
          curve: Curves.elasticOut,
        ),
      ),
    );

    // Title cascade animation
    if (titleComponent is PositionComponent) {
      (titleComponent as PositionComponent).position = Vector2(size.x / 2, size.y / 2 - size.y * 0.5);
    }
    titleComponent.add(
      MoveToEffect(
        Vector2(size.x / 2, size.y / 2 - size.y * 0.22),
        EffectController(
          duration: 1.2,
          curve: Curves.bounceOut,
          startDelay: 0.3,
        ),
      ),
    );

    // Staggered component animations with modern easing
    for (int i = 0; i < animatedComponents.length; i++) {
      final component = animatedComponents[i];

      // ScaleEffect ile başlangıç ve animasyon
      component.add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(
            duration: 0.6,
            curve: Curves.easeOutBack,
            startDelay: i * 0.08,
          ),
        ),
      );

      await Future.delayed(Duration(milliseconds: 80));
    }

    // Background shimmer effect
    _startBackgroundShimmer();
  }
  void _startBackgroundShimmer() {
    final shimmer = RectangleComponent(
      size: Vector2(size.x * 0.3, size.y),
      position: Vector2(-size.x * 0.3, 0),
      paint: Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.x * 0.3, size.y)),
    );
    add(shimmer);

    shimmer.add(
      MoveEffect.by(
        Vector2(size.x + size.x * 0.6, 0),
        EffectController(
          duration: 3.0,
          curve: Curves.easeInOut,
          startDelay: 1.0,
        ),
      ),
    );
  }




  Color _getThemeColor() {
    if (gameRef.isInfiniteMode) return Color(0xFFFF9500);
    return isSuccess ? Color(0xFF7ED321) : Color(0xFFD0021B);
  }

  double _getResponsiveFontSize(double baseSize) {
    final scale = (size.x / 400).clamp(0.8, 1.2);
    return baseSize * scale;
  }

  void _restartInfiniteMode() {
    final context = gameRef.buildContext;
    if (context != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InfiniteGameScreen(),
        ),
      );
    }
  }

  void _goToMainMenu() {
    final context = gameRef.buildContext;
    if (context != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _restartLevel() {
    final context = gameRef.buildContext;
    if (context != null && levelNumber != null) {
      final levelData = GameLevels.levels.firstWhere((l) => l.levelNumber == levelNumber);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LevelGameScreen(levelData: levelData),
        ),
      );
    }
  }

  void _nextLevel() {
    final context = gameRef.buildContext;
    if (context != null && levelNumber != null && levelNumber! < GameLevels.levels.length) {
      final nextLevelData = GameLevels.levels.firstWhere((l) => l.levelNumber == levelNumber! + 1);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LevelGameScreen(levelData: nextLevelData),
        ),
      );
    }
  }
}

// Karakter durumları için enum
enum ArcherState { idle, aiming, shooting, reloading }

class StickmanArcher extends PositionComponent with HasGameRef<ArcheryGame> {
  ArcherState currentState = ArcherState.idle;
  int arrowsLeft = 999;

  double animationTimer = 0.0;
  int currentFrame = 0;
  final double frameRate = 16.0;

  double shootingTimer = 0.0;
  final double shootingDuration = 0.05; // Çok hızlı animasyon
  double reloadingTimer = 0.0;
  final double reloadingDuration = 0.25;

  late Paint bodyPaint;
  late Paint bowPaint;
  late Paint quiverPaint;

  double bowDrawAmount = 0.0;
  double upperBodyLean = 0.0;
  double headTurn = 0.0;

  Vector2 aimDirection = Vector2(1, 0);
  double targetAngle = 0.0;

  @override
  Future<void> onLoad() async {
    size = Vector2(100, 120);

    bodyPaint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    bowPaint = Paint()
      ..color = Colors.brown.shade800
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    quiverPaint = Paint()..color = Colors.brown.shade700;
  }

  void updateAimDirection(Vector2 direction) {
    aimDirection = direction.clone();
    final bool facingRightNow = aimDirection.x >= 0;
    final double rawAngle = facingRightNow
        ? math.atan2(direction.y, direction.x)
        : math.atan2(direction.y, -direction.x);
    targetAngle = rawAngle.clamp(-math.pi / 4, math.pi / 4);
  }

  @override
  void update(double dt) {
    super.update(dt);

    animationTimer += dt;
    currentFrame = (animationTimer * frameRate).floor() % 4;

    switch (currentState) {
      case ArcherState.idle:
        _updateIdleAnimation(dt);
        break;
      case ArcherState.aiming:
        _updateAimingAnimation(dt);
        break;
      case ArcherState.shooting:
        _updateShootingAnimation(dt);
        break;
      case ArcherState.reloading:
        _updateReloadingAnimation(dt);
        break;
    }
  }

  void _updateIdleAnimation(double dt) {
    final breathCycle = math.sin(animationTimer * 1.2) * 0.1;
    upperBodyLean = breathCycle * 0.005;
    bowDrawAmount = 0.0;
    targetAngle = 0.0;
    headTurn = 0.05;
  }

  void triggerShoot() {
    // Hızlı atıma izin ver, animasyon durumuna bakmaksızın
    currentState = ArcherState.shooting;
    shootingTimer = 0.0;
  }
  void _updateAimingAnimation(double dt) {
    bowDrawAmount = math.min(bowDrawAmount + dt * 12.0, 1.0); // 6.0'dan 12.0'ye çıkardık
    upperBodyLean = -0.05;
    headTurn = 0.1;
    final steadyAim = math.sin(animationTimer * 12.0) * 0.0005; // Daha hızlı ama daha az titreme
    upperBodyLean += steadyAim;
  }

  void _updateShootingAnimation(double dt) {
    shootingTimer += dt;

    if (shootingTimer < shootingDuration) {
      final progress = shootingTimer / shootingDuration;

      if (progress < 0.2) { // Çok hızlı snap-back
        final snapBack = math.sin(progress * math.pi / 0.2);
        bowDrawAmount = 1.0;
        upperBodyLean = -0.18 - (snapBack * 0.03); // Daha az hareket
      } else {
        final forwardSnap = (progress - 0.2) / 0.8;
        bowDrawAmount = 1.0 - (forwardSnap * 0.8); // Hızlı geri dönüş
        upperBodyLean = -0.18 + (forwardSnap * 0.15); // Daha az hareket
      }

      headTurn = 0.25 + (progress * 0.05); // Daha az kafa hareketi
    } else {
      // Çok hızlı geçiş - direkt idle'a dön
      currentState = ArcherState.idle;
      shootingTimer = 0.0;
      bowDrawAmount = 0.0;
      upperBodyLean = 0.0;
      headTurn = 0.05;
    }
  }

  void _updateReloadingAnimation(double dt) {
    reloadingTimer += dt;

    if (reloadingTimer < reloadingDuration) {
      final progress = reloadingTimer / reloadingDuration;

      if (progress < 0.5) {
        final relaxProgress = progress / 0.5;
        bowDrawAmount = math.max(0.0, 0.2 * (1 - relaxProgress));
        upperBodyLean = math.max(0.0, 0.12 * (1 - relaxProgress));
        headTurn = 0.25 - (relaxProgress * 0.08);
      } else {
        final returnProgress = (progress - 0.5) / 0.5;
        upperBodyLean = -0.05 * (1 - returnProgress);
        headTurn = 0.15;
      }
    } else {
      _transitionToIdle();
    }
  }

  void startAiming() {
    if (arrowsLeft <= 0 || currentState == ArcherState.shooting || currentState == ArcherState.reloading) return;
    currentState = ArcherState.aiming;
  }

  void cancelAiming() {
    if (currentState == ArcherState.aiming) {
      currentState = ArcherState.idle;
      targetAngle = 0.0;
    }
  }

  void shootArrow() {
    if (currentState != ArcherState.aiming) return;
    currentState = ArcherState.shooting;
    shootingTimer = 0.0;
  }

  void _transitionToReloading() {
    // Reloading sürecini tamamen atlayıp direkt idle'a geç
    currentState = ArcherState.idle;
    reloadingTimer = 0.0;
    bowDrawAmount = 0.0;
    upperBodyLean = 0.0;
    headTurn = 0.05;
  }

  void _transitionToIdle() {
    currentState = ArcherState.idle;
    reloadingTimer = 0.0;
    targetAngle = 0.0;
    bowDrawAmount = 0.0;
    upperBodyLean = 0.0;
    headTurn = 0.05;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    final bool facingRightNow = aimDirection.x >= 0;
    if (!facingRightNow) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    _drawFixedLowerBody(canvas);
    _drawUpperBodyWithAiming(canvas);

    canvas.restore();
  }

  void _drawUpperBodyWithAiming(Canvas canvas) {
    canvas.save();

    const double shoulderX = 40.0;
    const double shoulderY = 45.0;
    final double angleToUse = targetAngle;

    canvas.translate(shoulderX, shoulderY);
    canvas.rotate(angleToUse);
    canvas.translate(-shoulderX, -shoulderY);

    const double headX = 40.0;
    const double headY = 20.0;

    canvas.drawCircle(
      const Offset(headX, headY),
      12,
      Paint()..color = Colors.pink.shade200,
    );
    canvas.drawCircle(
      const Offset(headX, headY),
      12,
      bodyPaint..style = PaintingStyle.stroke,
    );

    final double focusAmount = currentState == ArcherState.aiming ? 0.5 : 0.0;
    final double eyeHeight = 1.5 - focusAmount;
    canvas.drawCircle(const Offset(headX - 3, headY - 2), eyeHeight, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(headX + 3, headY - 2), eyeHeight, Paint()..color = Colors.black);

    canvas.restore();
    canvas.drawLine(const Offset(40, 32), const Offset(40, 60), bodyPaint);
    canvas.save();

    canvas.translate(shoulderX, shoulderY);
    canvas.rotate(angleToUse);
    canvas.translate(-shoulderX, -shoulderY);

    final Vector2 leftHandPos = _getLeftHandPosition();
    final Vector2 rightHandPos = _getRightHandPosition();

    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(leftHandPos.x, leftHandPos.y), bodyPaint);
    canvas.drawLine(Offset(shoulderX, shoulderY), Offset(rightHandPos.x, rightHandPos.y), bodyPaint);

    _drawAnimatedBow(canvas, leftHandPos, rightHandPos);

    if (_shouldDrawArrowInHand()) {
      _drawArrowInHand(canvas, rightHandPos);
    }

    canvas.restore();
  }

  void _drawFixedLowerBody(Canvas canvas) {
    canvas.drawLine(const Offset(40, 60), const Offset(40, 80), bodyPaint);
    canvas.drawLine(const Offset(40, 80), const Offset(25, 110), bodyPaint);
    canvas.drawLine(const Offset(40, 80), const Offset(55, 110), bodyPaint);
    canvas.drawLine(const Offset(20, 110), const Offset(30, 110), bodyPaint);
    canvas.drawLine(const Offset(50, 110), const Offset(60, 110), bodyPaint);
    _drawBackQuiver(canvas);
  }

  Vector2 _getLeftHandPosition() {
    switch (currentState) {
      case ArcherState.idle:
        final naturalSway = math.sin(animationTimer * 1.2) * 1;
        return Vector2(65 + naturalSway, 35 + math.cos(animationTimer * 1.0) * 0.5);
      case ArcherState.aiming:
      case ArcherState.shooting:
      case ArcherState.reloading:
        return Vector2(65, 35);
    }
  }

  Vector2 _getRightHandPosition() {
    switch (currentState) {
      case ArcherState.idle:
        final naturalSway = math.sin(animationTimer * 1.5) * 2;
        return Vector2(70 + naturalSway, 38 + math.cos(animationTimer * 1.2) * 1);
      case ArcherState.aiming:
        final pullAmount = bowDrawAmount;
        final pullDistance = pullAmount * 35;
        return Vector2(70 - pullDistance, 35);
      case ArcherState.shooting:
        final progress = shootingTimer / shootingDuration;
        if (progress < 0.4) {
          final snapBack = math.sin(progress * math.pi / 0.4) * 3;
          return Vector2(35 - snapBack, 35);
        } else {
          final forwardSnap = ((progress - 0.4) / 0.6) * 25;
          return Vector2(35 + forwardSnap, 38);
        }
      case ArcherState.reloading:
        final progress = reloadingTimer / reloadingDuration;
        if (progress > 0.3 && progress < 0.7) {
          final reachProgress = (progress - 0.3) / 0.4;
          final smoothReach = math.sin(reachProgress * math.pi);
          return Vector2(50 - smoothReach * 8, 45 + smoothReach * 10);
        }
        return Vector2(70, 38);
    }
  }

  bool _shouldDrawArrowInHand() {
    return (currentState == ArcherState.aiming ||
        (currentState == ArcherState.reloading && reloadingTimer > 0.6)) &&
        arrowsLeft >= 0;
  }

  void _drawAnimatedBow(Canvas canvas, Vector2 leftHand, Vector2 rightHand) {
    final bowBend = bowDrawAmount * 0.3;

    final bowPath = Path();
    bowPath.moveTo(65.0, 25.0);
    bowPath.quadraticBezierTo(70.0 + bowBend * 8.0, 35.0, 65.0, 45.0);
    canvas.drawPath(bowPath, bowPaint);

    final stringPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    if (currentState == ArcherState.aiming || currentState == ArcherState.shooting) {
      final stringPullX = 65.0 - (bowDrawAmount * 35.0);

      canvas.drawLine(const Offset(65.0, 25.0), Offset(stringPullX, 35.0), stringPaint);
      canvas.drawLine(Offset(stringPullX, 35.0), const Offset(65.0, 45.0), stringPaint);
    } else {
      canvas.drawLine(const Offset(65.0, 25.0), const Offset(65.0, 45.0), stringPaint);
    }

    canvas.drawCircle(Offset(leftHand.x, leftHand.y), 3.0, Paint()..color = Colors.pink.shade200);

    if (currentState == ArcherState.aiming || currentState == ArcherState.shooting) {
      final stringPullX = 65.0 - (bowDrawAmount * 35.0);
      canvas.drawCircle(Offset(stringPullX, 35.0), 3.0, Paint()..color = Colors.pink.shade200);
    } else {
      canvas.drawCircle(Offset(rightHand.x, rightHand.y), 3.0, Paint()..color = Colors.pink.shade200);
    }
  }

  void _drawBackQuiver(Canvas canvas) {
    final quiverRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 40, 12, 25),
      const Radius.circular(2),
    );

    canvas.drawRRect(quiverRect, Paint()..color = Colors.brown.shade800);
    canvas.drawRRect(
      quiverRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawLine(
      const Offset(27, 40),
      const Offset(30, 32),
      Paint()
        ..color = Colors.brown.shade600
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(35, 40),
      const Offset(32, 32),
      Paint()
        ..color = Colors.brown.shade600
        ..strokeWidth = 2,
    );

    for (int i = 0; i < 4; i++) {
      final arrowX = 27 + (i * 2.5);
      const arrowY = 45.0;

      canvas.drawLine(
        Offset(arrowX, arrowY),
        Offset(arrowX, arrowY + 15),
        Paint()
          ..color = Colors.brown.shade600
          ..strokeWidth = 1,
      );

      canvas.drawCircle(Offset(arrowX, arrowY), 0.8, Paint()..color = Colors.grey.shade600);

      canvas.drawLine(
        Offset(arrowX - 0.5, arrowY + 13),
        Offset(arrowX + 0.5, arrowY + 13),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 0.5,
      );
    }
  }

  void _drawArrowInHand(Canvas canvas, Vector2 handPos) {
    final arrowLength = 25 + (bowDrawAmount * 12);
    const bowStringCenterX = 65.0;
    const bowStringCenterY = 35.0;
    final arrowStartX = bowStringCenterX - (bowDrawAmount * 35.0);

    canvas.drawLine(
      Offset(arrowStartX, bowStringCenterY),
      Offset(arrowStartX + arrowLength, bowStringCenterY),
      Paint()
        ..color = Colors.brown.shade600
        ..strokeWidth = 2.5,
    );

    const tipLength = 8.0;
    const tipWidth = 4.0;
    final tipX = arrowStartX + arrowLength;

    final tipPath = Path();
    tipPath.moveTo(tipX + tipLength, bowStringCenterY);
    tipPath.lineTo(tipX, bowStringCenterY - tipWidth);
    tipPath.lineTo(tipX, bowStringCenterY + tipWidth);
    tipPath.close();

    canvas.drawPath(tipPath, Paint()..color = Colors.grey.shade600..style = PaintingStyle.fill);
    canvas.drawPath(
      tipPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final featherWave = math.sin(animationTimer * 6.0) * 0.6;
    final featherX = arrowStartX + 5.0;

    canvas.drawLine(
      Offset(featherX, bowStringCenterY - 2.0 + featherWave),
      Offset(featherX + 6.0, bowStringCenterY + 0.5 + featherWave * 0.5),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );

    canvas.drawLine(
      Offset(featherX, bowStringCenterY + 2.0 - featherWave),
      Offset(featherX + 6.0, bowStringCenterY - 0.5 - featherWave * 0.5),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );

    canvas.drawLine(
      Offset(featherX + 2.0, bowStringCenterY),
      Offset(featherX + 8.0, bowStringCenterY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );
  }
}

class AimingSystem extends Component {
  bool isVisible = false;
  Vector2? startPoint;
  Vector2? endPoint;

  late Paint linePaint;
  late Paint powerBarPaint;
  late Paint powerBarBgPaint;

  @override
  Future<void> onLoad() async {
    linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0;
    powerBarPaint = Paint()..color = Colors.orange;
    powerBarBgPaint = Paint()..color = Colors.grey.withOpacity(0.5);
  }

  void startAiming(Vector2 start) {
    isVisible = true;
    startPoint = start.clone();
  }

  void updateAiming(Vector2 start, Vector2 current) {
    startPoint = start.clone();
    endPoint = current.clone();
  }

  void stopAiming() {
    isVisible = false;
    startPoint = null;
    endPoint = null;
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || startPoint == null || endPoint == null) return;

    canvas.drawLine(
      Offset(startPoint!.x, startPoint!.y),
      Offset(endPoint!.x, endPoint!.y),
      linePaint,
    );

    final pullDistance = (startPoint! - endPoint!).length;
    final power = math.min(pullDistance / 60, 8.0);
    final powerPercent = (power / 8.0 * 100).round();

    canvas.drawRect(const Rect.fromLTWH(20, 30, 200, 25), powerBarBgPaint);

    final powerWidth = (powerPercent / 100) * 200;
    canvas.drawRect(Rect.fromLTWH(20, 30, powerWidth, 25), powerBarPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Power: $powerPercent%',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 5));
  }
}

class Arrow extends PositionComponent {
  Vector2 velocity;
  final double gravity = 300.0;
  final ArcheryGame gameRef;
  final int shotId;
  bool stuck = false;
  double stuckAngle = 0.0;

  Bird? attachedBird;
  Vector2 attachedOffset = Vector2.zero();
  bool _reportedMiss = false;

  Arrow({
    required Vector2 startPos,
    required Vector2 direction,
    required double power,
    required this.gameRef,
    required this.shotId,
  }) : velocity = direction * (power * 250) {
    position = startPos.clone();
    size = Vector2(30, 3);
  }

  void attachToBird(Bird bird) {
    // if (attachedBird != null) return; // Bu satırı sil
    attachedBird = bird;
    stuck = true;
    stuckAngle = angle;
    attachedOffset = position - bird.position;
    velocity = Vector2.zero();
    angle = stuckAngle;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      const Offset(-15.0, 0.0),
      const Offset(15.0, 0.0),
      Paint()
        ..color = Colors.brown.shade600
        ..strokeWidth = 2.5,
    );

    const tipLength = 10.0;
    const tipWidth = 4.0;

    final tipPath = Path();
    tipPath.moveTo(15.0 + tipLength, 0.0);
    tipPath.lineTo(15.0, -tipWidth);
    tipPath.lineTo(15.0, tipWidth);
    tipPath.close();

    canvas.drawPath(tipPath, Paint()..color = Colors.grey.shade600..style = PaintingStyle.fill);
    canvas.drawPath(tipPath, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.0);

    canvas.drawLine(
      const Offset(-12.0, -2.0),
      const Offset(-6.0, -1.0),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      const Offset(-12.0, 2.0),
      const Offset(-6.0, 1.0),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      const Offset(-10.0, 0.0),
      const Offset(-4.0, 0.0),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5,
    );

    for (int i = 0; i < 6; i++) {
      final x = -10.0 + (i * 4.0);
      canvas.drawLine(
        Offset(x, -0.5),
        Offset(x + 2.0, 0.5),
        Paint()
          ..color = Colors.brown.shade800
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  void update(double dt) {
    if (attachedBird != null) {
      position = attachedBird!.position + attachedOffset;
      angle = stuckAngle;
      return;
    }

    if (stuck) return;

    velocity.y += gravity * dt;
    velocity.scale(0.998);

    position.add(velocity * dt);

    if (velocity.length > 50) {
      angle = math.atan2(velocity.y, velocity.x);
    }

    _checkCollisions();

    if (position.y > gameRef.size.y || position.x > gameRef.size.x + 200 || position.x < -200) {
      if (!_reportedMiss) {
        gameRef.onArrowMissed();
        _reportedMiss = true;
      }
      removeFromParent();
    }
  }

  void _checkCollisions() {
    // Eğer ok zaten bir kuşa saplanmışsa çarpışma kontrolü yapma
    if (attachedBird != null) return;

    final tipOffset = Vector2(15.0, 0.0)..rotate(angle);
    final arrowTip = position + tipOffset;

    for (final bird in gameRef.birds) {
      if (bird.hasLanded) continue;

      final birdCenter = bird.position + bird.size / 2;
      final double hitRadius = math.min(bird.size.x, bird.size.y) * 0.45 + 6.0;
      final double distance = (arrowTip - birdCenter).length;

      if (distance <= hitRadius) {
        final bool isHeadShot = (arrowTip.y < birdCenter.y - bird.size.y * 0.2);

        if (!gameRef.isInfiniteMode && gameRef.levelData!.headShotsOnly && !isHeadShot) {
          if (!_reportedMiss) {
            gameRef.onArrowMissed();
            _reportedMiss = true;
          }
          removeFromParent();
          return;
        }

        bird.onHitByArrow(this, isHeadShot);
        return; // Bir kuşa vurduktan sonra döngüden çık
      }
    }

    if (position.y >= gameRef.ground.position.y - 10) {
      _stickToGround();
      if (!_reportedMiss) {
        gameRef.onArrowMissed();
        _reportedMiss = true;
      }
    }
  }

  void _stickToGround() {
    stuck = true;
    final double finalAngle = angle * 0.7;
    stuckAngle = finalAngle.clamp(0.1, math.pi * 0.4);
    angle = stuckAngle;
    velocity = Vector2.zero();
    position.y = gameRef.ground.position.y - 10;
  }
}
class BackgroundEffects extends Component with HasGameRef<ArcheryGame> {
  final String theme;
  late List<BackgroundParticle> particles;
  double timer = 0.0;

  BackgroundEffects({required this.theme});

  @override
  Future<void> onLoad() async {
    particles = [];
    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();

    switch (theme) {
      case 'spring':
      // Çiçek yaprakları havada uçuyor
        for (int i = 0; i < 15; i++) {
          particles.add(BackgroundParticle(
            position: Vector2(
              random.nextDouble() * gameRef.size.x,
              random.nextDouble() * gameRef.size.y * 0.6,
            ),
            velocity: Vector2(-20 - random.nextDouble() * 30, -10 + random.nextDouble() * 20),
            color: [Colors.pink, Colors.white, Colors.yellow][random.nextInt(3)].withOpacity(0.7),
            size: 2 + random.nextDouble() * 3,
            type: 'petal',
          ));
        }
        break;

      case 'desert':
      // Kum rüzgarı
        for (int i = 0; i < 25; i++) {
          particles.add(BackgroundParticle(
            position: Vector2(
              random.nextDouble() * gameRef.size.x,
              gameRef.size.y * 0.3 + random.nextDouble() * gameRef.size.y * 0.4,
            ),
            velocity: Vector2(40 + random.nextDouble() * 60, -5 + random.nextDouble() * 10),
            color: const Color(0xFFDAA520).withOpacity(0.4 + random.nextDouble() * 0.3),
            size: 1 + random.nextDouble() * 2,
            type: 'sand',
          ));
        }
        break;

      case 'ice':
      // Kar yağışı
        for (int i = 0; i < 30; i++) {
          particles.add(BackgroundParticle(
            position: Vector2(
              random.nextDouble() * gameRef.size.x,
              -random.nextDouble() * 100,
            ),
            velocity: Vector2(-10 + random.nextDouble() * 20, 50 + random.nextDouble() * 100),
            color: Colors.white.withOpacity(0.6 + random.nextDouble() * 0.4),
            size: 1 + random.nextDouble() * 3,
            type: 'snow',
          ));
        }
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    timer += dt;

    final random = math.Random();

    // Partikülleri güncelle
    for (final particle in particles) {
      particle.update(dt);

      // Ekrandan çıkanları yeniden spawn et
      if (particle.position.x < -50 || particle.position.x > gameRef.size.x + 50 ||
          particle.position.y > gameRef.size.y + 50) {

        switch (theme) {
          case 'spring':
            particle.position = Vector2(
              gameRef.size.x + random.nextDouble() * 100,
              random.nextDouble() * gameRef.size.y * 0.6,
            );
            break;
          case 'desert':
            particle.position = Vector2(
              -random.nextDouble() * 100,
              gameRef.size.y * 0.3 + random.nextDouble() * gameRef.size.y * 0.4,
            );
            break;
          case 'ice':
            particle.position = Vector2(
              random.nextDouble() * gameRef.size.x,
              -random.nextDouble() * 100,
            );
            break;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in particles) {
      particle.render(canvas);
    }
  }
}

// Arka plan partikül sınıfı
class BackgroundParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  String type;
  double rotation = 0.0;
  double rotationSpeed;

  BackgroundParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.type,
  }) : rotationSpeed = (-1 + math.Random().nextDouble() * 2) * 2;

  void update(double dt) {
    position += velocity * dt;
    rotation += rotationSpeed * dt;
  }

  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    final paint = Paint()..color = color;

    switch (type) {
      case 'petal':
      // Çiçek yaprağı şekli
        final path = Path();
        path.moveTo(0, -size);
        path.quadraticBezierTo(size * 0.7, -size * 0.5, 0, 0);
        path.quadraticBezierTo(-size * 0.7, -size * 0.5, 0, -size);
        canvas.drawPath(path, paint);
        break;

      case 'sand':
      // Kum tanecikleri
        canvas.drawCircle(Offset.zero, size, paint);
        break;

      case 'snow':
      // Kar tanesi
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;

        // Altı kollu kar tanesi
        for (int i = 0; i < 6; i++) {
          final angle = (i / 6) * 2 * math.pi;
          final endX = math.cos(angle) * size;
          final endY = math.sin(angle) * size;
          canvas.drawLine(Offset.zero, Offset(endX, endY), paint);

          // Küçük dallar
          final branchX = endX * 0.6;
          final branchY = endY * 0.6;
          canvas.drawLine(
            Offset(branchX, branchY),
            Offset(branchX + math.cos(angle + 0.5) * size * 0.3,
                branchY + math.sin(angle + 0.5) * size * 0.3),
            paint,
          );
          canvas.drawLine(
            Offset(branchX, branchY),
            Offset(branchX + math.cos(angle - 0.5) * size * 0.3,
                branchY + math.sin(angle - 0.5) * size * 0.3),
            paint,
          );
        }
        break;
    }

    canvas.restore();
  }
}

// Ground sınıfını tema destekli hale getiriyoruz
class Ground extends RectangleComponent {
  final String? theme;

  Ground(double y, {this.theme}) {
    position = Vector2(0, y);
    size = Vector2(1500, 150);
    _setupThemePaint();
  }

  void _setupThemePaint() {
    switch (theme) {
      case 'spring':
        paint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 150),
            [
              const Color(0xFF98FB98), // Açık yeşil
              const Color(0xFF228B22), // Orman yeşili
              const Color(0xFF006400), // Koyu yeşil
            ],
            [0.0, 0.6, 1.0],
          );
        break;

      case 'desert':
        paint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 150),
            [
              const Color(0xFFF4A460), // Kum rengi
              const Color(0xFFCD853F), // Peru
              const Color(0xFF8B4513), // Koyu kahverengi
            ],
            [0.0, 0.5, 1.0],
          );
        break;

      case 'ice':
        paint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 150),
            [
              const Color(0xFFE0FFFF), // Açık buz mavisi
              const Color(0xFF87CEEB), // Gökyüzü mavisi
              const Color(0xFF4682B4), // Çelik mavisi
            ],
            [0.0, 0.5, 1.0],
          );
        break;

      default:
        paint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 150),
            [Colors.green.shade300, Colors.green.shade700],
          );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Tema özel efektleri
    switch (theme) {
      case 'spring':
        _renderSpringDetails(canvas);
        break;
      case 'desert':
        _renderDesertDetails(canvas);
        break;
      case 'ice':
        _renderIceDetails(canvas);
        break;
    }
  }

  void _renderSpringDetails(Canvas canvas) {
    final paint = Paint();
    final random = math.Random(42); // Sabit seed için

    // Çiçekler
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 40 + 10;

      // Çiçek sapı
      paint.color = const Color(0xFF228B22);
      paint.strokeWidth = 2;
      canvas.drawLine(
        Offset(x, y + 8),
        Offset(x, y + 20),
        paint,
      );

      // Çiçek taçyaprakları
      final colors = [Colors.red, Colors.yellow, Colors.pink, Colors.purple];
      paint.color = colors[i % colors.length];
      paint.style = PaintingStyle.fill;

      for (int j = 0; j < 5; j++) {
        final angle = (j / 5) * 2 * math.pi;
        final petalX = x + math.cos(angle) * 4;
        final petalY = y + math.sin(angle) * 4;
        canvas.drawCircle(Offset(petalX, petalY), 2.5, paint);
      }

      // Çiçek merkezi
      paint.color = Colors.yellow;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }

    // Çimen detayları
    paint.color = const Color(0xFF90EE90);
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 20 + 5;
      final height = 8 + random.nextDouble() * 12;

      canvas.drawLine(
        Offset(x, y + height),
        Offset(x + random.nextDouble() * 4 - 2, y),
        paint,
      );
    }
  }

  void _renderDesertDetails(Canvas canvas) {
    final paint = Paint();
    final random = math.Random(42);

    // Kum tepecikleri
    paint.color = const Color(0xFFDEB887).withOpacity(0.6);
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 30 + 20;
      final width = 40 + random.nextDouble() * 60;
      final height = 15 + random.nextDouble() * 20;

      final path = Path();
      path.moveTo(x - width/2, y + height);
      path.quadraticBezierTo(x, y, x + width/2, y + height);
      canvas.drawPath(path, paint);
    }

    // Kaktüsler
    for (int i = 0; i < 6; i++) {
      final x = 100 + i * 200 + random.nextDouble() * 50;
      final y = 20 + random.nextDouble() * 40;

      // Ana gövde
      paint.color = const Color(0xFF228B22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 4, y, 8, 40),
          const Radius.circular(4),
        ),
        paint,
      );

      // Yan dallar
      if (i % 2 == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 15, y + 10, 12, 6),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 4, y + 15, 12, 6),
            const Radius.circular(3),
          ),
          paint,
        );
      }

      // Dikenler
      paint.color = Colors.white;
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.stroke;

      for (int j = 0; j < 8; j++) {
        final spikeX = x + (j % 2 == 0 ? -2 : 2);
        final spikeY = y + j * 5;
        canvas.drawLine(
          Offset(spikeX, spikeY),
          Offset(spikeX + (j % 2 == 0 ? -3 : 3), spikeY - 2),
          paint,
        );
      }
    }

    // Kum tanecikleri efekti
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFDAA520).withOpacity(0.3);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 60;
      canvas.drawCircle(Offset(x, y), 1 + random.nextDouble(), paint);
    }
  }

  void _renderIceDetails(Canvas canvas) {
    final paint = Paint();
    final random = math.Random(42);

    // Buz kristalleri
    paint.color = Colors.white.withOpacity(0.8);
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 40 + 10;
      final crystalSize = 3 + random.nextDouble() * 5;

      // Altıgen buz kristali
      final path = Path();
      for (int j = 0; j < 6; j++) {
        final angle = (j / 6) * 2 * math.pi;
        final pointX = x + math.cos(angle) * crystalSize;
        final pointY = y + math.sin(angle) * crystalSize;

        if (j == 0) {
          path.moveTo(pointX, pointY);
        } else {
          path.lineTo(pointX, pointY);
        }
      }
      path.close();
      canvas.drawPath(path, paint);

      // Kristal parlama efekti
      paint.color = Colors.cyan.withOpacity(0.6);
      canvas.drawCircle(Offset(x, y), crystalSize * 0.3, paint);
      paint.color = Colors.white.withOpacity(0.8);
    }


    // Buz sarkıtları
    paint.color = const Color(0xFFE0FFFF).withOpacity(0.9);

    for (int i = 0; i < 12; i++) {
      final x = 150 + i * 100 + random.nextDouble() * 50;
      final height = 15 + random.nextDouble() * 25;

      final path = Path();
      path.moveTo(x - 3, 0);
      path.lineTo(x + 3, 0);
      path.lineTo(x, height);
      path.close();

      canvas.drawPath(path, paint);

      // Buz parlaması
      paint.color = Colors.white.withOpacity(0.4);
      canvas.drawLine(
        Offset(x - 1, height * 0.3),
        Offset(x + 1, height * 0.7),
        paint,
      );
      paint.color = const Color(0xFFE0FFFF).withOpacity(0.9);
    }

    // Kar tanecikleri
    paint.color = Colors.white.withOpacity(0.6);
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * 80;
      canvas.drawCircle(Offset(x, y), 0.5 + random.nextDouble(), paint);
    }
  }
}

// Background sınıfını oluşturuyoruz
class ThemeBackground extends Component {
  final String theme;
  double animationTimer = 0.0;
  late Paint skyPaint;

  ThemeBackground({required this.theme});

  @override
  Future<void> onLoad() async {
    _setupSkyGradient();
  }

  void _setupSkyGradient() {
    switch (theme) {
      case 'spring':
        skyPaint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 600),
            [
              const Color(0xFF87CEEB), // Sky blue
              const Color(0xFFE0F6FF), // Light blue
              const Color(0xFFF0FFF0), // Honeydew
            ],
            [0.0, 0.6, 1.0],
          );
        break;

      case 'desert':
        skyPaint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 600),
            [
              const Color(0xFFFFE4B5), // Moccasin
              const Color(0xFFFFA500), // Orange
              const Color(0xFFFF8C00), // Dark orange
            ],
            [0.0, 0.5, 1.0],
          );
        break;

      case 'ice':
        skyPaint = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            const Offset(0, 600),
            [
              const Color(0xFFB0E0E6), // Powder blue
              const Color(0xFF87CEFA), // Light sky blue
              const Color(0xFFE6F3FF), // Alice blue
            ],
            [0.0, 0.4, 1.0],
          );
        break;

      default:
        skyPaint = Paint()..color = const Color(0xFF87CEEB);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    animationTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final gameRef = parent as ArcheryGame;

    // Gökyüzü arka planı
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      skyPaint,
    );

    // Tema özel arka plan öğeleri
    switch (theme) {
      case 'spring':
        _renderSpringBackground(canvas, gameRef.size);
        break;
      case 'desert':
        _renderDesertBackground(canvas, gameRef.size);
        break;
      case 'ice':
        _renderIceBackground(canvas, gameRef.size);
        break;
    }
  }

  void _renderSpringBackground(Canvas canvas, Vector2 screenSize) {
    // Bulutlar
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);

    for (int i = 0; i < 4; i++) {
      final cloudX = (screenSize.x * 0.2 * i) +
          (math.sin(animationTimer * 0.1 + i) * 20);
      final cloudY = 60 + (math.sin(animationTimer * 0.05 + i * 2) * 15);

      // Bulut şekli
      canvas.drawCircle(Offset(cloudX, cloudY), 15, cloudPaint);
      canvas.drawCircle(Offset(cloudX + 10, cloudY), 20, cloudPaint);
      canvas.drawCircle(Offset(cloudX + 25, cloudY), 15, cloudPaint);
      canvas.drawCircle(Offset(cloudX + 15, cloudY - 8), 12, cloudPaint);
    }

    // Arka planda ağaçlar
    final treeTrunkPaint = Paint()..color = Colors.brown.shade600;
    final treeLeavePaint = Paint()..color = Colors.green.shade400;

    for (int i = 1; i < 6; i++) {
      final treeX = screenSize.x * 0.15 * i + 50;
      final treeY = screenSize.y * 0.4;
      final treeHeight = 80.0 + (i * 10.0);
      final treeWave = math.sin(animationTimer * 0.8 + i) * 3;

      // Ağaç gövdesi
      canvas.drawRect(
        Rect.fromLTWH(treeX - 3 + treeWave, treeY, 6, treeHeight),
        treeTrunkPaint,
      );

      // Yapraklar
      canvas.drawCircle(
        Offset(treeX + treeWave, treeY - 10),
        25,
        treeLeavePaint,
      );
    }
  }

  void _renderDesertBackground(Canvas canvas, Vector2 screenSize) {
    // Güneş
    final sunPaint = Paint()..color = Colors.yellow.shade600;
    final sunGlowPaint = Paint()
      ..color = Colors.orange.shade300.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    const sunX = 80.0;
    const sunY = 80.0;

    canvas.drawCircle(const Offset(sunX, sunY), 30, sunGlowPaint);
    canvas.drawCircle(const Offset(sunX, sunY), 20, sunPaint);

    // Sıcaklık dalgaları (heat haze)
    final hazePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    for (int i = 0; i < screenSize.x.toInt(); i += 30) {
      final waveOffset = math.sin(animationTimer * 3 + i * 0.02) * 10;
      final startY = screenSize.y * 0.6;

      canvas.drawLine(
        Offset(i.toDouble(), startY + waveOffset),
        Offset(i.toDouble(), startY + waveOffset + 20),
        hazePaint,
      );
    }

    // Arka planda tepeler
    final hillPaint = Paint()..color = Colors.orange.shade400.withOpacity(0.7);

    final hillPath = Path();
    hillPath.moveTo(0, screenSize.y * 0.5);

    for (int i = 0; i <= screenSize.x.toInt(); i += 50) {
      final hillHeight = screenSize.y * 0.3 +
          math.sin(i * 0.01) * 30 +
          math.sin(i * 0.02 + 1) * 20;
      hillPath.lineTo(i.toDouble(), hillHeight);
    }

    hillPath.lineTo(screenSize.x, screenSize.y);
    hillPath.lineTo(0, screenSize.y);
    hillPath.close();

    canvas.drawPath(hillPath, hillPaint);
  }

  void _renderIceBackground(Canvas canvas, Vector2 screenSize) {
    // Kar taneleri
    final snowPaint = Paint()..color = Colors.white.withOpacity(0.8);

    for (int i = 0; i < 20; i++) {
      final snowX = (i * screenSize.x / 20) +
          (math.sin(animationTimer + i) * 30);
      final snowY = (animationTimer * 30 + i * 20) % screenSize.y;

      canvas.drawCircle(Offset(snowX, snowY), 2, snowPaint);
    }

    // Buzdağları (background mountains)
    final iceMountainPaint = Paint()
      ..color = Colors.lightBlue.shade200.withOpacity(0.6);

    // Sol buzdağı
    final leftMountainPath = Path();
    leftMountainPath.moveTo(screenSize.x * 0.1, screenSize.y * 0.6);
    leftMountainPath.lineTo(screenSize.x * 0.25, screenSize.y * 0.2);
    leftMountainPath.lineTo(screenSize.x * 0.4, screenSize.y * 0.6);
    leftMountainPath.close();

    canvas.drawPath(leftMountainPath, iceMountainPaint);

    // Sağ buzdağı
    final rightMountainPath = Path();
    rightMountainPath.moveTo(screenSize.x * 0.6, screenSize.y * 0.6);
    rightMountainPath.lineTo(screenSize.x * 0.75, screenSize.y * 0.15);
    rightMountainPath.lineTo(screenSize.x * 0.9, screenSize.y * 0.6);
    rightMountainPath.close();

    canvas.drawPath(rightMountainPath, iceMountainPaint);

    // Buzul çatlakları
    final crackPaint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final crackX = screenSize.x * (0.2 + 0.15 * i);
      final crackStartY = screenSize.y * 0.3;
      final crackEndY = crackStartY + 40 + math.sin(i.toDouble()) * 20;

      canvas.drawLine(
        Offset(crackX, crackStartY),
        Offset(crackX + 10, crackEndY),
        crackPaint,
      );
    }

    // Aurora (Northern Lights) efekti
    final auroraPaint = Paint()
      ..color = Colors.green.shade300.withOpacity(0.2)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final auroraPath = Path();
    auroraPath.moveTo(0, screenSize.y * 0.2);

    for (int i = 0; i <= screenSize.x.toInt(); i += 20) {
      final waveY = screenSize.y * 0.2 +
          math.sin(i * 0.02 + animationTimer * 0.5) * 15;
      auroraPath.lineTo(i.toDouble(), waveY);
    }

    canvas.drawPath(auroraPath, auroraPaint);
  }
}
class Bird extends PositionComponent with HasGameRef<ArcheryGame> {
  Vector2 velocity = Vector2.zero();
  bool isFalling = false;
  bool isAlive = true;
  bool hasLanded = false;
  final double gravity = 600.0;

  double animTime = 0.0;

  double flapSpeed = 12.0;
  double flapAmplitude = 0.95;
  final double deadWingDroop = 0.8;

  late double flightSpeedX;
  late double flightAmplitude;
  late double flightFrequency;
  late double flightPhase;
  late double baseY;
  int flightDirection = -1;

  bool bloodSplash = false;
  double bloodTimer = 0.0;
  double bloodPuddleRadius = 0.0;
  double bloodPuddleTargetRadius = 0.0;
  Vector2 lastHitDir = Vector2.zero();

  int? killedByShotId;

  @override
  Future<void> onLoad() async {
    size = Vector2(26, 18);

    final rnd = math.Random();
    flightDirection = rnd.nextBool() ? -1 : 1;
    flightSpeedX = 80 + rnd.nextDouble() * 50;
    flightAmplitude = 8 + rnd.nextDouble() * 8;
    flightFrequency = 1.6 + rnd.nextDouble() * 0.8;
    flightPhase = rnd.nextDouble() * math.pi * 2;
    baseY = position.y;
  }

  void onHitByArrow(Arrow arrow, bool isHeadShot) {
    // Eğer kuş zaten ölüyse, sadece fizik etkisi uygula
    bool wasAlreadyDead = !isAlive;

    if (isAlive) {
      isAlive = false;
      isFalling = true;

      // Sadece ilk vuruşta skor ver
      killedByShotId = arrow.shotId;

      (gameRef as ArcheryGame).onBirdKilled(
        isHeadShot: isHeadShot,
        shotId: killedByShotId,
        at: position + size / 2,
      );
    }

    // Ok hızına bağlı momentum hesaplama
    final Vector2 impulse = arrow.velocity.clone();
    final double arrowSpeed = impulse.length;

    // Hıza göre etki kuvveti ayarla (daha hızlı ok = daha fazla etki)
    double impulseScale = 0.02 + (arrowSpeed / 1000.0) * 0.06; // 0.02-0.08 arası
    impulseScale = impulseScale.clamp(0.02, 0.12);

    velocity.add(impulse * impulseScale);

    // Kan efekti (her vuruşta)
    bloodSplash = true;
    bloodTimer = 0.0;
    lastHitDir = impulse.length > 0 ? impulse.normalized() : Vector2(1, 0);

    _accumulateBloodFromHit(impulse);

    // Oku kuşa sapla
    arrow.attachToBird(this);

    // Titreşim efekti (daha güçlü momentum için daha fazla titreşim)
    final double shakeAmount = 4.0 + (arrowSpeed / 500.0) * 4.0; // 4-8 piksel arası
    add(MoveEffect.by(
      Vector2(shakeAmount, 0),
      EffectController(duration: 0.06, reverseDuration: 0.06),
    ));
  }

  void _accumulateBloodFromHit(Vector2 impulse) {
    final double mag = impulse.length;
    final double baseInc = math.max(2.5, size.x * 0.22);

    // Hıza göre kan artışı - daha hızlı oklar daha fazla kan
    final double speedFactor = (mag / 600.0).clamp(0.5, 3.0);
    final double scaled = speedFactor * 4.0;

    final double inc = baseInc + scaled;
    final double maxRadius = size.x * 3.5; // Maksimum kan havuzu boyutu
    bloodPuddleTargetRadius = math.min(maxRadius, bloodPuddleTargetRadius + inc);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (bloodSplash) {
      bloodTimer += dt;
      if (bloodTimer > 0.35) bloodSplash = false;
    }

    if (hasLanded) {
      final double growSpeed = 40.0 * dt;
      bloodPuddleRadius = math.min(bloodPuddleTargetRadius, bloodPuddleRadius + growSpeed);
      return;
    }

    if (!isFalling) {
      if (isAlive) {
        animTime += dt;

        position.x += flightDirection * flightSpeedX * dt;
        final double oscillation = math.sin((animTime * 2 * math.pi * flightFrequency) + flightPhase) * flightAmplitude;
        position.y = baseY + oscillation;

        final double leftMargin = -size.x * 0.5;
        final double rightMargin = (gameRef as ArcheryGame).size.x + size.x * 0.5;

        if (flightDirection < 0 && position.x < leftMargin) {
          position.x = rightMargin;
        } else if (flightDirection > 0 && position.x > rightMargin) {
          position.x = leftMargin;
        }

        final double topLimit = 60.0;
        final double bottomLimit = (gameRef as ArcheryGame).ground.position.y - 180.0;

        if (position.y < topLimit) {
          position.y = topLimit;
          baseY = position.y;
        } else if (position.y > bottomLimit) {
          position.y = bottomLimit;
          baseY = position.y;
        }
      }
      return;
    }

    velocity.y += gravity * dt;
    position += velocity * dt;

    if (!hasLanded && velocity.length2 > 400) {
      final Vector2 myCenter = position + size / 2;
      for (final Bird other in (gameRef as ArcheryGame).birds) {
        if (identical(other, this)) continue;
        if (!other.isAlive || other.isFalling || other.hasLanded) continue;

        final Vector2 otherCenter = other.position + other.size / 2;
        final double rThis = math.min(size.x, size.y) * 0.45;
        final double rOther = math.min(other.size.x, other.size.y) * 0.45;
        if ((myCenter - otherCenter).length <= (rThis + rOther)) {
          other.onAirCollisionFrom(velocity.clone(), killedByShotId);
        }
      }
    }

    final double groundY = (gameRef as ArcheryGame).ground.position.y - size.y;
    if (position.y >= groundY) {
      position.y = groundY;
      velocity = Vector2.zero();
      isFalling = false;
      hasLanded = true;

      if (bloodPuddleTargetRadius <= 0) {
        bloodPuddleTargetRadius = math.max(4.0, size.x * 0.22);
      }
      bloodPuddleRadius = math.min(bloodPuddleTargetRadius, bloodPuddleRadius + 6.0);
    }
  }

  void onAirCollisionFrom(Vector2 incomingVelocity, int? killerShotId) {
    if (!isAlive && isFalling) return;

    isAlive = false;
    isFalling = true;
    killedByShotId = killerShotId;

    velocity = incomingVelocity * 0.85;
    velocity.y = math.max(velocity.y, 80.0);

    bloodSplash = true;
    bloodTimer = 0.0;
    lastHitDir = incomingVelocity.length > 0 ? incomingVelocity.normalized() : Vector2(1, 0);
    _accumulateBloodFromHit(incomingVelocity * 0.6);

    (gameRef as ArcheryGame).onBirdKilled(
      isHeadShot: false,
      shotId: killedByShotId,
      at: position + size / 2,
    );

    add(MoveEffect.by(
      Vector2(4, 0),
      EffectController(duration: 0.06, reverseDuration: 0.06),
    ));
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final center = Offset(w / 2, h / 2);

    if (hasLanded && bloodPuddleRadius > 0) {
      final puddleCenter = Offset(w * 0.48, h - 1);
      final Rect puddleRect = Rect.fromCenter(
        center: puddleCenter,
        width: bloodPuddleRadius * 2.1,
        height: bloodPuddleRadius * 0.9,
      );
      canvas.drawOval(puddleRect, Paint()..color = const Color(0xFF8B0000).withOpacity(0.75));
      canvas.drawOval(
        puddleRect.deflate(0.6),
        Paint()
          ..color = const Color(0xFF3D0000).withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final bodyWidth = w;
    final bodyHeight = h * 0.62;
    final bodyCenter = Offset(center.dx - w * 0.10, center.dy + h * 0.02);
    final neckPos = Offset(bodyCenter.dx + bodyWidth * 0.32, bodyCenter.dy - bodyHeight * 0.10);
    final headRadius = h * 0.16;
    final beakLen = h * 0.22;

    final double liveWingAngle = math.sin(animTime * flapSpeed) * flapAmplitude;
    final double wingAngle = isAlive ? liveWingAngle : deadWingDroop;

    final fillBlack = Paint()..color = Colors.black;
    final darkGrey = Paint()..color = Colors.grey.shade800;

    canvas.drawOval(
      Rect.fromCenter(center: bodyCenter, width: bodyWidth, height: bodyHeight),
      fillBlack,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(neckPos.dx - w * 0.02, neckPos.dy + h * 0.02),
        width: w * 0.20,
        height: h * 0.22,
      ),
      fillBlack,
    );

    final headCenter = Offset(neckPos.dx + w * 0.05, neckPos.dy - h * 0.04);
    canvas.drawCircle(headCenter, headRadius, fillBlack);

    final beakPath = Path()
      ..moveTo(headCenter.dx + headRadius, headCenter.dy)
      ..lineTo(headCenter.dx + headRadius + beakLen, headCenter.dy - h * 0.06)
      ..lineTo(headCenter.dx + headRadius + beakLen, headCenter.dy + h * 0.06)
      ..close();
    canvas.drawPath(beakPath, darkGrey);

    final eye = Offset(headCenter.dx + headRadius * 0.20, headCenter.dy - headRadius * 0.20);
    canvas.drawCircle(eye, 0.9, Paint()..color = Colors.white);
    canvas.drawCircle(eye, 0.5, Paint()..color = Colors.black);

    final tailBase = Offset(bodyCenter.dx - bodyWidth * 0.50, bodyCenter.dy + bodyHeight * 0.04);
    final tailPath = Path()
      ..moveTo(tailBase.dx, tailBase.dy)
      ..lineTo(tailBase.dx - w * 0.18, tailBase.dy - h * 0.10)
      ..lineTo(tailBase.dx - w * 0.10, tailBase.dy + h * 0.12)
      ..close();
    canvas.drawPath(tailPath, fillBlack);

    final leftShoulder = Offset(bodyCenter.dx - bodyWidth * 0.06, bodyCenter.dy - bodyHeight * 0.18);
    final rightShoulder = Offset(bodyCenter.dx + bodyWidth * 0.10, bodyCenter.dy - bodyHeight * 0.12);

    _drawWing(
      canvas: canvas,
      shoulder: rightShoulder,
      length: w * 0.52,
      span: h * 0.66,
      angle: -wingAngle * 0.9,
      fill: fillBlack,
    );
    _drawWing(
      canvas: canvas,
      shoulder: leftShoulder,
      length: w * 0.50,
      span: h * 0.64,
      angle: wingAngle,
      fill: Paint()..color = Colors.black.withOpacity(0.92),
    );

    if (bloodSplash) {
      final double t = (1 - (bloodTimer / 0.35)).clamp(0.0, 1.0);
      final dropletsPaint = Paint()..color = const Color(0xFF8B0000).withOpacity(0.70 * t);
      final Offset c = bodyCenter;
      final Vector2 dir = (lastHitDir * -1).normalized();
      for (int i = 1; i <= 3; i++) {
        final double f = i.toDouble();
        final dx = c.dx + dir.x * (2.0 + 2.0 * f) + (-1 + i) * 0.8;
        final dy = c.dy + dir.y * (1.2 + 1.4 * f) + (i - 2) * 0.6;
        canvas.drawCircle(Offset(dx, dy), 0.8 + 0.2 * f, dropletsPaint);
      }
    }
  }

  void _drawWing({
    required Canvas canvas,
    required Offset shoulder,
    required double length,
    required double span,
    required double angle,
    required Paint fill,
  }) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.25, -span * 0.75, length, -span * 0.10)
      ..quadraticBezierTo(length * 0.65, span * 0.65, 0, 0)
      ..close();

    canvas.drawPath(path, fill);

    final featherPaint = Paint()
      ..color = Colors.grey.shade900
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final px = length * (0.22 + 0.7 * t);
      final py = -span * (0.55 - 0.5 * t);
      canvas.drawLine(
        Offset(px, py),
        Offset(px - length * 0.16, py + span * 0.22),
        featherPaint,
      );
    }

    canvas.restore();
  }
}

class InfiniteScoresScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    var hs = GamePreferences.infiniteHighScore;
    var mb = GamePreferences.infiniteMostBirds;
    var bc = GamePreferences.infiniteBestCombo;
    var bh = GamePreferences.infiniteBestHeadshots;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
          ),
        ),
        child: Container(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                // Kompakt başlık
                _buildHeader(context),

                SizedBox(height: 8),

                // Ana skor kartı - daha kompakt
                _buildMainScoreCard(hs),

                SizedBox(height: 10),

                // İstatistikler grid - daha küçük
                _buildStatsGrid(mb, bc, bh),

                SizedBox(height: 10),

                // Başarılar - tek satır
                _buildCompactAchievements(hs, mb, bc, bh),

                SizedBox(height: 8),

                // Motivasyon mesajı - daha küçük
                _buildMotivationCard(hs, mb, bc, bh),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 40,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'RANKINGS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 12),
                SizedBox(width: 3),
                Text(
                  'INFINITE',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard(int hs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIGH SCORE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  '$hs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('👑', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int mb, int bc, int bh) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactStatCard(
            icon: Icons.my_location,
            title: 'BIRDS HIT',
            value: '$mb',
            color: Colors.green,
            emoji: '🎯',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            icon: Icons.whatshot,
            title: 'COMBO',
            value: 'x$bc',
            color: Colors.deepOrange,
            emoji: '🔥',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            icon: Icons.gps_fixed,
            title: 'HEADSHOT',
            value: 'x$bh',
            color: Colors.red,
            emoji: '💀',
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String emoji,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                SizedBox(width: 2),
                Text(emoji, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAchievements(int hs, int mb, int bc, int bh) {
    final achievements = _getAchievements(hs, mb, bc, bh);
    final achievedCount = achievements.where((a) => a['achieved']).length;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'GOOD LUCK ($achievedCount/${achievements.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: achievements.map((achievement) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: achievement['achieved']
                      ? achievement['color'].withOpacity(0.2)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: achievement['achieved']
                        ? achievement['color'].withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievement['emoji'],
                      style: TextStyle(fontSize: 10),
                    ),
                    SizedBox(width: 2),
                    Text(
                      achievement['title'],
                      style: TextStyle(
                        color: achievement['achieved']
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(int hs, int mb, int bc, int bh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.white60, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getMotivationalMessage(hs, mb, bc, bh),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAchievements(int hs, int mb, int bc, int bh) {
    return [
      {
        'title': 'Avcı',
        'emoji': '🏹',
        'achieved': mb >= 10,
        'color': Colors.green,
      },
      {
        'title': 'Nişancı',
        'emoji': '🎯',
        'achieved': mb >= 50,
        'color': Colors.blue,
      },
      {
        'title': 'Combo',
        'emoji': '🔥',
        'achieved': bc >= 5,
        'color': Colors.orange,
      },

      {
        'title': 'Efsane',
        'emoji': '👑',
        'achieved': hs >= 10000,
        'color': Colors.amber,
      },
    ];
  }

  String _getMotivationalMessage(int hs, int mb, int bc, int bh) {
    if (hs >= 50000) {
      return "🔥 LEGENDARY! These records are untouchable!";
    } else if (hs >= 20000) {
      return "🎯 MASTER CLASS! You're dominating!";
    } else if (hs >= 10000) {
      return "⚡ EPIC RUN! You're crushing records!";
    } else if (hs >= 5000) {
      return "🏹 SOLID START! Keep grinding!";
    } else if (hs > 0) {
      return "🌟 EVERY PRO STARTS SOMEWHERE!";
    } else {
      return "🚀 READY FOR YOUR FIRST SHOT?";
    }
  }
}
// InfiniteGameUI sınıfını ekleyin (daha kompakt hali)
class InfiniteGameUI extends PositionComponent {
  final ArcheryGame gameRef;
  late TextComponent dynamicInfoText;

  InfiniteGameUI({required this.gameRef});

  @override
  Future<void> onLoad() async {
    position = Vector2(20, 20);

    dynamicInfoText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
    add(dynamicInfoText);
  }

  @override
  void update(double dt) {
    super.update(dt);

    List<String> infoList = [];

    // Ok bilgisi
    if (gameRef.infiniteArrowsLimit != null) {
      infoList.add('Arrow: ${gameRef.archer.arrowsLeft}/${gameRef.infiniteArrowsLimit}');
    } else {
      infoList.add('Arrow: ∞');
    }

    // Kuş bilgisi
    final aliveBirds = gameRef.birds.where((bird) => bird.isAlive).length;
    if (gameRef.infiniteBirdCount != null) {
      infoList.add('Bird: $aliveBirds/${gameRef.infiniteBirdCount}');
    } else {
      infoList.add('Bird: $aliveBirds (∞)');
    }

    // Süre bilgisi
    if (gameRef.infiniteTimeLimit != null) {
      final remainingTime = math.max(0, gameRef.infiniteTimeLimit! - gameRef.gameTime.toInt());
      infoList.add('Time: ${remainingTime}s');

      if (remainingTime <= 10 && remainingTime > 0) {
        dynamicInfoText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        );
      } else {
        dynamicInfoText.textRenderer = TextPaint(
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        );
      }
    } else {
      infoList.add('Time: ∞');
    }

    dynamicInfoText.text = infoList.join('  |  ');
  }
}
// “Nasıl Oynanır”
class HowToPlayScreen extends StatelessWidget {
  // HowToPlayScreen sınıfının build metodunu güncelle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎮 How To Play',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4682B4),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF4682B4)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Temel Kontroller
              _buildSection(
                icon: '🎯',
                title: 'Basic Controls',
                color: Colors.green,
                children: [
                  _buildInfoRow('👆', 'Tap and drag to aim'),
                  _buildInfoRow('🏹', 'Release to shoot arrow'),
                  _buildInfoRow('💪', 'Longer pull = stronger shot'),
                ],
              ),

              SizedBox(height: 16),

              // Puanlama Sistemi
              _buildSection(
                icon: '🏆',
                title: 'Scoring System',
                color: Colors.orange,
                children: [
                  _buildScoreRow('🎯', 'Normal Hit', '100 pts', Colors.blue),
                  _buildScoreRow('💀', 'Headshot', '+150 bonus', Colors.red),
                  _buildDivider(),
                  _buildMultiKillSection(),
                ],
              ),

              SizedBox(height: 16),

              // Combo Sistemi
              _buildSection(
                icon: '🔥',
                title: 'Combo System',
                color: Colors.deepOrange,
                children: [
                  _buildComboRow('2x', '1.2x multiplier', Colors.yellow),
                  _buildComboRow('3x', '1.5x multiplier', Colors.orange),
                  _buildComboRow('5x', '2.2x multiplier', Colors.deepOrange),
                  _buildComboRow('10x', '5.0x multiplier', Colors.red),
                  _buildInfoText('⚡ Consecutive hits increase your combo!'),
                ],
              ),

              SizedBox(height: 16),

              // Kafa Vuruşu Combo
              _buildSection(
                icon: '💀',
                title: 'Headshot Combo',
                color: Colors.purple,
                children: [
                  _buildComboRow('3x', '2.0x multiplier', Colors.pink),
                  _buildComboRow('5x', '3.8x multiplier', Colors.pinkAccent),
                  _buildComboRow('10x', '12.0x multiplier', Colors.purple),
                  _buildInfoText('🎯 Stacks with normal combo!'),
                ],
              ),

              SizedBox(height: 16),

              // Özel Durumlar
              _buildSection(
                icon: '⚡',
                title: 'Special Cases',
                color: Colors.indigo,
                children: [
                  _buildInfoRow('🌪️', 'Birds can collide mid-air'),
                  _buildInfoRow('🎪', 'Multi-kill bonus for single arrows'),
                  _buildInfoRow('❌', 'Missed arrows reset combo'),
                ],
              ),

              SizedBox(height: 16),

              // Pro İpuçları
              _buildSection(
                icon: '💡',
                title: 'Pro Tips',
                color: Colors.teal,
                children: [
                  _buildTipCard(
                    '🎯',
                    'Aim for Headshots',
                    'Target birds\' heads for higher scores!',
                  ),
                  _buildTipCard(
                    '🔥',
                    'Maintain Your Combo',
                    'Chain consecutive hits to boost your multiplier!',
                  ),
                  _buildTipCard(
                    '⚡',
                    'Go for Multi-Kills',
                    'Try hitting multiple birds with one arrow!',
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Başarı Mesajları
              _buildAchievementPreview(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSection({
    required String icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  icon,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(icon, style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String icon, String title, String score, Color scoreColor) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Text(
              score,
              style: TextStyle(
                color: scoreColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiKillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎪 Multi-Kill Bonuses (Single Arrow)',
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        _buildMultiKillRow('2x', 'Double Kill', '+300', Colors.green),
        _buildMultiKillRow('3x', 'Triple Kill', '+900', Colors.orange),
        _buildMultiKillRow('4x', 'Quad Kill', '+1800', Colors.red),
        _buildMultiKillRow('5x', 'Penta Kill', '+3000', Colors.purple),
      ],
    );
  }

  Widget _buildMultiKillRow(String count, String name, String bonus, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '$name Shot',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            bonus,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboRow(String combo, String multiplier, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              combo,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              multiplier,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTipCard(String icon, String title, String description) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementPreview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('🏅', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text(
                'Achievement Messages',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildAchievementRow('🔥', 'Nice Combo!', '3x combo'),
          _buildAchievementRow('⚡', 'Combo On Fire!', '5x combo'),
          _buildAchievementRow('💀', 'Sharpshooter!', '3x headshot combo'),
          _buildAchievementRow('🎯', 'Legendary Accuracy!', '5x headshot combo'),
        ],
      ),
    );
  }

  Widget _buildAchievementRow(String icon, String message, String condition) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            condition,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
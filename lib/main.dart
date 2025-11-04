import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:untitled1/sound_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Position Skip Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF00A3CC),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final SoundController _soundController = SoundController();
  static const int totalCircles = 12 ;
  int roundID = 0;
  int currentPosition = 0;
  int? previousPosition;
  int? skippedPosition;
  int level = 2;
  int maxLevel = 26;
  int score = 20;
  int timeRemaining = 109;
  bool isWaitingForAnswer = false;
  bool? lastAnswerCorrect;
  bool didSkip = false;
  int? nextPosition;
  bool isPaused = false;
  int answerStartTime = 0;
  bool answeredFast = false; // Track if answered in first 500ms
  String lastAnswerSpeed = ''; // Show last answer speed
  bool hasAnsweredThisRound = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _jumpAnimation = CurvedAnimation(
      parent: _jumpController,
      curve: Curves.easeInOut,
    );

    _fillController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(_fillController);

    // Continuous slow rotation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Scale animation for target circle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _startGame();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _jumpController.dispose();
    _fillController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startGame() {
    Future.delayed(const Duration(seconds: 1), _makeMove);
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      _fillController.stop();
      _rotationController.stop();
    } else {
      _makeMove();
      // _fillController.forward();
      _rotationController.repeat();
    }
  }

  void _makeMove() async {
    if (isWaitingForAnswer || isPaused) return;

    roundID++;
    final int thisRound = roundID;

    // Reset scale from previous target
    _scaleController.reverse();

    setState(() {
      previousPosition = currentPosition;

      // Random: skip or normal
      didSkip = math.Random().nextBool();

      if (didSkip) {
        // Skip one position
        skippedPosition = (currentPosition + 1) % totalCircles;
        nextPosition = (currentPosition + 2) % totalCircles;
      } else {
        // Normal move
        skippedPosition = null;
        nextPosition = (currentPosition + 1) % totalCircles;
      }

      lastAnswerCorrect = null;
      lastAnswerSpeed = ''; // Reset speed indicator
    });

    // Start jump animation
    _jumpController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 800));

    if (isPaused) return;

    // Update position after jump
    setState(() {
      currentPosition = nextPosition!;
    });

    // Start scale animation for NEW target circle AFTER arriving
    await Future.delayed(const Duration(milliseconds: 100));

    if (isPaused) return;

    _scaleController.forward(from: 0);

    setState(() {
      hasAnsweredThisRound = false;
      isWaitingForAnswer = true;
      // Record time when answer period starts
      answerStartTime = DateTime.now().millisecondsSinceEpoch;
    });

    // Start fill animation (2 seconds)
    _fillController.forward(from: 0);

    // Auto-answer as wrong after 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));

    if (isWaitingForAnswer && !isPaused && thisRound == roundID) {
      _autoAnswerWrong();
    }
  }

  void _autoAnswerWrong() async {
    if (!isWaitingForAnswer || isPaused) return;

    setState(() {
      lastAnswerCorrect = false;
      isWaitingForAnswer = false;
      lastAnswerSpeed = 'Timeout';
    });

    // Stop animations
    _fillController.stop();
    _scaleController.reverse();

    // Shake screen
    _shakeController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      lastAnswerCorrect = null;
      previousPosition = null;
      skippedPosition = null;
      nextPosition = null;
    });

    // Reset fill animation
    _fillController.reset();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!isPaused) {
      _makeMove();
    }
  }

  void _answer(bool userSaidSkipped) async {
    if (hasAnsweredThisRound || !isWaitingForAnswer || isPaused) return;

    // Calculate response time
    int responseTime = DateTime.now().millisecondsSinceEpoch - answerStartTime;
    answeredFast = responseTime <= 500;

    bool correct = didSkip == userSaidSkipped;

    setState(() {
      lastAnswerCorrect = correct;
      hasAnsweredThisRound = true;
      isWaitingForAnswer = false;
      lastAnswerSpeed = answeredFast
          ? '⚡ Fast (${responseTime}ms)'
          : '🐢 Slow (${responseTime}ms)';
    });

    // Stop fill animation
    _fillController.stop();
    _scaleController.reverse();

    if (correct) {
      _soundController.playCorrect();
      // Award points based on speed: 3 points if answered within 500ms, 1 point otherwise
      int points = answeredFast ? 3 : 1;

      setState(() {
        score += points;
        if (score >= 100 && level < maxLevel) {
          level++;
          score = 0;
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Reset fill animation
      _fillController.reset();

      if (!isPaused) {
        _makeMove();
      }
    } else {
      _soundController.playWrong();
      // Shake screen on wrong answer
      _shakeController.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        lastAnswerCorrect = null;
        previousPosition = null;
        skippedPosition = null;
        nextPosition = null;
      });

      // Reset fill animation
      _fillController.reset();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!isPaused) {
        _makeMove();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _shakeAnimation.value *
                  math.sin(_shakeController.value * math.pi * 10),
              0,
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGameArea()),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {},
            child: const Text('Help', style: TextStyle(color: Colors.white)),
          ),
          Column(
            children: [
              const Text(
                'Level',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '$level/$maxLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'Score',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              const Text(
                'Time',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '1:${timeRemaining.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
            onPressed: _togglePause,
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.3),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),

          // Circles and connections
          SizedBox(
            width: 300,
            height: 300,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _jumpAnimation,
                _fillAnimation,
                _rotationAnimation,
                _scaleAnimation,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: CircleGamePainter(
                    currentPosition: currentPosition,
                    previousPosition: previousPosition,
                    nextPosition: nextPosition,
                    skippedPosition: lastAnswerCorrect == false
                        ? skippedPosition
                        : null,
                    jumpProgress: _jumpAnimation.value,
                    fillProgress: _fillAnimation.value,
                    rotationAngle: _rotationAnimation.value,
                    targetScale: _scaleAnimation.value,
                    showError: lastAnswerCorrect == false,
                  ),
                );
              },
            ),
          ),

          // Speed indicator
          if (lastAnswerSpeed.isNotEmpty)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: answeredFast ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lastAnswerSpeed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Pause overlay
          if (isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Icon(
                    Icons.pause_circle_filled,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF004455),
      child: Column(
        children: [
          const Text(
            'Was a position just skipped?',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: (isWaitingForAnswer && !isPaused)
                    ? () => _answer(false)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('No', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: (isWaitingForAnswer && !isPaused)
                    ? () => _answer(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Yes', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class CircleGamePainter extends CustomPainter {
  final int currentPosition;
  final int? previousPosition;
  final int? nextPosition;
  final int? skippedPosition;
  final double jumpProgress;
  final double fillProgress;
  final double rotationAngle;
  final double targetScale;
  final bool showError;

  CircleGamePainter({
    required this.currentPosition,
    this.previousPosition,
    this.nextPosition,
    this.skippedPosition,
    required this.jumpProgress,
    required this.fillProgress,
    required this.rotationAngle,
    required this.targetScale,
    required this.showError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    const circleCount = 12;

    // Save canvas state for rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Draw connections between circles
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < circleCount; i++) {
      final angle1 = (i * 2 * math.pi / circleCount) - math.pi / 2;
      final angle2 = ((i + 1) * 2 * math.pi / circleCount) - math.pi / 2;

      final p1 = Offset(
        center.dx + radius * math.cos(angle1),
        center.dy + radius * math.sin(angle1),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle2),
        center.dy + radius * math.sin(angle2),
      );

      canvas.drawLine(p1, p2, linePaint);
    }

    // Draw dashed line to skipped position (error indicator)
    if (showError && skippedPosition != null) {
      final skippedAngle =
          (skippedPosition! * 2 * math.pi / circleCount) - math.pi / 2;
      final skippedPos = Offset(
        center.dx + radius * math.cos(skippedAngle),
        center.dy + radius * math.sin(skippedAngle),
      );

      final dashedPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, center, skippedPos, dashedPaint);
    }

    // Draw circles
    final circlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < circleCount; i++) {
      final angle = (i * 2 * math.pi / circleCount) - math.pi / 2;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Draw gray halo first
      final haloPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 20, haloPaint);

      if (i == currentPosition) {
        // Current position - red circle with scale animation
        circlePaint.color = const Color(0xFFFF5555);
        canvas.drawCircle(pos, 15 * targetScale, circlePaint);
      } else {
        // Regular red circles
        circlePaint.color = const Color(0xFFFF5555);
        canvas.drawCircle(pos, 12, circlePaint);
      }
    }

    // Restore canvas for arrow (arrow should not rotate)
    canvas.restore();

    // Draw arrow pointer (like clock hand) from center to current position
    if (previousPosition != null && jumpProgress < 1.0) {
      // During jump animation - interpolate between previous and current
      final prevAngle =
          (previousPosition! * 2 * math.pi / circleCount) -
          math.pi / 2 +
          rotationAngle;
      final currAngle =
          (currentPosition * 2 * math.pi / circleCount) -
          math.pi / 2 +
          rotationAngle;
      final interpolatedAngle =
          prevAngle + (currAngle - prevAngle) * jumpProgress;

      _drawArrowPointer(
        canvas,
        center,
        radius * 0.85,
        interpolatedAngle,
        Colors.white,
      );
    } else {
      // Static position
      final angle =
          (currentPosition * 2 * math.pi / circleCount) -
          math.pi / 2 +
          rotationAngle;
      _drawArrowPointer(
        canvas,
        center,
        radius * 0.85,
        angle,
        Colors.white.withOpacity(.5),
      );
    }

    // Draw filling effect on the arrow (changes from white to blue)
    if (fillProgress > 0) {
      final angle =
          (currentPosition * 2 * math.pi / circleCount) -
          math.pi / 2 +
          rotationAngle;
      // Stop before arrow head (85% of total length)
      final filledLength = radius * 0.85 * fillProgress * 0.85;

      final fillPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final endX = center.dx + filledLength * math.cos(angle);
      final endY = center.dy + filledLength * math.sin(angle);

      canvas.drawLine(center, Offset(endX, endY), fillPaint);
    }
  }

  void _drawArrowPointer(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    Color color,
  ) {
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final endX = center.dx + length * math.cos(angle);
    final endY = center.dy + length * math.sin(angle);
    final endPoint = Offset(endX, endY);

    // Draw main line
    canvas.drawLine(center, endPoint, arrowPaint);

    // Draw arrow head
    final arrowHeadPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arrowHeadSize = 12.0;
    final arrowAngle1 = angle + math.pi - math.pi / 6;
    final arrowAngle2 = angle + math.pi + math.pi / 6;

    final arrowPath = Path();
    arrowPath.moveTo(endX, endY);
    arrowPath.lineTo(
      endX + arrowHeadSize * math.cos(arrowAngle1),
      endY + arrowHeadSize * math.sin(arrowAngle1),
    );
    arrowPath.lineTo(
      endX + arrowHeadSize * math.cos(arrowAngle2),
      endY + arrowHeadSize * math.sin(arrowAngle2),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowHeadPaint);

    // Draw small circle at center
    final centerCirclePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, centerCirclePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final dashEnd = math.min(currentDistance + dashWidth, distance);
      canvas.drawLine(
        Offset(
          start.dx + unitDx * currentDistance,
          start.dy + unitDy * currentDistance,
        ),
        Offset(start.dx + unitDx * dashEnd, start.dy + unitDy * dashEnd),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CircleGamePainter oldDelegate) => true;
}

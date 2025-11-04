import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/circle_painter_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ۱. Animation Controllers
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

    // ۲. تعریف انیمیشن‌ها
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

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

    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // ۳. اتصال متدهای انیمیشن به GameModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = Provider.of<GameModel>(context, listen: false);

      model.onShake = () => _shakeController.forward(from: 0);
      model.onJumpStart = () => _jumpController.forward(from: 0);
      model.onScaleTarget = () => _scaleController.forward(from: 0);
      model.onStopAnimations = () {
        _fillController.stop();
        _scaleController.reverse();
      };
      model.onFillStart = () => _fillController.forward(from: 0);
      model.onFillReset = () => _fillController.reset();
      model.onRotationRepeat = () => _rotationController.repeat();
      model.onRotationStop = () => _rotationController.stop();

      // شروع انیمیشن چرخش پس‌زمینه
      _rotationController.repeat();
    });
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

  @override
  Widget build(BuildContext context) {
    // ۴. دریافت مدل برای بازسازی ویجت در صورت تغییر
    final gameModel = context.watch<GameModel>();
    // ۵. دریافت مدل برای فراخوانی متدها بدون بازسازی
    final gameModelAction = context.read<GameModel>();

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
              _buildHeader(gameModel, gameModelAction),
              Expanded(child: _buildGameArea(gameModel)),
              _buildBottomSection(gameModel, gameModelAction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GameModel gameModel, GameModel gameModelAction) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // دکمه‌ها و نمایشگرهای وضعیت که از gameModel استفاده می‌کنند
          const Text('Help', style: TextStyle(color: Colors.white)),
          _buildStatusColumn('Level', '${gameModel.level}/${gameModel.maxLevel}'),
          _buildStatusColumn('Score', '${gameModel.score}'),
          _buildStatusColumn('Time', '1:${gameModel.timeRemaining.toString().padLeft(2, '0')}'),

          IconButton(
            icon: Icon(
              gameModel.isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
            onPressed: gameModelAction.togglePause, // فراخوانی متد از مدل
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameArea(GameModel gameModel) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ... دایره پس‌زمینه ...

          // Circles and connections - گوش دادن به انیمیشن‌های محلی و استفاده از داده‌های مدل
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
                    currentPosition: gameModel.currentPosition,
                    previousPosition: gameModel.previousPosition,
                    nextPosition: gameModel.nextPosition,
                    skippedPosition: gameModel.lastAnswerCorrect == false
                        ? gameModel.skippedPosition
                        : null,
                    jumpProgress: _jumpAnimation.value,
                    fillProgress: _fillAnimation.value,
                    rotationAngle: _rotationAnimation.value,
                    targetScale: _scaleAnimation.value,
                    showError: gameModel.lastAnswerCorrect == false,
                  ),
                );
              },
            ),
          ),

          // Speed indicator
          if (gameModel.lastAnswerSpeed.isNotEmpty)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gameModel.answeredFast ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gameModel.lastAnswerSpeed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Pause overlay
          if (gameModel.isPaused)
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

  Widget _buildBottomSection(GameModel gameModel, GameModel gameModelAction) {
    bool canAnswer = gameModel.isWaitingForAnswer && !gameModel.isPaused;

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
                onPressed: canAnswer ? () => gameModelAction.answer(false) : null,
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
                onPressed: canAnswer ? () => gameModelAction.answer(true) : null,
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
// lib/game_model.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../controller/sound_controller.dart';




class GameModel with ChangeNotifier {
  final SoundController _soundController = SoundController();
  static const int totalCircles = 12;

  // متغیرهای وضعیت
  int roundID = 0;
  int currentPosition = 0;
  int? previousPosition;
  int? skippedPosition;
  int level = 2;
  final int maxLevel = 26;
  int score = 20;
  int timeRemaining = 109; // نیاز به Timer مجزا دارد
  bool isWaitingForAnswer = false;
  bool? lastAnswerCorrect;
  bool didSkip = false;
  int? nextPosition;
  bool _isPaused = false;
  int answerStartTime = 0;
  bool answeredFast = false;
  String lastAnswerSpeed = '';
  bool hasAnsweredThisRound = false;

  // *توجه:* متغیرهایی برای مدیریت انیمیشن‌ها در GameScreen.
  // این توابع توسط GameScreen فراخوانی می‌شوند تا انیمیشن‌های محلی اجرا شوند.
  VoidCallback? onShake;
  VoidCallback? onJumpStart;
  VoidCallback? onScaleTarget;
  VoidCallback? onStopAnimations;
  VoidCallback? onFillStart;
  VoidCallback? onFillReset;
  VoidCallback? onRotationRepeat;
  VoidCallback? onRotationStop;

  bool get isPaused => _isPaused;

  GameModel() {
    _startGame();
  }

  void _startGame() {
    // یک ثانیه تأخیر برای شروع
    Future.delayed(const Duration(seconds: 1), _makeMove);
    onRotationRepeat?.call(); // شروع چرخش پس‌زمینه
  }

  void togglePause() {
    _isPaused = !_isPaused;

    if (_isPaused) {
      onStopAnimations?.call();
      onRotationStop?.call();
    } else {
      _makeMove(); // بلافاصله حرکت را از سر می‌گیرد
      onRotationRepeat?.call();
    }

    notifyListeners();
  }

  void _makeMove() async {
    if (isWaitingForAnswer || _isPaused) return;

    roundID++;
    final int thisRound = roundID;

    // اجرای انیمیشن مقیاس‌گذاری معکوس
    // این در GameScreen به _scaleController.reverse() ترجمه می‌شود.
    onScaleTarget?.call();

    previousPosition = currentPosition;

    // منطق پرش یا حرکت عادی
    didSkip = math.Random().nextBool();

    if (didSkip) {
      skippedPosition = (currentPosition + 1) % totalCircles;
      nextPosition = (currentPosition + 2) % totalCircles;
    } else {
      skippedPosition = null;
      nextPosition = (currentPosition + 1) % totalCircles;
    }

    lastAnswerCorrect = null;
    lastAnswerSpeed = '';
    notifyListeners();

    // شروع انیمیشن پرش
    onJumpStart?.call();

    await Future.delayed(const Duration(milliseconds: 800));

    if (_isPaused) return;

    // به‌روزرسانی موقعیت پس از پرش
    currentPosition = nextPosition!;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    if (_isPaused) return;

    // اجرای انیمیشن مقیاس‌گذاری برای هدف جدید
    onScaleTarget?.call();

    hasAnsweredThisRound = false;
    isWaitingForAnswer = true;
    answerStartTime = DateTime.now().millisecondsSinceEpoch;

    // شروع انیمیشن پر شدن نوار زمان
    onFillStart?.call();
    notifyListeners();

    // پاسخ خودکار غلط پس از ۲ ثانیه
    await Future.delayed(const Duration(milliseconds: 2000));

    if (isWaitingForAnswer && !_isPaused && thisRound == roundID) {
      _autoAnswerWrong();
    }
  }

  void _autoAnswerWrong() async {
    if (!isWaitingForAnswer || _isPaused) return;

    lastAnswerCorrect = false;
    isWaitingForAnswer = false;
    lastAnswerSpeed = 'Timeout';
    notifyListeners();

    onStopAnimations?.call();
    onShake?.call(); // اجرای انیمیشن لرزش

    _soundController.playWrong();

    await Future.delayed(const Duration(milliseconds: 1500));

    _resetRound();
  }

  void _answer(bool userSaidSkipped) async {
    if (hasAnsweredThisRound || !isWaitingForAnswer || _isPaused) return;

    int responseTime = DateTime.now().millisecondsSinceEpoch - answerStartTime;
    answeredFast = responseTime <= 500;
    bool correct = didSkip == userSaidSkipped;

    lastAnswerCorrect = correct;
    hasAnsweredThisRound = true;
    isWaitingForAnswer = false;
    lastAnswerSpeed = answeredFast
        ? '⚡ Fast (${responseTime}ms)'
        : '🐢 Slow (${responseTime}ms)';
    notifyListeners();

    onStopAnimations?.call();

    if (correct) {
      _soundController.playCorrect();
      int points = answeredFast ? 3 : 1;

      score += points;
      if (score >= 100 && level < maxLevel) {
        level++;
        score = 0;
      }
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      _resetRound();
    } else {
      _soundController.playWrong();
      onShake?.call(); // اجرای انیمیشن لرزش

      await Future.delayed(const Duration(milliseconds: 1500));
      _resetRound();
    }
  }

  void _resetRound() async {
    lastAnswerCorrect = null;
    previousPosition = null;
    skippedPosition = null;
    nextPosition = null;
    onFillReset?.call(); // ریست انیمیشن پر شدن
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isPaused) {
      _makeMove();
    }
  }

  // متد عمومی برای پاسخ دادن
  void answer(bool userSaidSkipped) => _answer(userSaidSkipped);
}
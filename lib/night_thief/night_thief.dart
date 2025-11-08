import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'dart:async';

import '../jump_circle_game/controller/sound_controller.dart';

class ThiefGameScreen extends StatefulWidget {
  const ThiefGameScreen({super.key});

  @override
  _ThiefGameScreenState createState() => _ThiefGameScreenState();
}

class _ThiefGameScreenState extends State<ThiefGameScreen>
    with TickerProviderStateMixin {
  final SoundController _soundController = SoundController();
  final _audioPlayer= AudioPlayer();
  int level = 1;
  int totalWindows = 9;
  int thiefCount = 3;
  List<int> thiefPositions = [];
  List<int> selectedPositions = [];
  bool showingThieves = false;
  bool canSelect = false;
  bool showResult = false;
  bool isCorrect = false;
  bool showWrongPositions = false;
  int correctSelections = 0;
  int score = 0;

  List<AnimationController> windowControllers = [];
  List<Animation<double>> windowAnimations = [];
  AnimationController? resultController;
  Animation<double>? resultAnimation;

  @override
  void initState() {
    super.initState();
    startLevel();
  }

  @override
  void dispose() {
    for (var controller in windowControllers) {
      controller.dispose();
    }
    resultController?.dispose();
    super.dispose();
  }

  void startLevel() {
    setState(() {
      switch (level) {
        case 1:
          totalWindows = 9;
          thiefCount = 3;
          break;
        case 2:
          totalWindows = 9;
          thiefCount = 4;
          break;
        case 3:
          totalWindows = 12;
          thiefCount = 5;
          break;
        case 4:
          totalWindows = 12;
          thiefCount = 6;
          break;
      }

      selectedPositions.clear();
      correctSelections = 0;
      showingThieves = false;
      canSelect = false;
      showResult = false;
      showWrongPositions = false;
    });

    _setupAnimations();
    _showWindows();
  }

  void _setupAnimations() {
    for (var controller in windowControllers) {
      controller.dispose();
    }
    windowControllers.clear();
    windowAnimations.clear();

    for (int i = 0; i < totalWindows; i++) {
      var controller = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );
      var animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      );
      windowControllers.add(controller);
      windowAnimations.add(animation);
    }

    resultController?.dispose();
    resultController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    resultAnimation = CurvedAnimation(
      parent: resultController!,
      curve: Curves.elasticOut,
    );
  }

  void _showWindows() async {
    for (int i = 0; i < totalWindows; i++) {
      await Future.delayed(Duration(milliseconds: 50));
      windowControllers[i].forward();
    }

    await Future.delayed(Duration(milliseconds: 200));
    _showThieves();
  }

  void _showThieves() {
    var random = Random();
    thiefPositions.clear();

    while (thiefPositions.length < thiefCount) {
      int pos = random.nextInt(totalWindows);
      if (!thiefPositions.contains(pos)) {
        thiefPositions.add(pos);
      }
    }

    setState(() {
      showingThieves = true;
    });

    Timer(Duration(milliseconds: 1500), () {
      setState(() {
        showingThieves = false;
        canSelect = true;
      });
    });
  }

  void _selectWindow(int index) {
    if (!canSelect || selectedPositions.contains(index) || showWrongPositions) {
      return;
    }

    setState(() {
      selectedPositions.add(index);
    });

    if (thiefPositions.contains(index)) {
      // _soundController.playStop();
      _audioPlayer.setAsset('assets/sounds/thief_select.mp3');
      _audioPlayer.play();
      // _soundController.playSound(path: 'thief_selectt.mp3');
      // _soundController.playSound(path: 'sounds/jump_circle_correct.mp3');
      setState(() {
        correctSelections++;
        score += 20;
      });

      if (correctSelections == thiefCount) {
        _soundController.playStop();
        _soundController.playSound(path: 'thief_correct.mp3');
        _showCorrectResult();
      }
    } else {
      _soundController.playStop();
      _soundController.playSound(path: 'thief_wrong.mp3');
      _showWrongResult();
    }
  }

  void _showCorrectResult() {
    setState(() {
      canSelect = false;
      showResult = true;
      isCorrect = true;
    });
    resultController?.forward();

    Timer(Duration(milliseconds: 1000), () {
      resultController?.reverse();
      _hideWindowsAndNext();
    });
  }

  void _showWrongResult() {
    setState(() {
      canSelect = false;
      showResult = true;
      isCorrect = false;
      showWrongPositions = true;
      correctSelections = 0;
    });
    resultController?.forward();

    Timer(Duration(milliseconds: 1000), () {
      resultController?.reverse();
      _hideWindowsAndNext();
    });
  }

  void _hideWindowsAndNext() async {
    await Future.delayed(Duration(milliseconds: 300));

    for (int i = totalWindows - 1; i >= 0; i--) {
      await Future.delayed(Duration(milliseconds: 30));
      windowControllers[i].reverse();
    }

    await Future.delayed(Duration(milliseconds: 500));

    if (isCorrect && level < 4) {
      setState(() {
        level++;
      });
    }

    startLevel();
  }

  String _getWindowImage(int index) {
    if (showingThieves && thiefPositions.contains(index)) {
      return 'assets/images/thief_card_preview.png';
    }
    if (showWrongPositions) {
      if (thiefPositions.contains(index)) {
        return 'assets/images/thief_card_wrong.png';
      }
      if (selectedPositions.contains(index) &&
          !thiefPositions.contains(index)) {
        return 'assets/images/thief_card_wrong_select.png';
      }
    }
    if (selectedPositions.contains(index) && thiefPositions.contains(index)) {
      return 'assets/images/thief_card_correct.png';
    }
    return 'assets/images/thief_card_empty.png';
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = totalWindows == 9 ? 3 : 4;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,

          children: [
            Image.asset(
              'assets/images/thief_background.jpg',
              fit: BoxFit.fitHeight,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مرحله $level',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'امتیاز: $score',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // if (canSelect || showWrongPositions)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xff3B3468),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$correctSelections',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: correctSelections > 0
                                        ? Color(0xff7FDA8D)
                                        : Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: ' از $thiefCount دزد',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16),

                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: totalWindows,
                        itemBuilder: (context, index) {
                          return ScaleTransition(
                            scale: windowAnimations[index],
                            child: GestureDetector(
                              onTap: () => _selectWindow(index),
                              child: Center(
                                child: Image.asset(
                                  _getWindowImage(index),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showResult)
              Center(
                child: ScaleTransition(
                  scale: resultAnimation!,
                  child: Image.asset(
                    isCorrect
                        ? 'assets/images/thief_win_game.png'
                        : 'assets/images/thief_lose_game.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

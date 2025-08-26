import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const LottoApp());
}

class LottoApp extends StatelessWidget {
  const LottoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로또 번호 생성기',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LottoMachineScreen(),
    );
  }
}

// 공의 데이터를 관리할 클래스
class Ball {
  final int number;
  final Color color;
  double x;
  double y;

  Ball({required this.number, required this.color, this.x = 0.0, this.y = 0.0});
}

class LottoMachineScreen extends StatefulWidget {
  const LottoMachineScreen({super.key});

  @override
  State<LottoMachineScreen> createState() => _LottoMachineScreenState();
}

class _LottoMachineScreenState extends State<LottoMachineScreen> {
  final Random _random = Random();
  final List<Ball> _balls = [];
  final List<Ball> _selectedBalls = [];

  bool _isDrawing = false;
  Timer? _shuffleTimer;

  @override
  void initState() {
    super.initState();
    _resetBalls();
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  // 공의 색상을 번호에 따라 결정하는 함수
  Color _getBallColor(int number) {
    if (number <= 10) return Colors.yellow.shade600;
    if (number <= 20) return Colors.blue.shade600;
    if (number <= 30) return Colors.red.shade600;
    if (number <= 40) return Colors.grey.shade700;
    return Colors.green.shade600;
  }

  // 1~45번 공을 초기화하는 함수
  void _resetBalls() {
    setState(() {
      _isDrawing = false;
      _selectedBalls.clear();
      _balls.clear();
      for (int i = 1; i <= 45; i++) {
        _balls.add(Ball(
          number: i,
          color: _getBallColor(i),
          x: _random.nextDouble() * 250, // 초기 위치 랜덤 설정
          y: _random.nextDouble() * 250,
        ));
      }
    });
  }

  // 추첨 시작 함수
  void _startDrawing() {
    if (_isDrawing) return;

    _resetBalls();
    setState(() => _isDrawing = true);

    // 1. 공 섞기 애니메이션
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        for (var ball in _balls) {
          ball.x = _random.nextDouble() * 250;
          ball.y = _random.nextDouble() * 250;
        }
      });
    });

    // 2. 섞이는 시간 (3초)
    Future.delayed(const Duration(seconds: 3), () {
      _shuffleTimer?.cancel();
      // 3. 공 뽑기 시작
      _pickBalls();
    });
  }

  // 공을 하나씩 뽑는 함수
  Future<void> _pickBalls() async {
    final availableBalls = List<Ball>.from(_balls);

    for (int i = 0; i < 7; i++) {
      // 1.2초 간격으로 하나씩 뽑기
      await Future.delayed(const Duration(milliseconds: 1200));

      setState(() {
        final pickedBall = availableBalls.removeAt(_random.nextInt(availableBalls.length));
        _selectedBalls.add(pickedBall);
      });
    }

    setState(() => _isDrawing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍀 행운의 로또 번호 🍀'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 당첨 번호가 표시될 영역
          _buildResultPanel(),

          // 2. 로또 머신 & 공 애니메이션 영역
          _buildLottoMachine(),

          // 3. 컨트롤 버튼 영역
          _buildControlButton(),
        ],
      ),
    );
  }

  // 당첨 번호 결과 패널 위젯
  Widget _buildResultPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text('🎉 당첨 번호 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              if (index >= _selectedBalls.length) {
                return _buildBallWidget(null); // 아직 뽑히지 않은 공
              }
              if (index == 6) {
                return Row(children: [
                  const Icon(Icons.add, size: 30, color: Colors.grey),
                  _buildBallWidget(_selectedBalls[index]), // 보너스 볼
                ]);
              }
              return _buildBallWidget(_selectedBalls[index]);
            }),
          ),
        ],
      ),
    );
  }

  // 로또 머신 위젯
  Widget _buildLottoMachine() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.indigo.shade200, width: 4),
      ),
      child: ClipOval(
        child: Stack(
          children: _balls.map((ball) {
            // 아직 선택되지 않은 공만 보여주기
            if (_selectedBalls.contains(ball)) return const SizedBox.shrink();

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: ball.x,
              top: ball.y,
              child: _buildBallWidget(ball, isSmall: true),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 컨트롤 버튼 위젯
  Widget _buildControlButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.casino),
      label: Text(_isDrawing ? '추첨 중...' : '추첨 시작!', style: const TextStyle(fontSize: 20)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: _isDrawing ? null : _startDrawing,
    );
  }

  // 공 하나를 그리는 위젯
  Widget _buildBallWidget(Ball? ball, {bool isSmall = false}) {
    final size = isSmall ? 35.0 : 45.0;
    final fontSize = isSmall ? 16.0 : 20.0;

    if (ball == null) {
      return Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ball.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          '${ball.number}',
          style: TextStyle(
            color: ball.number > 30 && ball.number <= 40 ? Colors.white : Colors.black, // 회색 공 글자색 흰색으로
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // ⭕ 기존 소민팡팡에서 쓰시던 파이어베이스 접속 키를 그대로 넣습니다.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBqdPjDzJJcSZYsem9sbZZY_Gf9TMAXm0o",
        appId: "1:749732944978:android:4d1f1f81da6621b19c138b",
        messagingSenderId: "749732944978",
        projectId: "somindoyoonapp",
        storageBucket: "somindoyoonapp.firebasestorage.app",
      ),
    );
    debugPrint("🔥 Firebase 연결 성공!");
  } catch (e) {
    debugPrint("Firebase 초기화 에러: $e");
  }
  runApp(const TetrisApp());
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '소민팡 테트리스',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: LoginScreen(), // const 제거
      debugShowCheckedModeBanner: false,
    );
  }
}

enum GameMode { pc, mobile }
enum ItemType { finger, bomb, scissors, eraser }

class Block {
  final Color color;
  final String? imagePath;
  final ItemType? itemType;
  final bool isGarbage;

  Block({required this.color, this.imagePath, this.itemType, this.isGarbage = false});
}

// --- 1. 로그인 화면 ---
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  String playerId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("TETRIS PANG!", style: TextStyle(color: Colors.yellowAccent, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              TextField(
                controller: _idController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                decoration: InputDecoration(
                  hintText: "아이디를 입력하세요",
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2), borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.yellowAccent, width: 2), borderRadius: BorderRadius.circular(15)),
                ),
                onChanged: (value) => setState(() => playerId = value.trim()),
              ),
              const SizedBox(height: 30),
              if (playerId.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ModeSelectionScreen(playerId: playerId)));
                  },
                  child: const Text("다음"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. 모드 선택 및 테스트 모드 진입 화면 ---
class ModeSelectionScreen extends StatefulWidget {
  final String playerId;
  const ModeSelectionScreen({required this.playerId});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool isTestModeActive = true; // 테스트 기능 활성화 여부
  bool isUnlocked = false;
  final TextEditingController _secretController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Text("환영합니다, ${widget.playerId}님!", style: const TextStyle(color: Colors.white, fontSize: 22)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBtn(context, "💻 PC 모드", GameMode.pc),
                  const SizedBox(width: 20),
                  _buildBtn(context, "📱 모바일 모드", GameMode.mobile),
                ],
              ),
              const SizedBox(height: 60),

              // 시크릿 코드 입력창
              if (isTestModeActive) ...[
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _secretController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                    decoration: const InputDecoration(hintText: "Secret Code", hintStyle: TextStyle(color: Colors.white10)),
                    onChanged: (v) => setState(() => isUnlocked = (v == "131012")),
                  ),
                ),
                if (isUnlocked) ...[
                  const SizedBox(height: 20),
                  const Text("라운드 점프", style: TextStyle(color: Colors.orangeAccent)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 20].map((r) => ElevatedButton(
                      onPressed: () => _jumpToGame(context, r),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, minimumSize: const Size(50, 40)),
                      child: Text("$r"),
                    )).toList(),
                  )
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToGame(BuildContext context, int round) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TetrisGameScreen(playerId: widget.playerId, mode: GameMode.mobile, startRound: round)));
  }

  Widget _buildBtn(BuildContext context, String text, GameMode mode) {
    return ElevatedButton(
      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TetrisGameScreen(playerId: widget.playerId, mode: mode))),
      child: Text(text),
    );
  }
}

// --- 3. 메인 게임 및 랭킹 페이지 ---
class TetrisGameScreen extends StatefulWidget {
  final String playerId;
  final GameMode mode;
  final int startRound;
  const TetrisGameScreen({required this.playerId, required this.mode, this.startRound = 1});

  @override
  State<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen> {
  static const int rowLength = 10;
  static const int colLength = 20;

  List<List<Block?>> board = List.generate(colLength, (_) => List.filled(rowLength, null));
  Map<ItemType, int> inventory = {ItemType.finger: 0, ItemType.bomb: 0, ItemType.scissors: 0, ItemType.eraser: 0};

  ItemType? selectedItem;
  Timer? gameTimer;
  Timer? garbageTimer;
  bool isGameOver = false;
  int score = 0;
  int currentRound = 1;

  List<Map<String, dynamic>> topRankings = [];
  bool isFetchingRank = false;

  List<List<int>> currentPiece = [];
  int currentPieceRow = 0;
  int currentPieceCol = 0;
  Color currentPieceColor = Colors.transparent;
  int currentFaceIndex = -1;
  String? currentFaceImage;
  ItemType? currentItemType;

  final Random random = Random();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    currentRound = widget.startRound;
    score = (currentRound - 1) * 1000;
    _spawnNewPiece();
    _startGameLoop();
  }

  void _playSound(String fileName) async {
    try {
      await AudioPlayer().play(AssetSource('audio/$fileName'));
    } catch (e) { debugPrint(e.toString()); }
  }

  // --- 랭킹 데이터 가져오기 ---
  Future<void> _fetchTopRankings() async {
    setState(() => isFetchingRank = true);
    try {
      var snap = await FirebaseFirestore.instance.collection('tetris_scores').orderBy('score', descending: true).limit(5).get();
      setState(() {
        topRankings = snap.docs.map((d) => d.data()).toList();
        isFetchingRank = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isFetchingRank = false);
    }
  }

  Future<void> _saveFinalScore() async {
    try {
      await FirebaseFirestore.instance.collection('tetris_scores').add({
        'playerId': widget.playerId,
        'score': score,
        'round': currentRound,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _fetchTopRankings();
    } catch (e) { debugPrint(e.toString()); }
  }

  void _startGameLoop() {
    gameTimer?.cancel();
    double speedMult = currentRound >= 5 ? pow(0.99, currentRound - 4).toDouble() : 1.0;
    gameTimer = Timer.periodic(Duration(milliseconds: (500 * speedMult).toInt()), (t) => _moveDown());
    _updateGarbageTimer();
  }

  void _updateGarbageTimer() {
    garbageTimer?.cancel();
    if (currentRound >= 5) {
      int sec = currentRound >= 10 ? 3 : 5;
      garbageTimer = Timer.periodic(Duration(seconds: sec), (t) => _addGarbageLine());
    }
  }

  void _addGarbageLine() {
    if (isGameOver) return;
    for (int r = 0; r < colLength - 1; r++) board[r] = List.from(board[r + 1]);
    int empty = random.nextInt(rowLength);
    board[colLength - 1] = List.generate(rowLength, (c) => c == empty ? null : Block(color: Colors.grey, isGarbage: true));
    setState(() {});
  }

  void _spawnNewPiece() {
    int idx = random.nextInt(7);
    final List<List<List<int>>> tetro = [
      [[0,0],[0,1],[0,2],[0,3]], [[0,0],[0,1],[1,0],[1,1]], [[0,1],[1,0],[1,1],[1,2]],
      [[0,1],[0,2],[1,0],[1,1]], [[0,0],[0,1],[1,1],[1,2]], [[0,0],[1,0],[1,1],[1,2]], [[0,2],[1,0],[1,1],[1,2]]
    ];
    currentPiece = tetro[idx].map((l) => List<int>.from(l)).toList();
    currentPieceColor = [Colors.cyan, Colors.yellow, Colors.purple, Colors.green, Colors.red, Colors.blue, Colors.orange][idx];
    currentPieceRow = 0;
    currentPieceCol = 3;

    int roll = random.nextInt(100) + 1;
    if (roll <= 10) { currentItemType = ItemType.finger; currentFaceImage = 'assets/do.png'; }
    else if (roll <= 15) { currentItemType = ItemType.bomb; currentFaceImage = 'assets/so.png'; }
    else if (roll <= 20) { currentItemType = ItemType.scissors; currentFaceImage = 'assets/c1.png'; }
    else if (roll <= 23) { currentItemType = ItemType.eraser; currentFaceImage = 'assets/c2.png'; }
    else { currentItemType = null; currentFaceImage = null; }

    currentFaceIndex = currentItemType != null ? random.nextInt(4) : -1;

    if (_checkCollision(currentPieceRow, currentPieceCol, currentPiece)) {
      setState(() => isGameOver = true);
      gameTimer?.cancel();
      garbageTimer?.cancel();
      _saveFinalScore();
    }
    setState(() {});
  }

  bool _checkCollision(int r, int c, List<List<int>> p) {
    for (var pos in p) {
      int row = r + pos[0]; int col = c + pos[1];
      if (row >= colLength || col < 0 || col >= rowLength) return true;
      if (row >= 0 && board[row][col] != null) return true;
    }
    return false;
  }

  void _lockPiece() {
    for (int i = 0; i < currentPiece.length; i++) {
      int row = currentPieceRow + currentPiece[i][0];
      int col = currentPieceCol + currentPiece[i][1];
      if (row >= 0) {
        board[row][col] = Block(color: currentPieceColor, imagePath: (i == currentFaceIndex) ? currentFaceImage : null, itemType: (i == currentFaceIndex) ? currentItemType : null);
      }
    }
    _playSound('block_drop.wav');
    _clearLines();
    _spawnNewPiece();
  }

  void _clearLines() {
    int linesCleared = 0;
    for (int r = colLength - 1; r >= 0; r--) {
      bool isFull = true;
      for (int c = 0; c < rowLength; c++) if (board[r][c] == null) { isFull = false; break; }
      if (isFull) {
        for (int c = 0; c < rowLength; c++) if (board[r][c]?.itemType != null) inventory[board[r][c]!.itemType!] = inventory[board[r][c]!.itemType!]! + 1;
        board.removeAt(r); board.insert(0, List.filled(rowLength, null));
        linesCleared++; r++;
      }
    }
    if (linesCleared > 0) {
      _playSound('line_clear.wav');
      score += [0, 10, 30, 60, 80][linesCleared];
      int nr = (score ~/ 1000) + 1;
      if (nr > currentRound) { currentRound = nr; _startGameLoop(); }
      setState(() {});
    }
  }

  void _hardDrop() {
    if (isGameOver) return;
    while (!_checkCollision(currentPieceRow + 1, currentPieceCol, currentPiece)) currentPieceRow++;
    _lockPiece();
  }

  void _applyItem(ItemType type, int r, int c) {
    inventory[type] = inventory[type]! - 1;
    switch (type) {
      case ItemType.finger: _playSound('item_curr.wav'); board[r][c] = null; break;
      case ItemType.bomb:
        _playSound('item_bom.wav');
        for (int i = r - 1; i <= r + 1; i++) for (int j = c - 1; j <= c + 1; j++) if (i >= 0 && i < colLength && j >= 0 && j < rowLength) board[i][j] = null;
        break;
      case ItemType.scissors: _playSound('item_line.wav'); board[r] = List.filled(rowLength, null); break;
      case ItemType.eraser: _playSound('item_all.wav'); board = List.generate(colLength, (_) => List.filled(rowLength, null)); break;
    }
    setState(() => selectedItem = null);
  }

  void _moveDown() { if (!_checkCollision(currentPieceRow + 1, currentPieceCol, currentPiece)) setState(() => currentPieceRow++); else _lockPiece(); }
  void _moveLeft() { if (!_checkCollision(currentPieceRow, currentPieceCol - 1, currentPiece)) setState(() => currentPieceCol--); }
  void _moveRight() { if (!_checkCollision(currentPieceRow, currentPieceCol + 1, currentPiece)) setState(() => currentPieceCol++); }
  void _rotate() {
    List<List<int>> rotated = currentPiece.map((p) => [p[1], -p[0]]).toList();
    if (!_checkCollision(currentPieceRow, currentPieceCol, rotated)) {
      setState(() => currentPiece = rotated);
      _playSound('block_change.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (n, e) {
            if (e is KeyDownEvent) {
              if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _moveLeft();
              else if (e.logicalKey == LogicalKeyboardKey.arrowRight) _moveRight();
              else if (e.logicalKey == LogicalKeyboardKey.arrowUp) _rotate();
              else if (e.logicalKey == LogicalKeyboardKey.arrowDown) _moveDown();
              else if (e.logicalKey == LogicalKeyboardKey.space) _hardDrop();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: [
              // 인벤토리
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ItemType.values.map((t) {
                    bool isArmed = selectedItem == t;
                    return GestureDetector(
                      onTap: () {
                        if (inventory[t]! > 0) {
                          if (t == ItemType.eraser) _applyItem(t, 0, 0);
                          else setState(() => selectedItem = isArmed ? null : t);
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: isArmed ? Colors.yellowAccent : Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: isArmed ? Colors.orange : Colors.transparent, width: 2)),
                            child: Icon(_getIcon(t), color: isArmed ? Colors.black : Colors.white),
                          ),
                          Text("${inventory[t]}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Text("ROUND $currentRound | SCORE $score", style: const TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: rowLength / colLength,
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
                      child: Stack(
                        children: [
                          Column(children: List.generate(colLength, (r) => Expanded(child: Row(children: List.generate(rowLength, (c) => Expanded(
                            child: GestureDetector(onTap: () => selectedItem != null ? _applyItem(selectedItem!, r, c) : null, child: _buildCell(r, c)),
                          )))))),
                          if (isGameOver) _buildRankingOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.mode == GameMode.mobile && !isGameOver)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        _buildBtn(Icons.arrow_back, _moveLeft), _buildBtn(Icons.rotate_right, _rotate), _buildBtn(Icons.arrow_forward, _moveRight), _buildBtn(Icons.arrow_downward, _moveDown, color: Colors.orange),
                      ]),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _hardDrop, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(200, 45)), child: const Text("한번에 떨구기")),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🏆 RANKING", style: TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 40),
          if (isFetchingRank) const CircularProgressIndicator()
          else ...topRankings.asMap().entries.map((e) {
            int rank = e.key + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$rank위  ${e.value['playerId']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Text("${e.value['round']}R / ${e.value['score']}점", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(150, 50)),
            child: const Text("다시 시작", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  IconData _getIcon(ItemType t) {
    switch (t) {
      case ItemType.finger: return Icons.touch_app;
      case ItemType.bomb: return Icons.wb_iridescent;
      case ItemType.scissors: return Icons.content_cut;
      case ItemType.eraser: return Icons.auto_fix_high;
    }
  }

  Widget _buildBtn(IconData i, VoidCallback t, {Color color = Colors.deepPurpleAccent}) => GestureDetector(
    onTap: t,
    child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(i, color: Colors.white)),
  );

  Widget _buildCell(int r, int c) {
    bool isC = false; String? img; ItemType? it;
    for (int i = 0; i < currentPiece.length; i++) {
      if (currentPieceRow + currentPiece[i][0] == r && currentPieceCol + currentPiece[i][1] == c) {
        isC = true; if (i == currentFaceIndex) { img = currentFaceImage; it = currentItemType; }
      }
    }
    Block? b = isC ? Block(color: currentPieceColor, imagePath: img, itemType: it) : board[r][c];
    return Container(
      decoration: BoxDecoration(color: b?.color ?? Colors.transparent, border: Border.all(color: Colors.white10, width: 0.5)),
      child: b?.imagePath != null ? Image.asset(b!.imagePath!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(_getIcon(b.itemType!), color: Colors.white, size: 14))
          : (b?.itemType != null ? Icon(_getIcon(b!.itemType!), color: Colors.white, size: 14) : null),
    );
  }

  @override
  void dispose() { gameTimer?.cancel(); garbageTimer?.cancel(); _focusNode.dispose(); super.dispose(); }
}
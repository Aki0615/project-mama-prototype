// =====================
// PosiLife メインアプリ
// =====================
//
// ・main.dartは全UIとロジックを1ファイルで管理
// ・UserSettings, ChatMessage, CalendarEvent, Memory などのデータ型を定義
// ・MockGeminiServiceでAIリアクション等を模擬
// ・4つの画面(Home/Calendar/Memories/Settings)をIndexedStackで切替
// ・FABで「起床」「食事」「家事」などのアクションを記録
// ・設定画面でリセットやメモも可能
//
// 2025/12/24 コメント追加

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter

// --- Types & Enums (types.ts equivalent) ---

enum PersonaType { mom, dad, idol, butler }
enum ViewState { home, calendar, memories, settings }
enum MemoryCategory { all, meal, achievement, morning }

class UserSettings {
  String name;
  PersonaType persona;
  String targetWakeUpTime;
  String? memo; // ユーザーメモを追加

  UserSettings({
    required this.name,
    required this.persona,
    required this.targetWakeUpTime,
    this.memo,
  });
}

class ChatMessage {
  String id;
  String text;
  String sender; // 'USER' or 'AI'
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class CalendarEvent {
  String id;
  String title;
  String date;
  String time;
  bool prepared;
  String? aiAdvice;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.prepared = false,
    this.aiAdvice,
  });
}

class Memory {
  String id;
  MemoryCategory category;
  String? note;
  DateTime timestamp;
  String? aiResponse;
  Color? imageColor; // Mocking image with color for simplicity

  Memory({
    required this.id,
    required this.category,
    this.note,
    required this.timestamp,
    this.aiResponse,
    this.imageColor,
  });
}

// --- Mock Services (services/geminiService.ts equivalent) ---

class MockGeminiService {
  static Future<String> generateReaction(UserSettings settings, String trigger, String context) async {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    
    // Simple logic to mimic AI personas
    String prefix = "";
    switch (settings.persona) {
      case PersonaType.mom:
        prefix = "あら、すごいじゃない！";
        break;
      case PersonaType.dad:
        prefix = "おぉ、よくやったな。";
        break;
      case PersonaType.idol:
        prefix = "さすが！その調子だよ✨";
        break;
      case PersonaType.butler:
        prefix = "素晴らしい成果でございます。";
        break;
    }
    return "$prefix $context よく頑張りましたね。 (${settings.name}さんへ)";
  }

  static Future<String> analyzeImage(UserSettings settings, Color color, String type) async {
    await Future.delayed(const Duration(seconds: 2));
    if (type == 'MEAL') {
      return settings.persona == PersonaType.mom 
          ? "美味しそう！ちゃんと食べて偉いわね。" 
          : "エネルギーチャージ完了だね！最高！";
    }
    return "いい写真ですね！";
  }

  static Future<String> checkSchedule(UserSettings settings, String title, String dateTime) async {
    await Future.delayed(const Duration(seconds: 1));
    return settings.persona == PersonaType.butler 
        ? "承知いたしました。準備は今のうちに済ませておきましょう。" 
        : "了解！準備万端にして楽しもうね！";
  }
}

// --- UI Components ---

class Avatar extends StatelessWidget {
  final PersonaType persona;
  final String mood; // 'neutral' or 'happy'
  final double size;

  const Avatar({
    super.key,
    required this.persona,
    this.mood = 'neutral',
    this.size = 56,
  });

  String getEmoji() {
    switch (persona) {
      case PersonaType.mom: return mood == 'happy' ? '👩‍🦱✨' : '👩‍🦱';
      case PersonaType.dad: return mood == 'happy' ? '👨🍺' : '👨';
      case PersonaType.idol: return mood == 'happy' ? '🎤💖' : '🎤';
      case PersonaType.butler: return mood == 'happy' ? '🤵🍷' : '🤵';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: size,
      height: size,
      transform: mood == 'happy' 
          ? (Matrix4.identity()..scale(1.1)..rotateZ(0.05)) 
          : Matrix4.identity(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade100, Colors.orange.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        getEmoji(),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
             // Placeholder for avatar if needed next to bubble, currently handled in header/logic
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFFFA726) : Colors.white, // Orange-400 or White
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                      bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    gradient: isUser 
                        ? LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]) 
                        : null,
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.grey.shade800,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main App ---

void main() {
  runApp(const PosiLifeApp());
}

class PosiLifeApp extends StatelessWidget {
  const PosiLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PosiLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans JP',
        scaffoldBackgroundColor: const Color(0xFFFFF7ED), // bg-warm (orange-50)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // State
  ViewState _view = ViewState.home;
  UserSettings? _settings;
  List<ChatMessage> _chatHistory = [];
  List<Memory> _memories = [];
  List<CalendarEvent> _events = [];
  
  // Interaction State
  bool _isThinking = false;
  String _mood = 'neutral';
  bool _fabOpen = false;
  MemoryCategory _activeTab = MemoryCategory.all;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _eventTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Simulate loading data
    // _settings = ... load from shared_preferences
  }

  // --- Logic Methods ---

  void _addMessage(String text, String sender) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
    );
    setState(() {
      _chatHistory.add(newMessage);
    });
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleFabAction(String action) {
    setState(() => _fabOpen = false);
    if (action == 'morning') _handleWakeUp();
    if (action == 'meal') _handleImageUpload();
    if (action == 'chore') _handleChore();
  }

  Future<void> _handleWakeUp() async {
    if (_settings == null) return;
    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    final target = _settings!.targetWakeUpTime;
    
    // Simple logic
    final targetParts = target.split(':').map(int.parse).toList();
    final targetDate = DateTime(now.year, now.month, now.day, targetParts[0], targetParts[1]);
    final isLate = now.isAfter(targetDate.add(const Duration(minutes: 30)));

    _addMessage("I woke up at $timeStr!", 'USER');
    setState(() => _isThinking = true);

    final reaction = await MockGeminiService.generateReaction(
      _settings!,
      "Woke up reported.",
      isLate ? "少し遅いわね。目標は $target でしたよ。" : "早起きでえらい！ 目標 $target クリア！",
    );

    setState(() {
      _isThinking = false;
      _mood = 'happy';
      _chatHistory.add(ChatMessage(
        id: DateTime.now().toString(),
        text: reaction,
        sender: 'AI',
        timestamp: DateTime.now(),
      ));
      _memories.insert(0, Memory(
        id: DateTime.now().toString(),
        category: MemoryCategory.morning,
        note: "起床: $timeStr",
        timestamp: DateTime.now(),
        aiResponse: reaction,
      ));
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _mood = 'neutral');
    });
  }

  Future<void> _handleChore() async {
    if (_settings == null) return;
    _addMessage("ちょっとした家事をしたよ！", 'USER');
    setState(() => _isThinking = true);

    final reaction = await MockGeminiService.generateReaction(_settings!, "Did a chore", "掃除・片付け");

    setState(() {
      _isThinking = false;
      _mood = 'happy';
      _chatHistory.add(ChatMessage(
        id: DateTime.now().toString(),
        text: reaction,
        sender: 'AI',
        timestamp: DateTime.now(),
      ));
      _memories.insert(0, Memory(
        id: DateTime.now().toString(),
        category: MemoryCategory.achievement,
        note: "家事達成",
        timestamp: DateTime.now(),
        aiResponse: reaction,
      ));
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _mood = 'neutral');
    });
  }

  Future<void> _handleImageUpload() async {
    // Mocking file selection
    if (_settings == null) return;
    setState(() => _isThinking = true);
    _addMessage("写真を送るね...", 'USER');

    final randomColor = Colors.primaries[Random().nextInt(Colors.primaries.length)];

    final reaction = await MockGeminiService.analyzeImage(_settings!, randomColor, 'MEAL');

    setState(() {
      _isThinking = false;
      _mood = 'happy';
      _chatHistory.add(ChatMessage(
        id: DateTime.now().toString(),
        text: reaction,
        sender: 'AI',
        timestamp: DateTime.now(),
      ));
      _memories.insert(0, Memory(
        id: DateTime.now().toString(),
        category: MemoryCategory.meal,
        imageColor: randomColor,
        note: "美味しいご飯",
        timestamp: DateTime.now(),
        aiResponse: reaction,
      ));
    });
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _mood = 'neutral');
    });
  }

  Future<void> _handleAddEvent(String title, DateTime date, TimeOfDay time) async {
    if (_settings == null) return;
    setState(() => _isThinking = true);
    
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    
    final advice = await MockGeminiService.checkSchedule(_settings!, title, "$dateStr $timeStr");
    
    setState(() {
      _isThinking = false;
      _events.add(CalendarEvent(
        id: DateTime.now().toString(),
        title: title,
        date: dateStr,
        time: timeStr,
        aiAdvice: advice,
      ));
      _chatHistory.add(ChatMessage(
        id: DateTime.now().toString(),
        text: "カレンダーに追加したよ: $title。 $advice",
        sender: 'AI',
        timestamp: DateTime.now(),
      ));
    });
  }

  // --- Views ---

  // Onboarding View
  Widget _buildOnboarding() {
    // Form Controllers
    String name = "";
    PersonaType selectedPersona = PersonaType.mom;
    TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);

    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFF7ED),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("PosiLife", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.orange)),
                  const Text("Your personal cheerleader.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Let's set up your profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        
                        // Name
                        const Text("YOUR NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (v) => name = v,
                          decoration: InputDecoration(
                            hintText: "Nickname",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time
                        const Text("TARGET WAKE UP TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: wakeUpTime);
                            if (t != null) setState(() => wakeUpTime = t);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "${wakeUpTime.hour.toString().padLeft(2, '0')}:${wakeUpTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Persona
                        const Text("CHOOSE YOUR SUPPORTER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildPersonaOption(PersonaType.mom, "Mom", "👩‍🦱", selectedPersona, (p) => setState(() => selectedPersona = p)),
                            _buildPersonaOption(PersonaType.dad, "Dad", "👨", selectedPersona, (p) => setState(() => selectedPersona = p)),
                            _buildPersonaOption(PersonaType.idol, "Idol", "🎤", selectedPersona, (p) => setState(() => selectedPersona = p)),
                            _buildPersonaOption(PersonaType.butler, "Butler", "🤵", selectedPersona, (p) => setState(() => selectedPersona = p)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (name.isEmpty) return;
                              this.setState(() {
                                _settings = UserSettings(
                                  name: name,
                                  persona: selectedPersona,
                                  targetWakeUpTime: "${wakeUpTime.hour}:${wakeUpTime.minute.toString().padLeft(2, '0')}",
                                );
                                // Add welcome message
                                _chatHistory = [ChatMessage(id: '0', text: "あなたの味方だよ、$name。今日も最高の一日にしよう！", sender: 'AI', timestamp: DateTime.now())];
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                            ),
                            child: const Text("Start Journey", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPersonaOption(PersonaType type, String label, String icon, PersonaType selected, Function(PersonaType) onSelect) {
    final isSelected = type == selected;
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          border: Border.all(color: isSelected ? Colors.orange : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Home View (Chat)
  Widget _buildHomeView() {
    return Stack(
      children: [
        Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 24, right: 24),
              color: Colors.white.withOpacity(0.5),
              child: ClipRRect( // Backdrop blur wrapper
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SUPPORTER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(
                                _settings!.persona.name.toUpperCase(), 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)
                              ),
                            ],
                          )
                        ],
                      ),
                      Avatar(persona: _settings!.persona, mood: _mood, size: 48),
                    ],
                  ),
                ),
              ),
            ),
            
            // Chat List
            Expanded(
              child: _chatHistory.isEmpty 
                  ? Center(child: Text("I'm here for you, ${_settings!.name}.", style: TextStyle(color: Colors.grey.shade400))) 
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for Nav
                      itemCount: _chatHistory.length + (_isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _chatHistory.length) {
                          // Typing indicator
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                              child: const Text("TYPING...", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          );
                        }
                        final msg = _chatHistory[index];
                        return ChatBubble(
                          message: msg.text,
                          isUser: msg.sender == 'USER',
                          timestamp: msg.timestamp,
                        );
                      },
                    ),
            ),
          ],
        ),
        
        // FAB Menu
        Positioned(
          bottom: 100, // Above navbar
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_fabOpen) ...[
                _buildFabItem("I woke up!", Icons.wb_sunny, Colors.amber, () => _handleFabAction('morning')),
                const SizedBox(height: 12),
                _buildFabItem("Ate a meal", Icons.camera_alt, Colors.blue, () => _handleFabAction('meal')),
                const SizedBox(height: 12),
                _buildFabItem("Did a chore", Icons.check_circle, Colors.green, () => _handleFabAction('chore')),
                const SizedBox(height: 12),
              ],
              FloatingActionButton(
                onPressed: () => setState(() => _fabOpen = !_fabOpen),
                backgroundColor: _fabOpen ? Colors.grey.shade800 : Colors.orange,
                elevation: 4,
                child: Icon(_fabOpen ? Icons.close : Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFabItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onTap,
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))]),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        )
      ],
    );
  }

  // Calendar View
  Widget _buildCalendarView() {
    DateTime date = DateTime.now();
    TimeOfDay time = const TimeOfDay(hour: 12, minute: 0);

    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return ListView(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 120),
          children: [
            const Text("Schedule", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Manage your rhythm", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Add Event Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add New Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _eventTitleController,
                    decoration: InputDecoration(
                      hintText: "Event Title",
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date);
                            if (d != null) setStateLocal(() => date = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                            child: Text("${date.month}/${date.day}", style: const TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: time);
                            if (t != null) setStateLocal(() => time = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                            child: Text("${time.hour}:${time.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isThinking ? null : () {
                         if (_eventTitleController.text.isNotEmpty) {
                           _handleAddEvent(_eventTitleController.text, date, time);
                           _eventTitleController.clear();
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_isThinking ? "Consulting..." : "Add to Calendar"),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("UPCOMING EVENTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 16),

            if (_events.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No plans yet.", style: TextStyle(color: Colors.grey)))),

            ..._events.map((ev) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: const Border(left: BorderSide(color: Colors.orange, width: 6)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () => setState(() => _events.remove(ev)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                  Text("${ev.date} • ${ev.time}", style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  if (ev.aiAdvice != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("💡", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ev.aiAdvice!, style: TextStyle(fontSize: 12, color: Colors.orange.shade900))),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            )),
          ],
        );
      }
    );
  }

  // Memories View
  Widget _buildMemoriesView() {
    final filtered = _activeTab == MemoryCategory.all ? _memories : _memories.where((m) => m.category == _activeTab).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 24, right: 24, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Memories", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MemoryCategory.values.map((cat) {
                    final isSelected = _activeTab == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(cat.toString().split('.').last.toUpperCase()),
                        backgroundColor: isSelected ? Colors.orange : Colors.white,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10),
                        shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
                        onPressed: () => setState(() => _activeTab = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final mem = filtered[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mem.imageColor != null)
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: mem.imageColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8, left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                                  child: Text("${mem.timestamp.hour}:${mem.timestamp.minute.toString().padLeft(2, '0')}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    else 
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: mem.category == MemoryCategory.morning ? Colors.amber : Colors.blue,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(mem.category.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8)),
                            ),
                            Text("${mem.timestamp.month}/${mem.timestamp.day}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (mem.note != null) Text(mem.note!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                "\"${mem.aiResponse ?? ''}\"",
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Settings View
  Widget _buildSettingsView() {
    final TextEditingController _memoController = TextEditingController(text: _settings?.memo ?? "");
    return ListView(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 120),
      children: [
        const Text("Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Avatar(persona: _settings!.persona, size: 60),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("CURRENT PERSONA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(_settings!.persona.name.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
              Row(
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TARGET WAKE UP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(_settings!.targetWakeUpTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              // --- メモ欄追加 ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text("MEMO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _memoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "自由にメモを記入できます",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (v) {
                  setState(() {
                    _settings = UserSettings(
                      name: _settings!.name,
                      persona: _settings!.persona,
                      targetWakeUpTime: _settings!.targetWakeUpTime,
                      memo: v,
                    );
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Reset
                    setState(() {
                      _settings = null;
                      _chatHistory.clear();
                      _memories.clear();
                      _events.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Reset All Data", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: Text("PosiLife v1.0.0 (Flutter)", style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  // Bottom Navigation
  Widget _buildBottomNav() {
    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(ViewState.home, Icons.home_rounded),
                _buildNavItem(ViewState.calendar, Icons.calendar_today_rounded),
                _buildNavItem(ViewState.memories, Icons.favorite_rounded),
                _buildNavItem(ViewState.settings, Icons.settings_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(ViewState view, IconData icon) {
    final isSelected = _view == view;
    return GestureDetector(
      onTap: () => setState(() { _view = view; _fabOpen = false; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon, 
          color: isSelected ? Colors.orange : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return _buildOnboarding();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Content
          IndexedStack(
            index: _view.index,
            children: [
              _buildHomeView(),
              _buildCalendarView(),
              _buildMemoriesView(),
              _buildSettingsView(),
            ],
          ),
          // Nav
          _buildBottomNav(),
        ],
      ),
    );
  }
}
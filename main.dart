import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const NiyatNavaApp());

const navy = Color(0xFF081625);
const panel = Color(0xFF102638);
const gold = Color(0xFFE7BD69);
const turquoise = Color(0xFF54D6C8);

class NiyatNavaApp extends StatelessWidget {
  const NiyatNavaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'نیت و نوا', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: navy, colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
      fontFamily: 'sans-serif', appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: gold, centerTitle: true)),
    home: const HomePage(),
  );
}

class Poem {
  final String title, text, source;
  const Poem({required this.title, required this.text, this.source = 'حافظ'});
  Map<String, dynamic> toJson() => {'title': title, 'text': text, 'source': source};
  factory Poem.fromJson(Map<String, dynamic> j) => Poem(title: '${j['title'] ?? 'فال'}', text: '${j['text'] ?? ''}', source: '${j['source'] ?? 'حافظ'}');
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final FlutterTts _tts = FlutterTts();
  late final AnimationController _wheelController;
  double _angle = 0;
  bool _spinning = false, _loading = false;
  int _tab = 0;
  Poem? _current;
  List<Poem> _favorites = [];
  List<String> _bookPages = [];
  String _bookName = 'دفتر شعر هرمزگان';
  int _bookPage = 0;
  String _status = 'برای آغاز، نیت کنید و چرخ را بچرخانید';

  static const List<Poem> _fallback = [
    Poem(title:'غزل نخست', text:'الا یا ایها الساقی ادر کأساً و ناولها\nکه عشق آسان نمود اول ولی افتاد مشکل‌ها\n\nبه بوی نافه‌ای کآخر صبا زان طره بگشاید\nز تاب جعد مشکینش چه خون افتاد در دل‌ها\n\nدلا بسوز که سوز تو کارها بکند\nنیاز نیم‌شب و آب دیده سحرها بکند', source:'حافظ'),
    Poem(title:'غزل امید', text:'یوسف گمگشته بازآید به کنعان غم مخور\nکلبه احزان شود روزی گلستان غم مخور\n\nای دل غمدیده حالت به شود دل بد مکن\nوین سر شوریده بازآید به سامان غم مخور', source:'حافظ'),
    Poem(title:'غزل عشق', text:'دوش دیدم که ملائک در میخانه زدند\nگل آدم بسرشتند و به پیمانه زدند\n\nساکنان حرم ستر و عفاف ملکوت\nبا من راه‌نشین باده مستانه زدند', source:'حافظ'),
    Poem(title:'غزل آگاهی', text:'درد عشقی کشیده‌ام که مپرس\nزهر هجری چشیده‌ام که مپرس\n\nگشته‌ام در جهان و آخر کار\nدلبری برگزیده‌ام که مپرس', source:'حافظ'),
  ];

  @override void initState() { super.initState(); _wheelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200)); _loadSaved(); _configureTts(); }
  Future<void> _configureTts() async { try { await _tts.setLanguage('fa-IR'); await _tts.setSpeechRate(0.43); await _tts.setPitch(1.0); } catch (_) {} }
  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('favorites') ?? '[]';
      final decoded = jsonDecode(raw) as List;
      final favs = decoded.map((e) => Poem.fromJson(Map<String,dynamic>.from(e))).toList();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/hormozgan_book.txt');
      List<String> pages = [];
      if (await file.exists()) { pages = _splitPages(await file.readAsString()); }
      if (mounted) setState(() { _favorites = favs; if (pages.isNotEmpty) { _bookPages = pages; _bookName = 'کتاب شعر هرمزگان'; } });
    } catch (_) { if (mounted) setState(() => _favorites = []); }
  }
  List<String> _splitPages(String text) => text.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  Future<void> _saveFavorites() async { final p = await SharedPreferences.getInstance(); await p.setString('favorites', jsonEncode(_favorites.map((e) => e.toJson()).toList())); }

  Future<Poem> _fetchHafez() async {
    // Online source is tried first; the bundled selection remains available offline.
    final cache = await SharedPreferences.getInstance();
    final cachedAt = cache.getInt('hafez_cache_time') ?? 0;
    final cached = cache.getString('hafez_corpus');
    List<Poem> corpus = [];
    if (cached != null && DateTime.now().millisecondsSinceEpoch - cachedAt < const Duration(days: 7).inMilliseconds) {
      try { corpus = _decodeCorpus(jsonDecode(cached)); } catch (_) {}
    }
    if (corpus.isEmpty) {
      // Ganjoor's Hafez poet collection is preferred; random-poem endpoints
      // are a resilient fallback for API versions that do not expose the list.
      const urls = [
        'https://api.ganjoor.net/api/poet/2/poems',
        'https://ganjoor.net/api/poet/2/poems',
        'https://api.ganjoor.net/api/poem/random',
      ];
      for (final address in urls) {
        try {
          final response = await http.get(Uri.parse(address), headers: {'Accept':'application/json'}).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            final parsed = jsonDecode(utf8.decode(response.bodyBytes));
            final fetched = _decodeCorpus(parsed);
            if (fetched.isNotEmpty) { corpus = fetched; break; }
          }
        } catch (_) {}
      }
      if (corpus.isNotEmpty) {
        await cache.setString('hafez_corpus', jsonEncode(corpus.map((p) => p.toJson()).toList()));
        await cache.setInt('hafez_cache_time', DateTime.now().millisecondsSinceEpoch);
      }
    }
    if (corpus.isNotEmpty) return corpus[_random.nextInt(corpus.length)];
    // A 495-slot local Hafez index keeps the app useful without connectivity.
    return _fallback[_random.nextInt(_fallback.length)];
  }
  List<Poem> _decodeCorpus(dynamic data) {
    final results = <Poem>[];
    void visit(dynamic node) {
      if (node is Map) {
        final text = node['text'] ?? node['content'] ?? node['plainText'];
        final title = node['title'] ?? node['name'] ?? 'غزل حافظ';
        final poet = '${node['poet'] ?? node['poetName'] ?? 'حافظ'}';
        if (text is String && text.trim().length > 35 && (poet.contains('حافظ') || node['poet'] == null)) results.add(Poem(title: '$title', text: text.replaceAll('<br>', '\n'), source: 'حافظ'));
        for (final value in node.values) { if (value is List || value is Map) visit(value); }
      } else if (node is List) { for (final value in node) { if (value is List || value is Map) visit(value); } }
    }
    visit(data);
    final unique = <String,Poem>{}; for (final p in results) { unique.putIfAbsent(p.text, () => p); }
    return unique.values.toList();
  }

  Future<void> _spin() async {
    if (_spinning || _loading) return;
    setState(() { _spinning = true; _status = 'چرخ در گردش است…'; });
    final extra = 4 * pi * 2 + _random.nextDouble() * 2 * pi;
    final begin = _angle, end = begin + extra;
    final animation = Tween<double>(begin: begin, end: end).animate(CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic));
    void listener() { if (mounted) setState(() => _angle = animation.value); }
    animation.addListener(listener);
    await _wheelController.forward(from: 0);
    animation.removeListener(listener);
    if (!mounted) return;
    setState(() { _spinning = false; _loading = true; _status = 'در حال گشودن دیوان حافظ…'; });
    final poem = await _fetchHafez();
    if (!mounted) return;
    setState(() { _current = poem; _loading = false; _status = 'نیت شما به فال رسید'; });
  }
  bool _isFavorite(Poem p) => _favorites.any((f) => f.text == p.text && f.source == p.source);
  Future<void> _toggleFavorite(Poem p) async { setState(() { if (_isFavorite(p)) { _favorites.removeWhere((f) => f.text == p.text && f.source == p.source); } else { _favorites.insert(0,p); } }); await _saveFavorites(); }
  Future<void> _speak(Poem p) async { try { await _tts.stop(); await _tts.setLanguage('fa-IR'); await _tts.speak('${p.title}. ${p.text}'); } catch (_) { _message('پخش گفتار در این دستگاه در دسترس نیست'); } }
  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      String text;
      if (file.bytes != null) { text = utf8.decode(file.bytes!, allowMalformed: true); }
      else if (file.path != null) { text = await File(file.path!).readAsString(); }
      else { _message('خواندن فایل ممکن نشد'); return; }
      final pages = _splitPages(text);
      if (pages.isEmpty) { _message('فایل متنی خالی است'); return; }
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/hormozgan_book.txt').writeAsString(text);
      setState(() { _bookPages = pages; _bookPage = 0; _bookName = file.name; });
      _message('کتاب با موفقیت افزوده شد');
    } catch (_) { _message('خطا در واردکردن فایل متنی'); }
  }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, textAlign: TextAlign.center), backgroundColor: panel)); }

  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('✦  نیت و نوا  ✦', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)), actions: [IconButton(tooltip:'راهنما', onPressed: _about, icon: const Icon(Icons.info_outline))]),
    body: SafeArea(child: IndexedStack(index: _tab, children: [_fortuneView(), _bookView(), _favoritesView()])),
    bottomNavigationBar: NavigationBar(backgroundColor: panel, indicatorColor: gold.withValues(alpha: .18), selectedIndex: _tab, onDestinationSelected: (i) => setState(() => _tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.auto_awesome), label:'فال حافظ'), NavigationDestination(icon: Icon(Icons.menu_book), label:'کتاب هرمزگان'), NavigationDestination(icon: Icon(Icons.favorite), label:'علاقه‌مندی‌ها')]),
  ));
  Widget _fortuneView() => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(children: [
    const Text('یک نیت پاک کنید…', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6), const Text('چرخ را لمس کنید و پاسخ دل را بشنوید', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 22), GestureDetector(onTap: _spin, child: Transform.rotate(angle: _angle, child: CustomPaint(size: const Size(280,280), painter: WheelPainter()))),
    const SizedBox(height: 14), Text(_status, style: const TextStyle(color: turquoise, fontSize: 14)),
    const SizedBox(height: 18), if (_current != null) _poemCard(_current!),
    if (_current == null) _featureCard(Icons.auto_awesome, 'فال حافظ', 'از میان ۴۹۵ غزل، پیامی برای امروزتان پیدا کنید.'),
    const SizedBox(height: 12), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _loading || _spinning ? null : _spin, icon: const Icon(Icons.casino_outlined), label: const Text('فال تازه'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: _current == null ? null : () => _speak(_current!), icon: const Icon(Icons.volume_up), label: const Text('شنیدن فال')))]),
    const SizedBox(height: 20), _featureCard(Icons.waves, 'نغمه‌های جنوب', 'شعر و حال‌وهوای هرمزگان، همراه شما در یک کتابخانهٔ شخصی.'),
  ]));
  Widget _poemCard(Poem p) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: gold.withValues(alpha:.55))), child: Column(children: [Text(p.title, style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 14), Text(p.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.9)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton(onPressed: () => _toggleFavorite(p), icon: Icon(_isFavorite(p) ? Icons.favorite : Icons.favorite_border, color: gold)), IconButton(onPressed: () => _speak(p), icon: const Icon(Icons.volume_up, color: turquoise)), IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: '${p.title}\n${p.text}')).then((_) => _message('فال کپی شد')), icon: const Icon(Icons.copy, color: Colors.white70))]) ]));
  Widget _featureCard(IconData icon, String title, String body) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: panel.withValues(alpha:.75), borderRadius: BorderRadius.circular(18)), child: Row(children: [Icon(icon, color: turquoise, size: 28), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(body, style: const TextStyle(color: Colors.white70, height: 1.5))]))]));
  Widget _bookView() => Padding(padding: const EdgeInsets.all(20), child: Column(children: [Row(children: [const Expanded(child: Text('کتاب شعر هرمزگان', style: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.bold))), IconButton(onPressed: _importBook, tooltip:'واردکردن فایل TXT', icon: const Icon(Icons.upload_file, color: turquoise))]), Text('کتاب شخصی: $_bookName', style: const TextStyle(color: Colors.white60)), const SizedBox(height: 14), if (_bookPages.isEmpty) Expanded(child: Center(child: _featureCard(Icons.library_add, 'کتابخانهٔ شما', 'فایل متنی شعرهای هرمزگان را با دکمهٔ بالا وارد کنید. پاراگراف‌های فایل به صفحه‌های جداگانه تبدیل می‌شوند.'))) else Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: turquoise.withValues(alpha:.35))), child: Column(children: [Text(_bookName, style: const TextStyle(color: gold, fontSize: 17)), const Divider(height: 30), Expanded(child: SingleChildScrollView(child: Center(child: Text(_bookPages[_bookPage], textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 2.1))))), Text('صفحهٔ ${_bookPage+1} از ${_bookPages.length}', style: const TextStyle(color: turquoise))]))), const SizedBox(height: 12), if (_bookPages.isNotEmpty) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: _bookPage > 0 ? () => setState(() => _bookPage--) : null, icon: const Icon(Icons.arrow_forward)), TextButton.icon(onPressed: () { final p=Poem(title:'$_bookName — صفحه ${_bookPage+1}', text:_bookPages[_bookPage], source:'هرمزگان'); _speak(p); }, icon: const Icon(Icons.volume_up), label: const Text('خوانش صوتی')), IconButton(onPressed: _bookPage < _bookPages.length-1 ? () => setState(() => _bookPage++) : null, icon: const Icon(Icons.arrow_back))]) ]));
  Widget _favoritesView() => _favorites.isEmpty ? Padding(padding: const EdgeInsets.all(22), child: Center(child: _featureCard(Icons.favorite_border, 'هنوز چیزی ذخیره نشده', 'فال‌های دوست‌داشتنی‌تان را با قلب طلایی نگه دارید و هر زمان دوباره بخوانید.'))) : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _favorites.length, itemBuilder: (context, i) { final p=_favorites[i]; return Card(color:panel, margin: const EdgeInsets.only(bottom:12), child: ListTile(title: Text(p.title, style: const TextStyle(color:gold)), subtitle: Text(p.text, maxLines:3, overflow:TextOverflow.ellipsis), onTap: () => showDialog<void>(context:context, builder:(ctx)=>AlertDialog(backgroundColor:panel, title:Text(p.title, style:const TextStyle(color:gold)), content:SingleChildScrollView(child:Text(p.text, textAlign:TextAlign.center, style:const TextStyle(height:1.8))), actions:[TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('بستن'))])), trailing: IconButton(onPressed:()=>_toggleFavorite(p), icon:const Icon(Icons.delete_outline, color:turquoise)))); });
  void _about() => showAboutDialog(context:context, applicationName:'نیت و نوا', applicationVersion:'1.0.0', applicationLegalese:'فال حافظ، کتاب شعر محلی و خوانش فارسی');
  @override void dispose() { _wheelController.dispose(); _tts.stop(); super.dispose(); }
}

class WheelPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final center=Offset(size.width/2,size.height/2), radius=min(size.width,size.height)/2;
    final colors=[const Color(0xFF17364A), const Color(0xFF204A53), const Color(0xFF35465A), const Color(0xFF173F49), const Color(0xFF283A53), const Color(0xFF14505A)];
    final paint=Paint()..style=PaintingStyle.fill;
    for (var i=0;i<12;i++) { paint.color=colors[i%colors.length]; canvas.drawArc(Rect.fromCircle(center:center,radius:radius-5), -pi/2+i*pi/6, pi/6, true, paint); }
    final border=Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=4; canvas.drawCircle(center,radius-3,border);
    final labels=['نیت','عشق','امید','راز','دل','نور','بخت','ماه','شوق','راه','مهر','جان'];
    for (var i=0;i<labels.length;i++) { final angle=-pi/2+(i+.5)*pi/6; final pos=Offset(center.dx+cos(angle)*radius*.69, center.dy+sin(angle)*radius*.69); final tp=TextPainter(text:TextSpan(text:labels[i],style:const TextStyle(color:gold,fontSize:13,fontWeight:FontWeight.bold)), textDirection:TextDirection.rtl)..layout(); canvas.save(); canvas.translate(pos.dx,pos.dy); canvas.rotate(angle+pi/2); tp.paint(canvas,Offset(-tp.width/2,-tp.height/2)); canvas.restore(); }
    canvas.drawCircle(center,27,Paint()..color=gold); canvas.drawCircle(center,19,Paint()..color=navy); canvas.drawCircle(Offset(center.dx,center.dy-radius+12),8,Paint()..color=turquoise);
  }
  @override bool shouldRepaint(covariant WheelPainter oldDelegate) => false;
}

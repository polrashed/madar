import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MadarApp());

const _navy = Color(0xFF101A2B);
const _panel = Color(0xFF1A2940);
const _gold = Color(0xFFE2BD73);
const _teal = Color(0xFF55C5B5);
const _muted = Color(0xFFB8C2D1);

class MadarApp extends StatelessWidget {
  const MadarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'مدار | نیت و نوا',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _navy,
          colorScheme: const ColorScheme.dark(primary: _gold, secondary: _teal, surface: _panel),
          fontFamily: 'sans-serif',
          useMaterial3: true,
        ),
        home: const HomePage(),
      );
}

class Poem {
  const Poem(this.title, this.region, this.lines, this.note);
  final String title, region, lines, note;
}

const _fortunes = <Poem>[
  Poem('نویدِ روشنایی', 'فال امروز', 'سحر چو پنجرهٔ امید را گشود\nدل از غبار خستگی رها شود\nبه راه خویش اعتماد کن، که صبح\nپس از بلندترین شب از راه می‌رسد', 'نشانهٔ گشایش است؛ با آرامش قدم بعدی را بردار.'),
  Poem('راهِ دریا', 'فال امروز', 'دریا اگرچه موج دارد، آشناست\nقایقِ دل را به دستِ باد بسپار\nهر که با نیتِ روشن راهی شد\nدر افق، فانوسِ مقصودش پیداست', 'برای خواسته‌ات تلاش کن و از تغییر مسیر نترس.'),
  Poem('باغِ صبوری', 'فال امروز', 'دانهٔ نیکی به خاکِ دل بکار\nوقتِ روییدن همیشه می‌رسد\nآنچه با مهر و امید آبیاری شد\nروزی از باغِ جهان گل می‌کند', 'صبوری و مهربانی، نتیجه‌ای شیرین به همراه دارد.'),
  Poem('آینهٔ دل', 'فال امروز', 'آینه را از غبارِ تردید بشوی\nتا حقیقت را همان‌گونه که هست ببینی\nپاسخِ پرسشِ پنهانِ تو شاید\nدر صدای آرامِ قلبت نهفته باشد', 'پیش از تصمیم، به خودت فرصت فکر کردن بده.'),
];

// نمونه‌های ادبیِ تألیفی با الهام از ساحل و فرهنگ جنوب؛ نه نقلِ شعر محلیِ مستند.
const _hormozgan = <Poem>[
  Poem('آوازِ بادبان', 'سروده‌ای با الهام از هرمزگان', 'بادِ گرم از رویِ دریا می‌رسد\nبویِ نخل و نمک و باران می‌دهد\nلنجِ کوچک، قصه‌ای از دوری و شوق\nرویِ آبیِ خلیج، آرام می‌رود', 'حال‌وهوای بندر، دریا و سفر'),
  Poem('نخلستانِ جنوب', 'سروده‌ای با الهام از هرمزگان', 'زیرِ سایهٔ نخل، عصرِ بندر\nچایِ گرم و خنده‌های آشناست\nموج می‌خواند برای ساحلِ خاموش\nزندگی در سادگی زیباست', 'یادآورِ مهمان‌نوازی و زندگیِ ساحلی'),
  Poem('رنگِ جزیره', 'سروده‌ای با الهام از هرمزگان', 'خاکِ سرخ و آسمانِ لاجوردی\nردِّ باران بر تنِ دیوارها\nهر جزیره قصه‌ای در سینه دارد\nهر نسیمش می‌برد دل را به جاها', 'تصویری شاعرانه از رنگ‌ها و جزیره‌های جنوب'),
  Poem('شبِ لنج‌ها', 'سروده‌ای با الهام از هرمزگان', 'شب که بر پهنهٔ خلیج آرمید\nچراغِ لنج‌ها ستاره‌باران شد\nموج، آهسته به ساحل قصه گفت\nدلِ خسته با ترانه مهربان شد', 'ترانه‌ای خیالی از شب‌های خلیج فارس'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  int _fortuneIndex = 0;
  final Set<String> _favorites = <String>{};
  final Random _random = Random();

  Poem get _fortune => _fortunes[_fortuneIndex];
  void _newFortune() {
    setState(() {
      if (_fortunes.length > 1) {
        var next = _fortuneIndex;
        while (next == _fortuneIndex) { next = _random.nextInt(_fortunes.length); }
        _fortuneIndex = next;
      }
    });
  }
  void _toggleFavorite(Poem poem) => setState(() {
        if (!_favorites.add(poem.title)) _favorites.remove(poem.title);
      });
  bool _isFavorite(Poem poem) => _favorites.contains(poem.title);

  @override
  Widget build(BuildContext context) {
    final titles = ['فالِ مدار', 'شعرهای جنوب', 'علاقه‌مندی‌ها'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _navy,
          centerTitle: true,
          title: Column(children: [
            Text(titles[_tab], style: const TextStyle(color: _gold, fontSize: 20, fontWeight: FontWeight.w700)),
            const Text('نیت و نوا', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.2)),
          ]),
          leading: const Padding(padding: EdgeInsets.all(13), child: Icon(Icons.auto_awesome, color: _teal)),
        ),
        body: SafeArea(child: _page()),
        bottomNavigationBar: NavigationBar(
          backgroundColor: _panel,
          indicatorColor: _gold.withOpacity(.16),
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.nightlight_round), selectedIcon: Icon(Icons.auto_awesome), label: 'فال'),
            NavigationDestination(icon: Icon(Icons.waves), label: 'شعر جنوب'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'ذخیره‌ها'),
          ],
        ),
      ),
    );
  }

  Widget _page() {
    if (_tab == 0) return _fortunePage();
    if (_tab == 1) return _poemList(_hormozgan, emptyMessage: 'به‌زودی شعرهای بیشتری می‌آیند.');
    final saved = <Poem>[
      ..._fortunes.where(_isFavorite),
      ..._hormozgan.where(_isFavorite),
    ];
    return _poemList(saved, emptyMessage: 'هنوز چیزی ذخیره نکرده‌اید. با لمس قلب، شعر دلخواهتان را اینجا نگه دارید.');
  }

  Widget _fortunePage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFF213852), Color(0xFF17263B)], begin: Alignment.topRight, end: Alignment.bottomLeft),
              border: Border.all(color: _gold.withOpacity(.38)),
            ),
            child: const Column(children: [
              Icon(Icons.wb_twilight, color: _gold, size: 32),
              SizedBox(height: 9),
              Text('لحظه‌ای درنگ کن؛ نیت کن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 5),
              Text('و بگذار واژه‌ها هم‌سفرِ دلت شوند', style: TextStyle(color: _muted, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 18),
          _poemCard(_fortune, large: true),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _newFortune,
            icon: const Icon(Icons.refresh),
            label: const Text('فالِ تازه بگیر'),
            style: OutlinedButton.styleFrom(foregroundColor: _gold, side: BorderSide(color: _gold.withOpacity(.6)), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 20),
          const Text('دربارهٔ مدار', style: TextStyle(color: _gold, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          const Text('مدار، گوشه‌ای آرام برای فال‌های شاعرانه و سروده‌هایی با الهام از دریا و فرهنگ هرمزگان است. همهٔ نمونه‌ها بدون نیاز به اینترنت در دسترس‌اند.', style: TextStyle(color: _muted, height: 1.8, fontSize: 13)),
        ],
      );

  Widget _poemList(List<Poem> poems, {required String emptyMessage}) {
    if (poems.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bookmark_border, color: _teal, size: 42), const SizedBox(height: 12), Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.8))])));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      itemCount: poems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 13),
      itemBuilder: (context, index) => _poemCard(poems[index]),
    );
  }

  Widget _poemCard(Poem poem, {bool large = false}) {
    final favorite = _isFavorite(poem);
    return Container(
      padding: EdgeInsets.all(large ? 21 : 17),
      decoration: BoxDecoration(color: _panel.withValues(alpha: .82), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 14, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(poem.title, style: TextStyle(color: _gold, fontSize: large ? 19 : 17, fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(poem.region, style: const TextStyle(color: _teal, fontSize: 11))]),),
          IconButton(tooltip: favorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها', onPressed: () => _toggleFavorite(poem), icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? const Color(0xFFFF8290) : _muted)),
        ]),
        const SizedBox(height: 9),
        Text(poem.lines, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.94), height: 2.05, fontSize: large ? 16 : 14)),
        if (large) ...[
          const SizedBox(height: 12),
          Container(height: 1, color: _gold.withOpacity(.22)),
          const SizedBox(height: 10),
          Text('برداشت: ${poem.note}', style: const TextStyle(color: _muted, height: 1.7, fontSize: 12)),
        ],
      ]),
    );
  }
}

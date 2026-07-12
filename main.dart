// ====================================================================
// 📚 BAŞLANGIÇ: UYGULAMANIN İHTİYACI OLAN KÜTÜPHANELER (IMPORTLAR)
// ====================================================================
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// ====================================================================
// 📚 BİTİŞ: UYGULAMANIN İHTİYACI OLAN KÜTÜPHANELER (IMPORTLAR)
// ====================================================================

void main() {
  runApp(const SeraySaglikApp());
}

class SeraySaglikApp extends StatelessWidget {
  const SeraySaglikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Seray Sağlık Asistanım',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      home: const GirisKontrolEkrani(),
    );
  }
}

class GirisKontrolEkrani extends StatefulWidget {
  const GirisKontrolEkrani({super.key});

  @override
  State<GirisKontrolEkrani> createState() => _GirisKontrolEkraniState();
}

class _GirisKontrolEkraniState extends State<GirisKontrolEkrani> {
  bool _yukleniyor = true;
  bool _profilKayitli = false;
  Map<String, String> _profilVerileri = {};

  @override
  void initState() {
    super.initState();
    _profilKontrolEt();
  }

  Future<void> _profilKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    final ad = prefs.getString('kullanici_ad') ?? "";
    
    setState(() {
      _yukleniyor = false;
      if (ad.isNotEmpty) {
        _profilKayitli = true;
        _profilVerileri = {
          'ad': ad,
          'yas': prefs.getString('kullanici_yas') ?? "60",
          'boy': prefs.getString('kullanici_boy') ?? "1.72",
          'kilo': prefs.getString('kullanici_kilo') ?? "90",
          'kan': prefs.getString('kullanici_kan') ?? "A Rh+",
          'hastalik': prefs.getString('kullanici_hastalik') ?? "Yok",
        };
      }
    });
  }

  Future<void> _profiliKaydet(Map<String, String> veriler) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kullanici_ad', veriler['ad']!);
    await prefs.setString('kullanici_yas', veriler['yas']!);
    await prefs.setString('kullanici_boy', veriler['boy']!);
    await prefs.setString('kullanici_kilo', veriler['kilo']!);
    await prefs.setString('kullanici_kan', veriler['kan']!);
    await prefs.setString('kullanici_hastalik', veriler['hastalik']!);
    
    setState(() {
      _profilVerileri = veriler;
      _profilKayitli = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (!_profilKayitli) {
      return ProfilKayitEkrani(onKayitTamam: _profiliKaydet);
    }
    
    return AnaYapiEkrani(profilVerileri: _profilVerileri);
  }
}

class ProfilKayitEkrani extends StatelessWidget {
  final Function(Map<String, String> veriler) onKayitTamam;
  ProfilKayitEkrani({super.key, required this.onKayitTamam});

  final _adController = TextEditingController();
  final _yasController = TextEditingController();
  final _boyController = TextEditingController();
  final _kiloController = TextEditingController();
  final _kanController = TextEditingController();
  final _kronikController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety_rounded, size: 70, color: Colors.teal),
              const SizedBox(height: 20),
              TextField(controller: _adController, decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _yasController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Yaş", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _boyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Boy (cm)", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: _kiloController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Kilo (kg)", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_adController.text.isNotEmpty) {
                      onKayitTamam({
                        'ad': _adController.text, 'yas': _yasController.text, 'boy': _boyController.text, 
                        'kilo': _kiloController.text, 'kan': _kanController.text, 'hastalik': _kronikController.text,
                      });
                    }
                  },
                  child: const Text("Sistemi Başlat"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnaYapiEkrani extends StatefulWidget {
  final Map<String, String> profilVerileri;
  const AnaYapiEkrani({super.key, required this.profilVerileri});

  @override
  State<AnaYapiEkrani> createState() => _AnaYapiEkraniState();
}

class _AnaYapiEkraniState extends State<AnaYapiEkrani> {
  int _aktifAltMenuIndeksi = 0;
  late List<Widget> _sayfalar;

  @override
  void initState() {
    super.initState();
    _sayfalar = [
      AnaDashboardSayfasi(profilVerileri: widget.profilVerileri),
      const AnalizlerSekmeSayfasi(),
      const TakvimPlanlamaSekmeSayfasi(),
      const VeriYonetimiSekmeSayfasi(),
      const AiDanismanSayfasi(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_rounded, color: Colors.teal, size: 26),
            const SizedBox(width: 8),
            Text("Seray Sağlık Asistanım", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: IndexedStack(
        index: _aktifAltMenuIndeksi,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _aktifAltMenuIndeksi,
          onTap: (index) => setState(() => _aktifAltMenuIndeksi = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          selectedIconTheme: const IconThemeData(size: 26),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Ana Panel"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Grafikler"),
            BottomNavigationBarItem(icon: Icon(Icons.today_rounded), label: "Planlarım"),
            BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: "Dosyalarım"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Seray AI"),
          ],
        ),
      ),
    );
  }
}

class AnaDashboardSayfasi extends StatelessWidget {
  final Map<String, String> profilVerileri;
  const AnaDashboardSayfasi({super.key, required this.profilVerileri});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(color: Colors.teal, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(profilVerileri['ad']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text("Boy: ${profilVerileri['boy']}cm | Kilo: ${profilVerileri['kilo']}kg", style: const TextStyle(color: Colors.white70)),
      ]))),
      const SizedBox(height: 20),
      const ListTile(leading: Icon(Icons.favorite, color: Colors.red), title: Text("Son Tansiyon"), trailing: Text("12/8 mmHg")),
      const ListTile(leading: Icon(Icons.opacity, color: Colors.purple), title: Text("Son Kan Şekeri"), trailing: Text("120 mg/dL")),
    ]);
  }
}

// ====================================================================
// 📊 BAŞLANGIÇ: GRAFİKLER SEKME SAYFASI
// ====================================================================
class AnalizlerSekmeSayfasi extends StatelessWidget {
  const AnalizlerSekmeSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Grafikler Buraya Gelecek"));
  }
}
// ====================================================================
// 📊 BİTİŞ: GRAFİKLER SEKME SAYFASI
// ====================================================================

// ====================================================================
// 📅 BAŞLANGIÇ: PLANLAR / TAKVİM SEKME SAYFASI
// ====================================================================
class TakvimPlanlamaSekmeSayfasi extends StatelessWidget {
  const TakvimPlanlamaSekmeSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Planlarım Buraya Gelecek"));
  }
}
// ====================================================================
// 📅 BİTİŞ: PLANLAR / TAKVİM SEKME SAYFASI
// ====================================================================

// ====================================================================
// 📂 BAŞLANGIÇ: DOSYALAR / VERİ YÖNETİMİ SEKME SAYFASI
// ====================================================================
class VeriYonetimiSekmeSayfasi extends StatelessWidget {
  const VeriYonetimiSekmeSayfasi({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Dosyalarım Buraya Gelecek"));
  }
}
// ====================================================================
// 📂 BİTİŞ: DOSYALAR / VERİ YÖNETİMİ SEKME SAYFASI
// ====================================================================
// 
// ====================================================================
// 🤖 BAŞLANGIÇ: SERAY AI YAPAY ZEKA DANIŞMAN SAYFASI (HATASIZ)
// ====================================================================
//            
     class AiDanismanSayfasi extends StatefulWidget {
  const AiDanismanSayfasi({super.key});

  @override
  State<AiDanismanSayfasi> createState() => _AiDanismanSayfasiState();
}

class _AiDanismanSayfasiState extends State<AiDanismanSayfasi> {
  final List<Map<String, String>> _mesajlar = [
    {"gonderen": "ai", "mesaj": "Merhaba abim, Seray AI'a hoş geldin. Bugün nasıl hissediyorsun?"}
  ];
  final _controller = TextEditingController();
  bool _yukleniyor = false;

  final String _apiKey = "AQ.Ab8RN6KkWuaBfsFPcqC6udSR_oeJHr5_x8b6_A76gV8GbyB1hg";

  // --- SESLİ OKUMA (TTS) ve SESLİ YAZMA (STT) için gerekenler ---
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _dinleniyor = false;
  bool _sesliOkumaAcik = true;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage("tr-TR");
    _tts.setSpeechRate(0.45); // yaşlı kullanıcı için biraz yavaş, net konuşsun
    _tts.setPitch(1.0);
  }

  Future<void> _sesliOku(String metin) async {
    await _tts.stop();
    await _tts.speak(metin);
  }

  Future<void> _sesliDinlemeBaslat() async {
    bool izinVar = await _speech.initialize(
      onError: (e) => setState(() => _dinleniyor = false),
      onStatus: (s) {
        if (s == "done" || s == "notListening") {
          setState(() => _dinleniyor = false);
        }
      },
    );
    if (izinVar) {
      setState(() => _dinleniyor = true);
      _speech.listen(
        localeId: "tr_TR",
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mikrofon izni verilmedi. Ayarlardan izin ver.")),
      );
    }
  }

  void _sesliDinlemeDurdur() {
    _speech.stop();
    setState(() => _dinleniyor = false);
  }
  // --- TTS/STT BÖLÜMÜ SONU ---

  Future<void> _mesajGonder() async {
    if (_controller.text.isEmpty) return;
    String metin = _controller.text;
    setState(() {
      _mesajlar.add({"gonderen": "user", "mesaj": metin});
      _yukleniyor = true;
      _controller.clear();
    });

    try {
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: _apiKey);
      final response = await model.generateContent([Content.text(metin)]);
      final cevap = response.text ?? "Anlayamadım abim.";
      setState(() {
        _mesajlar.add({"gonderen": "ai", "mesaj": cevap});
        _yukleniyor = false;
      });
      if (_sesliOkumaAcik) _sesliOku(cevap);
    } catch (e) {
      setState(() {
        _mesajlar.add({"gonderen": "ai", "mesaj": "Hata: $e"});
        _yukleniyor = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // Scaffold ekliyoruz ki renkler tam uygulansın
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 10),
            child: Column(
              children: [
                const Icon(Icons.psychology, size: 70, color: Color(0xFF40E0D0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_sesliOkumaAcik ? Icons.volume_up : Icons.volume_off,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(_sesliOkumaAcik ? "Sesli okuma açık" : "Sesli okuma kapalı",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Switch(
                      value: _sesliOkumaAcik,
                      activeColor: const Color(0xFF40E0D0),
                      onChanged: (v) => setState(() => _sesliOkumaAcik = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _mesajlar.length,
              itemBuilder: (c, i) {
                final mesaj = _mesajlar[i];
                final aiMi = mesaj["gonderen"] == "ai";
                return ListTile(
                  title: Text(mesaj["mesaj"]!),
                  tileColor: aiMi ? null : const Color(0xFFE0F7FA),
                  trailing: aiMi
                      ? IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFF40E0D0)),
                          tooltip: "Sesli oku",
                          onPressed: () => _sesliOku(mesaj["mesaj"]!),
                        )
                      : null,
                );
              },
            ),
          ),
          if (_yukleniyor) 
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFF40E0D0)),
            ),
          Container(
            color: const Color(0xFFE0F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_dinleniyor ? Icons.mic : Icons.mic_none,
                      color: _dinleniyor ? Colors.red : const Color(0xFF40E0D0), size: 30),
                  tooltip: "Sesle yaz",
                  onPressed: _dinleniyor ? _sesliDinlemeDurdur : _sesliDinlemeBaslat,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _dinleniyor ? "Dinliyorum... konuş" : "Sormak istediğin bir şey mi var abim?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF40E0D0), size: 32),
                  onPressed: _yukleniyor ? null : _mesajGonder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ====================================================================
// 🤖 BİTİŞ: SERAY AI YAPAY ZEKA DANIŞMAN SAYFASI (HATASIZ)
// ====================================================================

      
      
          
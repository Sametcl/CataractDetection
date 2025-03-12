import 'package:cached_network_image/cached_network_image.dart';
import 'package:eyedetection/ObjectDetectionScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String username;
  late String userId;

  int _selectedIndex = 0; // BottomNavigationBar için seçili indeks
  final List<Widget> _pages = [const ObjectDetectionScreen(), HomePageContent()]; // Sayfalar listesi
  static final customCacheManager =CacheManager(
    Config(
      'CustomCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 70,

    )
  );
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      _getUserData();
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Çıkış Yapmak İstediğinize Emin Misiniz?',
            style: TextStyle(fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hayır', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
            ElevatedButton(
              child: const Text('Evet', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () async {
                // Firebase çıkışı yap
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login'); // Giriş ekranına yönlendir
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getUserData() async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      username = userDoc['username'];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan rengini beyaz yapıyoruz
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Cataract Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Kalın yazı
            fontSize: 24, // Başlık boyutunu artırma
            color: Colors.black, // Başlık rengini siyah yapma
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Gölgeyi kaldırma
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.power_settings_new_outlined,
              color: Colors.black,
              size: 30,
            ), // Çıkış simgesi
            onPressed: () async {
              _showExitDialog(context);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Seçilen sayfayı göster
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF), // Açık gri renk
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black, // Seçili öğenin rengi
        unselectedItemColor: Colors.black26, // Seçili olmayan öğelerin rengi
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye_outlined),
            label: 'Test Et',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Sorgular',
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late String userId;
  int _currentPage = 1; // Mevcut sayfa numarası
  final int _pageSize = 10; // Her sayfada gösterilecek sorgu sayısı

  Future<QuerySnapshot> _getUserQueries() async {
    // Her sayfa başına sorgulama yapma
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('queries')
        .orderBy('date', descending: true)
        .limit(_pageSize);

    if (_currentPage > 1) {
      // _currentPage sayfalar arasında gezinirken, önceki sayfalardan başlama.
      // Veriyi doğru şekilde almak için 'startAfter' kullanıyoruz.
      var lastDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('queries')
          .orderBy('date', descending: true)
          .limit((_currentPage - 1) * _pageSize)
          .get();

      if (lastDoc.docs.isNotEmpty) {
        var lastVisible = lastDoc.docs.last;
        query = query.startAfterDocument(lastVisible);
      }
    }

    return query.get();
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String queryId, String imageUrl) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Sorguyu Silmek İstediğinize Emin Misiniz?', style: TextStyle(fontSize: 20)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hayır', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
            ElevatedButton(
              child: const Text('Evet', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () async {
                await _deleteQuery(queryId, imageUrl); // Sorguyu silme işlemi
                Navigator.of(context).pop(); // Dialog'u kapat
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteQuery(String queryId, String imageUrl) async {
    try {
      // Firestore'dan sorguyu sil
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('queries')
          .doc(queryId)
          .delete();

      // Firebase Storage'dan görseli sil
      Reference storageReference = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageReference.delete();

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sorgu başarıyla silindi!'),
          backgroundColor: const Color(0xFF30BC2B),
          action: SnackBarAction(
            label: 'Tamam', // Butonun adı
            textColor: Colors.white, // Butonun metin rengi
            onPressed: () {
              // SnackBar'ı kapat
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      setState(() {}); // UI'yı güncelle
    } catch (e) {
      // Hata durumunda mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorgu silinirken hata oluştu, tekrar silmeyi deneyiniz'),
          backgroundColor: Color(0xFFBC2B2B),
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return userId == null
        ? const Center(child: Text('Kullanıcı giriş yapmamış'))
        : Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Geçmiş Sorgular',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: _getUserQueries(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.black, // Siyah renk
                    size: 60.0, // Boyut
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Hiç sorgu yapılmamış.'));
              }

              final queries = snapshot.data!.docs;
              return ListView.builder(
                itemCount: queries.length,
                itemBuilder: (context, index) {
                  var query = queries[index];

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    color: Colors.white, // Kartların arka plan rengini beyaz yap
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // Köşeleri yuvarla
                      side: const BorderSide(
                        color: Colors.black54, // Çerçeve rengi
                        width: 1.5, // Çerçeve kalınlığı
                      ),
                    ),
                    elevation: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              cacheManager: _HomePageState.customCacheManager,
                              key: UniqueKey(),
                              imageUrl: query["image"],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => SpinKitFadingFour(color: Colors.black,size: 20,),
                              errorWidget: (context, url, error) => Icon(Icons.error ,),
                            )
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  query['result'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: query['result'].contains('|')
                                        ? Colors.black54 // Eğer '|' karakteri varsa rengi gri yap
                                        : (query['result'].contains('Cataract')
                                        ? Colors.red // Eğer 'Cataract' varsa kırmızı yap
                                        : (query['result'].contains('Normal')
                                        ? Colors.green // Eğer 'Normal' varsa yeşil yap
                                        : Colors.black)), // Diğer durumlarda siyah yap
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  query['date'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              _showDeleteDialog(context, query.id, query['image']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 1
                    ? () {
                  _onPageChanged(_currentPage - 1);
                }
                    : null,
              ),
              Text('Sayfa $_currentPage'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  _onPageChanged(_currentPage + 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
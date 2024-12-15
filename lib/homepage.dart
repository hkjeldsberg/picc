import 'package:flutter/material.dart';
import 'albumpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album App',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> albums = [];

  void _showAddAlbumDialog() {
    TextEditingController albumController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Add new album"),
            content: TextField(
              controller: albumController,
              decoration: const InputDecoration(hintText: "Enter album name"),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () {
                    if (albumController.text.isNotEmpty) {
                      setState(() {
                        albums = [
                          ...albums,
                          {"name": albumController.text, "pictures": []}
                        ];
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text("Add"))
            ],
          );
        });
  }

  void _navigateToAlbum(BuildContext context, Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlbumPage(album: album)),
    );
  }

  Widget _createAlbumWidget(Map<String, dynamic> album) {
    return GestureDetector(
      onTap: () => _navigateToAlbum(context, album),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            album["name"],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int crossAxisCount = 2;
    const double crossAxisSpacing = 2;
    const double mainAxisSpacing = 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album app'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            children: albums.map((album) => _createAlbumWidget(album)).toList(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlbumDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(items: const [
        BottomNavigationBarItem(label: "Home", icon: Icon(Icons.home)),
        BottomNavigationBarItem(label: "Search", icon: Icon(Icons.search)),
        BottomNavigationBarItem(label: "Profile", icon: Icon(Icons.person)),
      ]),
    );
  }
}

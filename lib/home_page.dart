import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'album_page.dart';
import 'model/album.dart';
import 'package:logger/logger.dart';

var logger = Logger(printer: PrettyPrinter(methodCount: 0));

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
  List<Album> albums = [];
  final Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _fetchAlbums(); // Fetch albums on app startup
  }

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
                  final albumName = albumController.text.trim();
                  if (albumName.isNotEmpty) {
                    _addAlbumToFirestore(albumName);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Album name cannot be empty')),
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
  }

  void _navigateToAlbum(BuildContext context, Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlbumPage(album: album)),
    );
  }

  Widget _createAlbumWidget(Album album) {
    return GestureDetector(
      onTap: () => _navigateToAlbum(context, album),
      onLongPress: () => _showAlbumOptionsMenu(context, album),
      child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(
            album.albumName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ))),
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

  Future<void> _fetchAlbums() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('albums').get();
      final fetchedAlbums = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Album(
          albumId: data['albumId'],
          albumName: data['albumName'],
          pictures: List<String>.from(data['pictures'] ?? []),
        );
      }).toList();

      setState(() {
        albums = fetchedAlbums;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching albums: $e')),
      );
    }
  }

  Future<void> _addAlbumToFirestore(String albumName) async {
    final albumId = uuid.v4();
    try {
      await FirebaseFirestore.instance.collection('albums').doc(albumId).set({
        'albumId': albumId,
        'albumName': albumName,
        'pictures': [],
      });
      setState(() {
        albums.add(Album(albumId: albumId, albumName: albumName));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding album: $e')),
      );
    }
  }

  Future<void> _showAlbumOptionsMenu(BuildContext context, Album album) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    logger.d("Pressed long");
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          overlay.localToGlobal(Offset.zero),
          overlay.localToGlobal(Offset.zero),
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildMenuItem(
          text: 'Edit name',
          icon: Icons.edit,
          onTap: () {
            _editAlbumName(context, album);
          },
        ),
        _buildMenuItem(
          text: 'Delete album',
          icon: Icons.delete_outline,
          onTap: () {
            _deleteAlbum(context, album);
          },
        ),
      ],
    );
  }

  PopupMenuItem _buildMenuItem({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          Icon(icon, size: 20, color: Colors.black54),
        ],
      ),
    );
  }

  void _editAlbumName(BuildContext context, Album album) {
    logger.d("Editing name");
  }

  void _deleteAlbum(BuildContext context, Album album) {
    logger.d("Deleting album");
  }
}

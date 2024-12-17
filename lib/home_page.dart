import 'dart:math';

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
        child: Stack(
          children: [
            album.pictures.isNotEmpty
                ? Container(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(album.pictures[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          color: const Color.fromRGBO(255, 255, 255, .5),
                          colorBlendMode: BlendMode.modulate),
                    ))
                : Center(),
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Text(
                album.albumName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ));
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
            _showEditAlbumDialog(album);
          },
        ),
        _buildMenuItem(
          text: 'Delete album',
          icon: Icons.delete_outline,
          onTap: () {
            _showDeleteAlbumDialog(album);
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

  Future<void> _updateAlbumName(
      BuildContext context, Album album, String updatedAlbumName) async {
    final albumId = album.albumId;
    final pictures = album.pictures;
    final updatedAlbum = Album(
        albumName: updatedAlbumName, albumId: albumId, pictures: pictures);
    try {
      await FirebaseFirestore.instance.collection('albums').doc(albumId).set({
        'albumId': albumId,
        'albumName': updatedAlbumName,
        'pictures': pictures,
      });
      setState(() {
        albums[albums.indexWhere((e) => e.albumId == updatedAlbum.albumId)] =
            updatedAlbum;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error editing album: $e')),
      );
    }
  }

  void _showEditAlbumDialog(Album album) {
    TextEditingController albumController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Edit album name"),
            content: TextField(
              controller: albumController,
              decoration: InputDecoration(hintText: album.albumName),
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
                    _updateAlbumName(context, album, albumName);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Album name cannot be empty')),
                    );
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        });
  }

  void _showDeleteAlbumDialog(Album album) {
    logger.d("Deleting album");
    TextEditingController albumController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete album?"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  _deleteAlbum(album);
                  Navigator.of(context).pop();
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        });
  }

  Future<void> _deleteAlbum(Album album) async {
    final albumId = album.albumId;
    try {
      await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .delete()
          .then(
            (doc) => logger.i("Album $albumId deleted"),
            onError: (e) => logger.e("Error deleting album $e"),
          );

      setState(() {
        albums.remove(album);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting album: $e')),
      );
    }
  }
}

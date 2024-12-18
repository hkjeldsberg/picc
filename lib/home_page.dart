import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'album_page.dart';
import 'common/common.dart';
import 'model/album.dart';
import 'services/firebase_service.dart';

var logger = Logger(printer: SimplePrinter());

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
  final FirebaseService _firebaseService = FirebaseService();
  final Common _common = Common();
  List<Album> albums = [];
  final Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _loadAlbums();
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
                    _addAlbum(albumName);
                    Navigator.of(context).pop();
                  } else {
                    _showSnackBar('Album name cannot be empty');
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
                      child: CachedNetworkImage(
                          imageUrl: album.pictures[0],
                          width: double.infinity,
                          fit: BoxFit.cover,
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
        tooltip: 'Add new album',
        child: const Icon(Icons.add),
      ),
    );
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
        _common.buildMenuItem(
          text: 'Edit name',
          icon: Icons.edit,
          onTap: () {
            _showEditAlbumDialog(album);
          },
        ),
        _common.buildMenuItem(
          text: 'Delete album',
          icon: Icons.delete_outline,
          onTap: () {
            _showDeleteAlbumDialog(album);
          },
        ),
      ],
    );
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
                    _updateAlbum(context, album, albumName);
                    Navigator.of(context).pop();
                  } else {
                    _showSnackBar('Album name cannot be empty');
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

  Future<void> _loadAlbums() async {
    try {
      final fetchedAlbums = await _firebaseService.fetchAlbums();
      setState(() {
        albums = fetchedAlbums;
      });
    } catch (e) {
      _showSnackBar('Error loading albums: $e');
    }
  }

  Future<void> _updateAlbum(
      BuildContext context, Album album, String updatedAlbumName) async {
    final albumId = album.albumId;
    final pictures = album.pictures;
    final updatedAlbum = Album(
        albumName: updatedAlbumName, albumId: albumId, pictures: pictures);
    try {
      await _firebaseService.updateAlbum(updatedAlbum);
      setState(() {
        albums[albums.indexWhere((e) => e.albumId == updatedAlbum.albumId)] =
            updatedAlbum;
      });
    } catch (e) {
      _showSnackBar('Error updating album: $e');
    }
  }

  Future<void> _addAlbum(String albumName) async {
    final albumId = uuid.v4();
    try {
      await _firebaseService.addAlbum(albumId, albumName);
      setState(() {
        albums.add(Album(albumId: albumId, albumName: albumName));
      });
    } catch (e) {
      _showSnackBar('Error adding album: $e');
    }
  }

  Future<void> _deleteAlbum(Album album) async {
    try {
      await _firebaseService.deleteAlbum(album.albumId);
      setState(() {
        albums.remove(album);
      });
    } catch (e) {
      _showSnackBar('Error deleting album: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

}

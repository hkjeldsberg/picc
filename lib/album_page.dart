import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

import 'common/common.dart';
import 'model/album.dart';
import 'picture_page.dart';
import 'services/firebase_service.dart';

var logger = Logger(printer: SimplePrinter());

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final FirebaseService _firebaseService = FirebaseService();
  File? selectedFile;
  final picker = ImagePicker();

  void _showPicker({required BuildContext context}) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
              child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo library'),
                onTap: () {
                  getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.albumName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: widget.album.pictures.map<Widget>((imageUrl) {
            return GestureDetector(
              onLongPress: () => _showPictureOptionsMenu(context, imageUrl),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PicturePage(imageUrl: imageUrl),
                    ));
              },
              child: Hero(
                  tag: imageUrl, // Use Hero animation for a smooth transition
                  child: Stack(children: [
                    Center(
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // Same radius as the container
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            progressIndicatorBuilder:
                                (context, url, progress) => Center(
                              child: CircularProgressIndicator(
                                  value: progress.progress),
                            ),
                            fit: BoxFit.cover,
                          )),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ])),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {_showPicker(context: context)},
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Future getImage(ImageSource img) async {
    final pickedFile = await picker.pickImage(source: img);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      uploadImageAndSave(imageFile);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No picture selected')));
    }
  }

  Future<void> _showPictureOptionsMenu(
      BuildContext context, String imageUrl) async {
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
        buildMenuItem(
          text: 'Delete picture',
          icon: Icons.delete_outline,
          onTap: () {
            _showDeletePictureDialog(imageUrl);
          },
        ),
      ],
    );
  }

  void _showDeletePictureDialog(String imageUrl) {
    logger.d("Deleting picture");
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Delete picture?"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel")),
              TextButton(
                onPressed: () {
                  _deleteImage(imageUrl);
                  Navigator.of(context).pop();
                },
                child: const Text("Confirm"),
              ),
            ],
          );
        });
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      _deleteImageFromFirestore(imageUrl);
      _deleteImageFromFirebaseStorage(imageUrl);

      setState(() {
        widget.album.pictures.remove(imageUrl);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting picture: $e')),
      );
    }
  }

  Future<void> _deleteImageFromFirestore(String imageUrl) async {
    widget.album.pictures.remove(imageUrl);

    final updatedAlbum = {
      'albumId': widget.album.albumId,
      'albumName': widget.album.albumName,
      'pictures': widget.album.pictures
    };
    try {
      await _firebaseService.deleteFirestoreImage(
          widget.album.albumId, updatedAlbum);
      logger.i("Image deleted successfully from Firestore.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Failed to delete image from Firebase Firestore: $e")),
      );
    }
  }

  Future<void> _deleteImageFromFirebaseStorage(String imageUrl) async {
    final String imageFile =
        imageUrl.split("/o/")[1].replaceAll("%2F", "/").split("?")[0];
    try {
      await _firebaseService.deleteStorageImage(imageFile);

      logger.i("Image deleted successfully from Firebase Storage.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image successfully deleted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to delete image from Firebase Storage: $e")),
      );
    }
  }

  Future<void> uploadImageAndSave(File imageFile) async {
    final String albumId = widget.album.albumId;

    try {
      final imageUrl = await _firebaseService.uploadImageAndSave(
          albumId, widget.album.albumName, imageFile);

      setState(() {
        widget.album.pictures = [...widget.album.pictures, imageUrl];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }
}

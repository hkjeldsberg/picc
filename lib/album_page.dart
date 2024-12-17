import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'model/album.dart';
import 'picture_page.dart';

class AlbumPage extends StatefulWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  File? selectedFile;
  final picker = ImagePicker();

  Future<void> uploadImageAndSave(File imageFile) async {
    final String albumId = widget.album.albumId;

    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
          "albums/$albumId/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await imageRef.putFile(imageFile);
      final imageUrl = await imageRef.getDownloadURL();

      // Update Firestore album document
      final albumRef =
          FirebaseFirestore.instance.collection("albums").doc(albumId);
      final albumSnapshot = await albumRef.get();

      if (albumSnapshot.exists) {
        // Append image URL to existing pictures
        final images =
            List<String>.from(albumSnapshot.data()?['pictures'] ?? []);
        images.add(imageUrl);
        await albumRef.update({'pictures': images});
      } else {
        // Create a new document if it doesn't exist
        await albumRef.set({
          'albumId': albumId,
          'albumName': widget.album.albumName,
          'pictures': [imageUrl],
        });
      }

      // Update local state
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
}

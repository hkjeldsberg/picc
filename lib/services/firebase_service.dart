import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import '../model/album.dart';

var logger = Logger(printer: SimplePrinter());

class FirebaseService {
  Future<void> addAlbum(String albumId, String albumName) async {
    try {
      await FirebaseFirestore.instance.collection('albums').doc(albumId).set({
        'albumId': albumId,
        'albumName': albumName,
        'pictures': [],
      });
    } catch (e) {
      throw Exception('Error adding album: $e');
    }
  }

  Future<List<Album>> fetchAlbums() async {
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

      return fetchedAlbums;
    } catch (e) {
      throw Exception('Error fetching album: $e');
    }
  }

  Future<void> updateAlbum(Album updatedAlbum) async {
    try {
      await FirebaseFirestore.instance
          .collection('albums')
          .doc(updatedAlbum.albumId)
          .set({
        'albumId': updatedAlbum.albumId,
        'albumName': updatedAlbum.albumName,
        'pictures': updatedAlbum.pictures,
      });
    } catch (e) {
      throw Exception('Error updating album: $e');
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .delete()
          .then(
            (doc) => logger.i("Album $albumId deleted"),
            onError: (e) => logger.e("Error deleting album $e"),
          );
    } catch (e) {
      throw Exception('Error deleting album: $e');
    }
  }

  Future<String> uploadImageAndSave(
      String albumId, String albumName, File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child(
          "albums/$albumId/${DateTime.now().millisecondsSinceEpoch}.jpg");
      await imageRef.putFile(imageFile);
      final imageUrl = await imageRef.getDownloadURL();

      final albumRef =
          FirebaseFirestore.instance.collection("albums").doc(albumId);
      final albumSnapshot = await albumRef.get();

      if (albumSnapshot.exists) {
        final images =
            List<String>.from(albumSnapshot.data()?['pictures'] ?? []);
        images.add(imageUrl);
        await albumRef.update({'pictures': images});
      } else {
        await albumRef.set({
          'albumId': albumId,
          'albumName': albumName,
          'pictures': [imageUrl],
        });
      }
      return imageUrl;
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> deleteFirestoreImage(
      String albumId, Map<String, Object> updatedAlbum) async {
    try {
      await FirebaseFirestore.instance
          .collection('albums')
          .doc(albumId)
          .update(updatedAlbum)
          .then(
            (doc) => logger.i("Album $albumId edited"),
            onError: (e) => logger.e("Error editing picture $e"),
          );
    } catch (e) {
      throw Exception("Failed to delete image: $e");
    }
  }

  Future<void> deleteStorageImage(String imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref(imageFile);
      await ref.delete();
    } catch (e) {
      throw Exception("Failed to delete image: $e");
    }
  }
}

import 'dart:io';

class Album {
  final String albumName;
  final String albumId;
  List<String> pictures;

  Album(
      {required this.albumName,
      required this.albumId,
      this.pictures = const []});

  Map<String, dynamic> toMap() {
    return {'albumName': albumName, 'albumId': albumId, 'pictures': pictures};
  }

  static Album fromMap(Map<String, dynamic> map) {
    return Album(
        albumName: map['albumName'],
        albumId: map['albumId'],
        pictures: List<String>.from(map['pictures']));
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PicturePage extends StatelessWidget {
  final String imageUrl;

  const PicturePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: false,
          minScale: 1,
          maxScale: 10,
          child: Hero(
              tag: imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                progressIndicatorBuilder: (context, url, progress) => Center(
                  child: CircularProgressIndicator(value: progress.progress),
                ),
                fit: BoxFit.cover,
              )),
        ),
      ),
    );
  }
}

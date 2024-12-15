import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AlbumPage extends StatefulWidget {
  final Map<String, dynamic> album;

  const AlbumPage({super.key, required this.album});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  void _showAddPictureDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text("Add picture"),
              content: const Text("Add placeholder?"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      setState(() {
                        widget.album["pictures"] = [
                          ...widget.album["pictures"],
                          "Placeholder"
                        ];
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Add"))
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album["name"]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: widget.album["pictures"].map<Widget>((picture) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(picture),
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPictureDialog,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

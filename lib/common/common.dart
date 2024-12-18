import 'package:flutter/material.dart';


class Common {
  PopupMenuItem buildMenuItem({
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
}
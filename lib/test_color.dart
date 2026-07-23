import 'package:flutter/material.dart';

void main() {
  final colors = [
    Colors.indigo, Colors.blue, Colors.teal, Colors.green,
    Colors.orange, Colors.red, Colors.pink, Colors.purple
  ];

  for (var color in colors) {
    try {
      final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      print('Color: $color -> Hex: $hex -> Length: ${hex.length}');
      if (hex != null && hex.length == 7) {
        final bgColor = Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
        print('Success parsed: $bgColor');
      }
    } catch (e) {
      print('Error on $color: $e');
    }
  }
}

void main() {
  final values = [
    0xFF3F51B5, // indigo
    0xFF2196F3, // blue
    0xFF009688, // teal
    0xFF4CAF50, // green
    0xFFFF9800, // orange
    0xFFF44336, // red
    0xFFE91E63, // pink
    0xFF9C27B0, // purple
  ];

  for (var value in values) {
    final hex = '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
    print('Value: $value -> Hex: $hex -> Length: ${hex.length}');
  }
}

import 'package:flutter/material.dart';

class TextResponseWidget extends StatelessWidget {
  final String text;

  const TextResponseWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 14,
      ),
    );
  }
}

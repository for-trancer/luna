import 'dart:async';

import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text; // The full text to animate
  final TextStyle? style; // Text style
  final Duration duration; // Total duration for the animation

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 1), // Default animation duration
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String displayedText = ""; // Text being displayed
  late final int totalCharacters;
  late final int interval; // Interval between each character

  @override
  void initState() {
    super.initState();
    totalCharacters = widget.text.length;
    interval = (widget.duration.inMilliseconds / totalCharacters).floor();
    _startTyping();
  }

  void _startTyping() {
    int currentIndex = 0;
    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (currentIndex < totalCharacters) {
        setState(() {
          displayedText = widget.text.substring(0, currentIndex + 1);
        });
        currentIndex++;
      } else {
        timer.cancel(); // Stop the timer when typing is complete
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayedText,
      style: widget.style,
    );
  }
}

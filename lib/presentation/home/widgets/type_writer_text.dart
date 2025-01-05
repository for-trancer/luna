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
  int totalCharacters = 0; // Initialize to 0
  int interval = 0; // Initialize to 0
  Timer? _typingTimer; // Timer for typing effect

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the text has changed, reset the displayed text and start typing again
    if (oldWidget.text != widget.text) {
      displayedText = ""; // Reset displayed text
      _startTyping(); // Restart typing animation
    }
  }

  void _startTyping() {
    totalCharacters = widget.text.length;
    if (totalCharacters > 0) {
      interval = (widget.duration.inMilliseconds / totalCharacters).floor();
      int currentIndex = 0;

      // Cancel any existing timer before starting a new one
      _typingTimer?.cancel();
      _typingTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
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
  }

  @override
  void dispose() {
    _typingTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayedText,
      style: widget.style,
    );
  }
}

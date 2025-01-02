import 'package:flutter/material.dart';
import 'package:luna/core/colors/colors.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;
  const VoiceRecordButton({
    required this.onStart,
    required this.onStop,
    super.key,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final duration = const Duration(milliseconds: 300);
  var isRecording = false;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.15;
    return AnimatedContainer(
      width: width,
      height: width,
      duration: duration,
      child: tapButton(width),
    );
  }

  Widget tapButton(double size) => Center(
        child: GestureDetector(
          onTap: () => setState(() {
            isRecording = !isRecording;
            if (isRecording) {
              widget.onStart();
            } else {
              widget.onStop();
            }
          }),
          child: AnimatedContainer(
            duration: duration,
            width: isRecording ? size * 65 - 30 : size * 65,
            height: isRecording ? size * 65 - 30 : size * 65,
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: isRecording ? 4 : 8,
                ),
                color: recordingColor,
                borderRadius: BorderRadius.circular(isRecording ? 20 : 80),
                boxShadow: [
                  BoxShadow(
                    color: recordingColor.withOpacity(0.4),
                    blurRadius: isRecording ? 17.5 : 40,
                    spreadRadius: isRecording ? 7.5 : 20.0,
                  )
                ]),
            child: Center(
              child: isRecording
                  ? const Icon(Icons.mic_off)
                  : const Icon(Icons.mic),
            ),
          ),
        ),
      );
}

class SendButton extends StatelessWidget {
  final VoidCallback onSend;
  const SendButton({
    required this.onSend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.15;
    return GestureDetector(
      onTap: () {
        onSend();
      },
      child: Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 4,
            ),
            color: recordingColor,
            borderRadius: BorderRadius.circular(80),
            boxShadow: [
              BoxShadow(
                color: recordingColor.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 20.0,
              )
            ]),
        child: const Center(
          child: Icon(Icons.send),
        ),
      ),
    );
  }
}

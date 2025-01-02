import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:luna/core/colors/colors.dart';
import 'package:luna/core/constants/constants.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class ImageResponseWidget extends StatelessWidget {
  final String imageUrl;
  const ImageResponseWidget({
    super.key,
    required this.imageUrl,
  });

  Future<void> downloadImage() async {
    try {
      final bytes = base64Decode(imageUrl.split(',')[1]);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/downloaded_image.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      final result = await OpenFile.open(filePath);
    } catch (e) {
      log('error downloading image $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: imageUrl != ''
                  ? Image.memory(
                      base64Decode(imageUrl.split(',')[1]),
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        kHeight10,
                        Text('Generating...')
                      ],
                    ))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: imageUrl != ''
                  ? ElevatedButton(
                      onPressed: downloadImage,
                      child: const Icon(
                        Icons.download,
                        color: homeScreenDownloadIconColor,
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}

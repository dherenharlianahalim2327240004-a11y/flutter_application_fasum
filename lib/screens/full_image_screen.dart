import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:universal_html/html.dart' as html;

class FullScreenImageScreen extends StatefulWidget {
  final String imageBase64;

  const FullScreenImageScreen({super.key, required this.imageBase64});

  @override
  State<FullScreenImageScreen> createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    try {
      setState(() {
        _isDownloading = true;
      });

      final Uint8List bytes = base64Decode(widget.imageBase64);

      // WEB
      if (kIsWeb) {
        final blob = html.Blob([bytes]);

        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute(
            "download",
            "fasum_${DateTime.now().millisecondsSinceEpoch}.png",
          )
          ..click();

        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gambar berhasil diunduh')),
          );
        }

        return;
      }

      // ANDROID / WINDOWS
      final directory = await getApplicationDocumentsDirectory();

      final fileName = 'fasum_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gambar berhasil disimpan\n${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan gambar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _showDownloadConfirmation() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Download Gambar'),
          content: const Text(
            'Apakah Anda ingin menyimpan gambar ini ke perangkat?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadImage();
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(widget.imageBase64);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('Full Screen', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _showDownloadConfirmation,
            icon: _isDownloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            tooltip: 'Download Gambar',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(20),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

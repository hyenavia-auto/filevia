import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const FileToolApp());
}

class FileToolApp extends StatelessWidget {
  const FileToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Compressor & Converter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FileToolHomePage(),
    );
  }
}

class FileToolHomePage extends StatefulWidget {
  const FileToolHomePage({super.key});

  @override
  State<FileToolHomePage> createState() => _FileToolHomePageState();
}

class _FileToolHomePageState extends State<FileToolHomePage> {
  String _status = 'Pilih file untuk mulai.';
  bool _loading = false;

  Future<void> _compressFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _loading = true;
      _status = 'Mengompresi file...';
    });

    try {
      var encoder = ZipEncoder();
      var archive = Archive();

      for (var file in result.files) {
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          archive.addFile(ArchiveFile(file.name, bytes.length, bytes));
        }
      }

      var encoded = encoder.encode(archive);
      if (encoded != null) {
        Directory? outputDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        String outputPath = '${outputDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.zip';
        await File(outputPath).writeAsBytes(encoded);

        setState(() {
          _status = 'Berhasil kompres ke: $outputPath';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Gagal kompres: $e';
        _loading = false;
      });
    }
  }

  Future<void> _convertImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _loading = true;
      _status = 'Mengonversi gambar...';
    });

    try {
      String inputPath = result.files.single.path!;
      final bytes = await File(inputPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Format gambar tidak valid.');
      }

      String ext = result.files.single.extension?.toLowerCase() == 'png' ? 'jpg' : 'png';
      List<int> convertedBytes = ext == 'jpg' ? img.encodeJpg(image) : img.encodePng(image);

      Directory? outputDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      String outputPath = '${outputDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(outputPath).writeAsBytes(convertedBytes);

      setState(() {
        _status = 'Berhasil konversi ke: $outputPath';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Gagal konversi: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter File Compressor & Converter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (_loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton.icon(
                onPressed: _compressFiles,
                icon: const Icon(Icons.archive),
                label: const Text('Kompres File ke ZIP'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _convertImage,
                icon: const Icon(Icons.transform),
                label: const Text('Konversi Format Gambar (PNG/JPG)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

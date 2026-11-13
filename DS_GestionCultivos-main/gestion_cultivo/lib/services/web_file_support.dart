import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:doc_text_extractor/doc_text_extractor.dart';
import 'package:web/web.dart' as web;

String _contentType(String extension) => switch (extension) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  'pdf' => 'application/pdf',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  _ => 'application/octet-stream',
};

Future<String> extractTextFromBytes(Uint8List bytes, String extension) async {
  if (extension != 'pdf' && extension != 'docx') return '';

  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _contentType(extension)),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    final result = await TextExtractor().extractText(url);
    return result.text;
  } finally {
    web.URL.revokeObjectURL(url);
  }
}

Future<void> openFileBytes(
  Uint8List bytes,
  String name,
  String extension,
) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _contentType(extension)),
  );
  final url = web.URL.createObjectURL(blob);
  if (web.window.open(url, '_blank') == null) {
    web.URL.revokeObjectURL(url);
    throw StateError('El navegador bloqueó la apertura de $name.');
  }
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
}

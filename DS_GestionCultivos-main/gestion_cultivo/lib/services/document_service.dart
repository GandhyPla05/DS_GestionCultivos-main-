import 'dart:io';

import 'package:doc_text_extractor/doc_text_extractor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/crop_record.dart';
import 'local_database.dart';
import 'web_file_support_stub.dart'
    if (dart.library.html) 'web_file_support.dart'
    as web_file_support;

class DocumentService {
  const DocumentService();

  static const supportedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
    'docx',
  ];

  Future<List<CropAttachment>> pickAndStoreFiles({String? cropId}) async {
    final selectedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (selectedFiles == null || selectedFiles.files.isEmpty) return [];

    Directory? attachmentsDirectory;
    if (!kIsWeb) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      attachmentsDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}cultivo_archivos',
      );
      await attachmentsDirectory.create(recursive: true);
    }

    final storedAttachments = <CropAttachment>[];
    for (final selectedFile in selectedFiles.files) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final extension = (selectedFile.extension ?? '').toLowerCase();
      final addedAt = DateTime.now();
      final CropAttachment attachment;
      if (kIsWeb) {
        final bytes = selectedFile.bytes;
        if (bytes == null) {
          throw StateError(
            'El navegador no entregó el contenido de ${selectedFile.name}.',
          );
        }
        final extractedText = await web_file_support.extractTextFromBytes(
          bytes,
          extension,
        );
        attachment = CropAttachment(
          id: id,
          cropId: cropId,
          name: selectedFile.name,
          path: '',
          extension: extension,
          size: bytes.length,
          addedAt: addedAt,
          extractedText: extractedText,
          content: bytes,
        );
      } else {
        final sourcePath = selectedFile.path;
        if (sourcePath == null) {
          throw FileSystemException(
            'No se pudo acceder al archivo seleccionado.',
            selectedFile.name,
          );
        }

        final safeName = selectedFile.name.replaceAll(
          RegExp(r'[^\w.\- ]'),
          '_',
        );
        final storedPath =
            '${attachmentsDirectory!.path}${Platform.pathSeparator}${id}_$safeName';
        final sourceFile = File(sourcePath);
        final extractedText = await _extractText(sourceFile, extension);
        final storedFile = await sourceFile.copy(storedPath);
        attachment = CropAttachment(
          id: id,
          cropId: cropId,
          name: selectedFile.name,
          path: storedFile.path,
          extension: extension,
          size: await storedFile.length(),
          addedAt: addedAt,
          extractedText: extractedText,
        );
      }
      await LocalDatabase.instance.saveAttachment(attachment);
      storedAttachments.add(attachment);
    }

    return storedAttachments;
  }

  Future<void> delete(CropAttachment attachment) async {
    if (!kIsWeb) {
      final file = File(attachment.path);
      if (await file.exists()) await file.delete();
    }
    await LocalDatabase.instance.deleteAttachment(attachment.id);
  }

  Future<void> open(CropAttachment attachment) async {
    if (kIsWeb) {
      final content = attachment.content;
      if (content == null) {
        throw StateError('No se encontró el contenido de ${attachment.name}.');
      }
      await web_file_support.openFileBytes(
        content,
        attachment.name,
        attachment.extension,
      );
      return;
    }

    final result = await OpenFilex.open(attachment.path);
    if (result.type != ResultType.done) {
      throw FileSystemException(result.message, attachment.path);
    }
  }

  Future<String> _extractText(File file, String extension) async {
    if (extension == 'docx') {
      final result = await TextExtractor().extractText(file.path, isUrl: false);
      return result.text;
    }
    if (extension == 'pdf') {
      final result = await TextExtractor().extractText(file.path, isUrl: false);
      return result.text;
    }
    return '';
  }
}

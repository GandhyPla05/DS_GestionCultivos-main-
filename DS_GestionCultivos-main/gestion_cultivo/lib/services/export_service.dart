import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:docs_gee/docs_gee.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/crop_record.dart';
import 'local_database.dart';

enum ExportFormat { csv, xlsx, pdf, docx, json }

class ExportService {
  const ExportService();

  Future<String?> exportAll(ExportFormat format) async {
    final crops = await LocalDatabase.instance.getCrops();
    final files = await LocalDatabase.instance.getAttachments();
    final extension = switch (format) {
      ExportFormat.csv => 'csv',
      ExportFormat.xlsx => 'xlsx',
      ExportFormat.pdf => 'pdf',
      ExportFormat.docx => 'docx',
      ExportFormat.json => 'json',
    };
    final bytes = switch (format) {
      ExportFormat.csv => _csv(crops, files),
      ExportFormat.xlsx => _xlsx(crops, files),
      ExportFormat.pdf => _document(crops, files, asPdf: true),
      ExportFormat.docx => _document(crops, files, asPdf: false),
      ExportFormat.json => _json(crops, files),
    };
    final fileName = 'gestion_cultivos.$extension';
    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Guardar exportación',
      fileName: fileName,
      bytes: bytes,
    );
    if (kIsWeb) return fileName;
    if (outputPath == null) return null;
    return outputPath;
  }

  Uint8List _json(List<CropRecord> crops, List<CropAttachment> files) {
    final content = {
      'exportedAt': DateTime.now().toIso8601String(),
      'crops': crops.map((crop) => crop.toMap()).toList(),
      'files': files
          .map(
            (file) => {
              'id': file.id,
              'cropId': file.cropId,
              'name': file.name,
              'extension': file.extension,
              'size': file.size,
              'addedAt': file.addedAt.toIso8601String(),
              'extractedText': file.extractedText,
            },
          )
          .toList(),
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(content)),
    );
  }

  Uint8List _csv(List<CropRecord> crops, List<CropAttachment> files) {
    const headers = [
      'Tipo',
      'ID',
      'Cultivo',
      'Variedad',
      'Parcela',
      'Siembra',
      'Riego',
      'Fertilización',
      'Plagas',
      'Cosecha',
      'Estado',
      'Notas',
      'Archivo',
      'Extensión',
      'Tamaño (bytes)',
      'Fecha de carga',
      'Texto extraído',
    ];
    final rows = <List<String>>[headers];
    for (final crop in crops) {
      final linkedFiles = files
          .where((file) => file.cropId == crop.id)
          .toList();
      if (linkedFiles.isEmpty) {
        rows.add(_cropRow(crop));
      } else {
        for (final file in linkedFiles) {
          rows.add(_cropRow(crop, file: file));
        }
      }
    }
    for (final file in files.where((file) => file.cropId == null)) {
      rows.add(_fileRow(file));
    }
    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
  }

  List<String> _cropRow(CropRecord crop, {CropAttachment? file}) => [
    'Cultivo',
    crop.id,
    crop.crop,
    crop.variety,
    crop.parcel,
    _date(crop.sowingDate),
    crop.irrigation,
    crop.fertilization,
    crop.pests,
    _date(crop.harvestDate),
    crop.status,
    crop.notes,
    file?.name ?? '',
    file?.extension ?? '',
    file?.size.toString() ?? '',
    file?.addedAt.toIso8601String() ?? '',
    file?.extractedText ?? '',
  ];

  List<String> _fileRow(CropAttachment file) => [
    'Archivo',
    file.id,
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    file.name,
    file.extension,
    file.size.toString(),
    file.addedAt.toIso8601String(),
    file.extractedText,
  ];

  String _escapeCsv(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  Uint8List _xlsx(List<CropRecord> crops, List<CropAttachment> files) {
    final workbook = Archive();
    _addArchiveText(
      workbook,
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''',
    );
    _addArchiveText(
      workbook,
      '_rels/.rels',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''',
    );
    _addArchiveText(
      workbook,
      'xl/workbook.xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Cultivos" sheetId="1" r:id="rId1"/><sheet name="Archivos" sheetId="2" r:id="rId2"/></sheets>
</workbook>''',
    );
    _addArchiveText(
      workbook,
      'xl/_rels/workbook.xml.rels',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
</Relationships>''',
    );

    final cropRows = <List<String>>[
      [
        'ID',
        'Cultivo',
        'Variedad',
        'Parcela',
        'Siembra',
        'Riego',
        'Fertilización',
        'Plagas',
        'Cosecha',
        'Estado',
        'Notas',
      ],
      ...crops.map(
        (crop) => [
          crop.id,
          crop.crop,
          crop.variety,
          crop.parcel,
          _date(crop.sowingDate),
          crop.irrigation,
          crop.fertilization,
          crop.pests,
          _date(crop.harvestDate),
          crop.status,
          crop.notes,
        ],
      ),
    ];
    final fileRows = <List<String>>[
      [
        'ID',
        'Cultivo ID',
        'Archivo',
        'Tipo',
        'Tamaño',
        'Fecha',
        'Texto extraído',
      ],
      ...files.map(
        (file) => [
          file.id,
          file.cropId ?? '',
          file.name,
          file.extension,
          file.size.toString(),
          file.addedAt.toIso8601String(),
          file.extractedText,
        ],
      ),
    ];
    _addArchiveText(workbook, 'xl/worksheets/sheet1.xml', _sheetXml(cropRows));
    _addArchiveText(workbook, 'xl/worksheets/sheet2.xml', _sheetXml(fileRows));
    final encoded = ZipEncoder().encode(workbook);
    return Uint8List.fromList(encoded);
  }

  void _addArchiveText(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  String _sheetXml(List<List<String>> rows) {
    final buffer = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
    );
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      buffer.write('<row r="${rowIndex + 1}">');
      for (
        var columnIndex = 0;
        columnIndex < rows[rowIndex].length;
        columnIndex++
      ) {
        final cell = '${_columnName(columnIndex)}${rowIndex + 1}';
        final value = _escapeXml(rows[rowIndex][columnIndex]);
        buffer.write(
          '<c r="$cell" t="inlineStr"><is><t xml:space="preserve">$value</t></is></c>',
        );
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  String _columnName(int index) {
    var number = index + 1;
    var result = '';
    while (number > 0) {
      final remainder = (number - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      number = (number - remainder - 1) ~/ 26;
    }
    return result;
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  Uint8List _document(
    List<CropRecord> crops,
    List<CropAttachment> files, {
    required bool asPdf,
  }) {
    final document = DocxDocument(
      title: 'Gestión de cultivos',
      author: 'Gestión de Cultivos',
    );
    document.addParagraph(
      DocxParagraph.heading('Informe de cultivos', level: 1),
    );
    document.addParagraph(
      DocxParagraph.text('Generado: ${DateTime.now().toLocal()}'),
    );
    for (final crop in crops) {
      document.addParagraph(DocxParagraph.heading(crop.crop, level: 2));
      document.addParagraph(DocxParagraph.text('Variedad: ${crop.variety}'));
      document.addParagraph(DocxParagraph.text('Parcela: ${crop.parcel}'));
      document.addParagraph(
        DocxParagraph.text('Fecha de siembra: ${_date(crop.sowingDate)}'),
      );
      document.addParagraph(DocxParagraph.text('Riego: ${crop.irrigation}'));
      document.addParagraph(
        DocxParagraph.text('Fertilización: ${crop.fertilization}'),
      );
      document.addParagraph(DocxParagraph.text('Plagas: ${crop.pests}'));
      document.addParagraph(
        DocxParagraph.text('Fecha de cosecha: ${_date(crop.harvestDate)}'),
      );
      document.addParagraph(DocxParagraph.text('Estado: ${crop.status}'));
      if (crop.notes.isNotEmpty) {
        document.addParagraph(DocxParagraph.text('Notas: ${crop.notes}'));
      }
      final linkedFiles = files.where((file) => file.cropId == crop.id);
      for (final file in linkedFiles) {
        document.addParagraph(DocxParagraph.text('Archivo: ${file.name}'));
      }
    }
    final bytes = asPdf
        ? PdfGenerator().generate(document)
        : DocxGenerator().generate(document);
    return Uint8List.fromList(bytes);
  }

  String _date(DateTime? date) => date == null
      ? ''
      : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
}

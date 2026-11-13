import 'dart:typed_data';

class CropRecord {
  const CropRecord({
    required this.id,
    required this.crop,
    required this.variety,
    required this.parcel,
    required this.sowingDate,
    required this.irrigation,
    required this.fertilization,
    required this.pests,
    required this.harvestDate,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String crop;
  final String variety;
  final String parcel;
  final DateTime? sowingDate;
  final String irrigation;
  final String fertilization;
  final String pests;
  final DateTime? harvestDate;
  final String status;
  final String notes;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'crop': crop,
    'variety': variety,
    'parcel': parcel,
    'sowing_date': sowingDate?.toIso8601String(),
    'irrigation': irrigation,
    'fertilization': fertilization,
    'pests': pests,
    'harvest_date': harvestDate?.toIso8601String(),
    'status': status,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory CropRecord.fromMap(Map<String, Object?> map) => CropRecord(
    id: map['id']! as String,
    crop: map['crop']! as String,
    variety: map['variety'] as String? ?? '',
    parcel: map['parcel'] as String? ?? '',
    sowingDate: _dateFromMap(map['sowing_date']),
    irrigation: map['irrigation'] as String? ?? '',
    fertilization: map['fertilization'] as String? ?? '',
    pests: map['pests'] as String? ?? '',
    harvestDate: _dateFromMap(map['harvest_date']),
    status: map['status'] as String? ?? 'active',
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.parse(map['created_at']! as String),
  );
}

class CropAttachment {
  const CropAttachment({
    required this.id,
    required this.cropId,
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    required this.addedAt,
    required this.extractedText,
    this.content,
  });

  final String id;
  final String? cropId;
  final String name;
  final String path;
  final String extension;
  final int size;
  final DateTime addedAt;
  final String extractedText;
  final Uint8List? content;

  Map<String, Object?> toMap() => {
    'id': id,
    'crop_id': cropId,
    'name': name,
    'path': path,
    'extension': extension,
    'size': size,
    'added_at': addedAt.toIso8601String(),
    'extracted_text': extractedText,
    'content': content,
  };

  factory CropAttachment.fromMap(Map<String, Object?> map) => CropAttachment(
    id: map['id']! as String,
    cropId: map['crop_id'] as String?,
    name: map['name']! as String,
    path: map['path']! as String,
    extension: map['extension']! as String,
    size: map['size']! as int,
    addedAt: DateTime.parse(map['added_at']! as String),
    extractedText: map['extracted_text'] as String? ?? '',
    content: map['content'] as Uint8List?,
  );
}

DateTime? _dateFromMap(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.parse(value);
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_cultivo/models/crop_record.dart';
import 'package:gestion_cultivo/services/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'gestion_cultivos_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => supportDirectory.path,
        );
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  test('editing a crop keeps its attached files linked', () async {
    final database = LocalDatabase.instance;
    final createdAt = DateTime(2026, 1, 1);
    final crop = CropRecord(
      id: 'crop-1',
      crop: 'Maíz',
      variety: 'Dulce',
      parcel: 'A',
      sowingDate: null,
      irrigation: '',
      fertilization: '',
      pests: '',
      harvestDate: null,
      status: 'active',
      notes: '',
      createdAt: createdAt,
    );

    await database.saveCrop(crop);
    await database.saveAttachment(
      CropAttachment(
        id: 'file-1',
        cropId: crop.id,
        name: 'foto.jpg',
        path: '${supportDirectory.path}\\foto.jpg',
        extension: 'jpg',
        size: 12,
        addedAt: createdAt,
        extractedText: '',
      ),
    );
    await database.saveCrop(
      CropRecord(
        id: crop.id,
        crop: crop.crop,
        variety: crop.variety,
        parcel: crop.parcel,
        sowingDate: crop.sowingDate,
        irrigation: crop.irrigation,
        fertilization: crop.fertilization,
        pests: crop.pests,
        harvestDate: crop.harvestDate,
        status: crop.status,
        notes: 'Actualizado',
        createdAt: crop.createdAt,
      ),
    );

    final attachments = await database.getAttachments(cropId: crop.id);
    final savedCrop = await database.getCrops();

    expect(attachments, hasLength(1));
    expect(attachments.single.cropId, crop.id);
    expect(savedCrop.single.notes, 'Actualizado');
  });
}

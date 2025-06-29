import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ImageMod {
  final int? totalHits;
  final List<ImageModel> hits;
  final int? total;

  ImageMod({
    this.totalHits,
    required this.hits,
    this.total,
  });

  factory ImageMod.fromJson(Map<String, dynamic> json) {
    return ImageMod(
      totalHits: json['totalHits'] as int?,
      hits: (json['hits'] as List<dynamic>?)
          ?.map((item) => ImageModel.fromJson(id: item['id'].toString(), json: item))
          .toList() ??
          [],
      total: json['total'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalHits': totalHits,
      'hits': hits.map((v) => v.toJson()).toList(),
      'total': total,
    };
  }
}

// Model for a single image
class ImageModel {
  final String id;
  final String? name;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? adopted;
  final String? categoryId;
  final String? license;
  final DateTime? uploadedTime;
  final int? paid;
  final int? viewCount;
  final int? downloadCount;
  final List<String>? tags;

  ImageModel({
    required this.id,
    this.name,
    this.imageUrl,
    this.thumbnailUrl,
    this.adopted,
    this.categoryId,
    this.license,
    this.uploadedTime,
    this.paid,
    this.viewCount,
    this.downloadCount,
    this.tags,
  });

  factory ImageModel.fromJson({
    required String id,
    required Map<String, dynamic> json,
  }) {
    final uploadedTime = json['uploadedTime'];
    return ImageModel(
      id: id,
      name: json['name'] as String?,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      adopted: json['adopted'] as String?, // Fixed typo from 'adopted:1920 x 1080'
      categoryId: json['categoryId'] as String?,
      license: json['license'] as String?,
      uploadedTime: uploadedTime is String
          ? DateTime.tryParse(uploadedTime)
          : uploadedTime is Timestamp
          ? uploadedTime.toDate()
          : null,
      paid: json['paid'] as int?,
      viewCount: json['viewCount'] as int?,
      downloadCount: json['downloadCount'] as int?,
      tags: (json['tag'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'adopted': adopted,
      'categoryId': categoryId,
      'license': license,
      'uploadedTime': uploadedTime?.toIso8601String(),
      'paid': paid,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ImageModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ImageModel{id: $id, name: $name, imageUrl: $imageUrl, '
          'thumbnailUrl: $thumbnailUrl, adopted: $adopted, license: $license, '
          'categoryId: $categoryId, uploadedTime: $uploadedTime, paid: $paid, '
          'viewCount: $viewCount, downloadCount: $downloadCount, tags: $tags}';
}

// Firestore mapper functions
List<ImageModel> mapper(QuerySnapshot querySnapshot) {
  return querySnapshot.docs.map(mapperImageModel).toList();
}

ImageModel mapperImageModel(DocumentSnapshot documentSnapshot) {
  return ImageModel.fromJson(
    id: documentSnapshot.id,
    json: documentSnapshot.data() as Map<String, dynamic>,
  );
}

// Utility function to save an image file locally
Future<bool> saveImage(Map<String, dynamic> map) async {
  try {
    final filePath = map['filePath'] as String?;
    final bytes = map['bytes'] as List<int>?;
    if (filePath == null || bytes == null) {
      return false;
    }
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    print('Error saving image: $e');
    return false;
  }
}

// SQLite database manager
class ImageDB {
  static const dbName = 'images.db';
  static const tableRecent = 'recents';
  static const tableFavorites = 'favorites';
  static const createdAtDesc = 'createdAt DESC';
  static const nameAsc = 'name ASC';

  Database? _db;
  static ImageDB? _instance;

  ImageDB._internal();

  factory ImageDB() => _instance ??= ImageDB._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create favorites table
        await db.execute('''
          CREATE TABLE $tableFavorites (
            id TEXT PRIMARY KEY UNIQUE NOT NULL,
            name TEXT,
            imageUrl TEXT,
            thumbnailUrl TEXT,
            adopted TEXT,
            categoryId TEXT,
            license TEXT,
            uploadedTime TEXT,
            createdAt TEXT NOT NULL,
            viewCount INTEGER,
            downloadCount INTEGER
          )
        ''');
        // Create recents table
        await db.execute('''
          CREATE TABLE $tableRecent (
            id TEXT PRIMARY KEY UNIQUE NOT NULL,
            name TEXT,
            imageUrl TEXT,
            thumbnailUrl TEXT,
            adopted TEXT,
            categoryId TEXT,
            license TEXT,
            uploadedTime TEXT,
            createdAt TEXT NOT NULL,
            viewCount INTEGER,
            downloadCount INTEGER
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    final dbClient = await db;
    await dbClient.close();
    _db = null;
  }

  Future<List<ImageModel>> fetchFavorites({
    String orderBy = createdAtDesc,
    int? limit,
  }) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      tableFavorites,
      orderBy: orderBy,
      limit: limit,
    );
    return maps.map((json) => ImageModel.fromJson(id: json['id'] as String, json: json)).toList();
  }

  Future<int> insertFavoriteImage(ImageModel image) async {
    final values = image.toJson();
    values['createdAt'] = DateTime.now().toIso8601String();
    values['adopted'] = image.adopted ?? image.imageUrl;
    values.remove('paid');
    values.remove('tags'); // Changed from 'tag' to match field name
    final dbClient = await db;
    return dbClient.insert(
      tableFavorites,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateFavorite(ImageModel image) async {
    final dbClient = await db;
    return dbClient.update(
      tableFavorites,
      {
        'name': image.name,
        'imageUrl': image.imageUrl,
        'thumbnailUrl': image.thumbnailUrl,
        'adopted': image.adopted ?? image.imageUrl,
        'categoryId': image.categoryId,
        'license': image.license,
        'viewCount': image.viewCount,
        'downloadCount': image.downloadCount,
        'uploadedTime': image.uploadedTime?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  Future<int> deleteFavorite(String id) async {
    final dbClient = await db;
    return dbClient.delete(
      tableFavorites,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isFavorite(String id) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      tableFavorites,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // Methods for recents table (added for completeness)
  Future<int> insertRecentImage(ImageModel image) async {
    final values = image.toJson();
    values['createdAt'] = DateTime.now().toIso8601String();
    values['adopted'] = image.adopted ?? image.imageUrl;
    values.remove('paid');
    values.remove('tags');
    final dbClient = await db;
    return dbClient.insert(
      tableRecent,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ImageModel>> fetchRecents({
    String orderBy = createdAtDesc,
    int? limit,
  }) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      tableRecent,
      orderBy: orderBy,
      limit: limit,
    );
    return maps.map((json) => ImageModel.fromJson(id: json['id'] as String, json: json)).toList();
  }
}
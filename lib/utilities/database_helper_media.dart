import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelperMedia {
  static const _databaseName = "MediaFilesDatabase.db";
  static const _databaseVersion = 1;

  static const table = 'media_files_table';

  static const columnId = 'id';
  static const columnFileId = 'fileId';
  static const columnFileType = 'fileType';
  static const columnFileName = 'fileName';
  static const columnFileUrl = 'fileUrl';
  static const columnLabel = 'label';
  static const columnLocalDir = 'localDir';
  static const columnCreatedOn = 'createdOn';

  // make singleton class
  DatabaseHelperMedia._privateConstructor();
  static final DatabaseHelperMedia instance =
      DatabaseHelperMedia._privateConstructor();

  static Database? _database;
  Future<Database?> get database async {
    // Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // String path = join(documentsDirectory.path, _databaseName);
    // deleteDatabase(path);
    if (_database != null) return _database;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          create table $table (
            $columnId INTEGER PRIMARY KEY,
            $columnFileId TEXT NOT NULL,
            $columnFileType TEXT NOT NULL,
            $columnFileName TEXT NOT NULL,
            $columnFileUrl TEXT NOT NULL,
            $columnLabel TEXT NOT NULL,
            $columnLocalDir TEXT NOT NULL,
            $columnCreatedOn TEXT NOT NULL
            )
          ''');
  }

  // Helper methods

  // Insert a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is key-value list of columns
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database? db = await instance.database;
    return await db!.query(table);
  }

  // Only one row is returned as a map by columnId, where each map is key-value list of columns
  Future<List<Map<String, dynamic>>> queryOneRow(int id) async {
    Database? db = await instance.database;
    return await db!
        .query(table, where: '$columnId = ?', whereArgs: [id], limit: 1);
  }

  // Only one row is returned as a map by fileId, where each map is key-value list of columns
  Future<List<Map<String, dynamic>>> queryOneRowByFileId(String fileId) async {
    Database? db = await instance.database;
    return await db!
        .query(table, where: '$columnFileId = ?', whereArgs: [fileId]);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.

  Future<int?> queryRowCount() async {
    Database? db = await instance.database;
    return Sqflite.firstIntValue(
        await db!.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    int id = row[columnId];
    return await db!
        .update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is returned
  // This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    Database? db = await instance.database;
    return await db!.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}

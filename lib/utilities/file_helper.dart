import '../utilities/database_helper_media.dart';

class MediaFileHelper {
  final dbHelperMedia = DatabaseHelperMedia.instance;

  Future<int> update(
      int columnId,
      String fileId,
      String fileType,
      String filename,
      String fileUrl,
      String label,
      String localDir,
      String createdOn) async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelperMedia.columnId: columnId,
      DatabaseHelperMedia.columnFileId: fileId,
      DatabaseHelperMedia.columnFileType: fileType,
      DatabaseHelperMedia.columnFileName: filename,
      DatabaseHelperMedia.columnFileUrl: fileUrl,
      DatabaseHelperMedia.columnLabel: label,
      DatabaseHelperMedia.columnLocalDir: localDir,
      DatabaseHelperMedia.columnCreatedOn: createdOn
    };
    final id = await dbHelperMedia.update(row);
    print('Updated status: $id');
    return id;
  }

  Future<int> insert(String fileId, String fileType, String filename,
      String fileUrl, String label, String localDir, String createdOn) async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelperMedia.columnFileId: fileId,
      DatabaseHelperMedia.columnFileType: fileType,
      DatabaseHelperMedia.columnFileName: filename,
      DatabaseHelperMedia.columnFileUrl: fileUrl,
      DatabaseHelperMedia.columnLabel: label,
      DatabaseHelperMedia.columnLocalDir: localDir,
      DatabaseHelperMedia.columnCreatedOn: createdOn
    };
    final id = await dbHelperMedia.insert(row);
    print('inserted row id: $id');
    return id;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/media_file.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<MyMediaFile>> getAllFiles(String id) {
    var ref = _db
        .collection("files")
        .where('userId', isEqualTo: id)
        .where('isReminder', isEqualTo: false);

    return ref.get().then((doc) {
      return doc.docs.map<MyMediaFile>((doc) {
        var data = doc.data();
        data["id"] = doc.id;
        return MyMediaFile.fromJson(data);
      }).toList();
    });
  }

  Future<void> deleteFile(String id) {
    var ref = _db.collection("files").doc(id);
    return ref.delete().then((_) {
      print('<<<< Successfully deleted: $id >>>>');
      // ignore: invalid_return_type_for_catch_error
    }).catchError((err) => print('<<<< Err during deletion: $err >>'));
  }
}

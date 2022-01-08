import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:fluttertoast/fluttertoast.dart';
import '../utilities/database_helper_media.dart';
import '../utilities/file_helper.dart';
import '../utilities/db.dart';
import '../widgets/video_loader.dart';
import '../models/media_file.dart';

typedef void IntegerCallback(int value);
typedef void BoolCallback(bool isDone);

class Slideshow extends StatefulWidget {
  final IntegerCallback progressCallback;
  final BoolCallback isDownloadingCallback;
  const Slideshow({
    required Key key,
    required this.progressCallback,
    required this.isDownloadingCallback,
  }) : super(key: key);

  @override
  _SlideshowState createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow> {
  final PageController ctrl = PageController(viewportFraction: 0.8);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService db = DatabaseService();
  final dbHelperMedia = DatabaseHelperMedia.instance;
  final mediaFileHelper = MediaFileHelper();
  var _pageLen = 0;
  Future<List<MyMediaFile>>? images;
  List<MyMediaFile> slideList = [];
  List<MyMediaFile> allFilesRestored = [];
  var defaultImage = '/storage/emulated/0/Download/video_icon.png';
  List<MyMediaFile> medias = [
    MyMediaFile(
      fileType: 'image',
      fileSize: 0,
      isReminder: false,
      name: 'gap',
      label: 'My label',
      userId: 'SkgTAJzMFwPpKJBrZg3czljggdX2',
      isDeleted: false,
      fileUrl:
          'https://i.kym-cdn.com/photos/images/newsfeed/000/295/544/a63.png',
      id: 'NuISOEpI3yhBcLXxq0Wi',
      createdOn: Timestamp.now(),
    )
  ];
  late Map<Permission, PermissionStatus> status;
  // Keep track of current page to avoid unnecessary renders
  int currentPage = 0;
  Duration updateDuration = const Duration(minutes: 1);
  int _downloadCount = 0;
  Timer? shiftTimer;
  var currentStep = 0;
  final _mainDelay = const Duration(seconds: 15);
  final _reloadDelay = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    shiftTimer = Timer.periodic(updateDuration, _shiftMedia);
    // Set state when page changes
    ctrl.addListener(() {
      var next = ctrl.page!.round();
      if (currentPage != next) {
        // setState(() {
        currentPage = next;
        // });
      }
    });
    Timer(_mainDelay, _startDownload);
    Timer(_reloadDelay, _reloadFiles);
  }

  _reloadFiles() async {
    if (mounted) {
      dbHelperMedia.queryAllRows().then((table) {
        // setState(() {
        // });
        for (var row in table) {
          var media = MyMediaFile(
            fileType: row['fileType'],
            isReminder: false,
            name: row['fileName'],
            label: row['label'],
            fileSize: 0,
            userId: '',
            isDeleted: false,
            fileUrl: row['localDir'],
            id: row['fileId'],
            createdOn: Timestamp.now(),
          );
          setState(() {
            slideList.add(media);
          });
        }
        _pageLen = slideList.length;
      }).catchError((err) => print('<<<< Err during local reload: $err >>'));
    }
  }

  _startDownload() async {
    if (mounted) {
      status = await [
        Permission.storage
        //add more permission to request here.
      ].request();
      _filesListener('SkgTAJzMFwPpKJBrZg3czljggdX2');
    }
  }

  Future<void> _filesListener(String uid) async {
    var ref = _db.collection('files').where('userId', isEqualTo: uid);
    ref.snapshots().listen((snapshots) {
      print('\n======================================================');
      print('========= Something changed in Files ================');
      print('======================================================\n');
      db.getAllFiles(uid).then((allFiles) {
        allFilesRestored = allFiles;
        _fetchFiles(allFiles);
      });
    });
  }

  Future? _fetchFiles(List<MyMediaFile> files) async {
    if (files.isNotEmpty) {
      FutureGroup futureGroup = FutureGroup();
      for (var file in files) {
        if (file.isDeleted) {
          dbHelperMedia.queryOneRowByFileId(file.id).then((query) {
            if (query.isNotEmpty) {
              try {
                print('\n << Delete directory: ${query[0]['localDir']} >>> \n');
                var toBeDeleted = File(query[0]['localDir']);
                toBeDeleted.delete();
              } catch (e) {
                print('\n << Error: $e >>> \n');
              }
              dbHelperMedia.delete(query[0]['id']).then((_) {
                print(
                    '\n << Now this deleted: ${query[0]['id']} : ${query[0]['localDir']} >>> \n');
              }).catchError(
                  (err) => print('<<<< Err during deletion: $err >>'));
              ;
              List temp = slideList;
              for (int i = 0; i < temp.length; i++) {
                if (temp[i].id == query[0]['fileId']) {
                  setState(() {
                    slideList.removeAt(i);
                  });
                }
              }
              _pageLen = slideList.length;
            }
          });
          db.deleteFile(file.id);
        } else {
          dbHelperMedia.queryOneRowByFileId(file.id).then((query) async {
            if (query.isNotEmpty) {
              if (query.length > 1) {
                for (var i = 1; i < query.length; i++) {
                  dbHelperMedia.delete(query[i]['id']).then((_) {
                    print(
                        '\n << File duplication deleted: ${query[i]['id']} >>> \n');
                  });
                }
              }
              if (query[0]['createdOn'] == file.createdOn.toDate().toString()) {
                print(
                    '=== Nothing is changed for file id ${file.id} : ${file.fileUrl}.');
              } else {
                //Update media file info on local db
                var index =
                    slideList.indexWhere((element) => element.id == file.id);
                var media = MyMediaFile(
                  id: file.id,
                  fileType: file.fileType,
                  isReminder: false,
                  name: file.name,
                  label: file.label,
                  fileSize: 0,
                  userId: file.userId,
                  isDeleted: false,
                  fileUrl: query[0]['localDir'],
                  createdOn: file.createdOn,
                );
                if (index >= 0) {
                  slideList[index] = media;
                } else {
                  print('\n\n Not in here!!! \n\n');
                  setState(() {
                    slideList.add(media);
                  });
                  _pageLen = slideList.length;
                }

                mediaFileHelper.update(
                  query[0]['id'],
                  file.id,
                  file.fileType,
                  file.name,
                  file.fileUrl,
                  file.label,
                  query[0]['localDir'],
                  file.createdOn.toDate().toString(),
                );
              }
            } else {
              // Downlaod file and get local path of
              var dir = await DownloadsPathProvider.downloadsDirectory;

              if (status[Permission.storage]!.isGranted) {
                if (dir != null) {
                  print('\n\n Filename: ${file.name.split('/')[1]} \n\n');
                  if (file.fileSize > 1024000 &&
                      file.fileType.contains('image')) {
                    // Not ready to download
                    print('\n\n Not ready to download \n\n');
                  } else {
                    _downloadCount++;
                    String savePath =
                        dir.path + '/mApp/' + file.name.split('/')[1];
                    print('\n\n <<< Download file: ${file.fileUrl} >>>\n\n');
                    futureGroup.add(downloadFile(file, savePath));
                  }
                } else {
                  print('File path dir is null');
                }
              }
            }
          });
        }
      }

      if (futureGroup.isClosed) {
        print('\n\n <<< Future group is already closed. >>>\n\n');
      } else {
        futureGroup.close();
        futureGroup.future.then((val) {
          print('\n\n <<< Done for downloading $_downloadCount >>> \n\n');
          _downloadCount--;
          if (_downloadCount == 0) {
            print('\n\n << COMPLETED >> \n\n');
          }
        });
      }
    }
  }

  Future<void> downloadFile(MyMediaFile file, String savePath) async {
    Dio dio = Dio();
    widget.isDownloadingCallback(true);
    try {
      dio.download(
        file.fileUrl,
        savePath,
        onReceiveProgress: (count, total) {
          // print('\n Path: $filePath \n');
          // print('Count: $count, Total: $total');
          setState(() {
            currentStep = ((count / total) * 100).toInt();
            widget.progressCallback(currentStep);
          });
          if (currentStep == 100) {
            widget.isDownloadingCallback(false);
            var sortedList = slideList.where((s) => (s.id.contains(file.id)));
            if (sortedList.isEmpty) {
              var media = MyMediaFile(
                id: file.id,
                fileType: file.fileType,
                isReminder: false,
                name: file.name,
                label: file.label,
                fileSize: 0,
                userId: file.userId,
                isDeleted: false,
                fileUrl: savePath,
                createdOn: file.createdOn,
              );

              slideList.add(media);
              _pageLen = slideList.length;
              print('===== Inserted file ${file.id} : $savePath.');
              mediaFileHelper.insert(
                file.id,
                file.fileType,
                file.name,
                file.fileUrl,
                file.label,
                savePath,
                file.createdOn.toDate().toString(),
              );
            }
          }
        },
      );
    } catch (e) {
      print('\n\n $e');
      widget.isDownloadingCallback(false);
    }
  }

  _shiftMedia(Timer timer) async {
    if (mounted) {
      var next = ctrl.page!.round() + 1;
      print('\n\n <<<<< Length: $_pageLen  >>>>> \n\n');
      if (next == _pageLen) {
        setState(() {
          currentPage = 0;
        });
        // shiftTimer?.cancel();
        // shiftTimer = Timer.periodic(updateDuration, _shiftMedia);
        ctrl.animateToPage(0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
      } else {
        if (currentPage != next) {
          setState(() {
            currentPage = next;
          });
          ctrl.animateToPage(
            currentPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return slideList.isEmpty
        ? const Center(
            child: Text('Empty'),
          )
        : PageView.builder(
            controller: ctrl,
            itemCount: slideList.length,
            itemBuilder: (context, int currentIdx) {
              if (slideList.length > currentIdx) {
                // Active page
                var active = currentIdx == currentPage;
                return _buildStoryPage(slideList[currentIdx], active);
              } else {
                return const Center(
                  child: Text('Not able to load the pages'),
                );
              }
            });
  }
  // Builder Functions

  _buildStoryPage(MyMediaFile media, bool active) {
    // Animated Properties
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: media.fileType.contains('image') ? BoxFit.cover : BoxFit.contain,
          image: media.fileType.contains('image')
              ? FileImage(File(media.fileUrl))
              : media.fileType.contains('video')
                  ? Image.asset('assets/images/video_icon.png').image
                  : Image.asset('assets/images/music.png').image,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: blur,
            offset: Offset(offset, offset),
          )
        ],
      ),
      child: media.fileType.contains('image')
          ? Center(
              child: Text(
                media.label,
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            )
          : MyVideoPlayer(
              key: GlobalKey(),
              videoUrl: media.fileUrl,
              isActive: active,
              fileType: media.fileType,
              label: media.label,
              sendVideoDuration: (value) {
                print('\n\n ========== Duration: $value  =========== \n\n');
              },
              onVideoCompleted: () {
                // Video completed
                ctrl.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
                shiftTimer?.cancel();
                shiftTimer = Timer.periodic(updateDuration, _shiftMedia);
              },
              onVideoStarted: () {
                shiftTimer?.cancel();
                print('\n\n  <<<<< Shift timer is cancelled!  >>>>> \n\n');
              },
              onVideoPlayStatus: (isPlaying) {
                // Will trigger when play button is clicked
                if (isPlaying) {
                  shiftTimer?.cancel();
                } else {
                  shiftTimer?.cancel();
                  shiftTimer = Timer.periodic(updateDuration, _shiftMedia);
                }
              },
            ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/video_loader.dart';
import '../models/media_file.dart';

class Slideshow extends StatefulWidget {
  Slideshow({required Key key}) : super(key: key);

  @override
  _SlideshowState createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow> {
  final PageController ctrl = PageController(viewportFraction: 0.8);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  var _pageLen = 0;
  Stream<List<MyMediaFile>>? slides;
  Future<List<MyMediaFile>>? images;
  List<MyMediaFile> photos = [
    MyMediaFile(
      fileType: 'image',
      fileSize: 0,
      isReminder: false,
      name: 'gap',
      label: 'My label',
      isDeleted: false,
      userId: 'SkgTAJzMFwPpKJBrZg3czljggdX2',
      fileUrl: '',
      id: 'NuISOEpI3yhBcLXxq0Wi',
      createdOn: Timestamp.now(),
    )
  ];
  // Keep track of current page to avoid unnecessary renders
  int currentPage = 0;
  Duration updateDuration = const Duration(minutes: 1);
  Timer? shiftTimer;
  @override
  void initState() {
    super.initState();
    shiftTimer = Timer.periodic(updateDuration, _shiftPhotos);
    // Set state when page changes
    ctrl.addListener(() {
      var next = ctrl.page!.round();
      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  _shiftPhotos(Timer timer) async {
    if (mounted) {
      var next = ctrl.page!.round() + 1;
      print('\n\n <<<<< Length: $_pageLen  >>>>> \n\n');
      if (next == _pageLen) {
        setState(() {
          currentPage = 0;
        });
        // shiftTimer = Timer.periodic(updateDuration, _shiftPhotos);
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
    return FutureBuilder(
        future: _getFiles('SkgTAJzMFwPpKJBrZg3czljggdX2'),
        initialData: photos,
        builder: (context, AsyncSnapshot snap) {
          List<MyMediaFile> slideList = snap.data.toList();
          slideList.sort((a, b) {
            var aDate = a.createdOn;
            var bDate = b.createdOn;
            return aDate.compareTo(bDate);
          });
          photos = slideList;
          return PageView.builder(
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
        });
  }

  Future<List<MyMediaFile>>? _getFiles(String id) {
    final ref = FirebaseFirestore.instance.collection('photos');
    Query<Map<String, Object?>> query = ref
        .where('userId', isEqualTo: id)
        .where('isReminder', isEqualTo: false);
    // Map the documents to the data payload
    images = query.get().then((list) {
      // setState(() {
      _pageLen = list.docs.length;
      // });
      return list.docs.map<MyMediaFile>((doc) {
        var data = doc.data();
        data["id"] = doc.id;
        return MyMediaFile.fromJson(data);
      }).toList();
    });
    // Update the active tag

    // images?.add(myVideo);
    return images;
  }

  // Builder Functions

  _buildStoryPage(MyMediaFile photo, bool active) {
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
          fit: BoxFit.cover,
          image: NetworkImage(photo.fileUrl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: blur,
            offset: Offset(offset, offset),
          )
        ],
      ),
      child: photo.fileType.contains('image')
          ? Center(
              child: Text(
                photo.label,
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            )
          : MyVideoPlayer(
              key: GlobalKey(),
              videoUrl: photo.fileUrl,
              isActive: active,
              fileType: photo.fileType,
              label: photo.label,
              sendVideoDuration: (value) {
                print('\n\n ========== Duration: $value  =========== \n\n');
              },
              onVideoCompleted: () {
                // Video completed
                ctrl.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
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
                  shiftTimer = Timer.periodic(updateDuration, _shiftPhotos);
                }
              },
            ),
    );
  }
}

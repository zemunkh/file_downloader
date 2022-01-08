import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String label;
  final String fileType;
  final bool isActive;
  final Function(int) sendVideoDuration;
  final VoidCallback onVideoCompleted;
  final VoidCallback onVideoStarted;
  final Function(bool) onVideoPlayStatus;

  const MyVideoPlayer(
      {required Key key,
      required this.videoUrl,
      required this.label,
      required this.fileType,
      required this.isActive,
      required this.sendVideoDuration,
      required this.onVideoCompleted,
      required this.onVideoStarted,
      required this.onVideoPlayStatus})
      : super(key: key);

  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.videoUrl),
    );
    _controller?.addListener(() {
      if (_controller!.value.isInitialized) {
        Duration duration = _controller!.value.duration;
        // widget.sendVideoDuration(duration.inSeconds);
        Duration position = _controller!.value.position;
        if (duration.compareTo(position) != 1) {
          widget.onVideoCompleted();
          print('\n\n ========== Video Completed!  =========== \n\n');
        } else if (duration.compareTo(position) == 0) {
          widget.onVideoStarted();
          widget.sendVideoDuration(duration.inSeconds);
        }
      }
    });
    _initializeVideoPlayerFuture = _controller!.initialize();

    // Checking that current page is active or not.
    if (widget.isActive) {
      _controller?.play();
    } else {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _initializeVideoPlayerFuture = null;
    _controller?.pause().then((_) {
      _controller?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: <Widget>[
              VideoPlayer(_controller!),
              widget.fileType.contains('audio')
                  ? Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Image.asset(
                          'assets/images/music.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : const Text(''),
              widget.fileType.contains('audio')
                  ? Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Text(''),
              Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          if (_controller!.value.isPlaying) {
                            _controller?.pause();
                          } else {
                            _controller?.play();
                          }
                          widget
                              .onVideoPlayStatus(_controller!.value.isPlaying);
                        });
                      },
                      child: Icon(_controller!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.yellow,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

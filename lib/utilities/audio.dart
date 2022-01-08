import 'dart:async';
import 'dart:io';
// ignore: import_of_legacy_library_into_null_safe
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

enum PlayerState { stopped, playing, paused }

class AudioService {
  String starterAudio = 'ding.wav';

  AudioPlayer? audioPlayer;
  PlayerState playerState = PlayerState.stopped;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;
  get isStopped => playerState == PlayerState.stopped;

  StreamSubscription? _audioPlayerStateSubscription;
  String? localFilePath;

  void cancelAudioSub() {
    _audioPlayerStateSubscription?.cancel();
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer();
    _audioPlayerStateSubscription =
        audioPlayer?.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        print("Still Playing...");
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
      }
    }, onError: (msg) {
      playerState = PlayerState.stopped;
    });
  }

  Future<ByteData> loadAsset(name) async {
    return await rootBundle.load('assets/audio/$name');
  }

  Future loadFile(String name) async {
    final file = new File('${(await getTemporaryDirectory()).path}/$name');
    await file.writeAsBytes((await loadAsset(name)).buffer.asUint8List());
    // print('Temp File Path: ${file.path}');

    if (await file.exists())
      // setState(() {
      localFilePath = file.path;
    // });
  }

  Future loadLocalFile(String path) async {
    final file = File(path);
  }

  Future play(String name) async {
    await audioPlayer?.play(localFilePath, isLocal: true);
    playerState = PlayerState.playing;
    // setState(() => );
  }

  Future stop() async {
    await audioPlayer?.stop();
    // setState(() {
    playerState = PlayerState.stopped;
    // });
  }

  void onComplete() {
    // setState(() {
    playerState = PlayerState.stopped;
    // });
    // _audioPlayerStateSubscription.cancel();
    print("##### #### ### Ready to Play next audio");
  }

  Future<Null> playAudioNotifier() async {
    if (!isPlaying) {
      loadFile(starterAudio).then((_) {
        play(starterAudio);
      });
    }
  }

  Future<Null> playAudioNotifierFile(String filename) async {
    print('\n\n <<<<<<<< PLAYING >>>>>>>>>> \n\n');
    if (!isPlaying) {
      loadFile(filename).then((_) {
        play(filename);
      });
    }
  }

  Future<Null> playMusicFile(String localPath) async {
    print('\n\n <<<<<<<< PLAYING >>>>>>>>>> \n\n');
    if (!isPlaying) {
      play(localPath);
    }
  }
}

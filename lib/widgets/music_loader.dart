import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../utilities/audio.dart';

class MyMusicPlayer extends StatefulWidget {
  final String musicPath;
  final bool isActive;
  final String label;
  final Function(int) sendMusicDurations;
  final VoidCallback onMusicCompleted;
  final Function(bool) onMusicPlayStatus;
  const MyMusicPlayer({
    Key? key,
    required this.musicPath,
    required this.label,
    required this.isActive,
    required this.sendMusicDurations,
    required this.onMusicCompleted,
    required this.onMusicPlayStatus,
  }) : super(key: key);

  @override
  _MyMusicPlayerState createState() => _MyMusicPlayerState();
}

class _MyMusicPlayerState extends State<MyMusicPlayer> {
  AudioService audio = AudioService();

  @override
  void initState() {
    super.initState();
    audio.initAudioPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

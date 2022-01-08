import 'dart:io';
import 'package:flutter/material.dart';
import 'package:disk_space/disk_space.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import './widgets/slider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();

    runApp(const MainApp());
  } catch (error) {
    print('Activation Status error: $error');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'File loader app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'File loading app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _percentage = 0;
  bool _isDownloading = false;
  double _diskSpace = 0.0;
  Map<Directory, double> _directorySpace = {};
  final GlobalKey _sliderKey = GlobalKey();
  _buildSlidePage(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
        child: Slideshow(
          key: _sliderKey,
          progressCallback: (val) => setState(() => _percentage = val),
          isDownloadingCallback: (val) => setState(() => _isDownloading = val),
        ),
      ),
    );
  }

  Future<void> initDiskSpace() async {
    double? diskSpace = 0.0;

    diskSpace = await DiskSpace.getFreeDiskSpace as double;

    List<Directory> directories;
    Map<Directory, double> directorySpace = {};

    if (Platform.isIOS) {
      directories = [await getApplicationDocumentsDirectory()];
    } else if (Platform.isAndroid) {
      directories =
          await getExternalStorageDirectories(type: StorageDirectory.movies)
              .then(
        (list) async => list ?? [await getApplicationDocumentsDirectory()],
      );
    } else {
      return;
    }

    for (var directory in directories) {
      var space = await DiskSpace.getFreeDiskSpaceForPath(directory.path);
      directorySpace.addEntries([MapEntry(directory, space!)]);
    }

    if (!mounted) return;

    print('\n\n DISK SIZE: $diskSpace (MB) \n\n');
    setState(() {
      _diskSpace = diskSpace!;
      _directorySpace = directorySpace;
    });
  }

  @override
  void initState() {
    super.initState();
    initDiskSpace();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _buildSlidePage(context),
      floatingActionButton: _isDownloading
          ? Padding(
              padding: const EdgeInsets.only(top: 120),
              child: CircularStepProgressIndicator(
                totalSteps: 100,
                currentStep: _percentage,
                stepSize: 1,
                selectedColor: Colors.blue[700],
                unselectedColor: Colors.grey,
                padding: 0,
                width: 90,
                height: 90,
                selectedStepSize: 8,
                unselectedStepSize: 4,
                roundedCap: (_, __) => true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Text(
                    '$_percentage%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : const Text(''),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

class MainSlide extends StatefulWidget {
  const MainSlide({Key? key}) : super(key: key);

  @override
  _MainSlideState createState() => _MainSlideState();
}

class _MainSlideState extends State<MainSlide> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Mmm extends StatefulWidget {
  const Mmm({Key? key}) : super(key: key);

  @override
  State<Mmm> createState() => _MmmState();
}

class _MmmState extends State<Mmm> {
  FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer? myPlayer = FlutterSoundPlayer();
  String? path;
  late bool isRecording = myRecorder!.isRecording;
  File? file;
  record() async {
    var tempDir = await getApplicationDocumentsDirectory();
    path = "${tempDir.path}/voice.aac";
    file = File(path!);

    path = "${tempDir.path}/voice.aac";
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      myRecorder.openAudioSession();
      myRecorder.startRecorder(toFile: file?.path, codec: Codec.aacADTS);
      setState(() {});
    }
  }

  stopRecord() async {
    await myRecorder.stopRecorder();

    setState(() {});
  }

  startPlay() async {
    await myPlayer?.openAudioSession();
    setState(() {});
    await myPlayer?.startPlayer(fromURI: file?.path, codec: Codec.aacADTS);
  }

  stopPlay() async {
    setState(() {});
    await myPlayer?.stopPlayer();
    myPlayer?.closeAudioSession();
  }

  @override
  void initState() {
    //recorder.init();
    super.initState();
  }

  @override
  void dispose() {
    myRecorder.closeAudioSession();
    myPlayer?.closeAudioSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("${myRecorder.isRecording}hh");
    return Scaffold(
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text(
                myRecorder.isRecording ? "STOP" : "START",
              ),
              onPressed: () async {
                setState(() {});
                await record();
              },
            ),
            ElevatedButton(
              child: Text(
                "STOP",
              ),
              onPressed: () async {
                await stopRecord();
              },
            ),
            ElevatedButton(
              child: Text(
                "PLAY",
              ),
              onPressed: () async {
                await startPlay();
              },
            ),
            ElevatedButton(
              child: Text(
                "STOP PLAY",
              ),
              onPressed: () async {
                await stopPlay();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// class Soundrecorder {
//   FlutterSoundRecorder? audioRecorder;
//   bool isRecorderInitialised = false;
//   bool? get isRecordin => audioRecorder?.isRecording;
//   Future init() async {
//     final audioRecorder = FlutterSoundRecorder();
//     final status = await Permission.microphone.request();

//     if (status != PermissionStatus.granted) {
//       throw RecordingPermissionException("Something gone wrong");
//     }
//     await audioRecorder?.openAudioSession();
//     isRecorderInitialised = true;
//   }

//   dispose() {
//     audioRecorder?.closeAudioSession();
//     audioRecorder = null;
//     isRecorderInitialised = false;
//   }

//   Future record() async {
//     if (!isRecorderInitialised) return;
//     await audioRecorder?.startRecorder();
//   }

//   Future stop() async {
//     if (!isRecorderInitialised) return;
//     await audioRecorder?.stopRecorder();
//   }

//   Future toogleRecording() async {
//     if (audioRecorder?.isStopped != null && true) {
//       await record();
//     } else {
//       await stop();
//     }
//   }
// }

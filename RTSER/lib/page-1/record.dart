import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtser/page-1/playaudio.dart';

class Record extends StatefulWidget {
  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  late final RecorderController recorderController;
  late Duration recordingDuration;
  late Timer _timer;

  String? path;
  String? musicFile;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  bool isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = "${appDirectory.path}/recording.m4a";
    isLoading = false;
    setState(() {});
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    recordingDuration = Duration(seconds: 0);
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      musicFile = result.files.single.path;
      setState(() {});
    } else {
      debugPrint("File not picked");
    }
  }

  @override
  void dispose() {
    recorderController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return Container(
      width: double.infinity,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff06030b),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding:
                  EdgeInsets.fromLTRB(17 * fem, 41 * fem, 14 * fem, 35 * fem),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin:
                        EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 3 * fem),
                    width: double.infinity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(
                              0 * fem, 0 * fem, 121.12 * fem, 0.68 * fem),
                          width: 21.88 * fem,
                          height: 21.32 * fem,
                          child: Image.asset(
                            'assets/page-1/images/vector-jWm.png',
                            width: 21.88 * fem,
                            height: 21.32 * fem,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(
                              0 * fem, 0 * fem, 107 * fem, 1 * fem),
                          child: RichText(
                            text: TextSpan(
                              text: 'SER',
                              style: TextStyle(
                                fontSize: 20 * ffem,
                                fontWeight: FontWeight.w800,
                                color: Color(0xffffffff),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 40 * fem,
                          height: 40 * fem,
                          child: Image.asset(
                            'assets/page-1/images/vector-Gx5.png',
                            width: 40 * fem,
                            height: 40 * fem,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 150,
                  ),
                  GestureDetector(
                    onTap: () async {
                      _startOrStopRecording();
                    },
                    child: AvatarGlow(
                      startDelay: const Duration(milliseconds: 1000),
                      repeat: isRecording,
                      glowColor: Colors.white,
                      glowShape: BoxShape.circle,
                      curve: Curves.fastOutSlowIn,
                      child: const Material(
                        elevation: 8.0,
                        shape: CircleBorder(),
                        color: Colors.transparent,
                        child: CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/page-1/images/mic.png'),
                          radius: 80.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${recordingDuration.inHours.toString().padLeft(2, '0')}:',
                        ),
                        TextSpan(
                          text:
                              '${(recordingDuration.inMinutes % 60).toString().padLeft(2, '0')}:',
                        ),
                        TextSpan(
                          text:
                              '${(recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AudioWaveforms(
                          enableGesture: true,
                          size: Size(
                              MediaQuery.of(context).size.width - 100, 100),
                          recorderController: recorderController,
                          waveStyle: const WaveStyle(
                            waveColor: Colors.blue,
                            extendWaveform: true,
                            showMiddleLine: false,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: const Color(0xff06030b),
                          ),
                          padding: const EdgeInsets.only(left: 18),
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();

        final path = await recorderController.stop(false);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path).lengthSync()}");

          // Upload recorded audio file to Firebase Storage
          await _uploadAudioToFirebase(path);
        }

        // Stop and reset the timer when recording stops
        _stopAndResetTimer();
      } else {
        recordingDuration =
            Duration(seconds: 0); // Reset duration when recording starts

        // Start the periodic timer to update the duration
        _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
          setState(() {
            recordingDuration = recordingDuration + Duration(seconds: 1);
          });
        });

        await recorderController.record(path: path!);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  // Function to stop and reset the timer
  void _stopAndResetTimer() {
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
    recordingDuration = Duration(seconds: 0);
  }

  Future<void> _uploadAudioToFirebase(String filePath) async {
    try {
      File audioFile = File(filePath);
      String fileName =
          "recordings/${DateTime.now().millisecondsSinceEpoch}.m4a";

      // Specify a reference by providing a path
      firebase_storage.Reference storageReference =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);

      await storageReference.putFile(audioFile);
      String downloadURL = await storageReference.getDownloadURL();

      // Now, you can save downloadURL to Firebase Database or perform any other actions.

      print("Audio file uploaded. Download URL: $downloadURL");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlayAudio()),
      );
    } catch (e) {
      // Handle audio file upload error
      print("Error uploading audio file: $e");
      if (e is firebase_storage.FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
        print("Firebase Storage Inner Exception: ${e.stackTrace}");
      }
    }
  }
}
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile pickedImage;
  var imageFile;
  File image;
  List<Rect> rect = [];
  List<Offset> eyes = [];

  bool isFaceDetected = false;

  Future pickImage(String mode) async {
    var awaitImage;
    mode == 'gallery'
        ? awaitImage = await ImagePicker().getImage(source: ImageSource.gallery)
        : awaitImage = await ImagePicker().getImage(source: ImageSource.camera);

    imageFile = await awaitImage.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      imageFile = imageFile;
      pickedImage = awaitImage;
      image = File(pickedImage.path);
    });
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);

    final FaceDetector faceDetector = FirebaseVision.instance
        .faceDetector(FaceDetectorOptions(enableLandmarks: true));

    final List<Face> faces = await faceDetector.processImage(visionImage);
    if (rect.length > 0) {
      rect = [];
      eyes = [];
    }
    for (Face face in faces) {
      rect.add(face.boundingBox);
      final FaceLandmark leftEye = face.getLandmark(FaceLandmarkType.leftEye);
      print(leftEye);
      if (leftEye != null) {
        print(leftEye.position);
        eyes.add(leftEye.position);
      }
      final FaceLandmark rightEye = face.getLandmark(FaceLandmarkType.rightEye);
      if (rightEye != null) {
        eyes.add(rightEye.position);
      }
    }

    setState(() {
      isFaceDetected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 50.0),
          isFaceDetected
              ? Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(blurRadius: 20),
                      ],
                    ),
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: FittedBox(
                      child: SizedBox(
                        width: imageFile.width.toDouble(),
                        height: imageFile.height.toDouble(),
                        child: CustomPaint(
                          painter: FacePainter(
                              rect: rect, imageFile: imageFile, eyes: eyes),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
          Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatButton.icon(
                icon: Icon(
                  Icons.photo_camera,
                  size: 100,
                ),
                label: Text(''),
                textColor: Theme.of(context).primaryColor,
                onPressed: () async {
                  pickImage('camera');
                },
              ),
              FlatButton.icon(
                icon: Icon(
                  Icons.photo_size_select_actual,
                  size: 100,
                ),
                label: Text(''),
                textColor: Theme.of(context).primaryColor,
                onPressed: () async {
                  pickImage('gallery');
                },
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rect;
  var imageFile;
  List<Offset> eyes;
  FacePainter(
      {@required this.rect, @required this.imageFile, @required this.eyes});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    for (Rect rectangle in rect) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawPoints(
        PointMode.points,
        eyes,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 6.0);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

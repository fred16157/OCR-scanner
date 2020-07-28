import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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

var text = '';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  File pickedImage;
  ImagePicker _picker = ImagePicker();
  bool imageLoaded = false;
  VisionText visionText;
  @override
  void initState() {
    super.initState();
  }

  Future pickImage() async {
    var awaitImage = await _picker.getImage(source: ImageSource.gallery);
    text = "";
    setState(() {
      pickedImage = File(awaitImage.path);
      imageLoaded = true;
    });
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    visionText = await textRecognizer.processImage(visionImage);
    setState(() {});
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            text = text + word.text + ' ';
          });
        }
        text = text + '\n';
      }
    }
    textRecognizer.close();
  }

  Future getCameraImage() async {
    var awaitImage = await _picker.getImage(source: ImageSource.camera);
    text = "";
    setState(() {
      pickedImage = File(awaitImage.path);
      imageLoaded = true;
    });
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    visionText = await textRecognizer.processImage(visionImage);
    setState(() {});
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            text = text + word.text + ' ';
          });
        }
        text = text + '\n';
      }
    }
    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(height: 100.0),
              imageLoaded
                  ? Center(
                      child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        boxShadow: const [
                          BoxShadow(blurRadius: 20),
                        ],
                      ),
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: Stack(children: <Widget>[
                        Image.file(
                          pickedImage,
                          fit: BoxFit.cover,
                        ),
                      ],)
                    ))
                  : Center(
                      child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          children: <Widget>[
                            Text("로드된 이미지가 없습니다."),
                            RaisedButton(
                              child: Text("카메라로 이미지 찍기"),
                              onPressed: () async {
                                await getCameraImage();
                              },
                            ),
                            Text("또는"),
                            RaisedButton(
                              child: Text("저장된 이미지 불러오기"),
                              onPressed: () async {
                                await pickImage();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
          _buildResults(visionText),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 200,
                width: double.maxFinite,
                child: imageLoaded
                    ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              PageRouteBuilder(
                                  transitionDuration:
                                      Duration(milliseconds: 500),
                                  pageBuilder: (_, __, ___) =>
                                      TextViewerPage()));
                        },
                        child: Hero(
                          tag: "transition-target",
                          child: Card(
                            elevation: 16,
                            child: text == ''
                                ? Text('텍스트 분석 중...')
                                : Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      text,
                                    ),
                                  ),
                          ),
                        ))
                    : Container(),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => print('OPENING DIAL'),
        onClose: () => print('DIAL CLOSED'),
        tooltip: 'Speed Dial',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 8.0,
        shape: CircleBorder(),
        children: [
          SpeedDialChild(
              child: Icon(Icons.folder),
              backgroundColor: Colors.red,
              label: '저장된 이미지 가져오기',
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () async => await pickImage()),
          SpeedDialChild(
              child: Icon(Icons.camera_alt),
              backgroundColor: Colors.blue,
              label: '카메라로 이미지 찍기',
              labelStyle: TextStyle(fontSize: 18.0),
              onTap: () async => await getCameraImage()),
        ],
      ),
    );
  }

  Widget _buildResults(VisionText scanResults) {
    CustomPainter painter;
    if (scanResults != null) {
      var decodedImage = Image.file(pickedImage);
      final Size imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      painter = TextDetectorPainter(imageSize, scanResults);

      return CustomPaint(
        painter: painter,
      );
    } else {
      return Container();
    }
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.visionText);

  final Size absoluteImageSize;
  final VisionText visionText;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        container.boundingBox.left * scaleX,
        container.boundingBox.top * scaleY,
        container.boundingBox.right * scaleX,
        container.boundingBox.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          paint.color = Colors.green;
          canvas.drawRect(scaleRect(element), paint);
        }

        paint.color = Colors.yellow;
        canvas.drawRect(scaleRect(line), paint);
      }

      paint.color = Colors.red;
      canvas.drawRect(scaleRect(block), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.visionText != visionText;
  }
}

class TextViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("텍스트 보기"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.content_copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                SnackBar(
                  content: Text("텍스트가 클립보드에 복사되었습니다."),
                  duration: Duration(milliseconds: 500),
                );
              },
            )
          ],
        ),
        body: Hero(
            tag: "transition-target",
            child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0), child: Text(text))));
  }
}

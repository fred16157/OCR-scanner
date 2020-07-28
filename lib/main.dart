import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  File pickedImage;
  ImagePicker _picker = ImagePicker();
  bool imageLoaded = false;

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
    VisionText visionText = await textRecognizer.processImage(visionImage);

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
    VisionText visionText = await textRecognizer.processImage(visionImage);

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
                    child: Image.file(
                      pickedImage,
                      fit: BoxFit.cover,
                    ),
                  ))
                : Center(
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
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
                  )),
          ],
        ),
        Positioned(
          bottom: 0.0,
          child: Container(
            alignment: Alignment.bottomCenter,
            height: 120,
            width: double.maxFinite,
            child: imageLoaded
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 500),
                              pageBuilder: (_, __, ___) => TextViewerPage()));
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
      ],
    ));
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

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_text/vision_detector_views/painters/coordinates_translator.dart';

import '../main.dart';

enum ScreenMode { liveFeed, gallery }

class TestView extends StatefulWidget {
  TestView(
      {Key? key,
      required this.title,
      required this.customPaint,
      this.text,
      this.onScreenModeChanged,
      this.initialDirection = CameraLensDirection.back})
      : super(key: key);

  final String title;
  final CustomPaint? customPaint;
  final String? text;

  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;

  @override
  State<TestView> createState() => _TestViewState();
}

class _TestViewState extends State<TestView> {
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraController? _controller;
  File? _image;
  String? _path;
  ImagePicker? _imagePicker;
  int _cameraIndex = -1;
  final bool _allowPicker = true;
  final bool _changingCameraLens = false;
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);
  List<Offset> offsetList = [];
  List<Widget> frameList = [];
  List<Size> sizeList = [];
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;

  @override
  void initState() {
    super.initState();

    _imagePicker = ImagePicker();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == widget.initialDirection) {
          _cameraIndex = i;
          break;
        }
      }
    }

    if (_cameraIndex != -1) {
      _startLiveFeed();
    } else {
      _mode = ScreenMode.gallery;
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    _canProcess = false;
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_allowPicker)
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: _switchScreenMode,
                child: Icon(
                  _mode == ScreenMode.liveFeed
                      ? Icons.photo_library_outlined
                      : (Platform.isIOS
                          ? Icons.camera_alt_outlined
                          : Icons.camera),
                ),
              ),
            ),
        ],
      ),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _floatingActionButton() {
    return SizedBox(
      height: 70.0,
      width: 70.0,
      child: FloatingActionButton(
        onPressed: () async {
          //final image = await _controller?.takePicture();
          await takePicture();
        },
        child: Icon(
          Platform.isIOS
              ? Icons.flip_camera_ios_outlined
              : Icons.flip_camera_android_outlined,
          size: 40,
        ),
      ),
    );
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.liveFeed) {
      body = _liveFeedBody();
    } else {
      body = _galleryBody();
    }
    return body;
  }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_image == null)
            Transform.scale(
              scale: scale,
              child: Center(
                child: _changingCameraLens
                    ? const Center(
                        child: Text('Changing camera lens'),
                      )
                    : CameraPreview(_controller!),
              ),
            ),
          if (_image != null)
            Transform.scale(
              scale: scale,
              child: Center(
                child: _changingCameraLens
                    ? const Center(
                        child: Text('Changing camera lens'),
                      )
                    : Image.file(_image!),
              ),
            ),
          //if (widget.customPaint != null) widget.customPaint!,
          if (_image != null)
            for (int i = 0; i < offsetList.length; i++)
              Positioned(
                left: offsetList[i].dx,
                top: offsetList[i].dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (DragUpdateDetails details) {
                    setState(() {
                      offsetList[i] = offsetList[i] += details.delta;
                    });
                  },
                  child: Container(
                    child: frameList[i],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? SizedBox(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image!),
                  if (widget.customPaint != null) widget.customPaint!,
                ],
              ),
            )
          : Icon(
              Icons.image,
              size: 200,
            ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
      if (_image != null)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
              '${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}'),
        ),
    ]);
  }

  Future _getImage(ImageSource source) async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile = await _imagePicker?.pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

  void _switchScreenMode() {
    _image = null;
    if (_mode == ScreenMode.liveFeed) {
      _mode = ScreenMode.gallery;
      _stopLiveFeed();
    } else {
      _mode = ScreenMode.liveFeed;
      _startLiveFeed();
    }
    if (widget.onScreenModeChanged != null) {
      widget.onScreenModeChanged!(_mode);
    }
    setState(() {});
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      //_controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;
    // final inputImage = InputImage.fromFilePath(path);
    // processImage(inputImage);
    // await _controller?.stopImageStream();
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    processImage(inputImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    setState(() {
      _text = '';
    });
    final recognizedText = await textRecognizer.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // final painter = TextRecognizerPainter(
      //   recognizedText,
      //   inputImage.inputImageData!.size,
      //   inputImage.inputImageData!.imageRotation,
      // );
      // _customPaint = CustomPaint(painter: painter);

      final offsets = <Offset>[];
      final frames = <Widget>[];
      final sizes = <Size>[];
      final height = MediaQuery.of(context).size.height;
      final width = MediaQuery.of(context).size.width;
      print(recognizedText.blocks.length);
      for (var i = 0; i < recognizedText.blocks.length; i++) {
        final left = translateX(
          recognizedText.blocks[i].boundingBox.left,
          inputImage.inputImageData!.imageRotation,
          Size(width, height),
          inputImage.inputImageData!.size,
        );
        final top = translateY(
          recognizedText.blocks[i].boundingBox.top,
          inputImage.inputImageData!.imageRotation,
          Size(width, height),
          inputImage.inputImageData!.size,
        );
        final right = translateX(
          recognizedText.blocks[i].boundingBox.right,
          inputImage.inputImageData!.imageRotation,
          Size(width, height),
          inputImage.inputImageData!.size,
        );
        final bottom = translateY(
          recognizedText.blocks[i].boundingBox.bottom,
          inputImage.inputImageData!.imageRotation,
          Size(width, height),
          inputImage.inputImageData!.size,
        );
        final frame = GestureDetector(
          onTap: () {
            print(recognizedText.blocks[i].text);
          },
          child: Container(
            height: bottom - top,
            width: right - left,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 3,
              ),
            ),
          ),
        );
        final offset = Offset(left, top);
        final size = Size(width, height);
        frames.add(frame);
        offsets.add(offset);
        sizes.add(size);
      }
      setState(() {
        frameList = frames;
        offsetList = offsets;
        sizeList = sizes;
      });
    } else {
      _text = 'Recognized text:\n\n${recognizedText.text}';
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> takePicture() async {
    if (_controller != null) {
      final image = await _controller!.takePicture();
      await _controller!.startImageStream((CameraImage cameraImage) async {
        await _controller!.stopImageStream();
        await _processPickedFile(image);
        await _processCameraImage(cameraImage);
      });
    }
  }
}

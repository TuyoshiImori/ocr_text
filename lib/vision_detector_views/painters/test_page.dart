import 'package:flutter/material.dart';
import 'package:ocr_text/vision_detector_views/test_view.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  CustomPaint? _customPaint;
  String? _text;

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestView(
      title: 'Text Detector',
      customPaint: _customPaint,
      text: _text,
    );
  }
}

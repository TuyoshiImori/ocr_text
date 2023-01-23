import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

part 'gallery_page_controller.freezed.dart';

@freezed
class GalleryPageState with _$GalleryPageState {
  const factory GalleryPageState({
    @Default('') String text,
    @Default(Offset.zero) Offset frameLeftTopOffset,
    @Default(Offset.zero) Offset frameRightTopOffset,
    @Default(Offset.zero) Offset frameLeftBottomOffset,
    @Default(Offset.zero) Offset frameRightBottomOffset,
    @Default(false) bool hasDeviceSize,
    @Default(0) double deviceHeight,
    @Default(0) double deviceWidth,
    File? imageFile,
    String? imagePath,
  }) = _GalleryPageState;
}

final galleryPageProvider =
StateNotifierProvider.autoDispose<GalleryPageController, GalleryPageState>(
        (ref) {
      return GalleryPageController();
    });

class GalleryPageController extends StateNotifier<GalleryPageState> {
  GalleryPageController() : super(const GalleryPageState()) {
    _init();
  }

  final TextRecognizer textRecognizer =
  TextRecognizer(script: TextRecognitionScript.japanese);

  Future<void> _init() async {
    await galleryPicker();
  }

  void initialFrameOffset({
    required double deviceHeight,
    required double deviceWidth,
  }) {
    if (!state.hasDeviceSize) {
      state = state.copyWith(
        // deviceHeight: deviceHeight,
        // deviceWidth: deviceWidth,
        frameLeftBottomOffset: Offset(0, deviceHeight * 0.75),
        frameRightTopOffset: Offset(deviceWidth * 0.75, 0),
        frameRightBottomOffset: Offset(deviceWidth * 0.75, deviceHeight * 0.75),
        hasDeviceSize: true,
      );
    }
  }

  Future<void> galleryPicker() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final path = pickedFile.path;
      final properties = await FlutterNativeImage.getImageProperties(path);
      final propertiesHeight = properties.height;
      final propertiesWidth = properties.width;
      if (propertiesHeight != null && propertiesWidth != null) {
        final deviceHeight = propertiesHeight.toDouble();
        final deviceWidth = propertiesWidth.toDouble();
        state = state.copyWith(
          imageFile: File(path),
          imagePath: path,
          deviceHeight: deviceHeight,
          deviceWidth: deviceWidth,
          frameLeftBottomOffset: Offset(0, deviceHeight),
          frameRightTopOffset: Offset(deviceWidth, 0),
          frameRightBottomOffset: Offset(deviceWidth, deviceHeight),
        );
      }

    }
  }

  Future<void> processImage() async {
    final imagePath = state.imagePath;
    if (imagePath == null) {
      return;
    }
    final properties = await FlutterNativeImage.getImageProperties(imagePath);
    final propertiesHeight = properties.height;
    final propertiesWidth = properties.width;
    if (propertiesHeight != null && propertiesWidth != null) {
      final frameLeftTopOffset = state.frameLeftTopOffset;
      final deviceHeight = state.deviceHeight;
      final deviceWidth = state.deviceWidth;

      ///写真上の座標比率を画面座標と合わせる
      final originX =
          propertiesWidth * (frameLeftTopOffset.dx / (deviceWidth));
      final originY =
          propertiesHeight * (frameLeftTopOffset.dy / (deviceHeight));

      ///画面上の長さをImagePropertiesと合わせる
      final originWidth =
          (state.frameRightTopOffset.dx - state.frameLeftTopOffset.dx) *
              (propertiesWidth / (deviceWidth));
      final originHeight =
          (state.frameLeftBottomOffset.dy - state.frameLeftTopOffset.dy) *
              (propertiesHeight / (deviceHeight));
      final croppedFile = await FlutterNativeImage.cropImage(
        imagePath,
        originX.toInt(),
        originY.toInt(),
        originWidth.toInt(),
        originHeight.toInt(),
      );
      state = state.copyWith(imageFile: croppedFile);

      final inputImage = InputImage.fromFile(croppedFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      if (inputImage.inputImageData?.size != null &&
          inputImage.inputImageData?.imageRotation != null) {
        state = state.copyWith(
          text: recognizedText.text,
        );
      } else {
        state = state.copyWith(
          text: recognizedText.text,
        );
      }
    }
  }

  /// 真ん中
  void dragFrame({
    required double dx,
    required double dy,
  }) {
    final frameLeftTopOffset = state.frameLeftTopOffset;
    final frameRightTopOffset = state.frameRightTopOffset;
    final frameLeftBottomOffset = state.frameLeftBottomOffset;
    final frameRightBottomOffset = state.frameRightBottomOffset;

    if (0 <= frameLeftTopOffset.dx + dx &&
        0 <= frameLeftTopOffset.dy + dy &&
        state.deviceWidth >= frameRightBottomOffset.dx + dx &&
        state.deviceHeight >= frameRightBottomOffset.dy + dy) {
      // 全体移動
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(frameLeftTopOffset.dx + dx, frameLeftTopOffset.dy + dy),
        frameLeftBottomOffset: Offset(
          frameLeftBottomOffset.dx + dx,
          frameLeftBottomOffset.dy + dy,
        ),
        frameRightTopOffset:
        Offset(frameRightTopOffset.dx + dx, frameRightTopOffset.dy + dy),
        frameRightBottomOffset: Offset(
          frameRightBottomOffset.dx + dx,
          frameRightBottomOffset.dy + dy,
        ),
      );
    } else if (0 <= frameLeftTopOffset.dx + dx &&
        state.deviceWidth >= frameRightBottomOffset.dx + dx) {
      // 横移動
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(frameLeftTopOffset.dx + dx, frameLeftTopOffset.dy),
        frameLeftBottomOffset: Offset(
          frameLeftBottomOffset.dx + dx,
          frameLeftBottomOffset.dy,
        ),
        frameRightTopOffset:
        Offset(frameRightTopOffset.dx + dx, frameRightTopOffset.dy),
        frameRightBottomOffset: Offset(
          frameRightBottomOffset.dx + dx,
          frameRightBottomOffset.dy,
        ),
      );
    } else if (0 <= frameLeftTopOffset.dy + dy &&
        state.deviceHeight >= frameRightBottomOffset.dy + dy) {
      // 縦移動
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(frameLeftTopOffset.dx, frameLeftTopOffset.dy + dy),
        frameLeftBottomOffset: Offset(
          frameLeftBottomOffset.dx,
          frameLeftBottomOffset.dy + dy,
        ),
        frameRightTopOffset:
        Offset(frameRightTopOffset.dx, frameRightTopOffset.dy + dy),
        frameRightBottomOffset: Offset(
          frameRightBottomOffset.dx,
          frameRightBottomOffset.dy + dy,
        ),
      );
    }
  }

  /// 左上
  void dragFrameLeftTopCorner({
    required double dx,
    required double dy,
  }) {
    final updateDxPosition = state.frameLeftTopOffset.dx + dx;
    final updateDyPosition = state.frameLeftTopOffset.dy + dy;
    if (0 <= updateDxPosition &&
        0 <= updateDyPosition &&
        60 <= state.frameRightTopOffset.dx - updateDxPosition &&
        60 <= state.frameLeftBottomOffset.dy - updateDyPosition) {
      // 全体移動
      state = state.copyWith(
        frameLeftTopOffset: Offset(updateDxPosition, updateDyPosition),
        frameLeftBottomOffset:
        Offset(updateDxPosition, state.frameLeftBottomOffset.dy),
        frameRightTopOffset:
        Offset(state.frameRightTopOffset.dx, updateDyPosition),
      );
    } else if (0 <= updateDxPosition &&
        60 <= state.frameRightTopOffset.dx - updateDxPosition) {
      // 横移動
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(updateDxPosition, state.frameLeftTopOffset.dy),
        frameLeftBottomOffset:
        Offset(updateDxPosition, state.frameLeftBottomOffset.dy),
      );
    } else if (0 <= updateDyPosition &&
        60 <= state.frameLeftBottomOffset.dy - updateDyPosition) {
      // 縦移動
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(state.frameLeftTopOffset.dx, updateDyPosition),
        frameRightTopOffset:
        Offset(state.frameRightTopOffset.dx, updateDyPosition),
      );
    }
  }

  /// 右上
  void dragFrameRightTopCorner({
    required double dx,
    required double dy,
  }) {
    final updateDxPosition = state.frameRightTopOffset.dx + dx;
    final updateDyPosition = state.frameRightTopOffset.dy + dy;
    if (updateDxPosition <= state.deviceWidth &&
        0 <= updateDyPosition &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx &&
        updateDyPosition <= state.frameLeftBottomOffset.dy - 60) {
      // 全体移動
      state = state.copyWith(
        frameRightTopOffset: Offset(updateDxPosition, updateDyPosition),
        frameLeftTopOffset:
        Offset(state.frameLeftTopOffset.dx, updateDyPosition),
        frameRightBottomOffset:
        Offset(updateDxPosition, state.frameRightBottomOffset.dy),
      );
    } else if (updateDxPosition <= state.deviceWidth &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx) {
      // 横移動
      state = state.copyWith(
        frameRightTopOffset:
        Offset(updateDxPosition, state.frameRightTopOffset.dy),
        frameRightBottomOffset:
        Offset(updateDxPosition, state.frameRightBottomOffset.dy),
      );
    } else if (0 <= updateDyPosition &&
        updateDyPosition <= state.frameLeftBottomOffset.dy - 60) {
      // 縦移動
      state = state.copyWith(
        frameRightTopOffset:
        Offset(state.frameRightTopOffset.dx, updateDyPosition),
        frameLeftTopOffset:
        Offset(state.frameLeftTopOffset.dx, updateDyPosition),
      );
    }
  }

  /// 左下
  void dragFrameLeftBottomCorner({
    required double dx,
    required double dy,
  }) {
    final updateDxPosition = state.frameLeftBottomOffset.dx + dx;
    final updateDyPosition = state.frameLeftBottomOffset.dy + dy;
    if (0 <= updateDxPosition &&
        updateDyPosition <= state.deviceHeight &&
        updateDxPosition <= state.frameRightBottomOffset.dx - 60 &&
        updateDyPosition >= state.frameLeftTopOffset.dy + 60) {
      // 全体移動
      state = state.copyWith(
        frameLeftBottomOffset: Offset(updateDxPosition, updateDyPosition),
        frameLeftTopOffset:
        Offset(updateDxPosition, state.frameLeftTopOffset.dy),
        frameRightBottomOffset:
        Offset(state.frameRightBottomOffset.dx, updateDyPosition),
      );
    } else if (0 <= updateDxPosition &&
        updateDxPosition <= state.frameRightBottomOffset.dx - 60) {
      // 横移動
      state = state.copyWith(
        frameLeftBottomOffset:
        Offset(updateDxPosition, state.frameLeftBottomOffset.dy),
        frameLeftTopOffset:
        Offset(updateDxPosition, state.frameLeftTopOffset.dy),
      );
    } else if (updateDyPosition <= state.deviceHeight &&
        updateDyPosition >= state.frameLeftTopOffset.dy + 60) {
      // 縦移動
      state = state.copyWith(
        frameLeftBottomOffset:
        Offset(state.frameLeftBottomOffset.dx, updateDyPosition),
        frameRightBottomOffset:
        Offset(state.frameRightBottomOffset.dx, updateDyPosition),
      );
    }
  }

  /// 右下
  void dragFrameRightBottomCorner({
    required double dx,
    required double dy,
  }) {
    final updateDxPosition = state.frameRightBottomOffset.dx + dx;
    final updateDyPosition = state.frameRightBottomOffset.dy + dy;
    if (updateDxPosition <= state.deviceWidth &&
        updateDyPosition <= state.deviceHeight &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx &&
        updateDyPosition >= state.frameLeftTopOffset.dy + 60) {
      // 全体移動
      state = state.copyWith(
        frameRightBottomOffset: Offset(updateDxPosition, updateDyPosition),
        frameRightTopOffset:
        Offset(updateDxPosition, state.frameRightTopOffset.dy),
        frameLeftBottomOffset:
        Offset(state.frameLeftBottomOffset.dx, updateDyPosition),
      );
    } else if (updateDxPosition <= state.deviceWidth &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx) {
      // 横移動
      state = state.copyWith(
        frameRightBottomOffset:
        Offset(updateDxPosition, state.frameRightBottomOffset.dy),
        frameRightTopOffset:
        Offset(updateDxPosition, state.frameRightTopOffset.dy),
      );
    } else if (updateDyPosition <= state.deviceHeight &&
        updateDyPosition >= state.frameLeftTopOffset.dy + 60) {
      // 縦移動
      state = state.copyWith(
        frameRightBottomOffset:
        Offset(state.frameRightBottomOffset.dx, updateDyPosition),
        frameLeftBottomOffset:
        Offset(state.frameLeftBottomOffset.dx, updateDyPosition),
      );
    }
  }

  /// 左
  void dragFrameLeftSide({
    required double dx,
  }) {
    final leftTopDxPosition = state.frameLeftTopOffset.dx;
    final updateDxPosition = leftTopDxPosition + dx;
    final upperWidth = state.frameRightTopOffset.dx - updateDxPosition;
    if (0 <= updateDxPosition && 60 <= upperWidth) {
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(updateDxPosition, state.frameLeftTopOffset.dy),
        frameLeftBottomOffset:
        Offset(updateDxPosition, state.frameLeftBottomOffset.dy),
      );
    }
  }

  /// 右
  void dragFrameRightSide({
    required double dx,
  }) {
    final rightTopDxPositon = state.frameRightTopOffset.dx;
    final updateDxPosition = rightTopDxPositon + dx;
    if (state.deviceWidth >= updateDxPosition &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx) {
      state = state.copyWith(
        frameRightTopOffset:
        Offset(updateDxPosition, state.frameRightTopOffset.dy),
        frameRightBottomOffset:
        Offset(updateDxPosition, state.frameRightBottomOffset.dy),
      );
    }
  }

  /// 上
  void dragFrameTopDySide({
    required double dy,
  }) {
    final leftTopDyPosition = state.frameLeftTopOffset.dy + dy;
    final updateDyPosition = leftTopDyPosition + dy;
    final upperHeight = state.frameLeftBottomOffset.dy - updateDyPosition;
    if (0 <= updateDyPosition && 60 <= upperHeight) {
      state = state.copyWith(
        frameLeftTopOffset:
        Offset(state.frameLeftTopOffset.dx, updateDyPosition),
        frameRightTopOffset:
        Offset(state.frameRightTopOffset.dx, updateDyPosition),
      );
    }
  }

  /// 下
  void dragFrameBottomDySide({
    required double dy,
  }) {
    final leftBottomDyPosition = state.frameLeftBottomOffset.dy;
    final updateDyPosition = leftBottomDyPosition + dy;
    if (state.deviceHeight >= updateDyPosition &&
        updateDyPosition >= 60 + state.frameLeftTopOffset.dy) {
      state = state.copyWith(
        frameLeftBottomOffset:
        Offset(state.frameLeftBottomOffset.dx, updateDyPosition),
        frameRightBottomOffset:
        Offset(state.frameRightBottomOffset.dx, updateDyPosition),
      );
    }
  }
}
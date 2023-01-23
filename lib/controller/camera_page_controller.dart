import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

part 'camera_page_controller.freezed.dart';

@freezed
class CameraPageState with _$CameraPageState {
  const factory CameraPageState({
    @Default(<CameraDescription>[]) List<CameraDescription> cameras,
    @Default(false) bool changingCameraLens,
    @Default(false) bool hasFlash,
    @Default(-1) int cameraIndex,
    @Default(Offset.zero) Offset frameLeftTopOffset,
    @Default(Offset.zero) Offset frameRightTopOffset,
    @Default(Offset.zero) Offset frameLeftBottomOffset,
    @Default(Offset.zero) Offset frameRightBottomOffset,
    @Default(false) bool hasDeviceSize,
    @Default(0) double deviceHeight,
    @Default(0) double deviceWidth,
    @Default(1) double scale,
    String? text,
    String? imagePath,
    File? imageFile,
    @Default(0) double imageHeight,
    @Default(0) double imageWidth,
    @Default(0) double aspectRatio,
  }) = _CameraPageState;
}

final cameraPageProvider =
    StateNotifierProvider.autoDispose<CameraPageController, CameraPageState>(
        (ref) {
  return CameraPageController();
});

class CameraPageController extends StateNotifier<CameraPageState> {
  CameraPageController() : super(const CameraPageState()) {
    _init();
  }

  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);

  //ScreenMode mode = ScreenMode.liveFeed;
  CameraController? controller;
  final CameraLensDirection initialDirection = CameraLensDirection.back;
  final imagePicker = ImagePicker();

  Future<void> _init() async {
    final cameras = await availableCameras();
    var cameraIndex = -1;
    if (cameras.any(
      (e) => e.lensDirection == initialDirection && e.sensorOrientation == 90,
    )) {
      cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) =>
              element.lensDirection == initialDirection &&
              element.sensorOrientation == 90,
        ),
      );
    } else {
      for (var i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == initialDirection) {
          cameraIndex = i;
          break;
        }
      }
    }
    final camera = cameras[cameraIndex];
    controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      //imageFormatGroup: ImageFormatGroup.yuv420,

      ///imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    print('init');
    if (controller != null) {
      await controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        controller!.getMaxZoomLevel();
        controller!.getMinZoomLevel();
        controller!.setZoomLevel(1);
      });
    }
  }

  void initialScale({
    required Size size,
  }) {
    if (controller != null) {
      var scale = size.aspectRatio * controller!.value.aspectRatio;
      // to prevent scaling down, invert the value
      //if (scale < 1) scale = 1 / scale;
      state = state.copyWith(scale: scale);
    }
  }

  void geDeviceSize({
    required double deviceHeight,
    required double deviceWidth,
  }) {
    if (!state.hasDeviceSize) {
      state = state.copyWith(
        deviceHeight: deviceHeight,
        deviceWidth: deviceWidth,
        hasDeviceSize: true,
      );
    }
  }

  Future<void> startLiveFeed() async {
    final camera = state.cameras[state.cameraIndex];
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,

      ///imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    if (controller != null) {
      await controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
      });
    }
  }

  Future<void> processCameraImage({required File image}) async {
    final path = image.path;
    final properties = await FlutterNativeImage.getImageProperties(path);
    final propertiesHeight = properties.height;
    final propertiesWidth = properties.width;

    if (propertiesHeight != null && propertiesWidth != null) {
      final frameLeftTopOffset = state.frameLeftTopOffset;
      // final deviceHeight = state.deviceHeight;
      // final deviceWidth = state.deviceWidth;
      final imageHeight = state.imageHeight;
      final imageWidth = state.imageWidth;

      ///写真上の座標比率を画面座標と合わせる
      final originX = propertiesWidth * (frameLeftTopOffset.dx / imageWidth);
      final originY = propertiesHeight * (frameLeftTopOffset.dy / imageHeight);

      ///画面上の長さをImagePropertiesと合わせる
      final originWidth = ((imageWidth / 2 - frameLeftTopOffset.dx) * 2) *
          (propertiesWidth / imageWidth);
      final originHeight = ((imageHeight / 3 - frameLeftTopOffset.dy) * 2) *
          (propertiesHeight / imageHeight);
      final croppedFile = await FlutterNativeImage.cropImage(
        path,
        originX.toInt(),
        originY.toInt(),
        originWidth.toInt(),
        originHeight.toInt(),
      );
      //state = state.copyWith(imageFile: croppedFile);
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
    print(state.text);
  }

  Future<void> takePicture() async {
    if (controller != null) {
      //await controller!.setFlashMode(FlashMode.off);
      final image = await controller!.takePicture();
      final file = File(image.path);
      final path = file.path;
      final properties = await FlutterNativeImage.getImageProperties(path);
      final propertiesHeight = properties.height;
      final propertiesWidth = properties.width;
      if (propertiesHeight != null && propertiesWidth != null) {
        // final deviceHeight = propertiesHeight.toDouble();
        // final deviceWidth = propertiesWidth.toDouble();
        final deviceWidth = state.deviceWidth;

        final imageWidth = deviceWidth;
        final imageHeight = deviceWidth * (propertiesHeight / propertiesWidth);
        final centerPosition = Offset(imageWidth / 2, imageHeight / 2);

        state = state.copyWith(
          imageFile: file,
          imagePath: path,
          // frameLeftTopOffset: const Offset(0, 0),
          // frameLeftBottomOffset: Offset(0, imageHeight),
          // frameRightTopOffset: Offset(imageWidth, 0),
          // frameRightBottomOffset: Offset(imageWidth, imageHeight),
          frameLeftTopOffset: Offset(imageWidth * 0.25, imageHeight * 0.25),
          frameLeftBottomOffset: Offset(imageWidth * 0.25, imageHeight * 0.75),
          frameRightTopOffset: Offset(imageWidth * 0.75, imageHeight * 0.25),
          frameRightBottomOffset: Offset(imageWidth * 0.75, imageHeight * 0.75),
          aspectRatio: propertiesWidth / propertiesHeight,
          imageHeight: imageHeight,
          imageWidth: imageWidth,
        );
      }

      /// await processCameraImage(image: image);
    }
  }

  /// 変更予定
  // void dragFrameCorner({
  //   required double dx,
  //   required double dy,
  // }) {
  //   final dxPosition = state.frameLeftTopOffset.dx + dx;
  //   final dyPosition = state.frameLeftTopOffset.dy + dy;
  //   final deviceHeight = state.deviceHeight;
  //   final deviceWidth = state.deviceWidth;
  //   final upperHeight = deviceHeight / 3 - 20;
  //   final upperWidth = deviceWidth / 2 - 20;
  //   final lowerHeight = deviceHeight / 6;
  //   final lowerWidth = deviceWidth / 10;
  //
  //   if ((lowerWidth <= dxPosition && dxPosition <= upperWidth) &&
  //       (lowerHeight <= dyPosition && dyPosition <= upperHeight)) {
  //     state = state.copyWith(
  //       frameLeftTopOffset: Offset(dxPosition, dyPosition),
  //     );
  //   } else if (lowerHeight <= dyPosition && dyPosition <= upperHeight) {
  //     state = state.copyWith(
  //       frameLeftTopOffset: Offset(state.frameLeftTopOffset.dx, dyPosition),
  //     );
  //   } else if (lowerWidth <= dxPosition && dxPosition <= upperWidth) {
  //     state = state.copyWith(
  //       frameLeftTopOffset: Offset(dxPosition, state.frameLeftTopOffset.dy),
  //     );
  //   }
  // }
  //
  // void dragFrameDxSide({
  //   required double dx,
  // }) {
  //   final dxPosition = state.frameLeftTopOffset.dx + dx;
  //   final deviceWidth = state.deviceWidth;
  //   final upperWidth = deviceWidth / 2 - 30;
  //   final lowerWidth = deviceWidth / 10;
  //   if (lowerWidth <= dxPosition && dxPosition <= upperWidth) {
  //     state = state.copyWith(
  //       frameLeftTopOffset: Offset(dxPosition, state.frameLeftTopOffset.dy),
  //     );
  //   }
  // }
  //
  // void dragFrameDySide({
  //   required double dy,
  // }) {
  //   final dyPosition = state.frameLeftTopOffset.dy + dy;
  //   final deviceHeight = state.deviceHeight;
  //   final upperHeight = deviceHeight / 3 - 30;
  //   final lowerHeight = deviceHeight / 6;
  //   if (lowerHeight <= dyPosition && dyPosition <= upperHeight) {
  //     state = state.copyWith(
  //       frameLeftTopOffset: Offset(state.frameLeftTopOffset.dx, dyPosition),
  //     );
  //   }
  // }

  /// 真ん中
  void dragFrame({
    required double dx,
    required double dy,
  }) {
    final frameLeftTopOffset = state.frameLeftTopOffset;
    final frameRightTopOffset = state.frameRightTopOffset;
    final frameLeftBottomOffset = state.frameLeftBottomOffset;
    final frameRightBottomOffset = state.frameRightBottomOffset;
    final imageHeight = state.imageHeight;
    final imageWidth = state.imageWidth;

    if (0 <= frameLeftTopOffset.dx + dx &&
        0 <= frameLeftTopOffset.dy + dy &&
        imageWidth >= frameRightBottomOffset.dx + dx &&
        imageHeight >= frameRightBottomOffset.dy + dy) {
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
        imageWidth >= frameRightBottomOffset.dx + dx) {
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
        imageHeight >= frameRightBottomOffset.dy + dy) {
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
    final imageWidth = state.imageWidth;
    if (updateDxPosition <= imageWidth &&
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
    } else if (updateDxPosition <= imageWidth &&
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
    final imageHeight = state.imageHeight;
    if (0 <= updateDxPosition &&
        updateDyPosition <= imageHeight &&
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
    } else if (updateDyPosition <= imageHeight &&
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
    final imageHeight = state.imageHeight;
    final imageWidth = state.imageWidth;
    if (updateDxPosition <= imageWidth &&
        updateDyPosition <= imageHeight &&
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
    } else if (updateDxPosition <= imageWidth &&
        updateDxPosition >= 60 + state.frameLeftTopOffset.dx) {
      // 横移動
      state = state.copyWith(
        frameRightBottomOffset:
            Offset(updateDxPosition, state.frameRightBottomOffset.dy),
        frameRightTopOffset:
            Offset(updateDxPosition, state.frameRightTopOffset.dy),
      );
    } else if (updateDyPosition <= imageHeight &&
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
    if (state.imageWidth >= updateDxPosition &&
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
    if (state.imageHeight >= updateDyPosition &&
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

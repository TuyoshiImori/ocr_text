import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ocr_text/controller/camera_page_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ocr_text/pages/camera_page/src/focus_painter.dart';

Widget cameraBody() {
  return Consumer(
    builder: (context, ref, _) {
      final controller = ref.read(cameraPageProvider.notifier).controller;
      final imageFile =
          ref.watch(cameraPageProvider.select((s) => s.imageFile));
      final changingCameraLens =
          ref.watch(cameraPageProvider.select((s) => s.changingCameraLens));

      final frameLeftTopOffset =
          ref.watch(cameraPageProvider.select((s) => s.frameLeftTopOffset));
      final frameRightTopOffset =
          ref.watch(cameraPageProvider.select((s) => s.frameRightTopOffset));
      final frameLeftBottomOffset =
          ref.watch(cameraPageProvider.select((s) => s.frameLeftBottomOffset));
      final frameRightBottomOffset =
          ref.watch(cameraPageProvider.select((s) => s.frameRightBottomOffset));

      final deviceHeight = MediaQuery.of(context).size.height;
      final deviceWidth = MediaQuery.of(context).size.width;
      final text = ref.watch(cameraPageProvider.select((s) => s.text));
      final flameHeight = frameLeftBottomOffset.dy - frameLeftTopOffset.dy;
      final flameWidth = frameRightTopOffset.dx - frameLeftTopOffset.dx;
      final size = MediaQuery.of(context).size;
      final aspectRatio =
          ref.watch(cameraPageProvider.select((s) => s.aspectRatio));
      final imageHeight =
          ref.watch(cameraPageProvider.select((s) => s.imageHeight));
      final imageWidth =
          ref.watch(cameraPageProvider.select((s) => s.imageWidth));

      Future.delayed(const Duration(milliseconds: 200), () {
        ref.read(cameraPageProvider.notifier).initialScale(size: size);
        ref.read(cameraPageProvider.notifier).geDeviceSize(
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            );
      });

      final scale = ref.watch(cameraPageProvider.select((s) => s.scale));
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: imageFile == null
                ? Transform.scale(
                    scale: 1,
                    child: controller != null
                        ? Align(
                      alignment: Alignment.topCenter,
                            child: CameraPreview(controller),
                          )
                        : Container(),
                  )
                : Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Image.file(imageFile),
                            ),
                            ///オーバーレイ
                            Positioned.fill(
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.srcOut,
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          backgroundBlendMode: BlendMode.dstOut,
                                        ),
                                      ),
                                    ),

                                    ///文字を映す部分
                                    Positioned(
                                      top: frameLeftTopOffset.dy,
                                      left: frameLeftTopOffset.dx,
                                      child: Container(
                                        height: flameHeight,
                                        width: flameWidth,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: frameLeftTopOffset.dy,
                              left: frameLeftTopOffset.dx,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref.read(cameraPageProvider.notifier).dragFrame(
                                        dx: delta.dx,
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  height: flameHeight,
                                  width: flameWidth,
                                  decoration: const FocusPainter(
                                    frameSFactor: 1,
                                    gap: -2,
                                  ),
                                ),
                              ),
                            ),

                            /// 左
                            Positioned(
                              top: frameLeftTopOffset.dy + 30,
                              left: frameLeftTopOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameLeftSide(
                                        dx: delta.dx,
                                      );
                                },
                                child: Container(
                                  color: Colors.yellowAccent.withOpacity(0.5),
                                  height: flameHeight - 60,
                                  width: 60,
                                ),
                              ),
                            ),

                            /// 右
                            Positioned(
                              top: frameRightTopOffset.dy + 30,
                              left: frameRightTopOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameRightSide(
                                        dx: delta.dx,
                                      );
                                },
                                child: Container(
                                  color: Colors.blueAccent.withOpacity(0.5),
                                  height: flameHeight - 60,
                                  width: 60,
                                ),
                              ),
                            ),

                            /// 上
                            Positioned(
                              top: frameLeftTopOffset.dy - 30,
                              left: frameLeftTopOffset.dx + 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameTopDySide(
                                        dy: delta.dy / 2,
                                      );
                                },
                                child: Container(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  height: 60,
                                  width: flameWidth - 60,
                                ),
                              ),
                            ),

                            /// 下
                            Positioned(
                              top: frameLeftBottomOffset.dy - 30,
                              left: frameLeftBottomOffset.dx + 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameBottomDySide(
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  height: 60,
                                  width: flameWidth - 60,
                                ),
                              ),
                            ),

                            ///左上
                            Positioned(
                              top: frameLeftTopOffset.dy - 30,
                              left: frameLeftTopOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameLeftTopCorner(
                                        dx: delta.dx,
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  color: Colors.yellow.withOpacity(0.5),
                                  height: 60,
                                  width: 60,
                                ),
                              ),
                            ),

                            ///左下
                            Positioned(
                              top: frameLeftBottomOffset.dy - 30,
                              left: frameLeftBottomOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameLeftBottomCorner(
                                        dx: delta.dx,
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  color: Colors.blue.withOpacity(0.5),
                                  height: 60,
                                  width: 60,
                                ),
                              ),
                            ),

                            ///右上
                            Positioned(
                              top: frameRightTopOffset.dy - 30,
                              left: frameRightTopOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameRightTopCorner(
                                        dx: delta.dx,
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  color: Colors.green.withOpacity(0.5),
                                  height: 60,
                                  width: 60,
                                ),
                              ),
                            ),

                            ///右下
                            Positioned(
                              top: frameRightBottomOffset.dy - 30,
                              left: frameRightBottomOffset.dx - 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (DragUpdateDetails details) {
                                  final delta = details.delta;
                                  ref
                                      .read(cameraPageProvider.notifier)
                                      .dragFrameRightBottomCorner(
                                        dx: delta.dx,
                                        dy: delta.dy,
                                      );
                                },
                                child: Container(
                                  color: Colors.red.withOpacity(0.5),
                                  height: 60,
                                  width: 60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

          ),
          Positioned(
            top: 65,
            left: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(context);
              },
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcATop,
                ),
                child: BackButtonIcon(),
              ),
              ),

          ),
        ],
      );
    },
  );
}

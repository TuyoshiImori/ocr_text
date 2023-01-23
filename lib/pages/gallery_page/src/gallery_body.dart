import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ocr_text/controller/gallery_page_controller.dart';
import 'package:ocr_text/pages/camera_page/src/focus_painter.dart';

class GalleryBody extends StatelessWidget {
  const GalleryBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final imageFile =
            ref.watch(galleryPageProvider.select((s) => s.imageFile));
        final frameLeftTopOffset =
            ref.watch(galleryPageProvider.select((s) => s.frameLeftTopOffset));
        final frameRightTopOffset =
            ref.watch(galleryPageProvider.select((s) => s.frameRightTopOffset));
        final frameLeftBottomOffset = ref
            .watch(galleryPageProvider.select((s) => s.frameLeftBottomOffset));
        final frameRightBottomOffset = ref
            .watch(galleryPageProvider.select((s) => s.frameRightBottomOffset));
        // final deviceHeight = MediaQuery.of(context).size.height;
        // final deviceWidth = MediaQuery.of(context).size.width;
        final deviceHeight =
            ref.watch(galleryPageProvider.select((s) => s.deviceHeight));
        final deviceWidth =
            ref.watch(galleryPageProvider.select((s) => s.deviceWidth));

        final flameHeight = frameLeftBottomOffset.dy - frameLeftTopOffset.dy;
        final flameWidth = frameRightTopOffset.dx - frameLeftTopOffset.dx;

        ///端末の縦横を保存
        // Future.delayed(const Duration(milliseconds: 150), () {
        //   ref.read(galleryPageProvider.notifier).initialFrameOffset(
        //         deviceHeight: deviceHeight,
        //         deviceWidth: deviceWidth,
        //       );
        // });
        return imageFile != null
            ? ColoredBox(
                color: Colors.grey,
                child: Center(
                  child: Container(
                    color: Colors.white,
                    height: deviceHeight,
                    width: deviceWidth,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(imageFile),

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
                              ref.read(galleryPageProvider.notifier).dragFrame(
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
                                  .read(galleryPageProvider.notifier)
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
              )
            : Container();
      },
    );
  }
}

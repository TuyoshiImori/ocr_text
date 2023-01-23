import 'package:flutter/material.dart';
import 'package:ocr_text/controller/camera_page_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ocr_text/pages/camera_page/src/camera_body.dart';
import 'package:ocr_text/pages/camera_page/src/result_dialog.dart';

class CameraPage extends ConsumerWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(cameraPageProvider.select((s) => s.text));
    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: cameraBody(),
      floatingActionButton: floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget floatingActionButton() {
    return Consumer(
      builder: (context, ref, _) {
        final imageFile =
            ref.watch(cameraPageProvider.select((s) => s.imageFile));
        ref.listen(cameraPageProvider.select((s) => s.text), <String>( previous, next) {
          resultDialog(context: context, message: next);
        });
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                if (imageFile != null) {
                  await ref
                      .read(cameraPageProvider.notifier)
                      .processCameraImage(image: imageFile);
                } else {
                  await ref.read(cameraPageProvider.notifier).takePicture();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                  ),
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 4,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

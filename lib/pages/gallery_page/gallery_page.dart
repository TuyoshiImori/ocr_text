
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ocr_text/controller/gallery_page_controller.dart';
import 'package:ocr_text/pages/camera_page/src/result_dialog.dart';
import 'package:ocr_text/pages/gallery_page/src/gallery_body.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(context);
            },
            child: const ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black,
                BlendMode.srcATop,
              ),
              child: BackButtonIcon(),
            ),
          ),
        ),
      ),
      body: const GalleryBody(),
      floatingActionButton: floatingActionButton(),
    );
  }

  Widget floatingActionButton() {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(galleryPageProvider.select((s) => s.text), (previous, next) {
          resultDialog(context: context, message: next.toString());
        });
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                await ref.read(galleryPageProvider.notifier).processImage();
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            GestureDetector(
              onTap: () {
                ref.read(galleryPageProvider.notifier).galleryPicker();
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.photo_outlined,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
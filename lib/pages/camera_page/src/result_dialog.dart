import 'package:flutter/material.dart';

void resultDialog({
  required BuildContext context,
  required String message,
  Object? value,
}) {
  showDialog(
    builder: (context) {
      return AlertDialog(
        content: SizedBox(
          height: MediaQuery.of(context).size.height - 10,
          width: MediaQuery.of(context).size.width - 10,
          child: Center(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        backgroundColor: Colors.white,
      );
    },
    context: context,
  );
}

/// BAD: PascalCase file name (should be bad_widget.dart)
/// BAD: StatefulWidget for static content
/// This file intentionally violates standards for testing

import 'package:flutter/material.dart';

// BAD: Using StatefulWidget when StatelessWidget would suffice
class BadWidget extends StatefulWidget {
  // BAD: No const constructor
  BadWidget({Key? key}) : super(key: key);

  @override
  State<BadWidget> createState() => _BadWidgetState();
}

class _BadWidgetState extends State<BadWidget> {
  @override
  Widget build(BuildContext context) {
    // BAD: Magic numbers
    return Container(
      width: 200,
      height: 100,
      padding: EdgeInsets.all(8),
      // BAD: Hardcoded colors instead of theme
      color: Color(0xFF123456),
      child: Text(
        'Bad Example',
        // BAD: Hardcoded text style
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}

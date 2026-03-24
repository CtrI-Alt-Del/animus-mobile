import 'package:flutter/widgets.dart';

class TopProgressBarView extends StatelessWidget {
  const TopProgressBarView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Row(
        children: const <Widget>[
          Expanded(child: ColoredBox(color: Color(0xFF5A5CFF))),
          Expanded(child: ColoredBox(color: Color(0xFF1A1C28))),
        ],
      ),
    );
  }
}

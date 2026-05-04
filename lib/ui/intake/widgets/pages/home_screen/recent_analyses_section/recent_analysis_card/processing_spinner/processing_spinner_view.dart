import 'package:flutter/material.dart';

class ProcessingSpinnerView extends StatefulWidget {
  final Color color;

  const ProcessingSpinnerView({required this.color, super.key});

  @override
  State<ProcessingSpinnerView> createState() => _ProcessingSpinnerViewState();
}

class _ProcessingSpinnerViewState extends State<ProcessingSpinnerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.color,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }
}

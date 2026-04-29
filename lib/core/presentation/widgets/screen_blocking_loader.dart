import 'package:flutter/material.dart';

class ScreenBlockingLoader extends StatelessWidget {
  const ScreenBlockingLoader({
    required this.isLoading,
    required this.child,
    super.key,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          const Opacity(
            opacity: 0.35,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

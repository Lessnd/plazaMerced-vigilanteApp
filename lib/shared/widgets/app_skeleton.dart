import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 12.0,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.7).animate(_controller),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant, // Usa el color del tema
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
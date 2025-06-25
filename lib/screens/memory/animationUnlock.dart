import 'package:flutter/material.dart';

class CapsuleUnlockAnimation extends StatefulWidget {
  final VoidCallback onCompleted;
  const CapsuleUnlockAnimation({super.key, required this.onCompleted});

  @override
  State<CapsuleUnlockAnimation> createState() => _CapsuleUnlockAnimationState();
}

class _CapsuleUnlockAnimationState extends State<CapsuleUnlockAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 700));
      widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_open_rounded, color: Colors.green, size: 64),
              SizedBox(height: 16),
              Text("Capsule Unlocked!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
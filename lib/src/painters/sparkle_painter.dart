import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

/// Painter for the Sparkle (Coating) effect.
class SparklePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Vector3 lightDirection;
  final double width;
  final double height;

  SparklePainter({
    required this.shader,
    required this.time,
    required this.lightDirection,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, width); // uSize.x
    shader.setFloat(1, height); // uSize.y
    shader.setFloat(2, time); // uTime
    shader.setFloat(3, lightDirection.x); // uLightDirection.x
    shader.setFloat(4, lightDirection.y); // uLightDirection.y
    shader.setFloat(5, lightDirection.z); // uLightDirection.z
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.shader != shader;
  }
}

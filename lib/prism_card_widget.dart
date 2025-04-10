import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class PrismCardWidget extends StatefulWidget {
  final ImageProvider imageProvider;
  final double width;
  final double height;

  const PrismCardWidget({
    super.key,
    required this.imageProvider,
    this.width = 300,
    this.height = 420, // Adjust aspect ratio as needed
  });

  @override
  State<PrismCardWidget> createState() => _PrismCardWidgetState();
}

class _PrismCardWidgetState extends State<PrismCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeController;
  ui.FragmentShader? _shader;
  ui.Image? _image;
  Vector3 _lightDirection =
      Vector3(0.0, 0.0, 1.0); // Initial light direction (straight on)
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Slower animation
    )..repeat();

    _loadResources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload image if the provider changes
    _resolveImage();
  }

  @override
  void didUpdateWidget(PrismCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resolveImage();
    }
  }

  Future<void> _loadResources() async {
    // Load the shader program
    try {
      print("Attempting to load shader..."); // 로딩 시도 로그
      // *** PATH MUST MATCH pubspec.yaml shaders: section ***
      final program =
          await ui.FragmentProgram.fromAsset('shaders/prism_shader.frag');
      print("Shader loaded successfully."); // 성공 로그
      _shader = program.fragmentShader();
      _resolveImage(); // Load image after shader is ready
      // Trigger a rebuild once shader is loaded
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading shader: $e');
      // Handle error appropriately
    }
  }

  void _resolveImage() {
    if (_shader == null) return; // Don't load image if shader isn't ready

    final ImageStream newStream =
        widget.imageProvider.resolve(createLocalImageConfiguration(context));
    // If the stream is the same, do nothing.
    if (newStream.key == _imageStream?.key) {
      return;
    }

    _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
    _imageStream = newStream;
    _imageStream!.addListener(ImageStreamListener(_handleImageFrame));
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo?.dispose();
      _imageInfo = imageInfo;
      _image = imageInfo.image;
    });
  }

  void _updateLightDirection(Offset localPosition) {
    // Calculate normalized device coordinates (-1 to +1)
    final double ndcX = (localPosition.dx / widget.width) * 2.0 - 1.0;
    final double ndcY = (localPosition.dy / widget.height) * 2.0 - 1.0;

    // Update light direction based on pointer position
    // Keep z relatively strong so the light source isn't 'behind' the card often
    // Invert Y because screen coordinates Y increases downwards
    setState(() {
      _lightDirection = Vector3(ndcX, -ndcY, 0.8).normalized();
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
    _imageInfo?.dispose();
    _shader?.dispose(); // Dispose shader resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a placeholder while loading
    if (_shader == null || _image == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MouseRegion(
      onHover: (event) => _updateLightDirection(event.localPosition),
      onExit: (_) => setState(() {
        // Reset light when mouse exits
        _lightDirection = Vector3(0.0, 0.0, 1.0);
      }),
      child: GestureDetector(
        onPanUpdate: (details) => _updateLightDirection(details.localPosition),
        onPanEnd: (_) => setState(() {
          _lightDirection = Vector3(0.0, 0.0, 1.0);
        }),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _timeController,
            builder: (context, _) {
              return CustomPaint(
                painter: _PrismShaderPainter(
                  shader: _shader!,
                  image: _image!,
                  time: _timeController.value * 20, // Pass time value
                  lightDirection: _lightDirection,
                ),
                // Add a child here if you want content on top of the effect
                // child: Center(child: Text('Card Content')),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrismShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final double time;
  final Vector3 lightDirection;

  _PrismShaderPainter({
    required this.shader,
    required this.image,
    required this.time,
    required this.lightDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, lightDirection.x);
    shader.setFloat(4, lightDirection.y);
    shader.setFloat(5, lightDirection.z);
    shader.setImageSampler(0, image);

    // Draw the shader over the entire canvas
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PrismShaderPainter oldDelegate) {
    // Repaint if time or light direction changes
    return oldDelegate.time != time ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.shader != shader ||
        oldDelegate.image != image;
  }
}

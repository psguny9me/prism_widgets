import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // Import for listEquals
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

// Enum for MATERIAL effects (under the image)
enum MaterialEffect {
  none,
  chromeMetal,
  diamondPrism,
}

// Enum for COATING effects (over the image)
enum CoatingEffect {
  none,
  prism,
  sparkle,
}

class PrismCardWidget extends StatefulWidget {
  final ImageProvider imageProvider;
  final double width;
  final double height;
  final MaterialEffect materialEffect; // Select one material
  final CoatingEffect coatingEffect; // Select one coating
  final double imageOpacity; // Control base image visibility

  const PrismCardWidget({
    super.key,
    required this.imageProvider,
    this.width = 300,
    this.height = 420,
    this.materialEffect = MaterialEffect.none,
    this.coatingEffect = CoatingEffect.none,
    this.imageOpacity = 0.85, // Default opacity for the image layer
  });

  @override
  State<PrismCardWidget> createState() => _PrismCardWidgetState();
}

class _PrismCardWidgetState extends State<PrismCardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _timeController;
  // Shaders for materials
  ui.FragmentShader? _chromeMetalShader;
  ui.FragmentShader? _diamondPrismShader;
  // Shaders for coatings
  ui.FragmentShader? _prismShader;
  ui.FragmentShader? _sparkleShader;

  ui.Image? _image;
  Vector3 _lightDirection = Vector3(0.0, 0.0, 1.0);
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  bool _resourcesReady = false;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _loadResources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(PrismCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageProvider != oldWidget.imageProvider) {
      _resolveImage();
    }
    // Check if selected effects changed
    if (widget.materialEffect != oldWidget.materialEffect ||
        widget.coatingEffect != oldWidget.coatingEffect) {
      // Check if newly selected effect requires a shader that wasn't loaded
      bool needsReload = _checkIfReloadNeeded();
      if (needsReload) {
        _loadResources(); // Reload shaders if needed
      } else {
        setState(() {}); // Trigger rebuild with new effect selection
      }
    }
    if (widget.imageOpacity != oldWidget.imageOpacity) {
      setState(() {}); // Rebuild if opacity changes
    }
  }

  // Helper to check if shader reload is needed based on current selection
  bool _checkIfReloadNeeded() {
    if (widget.materialEffect == MaterialEffect.chromeMetal &&
        _chromeMetalShader == null) return true;
    if (widget.materialEffect == MaterialEffect.diamondPrism &&
        _diamondPrismShader == null) return true;
    if (widget.coatingEffect == CoatingEffect.prism && _prismShader == null)
      return true;
    if (widget.coatingEffect == CoatingEffect.sparkle && _sparkleShader == null)
      return true;
    return false;
  }

  Future<void> _loadResources() async {
    setState(() {
      _resourcesReady = false;
    });
    try {
      print("Attempting to load shaders...");
      // Load all potential shaders
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset('shaders/chrome_metal_shader.frag')
            .catchError((_) => null),
        ui.FragmentProgram.fromAsset('shaders/diamond_prism_shader.frag')
            .catchError((_) => null),
        ui.FragmentProgram.fromAsset('shaders/prism_shader.frag')
            .catchError((_) => null),
        ui.FragmentProgram.fromAsset('shaders/sparkle_shader.frag')
            .catchError((_) => null),
      ]);
      _chromeMetalShader = results[0]?.fragmentShader();
      _diamondPrismShader = results[1]?.fragmentShader();
      _prismShader = results[2]?.fragmentShader();
      _sparkleShader = results[3]?.fragmentShader();
      print("Shader loading attempted.");
      _resolveImage(); // Attempt to resolve image after loading shaders
    } catch (e) {
      debugPrint('Error loading resources: $e');
      if (mounted) {
        setState(() {
          _resourcesReady = true;
        }); // Mark ready even on error
      }
    }
  }

  void _resolveImage() {
    if (!mounted) return;
    final ImageStream newStream =
        widget.imageProvider.resolve(createLocalImageConfiguration(context));
    // Only reset stream if key changes
    if (newStream.key != _imageStream?.key) {
      _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
      _imageStream = newStream;
      _imageStream!.addListener(ImageStreamListener(_handleImageFrame));
    } else {
      // If stream is same, check if we are now ready
      _checkAndSetReady();
    }
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo?.dispose();
    _imageInfo = imageInfo;
    _image = imageInfo.image;
    _checkAndSetReady(); // Check readiness after image loads
  }

  // Helper to check if all required resources are loaded
  void _checkAndSetReady() {
    bool shadersOk = true;
    if (widget.materialEffect == MaterialEffect.chromeMetal &&
        _chromeMetalShader == null) shadersOk = false;
    if (widget.materialEffect == MaterialEffect.diamondPrism &&
        _diamondPrismShader == null) shadersOk = false;
    if (widget.coatingEffect == CoatingEffect.prism && _prismShader == null)
      shadersOk = false;
    if (widget.coatingEffect == CoatingEffect.sparkle && _sparkleShader == null)
      shadersOk = false;

    // We consider ready if the image is loaded AND any selected shader is loaded
    if (_image != null && shadersOk && mounted && !_resourcesReady) {
      setState(() {
        _resourcesReady = true;
      });
    }
  }

  void _updateLightDirection(Offset localPosition) {
    final double ndcX = (localPosition.dx / widget.width) * 2.0 - 1.0;
    final double ndcY = (localPosition.dy / widget.height) * 2.0 - 1.0;
    setState(() {
      _lightDirection = Vector3(ndcX, -ndcY, 0.8).normalized();
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
    _imageInfo?.dispose();
    _prismShader?.dispose();
    _sparkleShader?.dispose();
    _diamondPrismShader?.dispose();
    _chromeMetalShader?.dispose();
    super.dispose();
  }

  // Build method completely refactored for Material/Coating structure
  @override
  Widget build(BuildContext context) {
    // --- Resource Loading Check ---
    if (!_resourcesReady || _image == null) {
      bool chromeNeeded = widget.materialEffect == MaterialEffect.chromeMetal;
      bool diamondNeeded = widget.materialEffect == MaterialEffect.diamondPrism;
      bool prismNeeded = widget.coatingEffect == CoatingEffect.prism;
      bool sparkleNeeded = widget.coatingEffect == CoatingEffect.sparkle;

      bool shadersError = _resourcesReady &&
          ((chromeNeeded && _chromeMetalShader == null) ||
              (diamondNeeded && _diamondPrismShader == null) ||
              (prismNeeded && _prismShader == null) ||
              (sparkleNeeded && _sparkleShader == null));

      if (shadersError) {
        return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: Text('Error loading required shaders')));
      }
      return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()));
    }

    // --- Main Build Logic with Stack ---
    return MouseRegion(
      onHover: (event) => _updateLightDirection(event.localPosition),
      onExit: (_) => setState(() {
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
              final double currentTime = _timeController.value * 20;
              List<Widget> layers = [];

              // --- Layer 1: Material Effect (Background) ---
              Widget materialLayer;
              switch (widget.materialEffect) {
                case MaterialEffect.chromeMetal:
                  materialLayer = _chromeMetalShader != null
                      ? CustomPaint(
                          size: Size(widget.width, widget.height),
                          painter: _ChromeMetalMaterialPainter(
                              shader: _chromeMetalShader!,
                              time: currentTime,
                              lightDirection: _lightDirection))
                      : Container(color: Colors.grey); // Fallback
                  break;
                case MaterialEffect.diamondPrism:
                  materialLayer = _diamondPrismShader != null
                      ? CustomPaint(
                          size: Size(widget.width, widget.height),
                          painter: _DiamondPrismMaterialPainter(
                              shader: _diamondPrismShader!,
                              time: currentTime,
                              lightDirection: _lightDirection))
                      : Container(color: Colors.grey); // Fallback
                  break;
                case MaterialEffect.none:
                default:
                  // If no material, use the base image itself as the background
                  // This allows coating to be applied directly over the image
                  materialLayer = CustomPaint(
                      size: Size(widget.width, widget.height),
                      painter: _ImagePainter(image: _image!));
                  // Or use an empty container if image should only appear in layer 2
                  // materialLayer = Container();
                  break;
              }
              layers.add(materialLayer);

              // --- Layer 2: Original Image ---
              // Only add this layer if a material effect is chosen (otherwise image is layer 1)
              if (widget.materialEffect != MaterialEffect.none) {
                layers.add(Opacity(
                  opacity: widget.imageOpacity,
                  child: CustomPaint(
                      size: Size(widget.width, widget.height),
                      painter: _ImagePainter(image: _image!)),
                ));
              }

              // --- Layer 3: Coating Effect (Overlay) ---
              Widget? coatingLayer;
              switch (widget.coatingEffect) {
                case CoatingEffect.prism:
                  coatingLayer = _prismShader != null
                      ? CustomPaint(
                          size: Size(widget.width, widget.height),
                          painter: _PrismCoatingPainter(
                              shader: _prismShader!,
                              time: currentTime,
                              lightDirection: _lightDirection))
                      : null; // Don't add layer if shader failed
                  break;
                case CoatingEffect.sparkle:
                  coatingLayer = _sparkleShader != null
                      ? CustomPaint(
                          size: Size(widget.width, widget.height),
                          painter: _SparkleCoatingPainter(
                              shader: _sparkleShader!, time: currentTime))
                      : null; // Don't add layer if shader failed
                  break;
                case CoatingEffect.none:
                default:
                  coatingLayer = null;
                  break;
              }
              if (coatingLayer != null) {
                layers.add(coatingLayer);
              }

              // Use Stack to layer the widgets
              return Stack(
                children: layers,
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Painters ---

// --- Material Painters (Opaque Backgrounds) ---

class _ChromeMetalMaterialPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Vector3 lightDirection;

  _ChromeMetalMaterialPainter({
    required this.shader,
    required this.time,
    required this.lightDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width); // uResolution
    shader.setFloat(1, size.height);
    shader.setFloat(2, time); // uTime
    shader.setFloat(3, lightDirection.x); // uLightDirection
    shader.setFloat(4, lightDirection.y);
    shader.setFloat(5, lightDirection.z);
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ChromeMetalMaterialPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.shader != shader;
  }
}

class _DiamondPrismMaterialPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Vector3 lightDirection;

  _DiamondPrismMaterialPainter({
    required this.shader,
    required this.time,
    required this.lightDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width); // uResolution
    shader.setFloat(1, size.height);
    shader.setFloat(2, time); // uTime
    shader.setFloat(3, lightDirection.x); // uLightDirection
    shader.setFloat(4, lightDirection.y);
    shader.setFloat(5, lightDirection.z);
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPrismMaterialPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.shader != shader;
  }
}

// --- Coating Painters (Transparent Overlays) ---

class _PrismCoatingPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Vector3 lightDirection;

  _PrismCoatingPainter({
    required this.shader,
    required this.time,
    required this.lightDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width); // uResolution
    shader.setFloat(1, size.height);
    shader.setFloat(2, time); // uTime
    shader.setFloat(3, lightDirection.x); // uLightDirection
    shader.setFloat(4, lightDirection.y);
    shader.setFloat(5, lightDirection.z);
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PrismCoatingPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightDirection != lightDirection ||
        oldDelegate.shader != shader;
  }
}

class _SparkleCoatingPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;

  _SparkleCoatingPainter({
    required this.shader,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width); // uResolution
    shader.setFloat(1, size.height);
    shader.setFloat(2, time); // uTime
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SparkleCoatingPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.shader != shader;
  }
}

// --- Base Image Painter ---
class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

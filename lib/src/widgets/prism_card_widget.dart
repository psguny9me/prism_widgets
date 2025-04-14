import 'dart:async';
import 'dart:ui' as ui;
// Remove unnecessary foundation import if present (it should be removed)
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../enums/shader_effects.dart';
import '../painters/chrome_metal_painter.dart';
import '../painters/diamond_prism_painter.dart';
import '../painters/prism_painter.dart';
import '../painters/sparkle_painter.dart';

class PrismCardWidget extends StatefulWidget {
  final ImageProvider imageProvider;
  final MaterialEffect materialEffect;
  final CoatingEffect coatingEffect;
  final double imageOpacity;

  const PrismCardWidget({
    super.key,
    required this.imageProvider,
    this.materialEffect = MaterialEffect.none,
    this.coatingEffect = CoatingEffect.none,
    this.imageOpacity = 0.85,
  });

  @override
  State<PrismCardWidget> createState() => _PrismCardWidgetState();
}

class _PrismCardWidgetState extends State<PrismCardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _timeController;
  ui.FragmentShader? _chromeMetalShader;
  ui.FragmentShader? _diamondPrismShader;
  ui.FragmentShader? _prismShader;
  ui.FragmentShader? _sparkleShader;

  ui.Image? _image;
  double? _renderWidth; // Last known render width from LayoutBuilder
  double? _renderHeight; // Last known render height from LayoutBuilder
  Vector3 _lightDirection = Vector3(0.0, 0.0, 1.0);
  ImageStream? _imageStream;
  // ImageInfo removed from state, only ui.Image is needed
  bool _shaderLoadAttemptFinished = false; // Tracks if _loadResources finished
  bool _imageLoadAttemptFinished = false; // Tracks if _resolveImage was called

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    // Load shaders initially, regardless of selection (can be optimized later)
    _loadResources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve image when dependencies change (e.g., first time or theme changes)
    _resolveImage();
  }

  @override
  void didUpdateWidget(PrismCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool effectsChanged = widget.materialEffect != oldWidget.materialEffect ||
        widget.coatingEffect != oldWidget.coatingEffect;

    if (widget.imageProvider != oldWidget.imageProvider) {
      // Reset image state and trigger resolve
      setState(() {
        _image = null;
        _imageLoadAttemptFinished = false;
      });
      _resolveImage();
    }

    // Reload shaders if effects changed and needed shaders are missing
    // or if image provider changed (to ensure shaders are loaded with the new context)
    if (effectsChanged || widget.imageProvider != oldWidget.imageProvider) {
      if (_checkIfReloadNeeded()) {
        _loadResources();
      }
    } else if (widget.imageOpacity != oldWidget.imageOpacity) {
      // Trigger rebuild if only opacity changes
      setState(() {});
    }
  }

  // Checks if *currently selected* effects require shaders that are not yet loaded
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
    // Mark that loading is starting (or restarting)
    setState(() {
      _shaderLoadAttemptFinished = false;
    });

    // Dispose shaders that are no longer selected
    if (widget.materialEffect != MaterialEffect.chromeMetal) {
      _chromeMetalShader?.dispose();
      _chromeMetalShader = null;
    }
    if (widget.materialEffect != MaterialEffect.diamondPrism) {
      _diamondPrismShader?.dispose();
      _diamondPrismShader = null;
    }
    if (widget.coatingEffect != CoatingEffect.prism) {
      _prismShader?.dispose();
      _prismShader = null;
    }
    if (widget.coatingEffect != CoatingEffect.sparkle) {
      _sparkleShader?.dispose();
      _sparkleShader = null;
    }

    // Build list of futures for shaders that are needed AND not loaded yet
    final List<Future<ui.FragmentProgram?>> shaderFutures = [];
    final Map<String, int> typeToIndex =
        {}; // Map shader type to its index in shaderFutures
    int currentIndex = 0;

    Future<ui.FragmentProgram?> safeLoadShader(String shaderFileName) {
      final String assetPath = 'packages/prism_widgets/shaders/$shaderFileName';
      return ui.FragmentProgram.fromAsset(assetPath)
          .then<ui.FragmentProgram?>((program) => program)
          .catchError((error, stackTrace) {
        print('Failed to load shader $assetPath: $error');
        return null;
      });
    }

    if (widget.materialEffect == MaterialEffect.chromeMetal &&
        _chromeMetalShader == null) {
      shaderFutures.add(safeLoadShader('chrome_metal_shader.frag'));
      typeToIndex['chrome'] = currentIndex++;
    }
    if (widget.materialEffect == MaterialEffect.diamondPrism &&
        _diamondPrismShader == null) {
      shaderFutures.add(safeLoadShader('diamond_prism_shader.frag'));
      typeToIndex['diamond'] = currentIndex++;
    }
    if (widget.coatingEffect == CoatingEffect.prism && _prismShader == null) {
      shaderFutures.add(safeLoadShader('prism_shader.frag'));
      typeToIndex['prism'] = currentIndex++;
    }
    if (widget.coatingEffect == CoatingEffect.sparkle &&
        _sparkleShader == null) {
      shaderFutures.add(safeLoadShader('sparkle_shader.frag'));
      typeToIndex['sparkle'] = currentIndex++;
    }

    // If no new shaders need loading, just mark finished
    if (shaderFutures.isEmpty) {
      if (mounted)
        setState(() {
          _shaderLoadAttemptFinished = true;
        });
      return;
    }

    try {
      final List<ui.FragmentProgram?> results =
          await Future.wait(shaderFutures);

      // Assign results using the tracked indices
      if (typeToIndex.containsKey('chrome'))
        _chromeMetalShader = results[typeToIndex['chrome']!]?.fragmentShader();
      if (typeToIndex.containsKey('diamond'))
        _diamondPrismShader =
            results[typeToIndex['diamond']!]?.fragmentShader();
      if (typeToIndex.containsKey('prism'))
        _prismShader = results[typeToIndex['prism']!]?.fragmentShader();
      if (typeToIndex.containsKey('sparkle'))
        _sparkleShader = results[typeToIndex['sparkle']!]?.fragmentShader();
    } catch (e) {
      print('Error during Future.wait or shader assignment: $e');
      // Error occurred, but still mark the attempt as finished
    } finally {
      // Ensure the finished flag is set and trigger rebuild
      if (mounted) {
        setState(() {
          _shaderLoadAttemptFinished = true;
        });
      }
    }
  }

  void _resolveImage() {
    if (!mounted || _imageLoadAttemptFinished) return;

    setState(() {
      _imageLoadAttemptFinished = true;
    });

    final ImageStream newStream =
        widget.imageProvider.resolve(createLocalImageConfiguration(context));

    _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
    _imageStream = newStream;
    _imageStream!.addListener(ImageStreamListener(_handleImageFrame));
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    if (!mounted) return;
    // Just update the image object
    setState(() {
      _image = imageInfo.image;
    });
    // ImageInfo object is managed by the stream/framework
  }

  void _updateLightDirection(Offset localPosition) {
    // Use last known render dimensions
    if (_renderWidth == null ||
        _renderHeight == null ||
        _renderWidth! <= 0 ||
        _renderHeight! <= 0) return;

    final double ndcX = (localPosition.dx / _renderWidth!) * 2.0 - 1.0;
    final double ndcY = (localPosition.dy / _renderHeight!) * 2.0 - 1.0;
    final newDirection =
        Vector3(ndcX.clamp(-1.0, 1.0), -ndcY.clamp(-1.0, 1.0), 0.8)
            .normalized();
    if ((newDirection - _lightDirection).length2 > 0.0001) {
      setState(() {
        _lightDirection = newDirection;
      });
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
    _prismShader?.dispose();
    _sparkleShader?.dispose();
    _diamondPrismShader?.dispose();
    _chromeMetalShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Readiness check: image object must be loaded AND shader loading attempt must be finished
    final bool imageReady = _image != null;
    final bool shaderLoadAttempted = _shaderLoadAttemptFinished;

    // Check for errors *after* loading is attempted
    bool shadersError = false;
    if (imageReady && shaderLoadAttempted) {
      bool chromeNeeded = widget.materialEffect == MaterialEffect.chromeMetal;
      bool diamondNeeded = widget.materialEffect == MaterialEffect.diamondPrism;
      bool prismNeeded = widget.coatingEffect == CoatingEffect.prism;
      bool sparkleNeeded = widget.coatingEffect == CoatingEffect.sparkle;

      shadersError = (chromeNeeded && _chromeMetalShader == null) ||
          (diamondNeeded && _diamondPrismShader == null) ||
          (prismNeeded && _prismShader == null) ||
          (sparkleNeeded && _sparkleShader == null);
    }

    // --- Loading / Error State --- (Displayed before LayoutBuilder calculates size)
    if (!imageReady || !shaderLoadAttempted || shadersError) {
      String message = !_imageLoadAttemptFinished
          ? 'Resolving Image...'
          : (!imageReady ? 'Loading Image...' : 'Loading Shaders...');
      Widget indicator = const CircularProgressIndicator();

      if (shadersError) {
        message = 'Error loading required shaders';
        indicator = Icon(Icons.error_outline, color: Colors.red, size: 48);
      }

      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        indicator,
        SizedBox(height: 16),
        Text(message, style: TextStyle(color: shadersError ? Colors.red : null))
      ]));
    }

    // --- Main Build Logic (Image and Shaders Ready) ---
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine render size
        final double renderWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (_image?.width.toDouble() ?? 300);
        final double renderHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : (_image?.height.toDouble() ?? 420);
        final Size cardSize = Size(renderWidth, renderHeight);

        // Update state with render size after the frame
        // Use postFrameCallback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              (_renderWidth != renderWidth || _renderHeight != renderHeight)) {
            // Use a microtask to delay setState slightly after build completion
            Future.microtask(() {
              if (mounted) {
                // Check mounted again inside microtask
                setState(() {
                  _renderWidth = renderWidth;
                  _renderHeight = renderHeight;
                });
              }
            });
          }
        });

        // Rest of the build logic using renderWidth, renderHeight...
        return MouseRegion(
          onHover: (event) => _updateLightDirection(event.localPosition),
          onExit: (_) => setState(() {
            _lightDirection = Vector3(0.0, 0.0, 1.0);
          }),
          child: GestureDetector(
            onPanUpdate: (details) =>
                _updateLightDirection(details.localPosition),
            onPanEnd: (_) => setState(() {
              _lightDirection = Vector3(0.0, 0.0, 1.0);
            }),
            child: SizedBox(
              // Use determined render size
              width: renderWidth,
              height: renderHeight,
              child: AnimatedBuilder(
                animation: _timeController,
                builder: (context, _) {
                  final double currentTime = _timeController.value * 20;

                  // Layer 1: Material Effect (only if needed and loaded)
                  Widget materialLayer = const SizedBox.shrink();
                  if (widget.materialEffect == MaterialEffect.chromeMetal &&
                      _chromeMetalShader != null) {
                    materialLayer = CustomPaint(
                      size: cardSize,
                      painter: ChromeMetalPainter(
                        shader: _chromeMetalShader!,
                        time: currentTime,
                        lightDirection: _lightDirection,
                        width: renderWidth,
                        height: renderHeight,
                      ),
                    );
                  } else if (widget.materialEffect ==
                          MaterialEffect.diamondPrism &&
                      _diamondPrismShader != null) {
                    materialLayer = CustomPaint(
                      size: cardSize,
                      painter: DiamondPrismPainter(
                        shader: _diamondPrismShader!,
                        time: currentTime,
                        lightDirection: _lightDirection,
                        width: renderWidth,
                        height: renderHeight,
                      ),
                    );
                  }

                  // Layer 2: Base Image (Image is guaranteed non-null here)
                  final imageLayer = Opacity(
                    opacity: widget.imageOpacity.clamp(0.0, 1.0),
                    child: RawImage(
                        image: _image!,
                        fit: BoxFit.cover,
                        width: renderWidth,
                        height: renderHeight),
                  );

                  // Layer 3: Coating Effect (only if needed and loaded)
                  Widget coatingLayer = const SizedBox.shrink();
                  if (widget.coatingEffect == CoatingEffect.prism &&
                      _prismShader != null) {
                    coatingLayer = CustomPaint(
                      size: cardSize,
                      painter: PrismPainter(
                        shader: _prismShader!,
                        time: currentTime,
                        lightDirection: _lightDirection,
                        width: renderWidth,
                        height: renderHeight,
                      ),
                    );
                  } else if (widget.coatingEffect == CoatingEffect.sparkle &&
                      _sparkleShader != null) {
                    coatingLayer = CustomPaint(
                      size: cardSize,
                      painter: SparklePainter(
                        shader: _sparkleShader!,
                        time: currentTime,
                        lightDirection: _lightDirection,
                        width: renderWidth,
                        height: renderHeight,
                      ),
                    );
                  }

                  // Add ClipRect to prevent effects bleeding outside bounds
                  return ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        materialLayer,
                        imageLayer,
                        coatingLayer,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

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
  double? _imageWidth;
  double? _imageHeight;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(PrismCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool effectsChanged = widget.materialEffect != oldWidget.materialEffect ||
        widget.coatingEffect != oldWidget.coatingEffect;

    if (widget.imageProvider != oldWidget.imageProvider) {
      _image = null;
      _imageWidth = null;
      _imageHeight = null;
      _resourcesReady = false;
      _resolveImage();
    } else if (effectsChanged) {
      bool needsReload = _checkIfReloadNeeded();
      if (needsReload) {
        _loadResources();
      } else {
        setState(() {});
      }
    } else if (widget.imageOpacity != oldWidget.imageOpacity) {
      setState(() {});
    }
  }

  bool _checkIfReloadNeeded() {
    if (widget.materialEffect == MaterialEffect.chromeMetal &&
        _chromeMetalShader == null) {
      return true;
    }
    if (widget.materialEffect == MaterialEffect.diamondPrism &&
        _diamondPrismShader == null) {
      return true;
    }
    if (widget.coatingEffect == CoatingEffect.prism && _prismShader == null) {
      return true;
    }
    if (widget.coatingEffect == CoatingEffect.sparkle &&
        _sparkleShader == null) {
      return true;
    }
    return false;
  }

  Future<void> _loadResources() async {
    setState(() {
      _resourcesReady = false;
      _chromeMetalShader = null;
      _diamondPrismShader = null;
      _prismShader = null;
      _sparkleShader = null;
    });

    final List<Future<ui.FragmentProgram?>> shaderFutures = [];

    Future<ui.FragmentProgram?> safeLoadShader(String shaderFileName) {
      final String assetPath = 'packages/prism_widgets/shaders/$shaderFileName';
      return ui.FragmentProgram.fromAsset(assetPath)
          .then<ui.FragmentProgram?>((program) => program)
          .catchError((error, stackTrace) {
        print('Failed to load shader $assetPath: $error');
        return null;
      });
    }

    bool shouldLoadChrome =
        widget.materialEffect == MaterialEffect.chromeMetal ||
            MaterialEffect.chromeMetal != MaterialEffect.none;
    bool shouldLoadDiamond =
        widget.materialEffect == MaterialEffect.diamondPrism ||
            MaterialEffect.diamondPrism != MaterialEffect.none;
    bool shouldLoadPrism = widget.coatingEffect == CoatingEffect.prism ||
        CoatingEffect.prism != CoatingEffect.none;
    bool shouldLoadSparkle = widget.coatingEffect == CoatingEffect.sparkle ||
        CoatingEffect.sparkle != CoatingEffect.none;

    shaderFutures.add(shouldLoadChrome
        ? safeLoadShader('chrome_metal_shader.frag')
        : Future.value(null));
    shaderFutures.add(shouldLoadDiamond
        ? safeLoadShader('diamond_prism_shader.frag')
        : Future.value(null));
    shaderFutures.add(shouldLoadPrism
        ? safeLoadShader('prism_shader.frag')
        : Future.value(null));
    shaderFutures.add(shouldLoadSparkle
        ? safeLoadShader('sparkle_shader.frag')
        : Future.value(null));

    try {
      final List<ui.FragmentProgram?> results =
          await Future.wait(shaderFutures);

      _chromeMetalShader = results[0]?.fragmentShader();
      _diamondPrismShader = results[1]?.fragmentShader();
      _prismShader = results[2]?.fragmentShader();
      _sparkleShader = results[3]?.fragmentShader();

      _resolveImage();
    } catch (e) {
      print('Error during Future.wait or shader assignment: $e');
      if (mounted) {
        _checkAndSetReady(forceCheck: true);
      }
    }
  }

  void _resolveImage() {
    if (!mounted) {
      return;
    }
    final ImageStream newStream =
        widget.imageProvider.resolve(createLocalImageConfiguration(context));
    if (newStream.key != _imageStream?.key) {
      _imageStream?.removeListener(ImageStreamListener(_handleImageFrame));
      _imageStream = newStream;
      _imageStream!.addListener(ImageStreamListener(_handleImageFrame));
    } else {
      _checkAndSetReady();
    }
  }

  void _handleImageFrame(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo?.dispose();
    _imageInfo = imageInfo;
    _image = imageInfo.image;
    _imageWidth = _image!.width.toDouble();
    _imageHeight = _image!.height.toDouble();
    _checkAndSetReady();
  }

  void _checkAndSetReady({bool forceCheck = false}) {
    if (_resourcesReady && !forceCheck) {
      return;
    }

    bool shadersOk = true;
    if (widget.materialEffect == MaterialEffect.chromeMetal &&
        _chromeMetalShader == null) {
      shadersOk = false;
    }
    if (widget.materialEffect == MaterialEffect.diamondPrism &&
        _diamondPrismShader == null) {
      shadersOk = false;
    }
    if (widget.coatingEffect == CoatingEffect.prism && _prismShader == null) {
      shadersOk = false;
    }
    if (widget.coatingEffect == CoatingEffect.sparkle &&
        _sparkleShader == null) {
      shadersOk = false;
    }

    if (_image != null && shadersOk && mounted) {
      if (!_resourcesReady) {
        setState(() {
          _resourcesReady = true;
        });
      }
    } else if (forceCheck && mounted) {
      setState(() {
        _resourcesReady = false;
      });
    }
  }

  void _updateLightDirection(Offset localPosition) {
    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth! <= 0 ||
        _imageHeight! <= 0) return;

    final double ndcX = (localPosition.dx / _imageWidth!) * 2.0 - 1.0;
    final double ndcY = (localPosition.dy / _imageHeight!) * 2.0 - 1.0;
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
    _imageInfo?.dispose();
    _prismShader?.dispose();
    _sparkleShader?.dispose();
    _diamondPrismShader?.dispose();
    _chromeMetalShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool imageReady =
        _image != null && _imageWidth != null && _imageHeight != null;
    final bool shadersAttempted = _resourcesReady;

    bool shadersError = false;
    if (imageReady && shadersAttempted) {
      bool chromeNeeded = widget.materialEffect == MaterialEffect.chromeMetal;
      bool diamondNeeded = widget.materialEffect == MaterialEffect.diamondPrism;
      bool prismNeeded = widget.coatingEffect == CoatingEffect.prism;
      bool sparkleNeeded = widget.coatingEffect == CoatingEffect.sparkle;

      shadersError = (chromeNeeded && _chromeMetalShader == null) ||
          (diamondNeeded && _diamondPrismShader == null) ||
          (prismNeeded && _prismShader == null) ||
          (sparkleNeeded && _sparkleShader == null);
    }

    if (!imageReady || !shadersAttempted || shadersError) {
      String message = 'Loading Image...';
      Widget indicator = const CircularProgressIndicator();

      if (imageReady && !shadersAttempted) {
        message = 'Loading Shaders...';
      } else if (shadersError) {
        message = 'Error loading required shaders';
        indicator = Icon(Icons.error_outline, color: Colors.red, size: 48);
      } else if (!imageReady && shadersAttempted) {
        message = 'Error loading image';
        indicator = Icon(Icons.error_outline, color: Colors.red, size: 48);
      }

      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: shadersError ? Colors.red : null)),
        ],
      ));
    }

    final double currentWidth = _imageWidth!;
    final double currentHeight = _imageHeight!;
    final Size cardSize = Size(currentWidth, currentHeight);

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
          width: currentWidth,
          height: currentHeight,
          child: AnimatedBuilder(
            animation: _timeController,
            builder: (context, _) {
              final double currentTime = _timeController.value * 20;

              Widget materialLayer = const SizedBox.shrink();
              if (widget.materialEffect == MaterialEffect.chromeMetal &&
                  _chromeMetalShader != null) {
                materialLayer = CustomPaint(
                  size: cardSize,
                  painter: ChromeMetalPainter(
                    shader: _chromeMetalShader!,
                    time: currentTime,
                    lightDirection: _lightDirection,
                    width: currentWidth,
                    height: currentHeight,
                  ),
                );
              } else if (widget.materialEffect == MaterialEffect.diamondPrism &&
                  _diamondPrismShader != null) {
                materialLayer = CustomPaint(
                  size: cardSize,
                  painter: DiamondPrismPainter(
                    shader: _diamondPrismShader!,
                    time: currentTime,
                    lightDirection: _lightDirection,
                    width: currentWidth,
                    height: currentHeight,
                  ),
                );
              }

              final imageLayer = Opacity(
                opacity: widget.imageOpacity.clamp(0.0, 1.0),
                child: RawImage(
                    image: _image!,
                    fit: BoxFit.cover,
                    width: currentWidth,
                    height: currentHeight),
              );

              Widget coatingLayer = const SizedBox.shrink();
              if (widget.coatingEffect == CoatingEffect.prism &&
                  _prismShader != null) {
                coatingLayer = CustomPaint(
                  size: cardSize,
                  painter: PrismPainter(
                    shader: _prismShader!,
                    time: currentTime,
                    lightDirection: _lightDirection,
                    width: currentWidth,
                    height: currentHeight,
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
                    width: currentWidth,
                    height: currentHeight,
                  ),
                );
              }

              return Stack(
                children: [
                  materialLayer,
                  imageLayer,
                  coatingLayer,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

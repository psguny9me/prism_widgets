# prism_widgets

A Flutter widget library demonstrating various shader effects like prism, sparkle, diamond patterns, and chrome metal, simulating trading card effects.

## Features

*   Apply metallic and holographic effects using fragment shaders.
*   Combine different material (background) and coating (overlay) effects.
*   Interactive light reflection based on pointer position.
*   Configurable effects and image opacity.

## Getting started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  prism_widgets: ^1.0.0 # Replace with the latest version
```

Then import the package:

```dart
import 'package:prism_widgets/prism_card_widget.dart';
```

## Usage

```dart
PrismCardWidget(
  imageProvider: AssetImage('assets/images/your_card_image.png'),
  width: 300,
  height: 420,
  materialEffect: MaterialEffect.chromeMetal, // Or .diamondPrism, .none
  coatingEffect: CoatingEffect.sparkle,     // Or .prism, .none
  imageOpacity: 0.9, // Adjust visibility of the base image
)
```

See the `example` directory for a more detailed example application.

## Additional information

*   Repository: [Link to your repository]
*   Issue tracker: [Link to your issue tracker]
*   Feel free to contribute or report issues!
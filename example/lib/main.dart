import 'package:flutter/material.dart';
// Import the library package using the main library file
import 'package:prism_widgets/prism_widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prism Widgets Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MaterialEffect _selectedMaterial = MaterialEffect.none;
  CoatingEffect _selectedCoating = CoatingEffect.prism;
  double _imageOpacity = 0.85;
  final String _imagePath = 'assets/images/test.png'; // Example image path

  @override
  Widget build(BuildContext context) {
    // Precache the image to potentially improve initial load feel
    // Note: precacheImage might not be strictly necessary depending on ImageProvider used
    precacheImage(AssetImage(_imagePath), context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Prism Card Widget Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 300,
                height: 200,
                child: PrismCardWidget(
                  imageProvider: AssetImage(_imagePath),
                  materialEffect: _selectedMaterial,
                  coatingEffect: _selectedCoating,
                  imageOpacity: _imageOpacity,
                ),
              ),
              const SizedBox(height: 24),
              // --- Material Selection ---
              Text('Material (Background)',
                  style: Theme.of(context).textTheme.titleMedium),
              RadioListTile<MaterialEffect>(
                title: const Text('None'),
                value: MaterialEffect.none,
                groupValue: _selectedMaterial,
                onChanged: (MaterialEffect? value) {
                  setState(
                      () => _selectedMaterial = value ?? MaterialEffect.none);
                },
              ),
              RadioListTile<MaterialEffect>(
                title: const Text('Chrome Metal'),
                value: MaterialEffect.chromeMetal,
                groupValue: _selectedMaterial,
                onChanged: (MaterialEffect? value) {
                  setState(
                      () => _selectedMaterial = value ?? MaterialEffect.none);
                },
              ),
              RadioListTile<MaterialEffect>(
                title: const Text('Diamond Prism'),
                value: MaterialEffect.diamondPrism,
                groupValue: _selectedMaterial,
                onChanged: (MaterialEffect? value) {
                  setState(
                      () => _selectedMaterial = value ?? MaterialEffect.none);
                },
              ),
              const SizedBox(height: 20),

              // --- Coating Selection ---
              Text('Coating (Overlay)',
                  style: Theme.of(context).textTheme.titleMedium),
              RadioListTile<CoatingEffect>(
                title: const Text('None'),
                value: CoatingEffect.none,
                groupValue: _selectedCoating,
                onChanged: (CoatingEffect? value) {
                  setState(
                      () => _selectedCoating = value ?? CoatingEffect.none);
                },
              ),
              RadioListTile<CoatingEffect>(
                title: const Text('Prism'),
                value: CoatingEffect.prism,
                groupValue: _selectedCoating,
                onChanged: (CoatingEffect? value) {
                  setState(
                      () => _selectedCoating = value ?? CoatingEffect.none);
                },
              ),
              RadioListTile<CoatingEffect>(
                title: const Text('Sparkle'),
                value: CoatingEffect.sparkle,
                groupValue: _selectedCoating,
                onChanged: (CoatingEffect? value) {
                  setState(
                      () => _selectedCoating = value ?? CoatingEffect.none);
                },
              ),
              const SizedBox(height: 20),

              // --- Image Opacity Control ---
              Text('Image Opacity',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _imageOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 20, // Finer control
                label: _imageOpacity.toStringAsFixed(2),
                onChanged: (double value) {
                  setState(() {
                    _imageOpacity = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'prism_card_widget.dart'; // Import the custom widget and enums

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prism Shader Card Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        imagePath: 'assets/images/test.jpg', // Default image path
        cardWidth: 300.0,
        cardHeight: 420.0,
      ),
    );
  }
}

// Make MyHomePage stateful to manage the selected shader mode
class MyHomePage extends StatefulWidget {
  final String imagePath;
  final double cardWidth;
  final double cardHeight;

  const MyHomePage({
    super.key,
    required this.imagePath,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // State variables for selected material and coating
  MaterialEffect _selectedMaterial =
      MaterialEffect.chromeMetal; // Default material
  CoatingEffect _selectedCoating = CoatingEffect.sparkle; // Default coating
  double _imageOpacity = 0.85;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Material & Coating Effects'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          // Allow scrolling if content overflows
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            //
            // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
            // action in the IDE, or press "p" in the console), to see the
            // wireframe for each widget.
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Hover or drag over the card:',
              ),
              const SizedBox(height: 20),
              // Pass the selected effects to the widget
              PrismCardWidget(
                imageProvider: AssetImage(widget.imagePath),
                width: widget.cardWidth,
                height: widget.cardHeight,
                materialEffect: _selectedMaterial,
                coatingEffect: _selectedCoating,
                imageOpacity: _imageOpacity,
              ),
              const SizedBox(height: 30),

              // --- Material Selection ---
              const Text('Select Material (Background):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Select Coating (Overlay):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Image Opacity:'),
              Slider(
                value: _imageOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: _imageOpacity.toStringAsFixed(1),
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

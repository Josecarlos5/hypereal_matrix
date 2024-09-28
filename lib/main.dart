
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(HyperealMatrixApp());

class HyperealMatrixApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hypereal Matrix',
      theme: ThemeData.dark(),
      home: MatrixScreen(),
    );
  }
}

class MatrixScreen extends StatefulWidget {
  @override
  _MatrixScreenState createState() => _MatrixScreenState();
}

class _MatrixScreenState extends State<MatrixScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();  // Create an audio player instance
  bool _isPlaying = false;
  int density = 50;  // Start with low density
  final int maxDensity = 2000;
  List<MatrixElement> elements = [];
  Random random = Random();
  Timer? _timer;

  double greenOpacity = 0.0;  // Start with black screen
  double greenOpacityIncrement = 1.0 / (20 * 60);  // 1.0 over 1200 frames (~20 seconds at 60 FPS)
  int frameCounter = 0;  // To control progression

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initMatrix(density);  // Initialize the matrix with initial density
  }

  @override
  void dispose() {
    _audioPlayer.dispose();  // Dispose the audio player
    _timer?.cancel();
    super.dispose();
  }

  // Initialize the matrix with elements based on the current density
  void _initMatrix(int numElements) {
    elements.clear();
    for (int i = 0; i < numElements; i++) {
      elements.add(MatrixElement(random.nextDouble() * MediaQuery.of(context).size.width,
                                 random.nextDouble() * MediaQuery.of(context).size.height));
    }
  }

  // Gradually increase the green background opacity and kanji density over time
  void _increaseDensityGradually() {
    setState(() {
      if (greenOpacity < 1.0) {
        greenOpacity += greenOpacityIncrement;  // Gradually increase the green opacity
        if (greenOpacity > 1.0) greenOpacity = 1.0;  // Ensure it stays at 1.0 max
      }

      // Increase the density over 1200 frames (20 seconds at 60 FPS)
      if (density < maxDensity && frameCounter % 5 == 0) {  // Slow the density progression slightly
        density += 10;  // Increase density gradually every few frames
        _initMatrix(density);  // Reinitialize the matrix with updated density
      }

      frameCounter++;  // Track frames for smooth progression
    });
  }

  Future<void> _startAudioAndAnimation() async {
    if (!_isPlaying) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);  // Set the audio to loop
      await _audioPlayer.play(AssetSource('1.mp3'));  // Play the audio from assets

      setState(() {
        _isPlaying = true;
      });

      // Gradually increase density and green opacity at 60 frames per second
      _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (Timer t) {
        _increaseDensityGradually();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _startAudioAndAnimation,  // Start animation and music on tap
        child: Stack(
          children: [
            Container(
              color: Colors.black,
              child: CustomPaint(
                painter: MatrixPainter(elements, greenOpacity), // Pass the green opacity
              ),
            ),
            if (!_isPlaying)
              Center(
                child: Text(
                  'Click to start the music and animation',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MatrixPainter extends CustomPainter {
  final List<MatrixElement> elements;
  final double greenOpacity;  // To control the background color gradually turning green

  MatrixPainter(this.elements, this.greenOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the green background with increasing opacity
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.green.withOpacity(greenOpacity),
    );

    // Draw the matrix characters
    final textStyle = TextStyle(color: Colors.green, fontSize: 16);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var element in elements) {
      final textSpan = TextSpan(text: element.char, style: textStyle);
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(element.x, element.y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class MatrixElement {
  final double x;
  final double y;
  final String char;

  MatrixElement(this.x, this.y)
      : char = String.fromCharCode(0x30A0 + Random().nextInt(96));  // Generate random Kanji characters
}


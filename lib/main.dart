import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: const Text('VLP-32C Drawing'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Container(
          color: Colors.blueAccent,
          child: InteractiveViewer(
            maxScale: 10,
            minScale: 0.1,
            boundaryMargin: const EdgeInsets.all(10000),
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            constrained: false,
            child: const Vlp32cCanvas(
              maxAttackLength: 4000,
              pixelPerDegree: 50,
            )
          ),
        ),
      )
    );
  }
}

class Vlp32cCanvas extends StatefulWidget {
  final int maxAttackLength; // 最大攻撃長さ(1水平角あたり24)
  final double pixelPerDegree;
  const Vlp32cCanvas({super.key, required this.maxAttackLength, required this.pixelPerDegree});

  @override
  _Vlp32cCanvasState createState() => _Vlp32cCanvasState();
}

class _Vlp32cCanvasState extends State<Vlp32cCanvas> {
  final List<Vlp32cScan> scans = [];
  late final double canvasWidth;
  late final double canvasHeight;
  late final double minHorizontalAngle;
  late final double minVerticalAngle;

  @override
  void initState() {
    super.initState();
    double minHorizontalAngle = 0;
    double maxHorizontalAngle = 0;
    double minVerticalAngle = 0;
    double maxVerticalAngle = 0;
    for (int firingId = 0; firingId < widget.maxAttackLength; firingId++) {
      final laserIds = getLaserIdsFromFiringId(firingId);
      final azimuthIndex = firingId ~/ 24;
      final azimuthOffsetAngle = azimuthIndex * 0.2;
      for (final laserId in laserIds) {
        final fireAngle = laserIdToFireAngles[laserId];
        scans.add(Vlp32cScan(firingId, fireAngle.elevationAngle, fireAngle.azimuthAngle + azimuthOffsetAngle, false));
        minHorizontalAngle = math.min(minHorizontalAngle, fireAngle.azimuthAngle + azimuthOffsetAngle);
        maxHorizontalAngle = math.max(maxHorizontalAngle, fireAngle.azimuthAngle + azimuthOffsetAngle);
        minVerticalAngle = math.min(minVerticalAngle, fireAngle.elevationAngle);
        maxVerticalAngle = math.max(maxVerticalAngle, fireAngle.elevationAngle);
      }
    }
    canvasWidth = (maxHorizontalAngle - minHorizontalAngle) * widget.pixelPerDegree;
    canvasHeight = (maxVerticalAngle - minVerticalAngle) * widget.pixelPerDegree;
    this.minHorizontalAngle = minHorizontalAngle;
    this.minVerticalAngle = minVerticalAngle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: canvasWidth,
      height: canvasHeight,
      color: Colors.grey,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final scan in scans)
            Vlp32cCell(
              width: 10,
              height: 10,
              position: Offset(
                (scan.azimuthAngle - minHorizontalAngle) * widget.pixelPerDegree, 
                (scan.elevationAngle - minVerticalAngle) * widget.pixelPerDegree * -1 + canvasHeight,
              ),
              color: scan.underAttack ? Colors.red : Colors.white,
              borderColor: Colors.black,
              onTap: () {
                setState(() {
                  final indices = getIndicesFromFiringId(scan.firingId);
                  if (scan.underAttack) {
                    scans[indices[0]] = scans[indices[0]].unattack();
                    scans[indices[1]] = scans[indices[1]].unattack();
                  }
                  else {
                    scans[indices[0]] = scans[indices[0]].attack();
                    scans[indices[1]] = scans[indices[1]].attack();
                  }
                });
              },
            ),
        ],
      ),
    );
  }
}

List<int> getLaserIdsFromFiringId(int firingId) {
  final firingOrder = firingId % 24;
  if (firingOrder >= 16) return [];

  return [firingOrder * 2, firingOrder * 2 + 1];
}

List<int> getIndicesFromFiringId(int firingId) {
  final base = firingId % 24 + firingId ~/ 24 * 16;
  return [base * 2, base * 2 + 1];
}

const laserIdToFireAngles = <FireAngle>[
  FireAngle(-25, 1.4),
  FireAngle(-1, -4.2),
  FireAngle(-1.667, 1.4),
  FireAngle(-15.639, -1.4),
  FireAngle(-11.31, 1.4),
  FireAngle(0, -1.4),
  FireAngle(-0.667, 4.2),
  FireAngle(-8.843, -1.4),
  FireAngle(-7.254, 1.4),
  FireAngle(0.333, -4.2),
  FireAngle(-0.333, 1.4),
  FireAngle(-6.148, -1.4),
  FireAngle(-5.333, 4.2),
  FireAngle(1.333, -1.4),
  FireAngle(0.667, 4.2),
  FireAngle(-4, -1.4),
  FireAngle(-4.667, 1.4),
  FireAngle(1.667, -4.2),
  FireAngle(1, 1.4),
  FireAngle(-3.667, -4.2),
  FireAngle(-3.333, 4.2),
  FireAngle(3.333, -1.4),
  FireAngle(2.333, 1.4),
  FireAngle(-2.667, -1.4),
  FireAngle(-3, 1.4),
  FireAngle(7, -1.4),
  FireAngle(4.667, 1.4),
  FireAngle(-2.333, -4.2),
  FireAngle(-2, 4.2),
  FireAngle(15, -1.4),
  FireAngle(10.333, 1.4),
  FireAngle(-1.333, -1.4),
];

class FireAngle {
  final double elevationAngle;
  final double azimuthAngle;

  const FireAngle(this.elevationAngle, this.azimuthAngle);
}

Color getRandomColor() {
  final random = math.Random();
  return Color.fromARGB(
    255,
    random.nextInt(255),
    random.nextInt(255),
    random.nextInt(255),
  );
}

class Vlp32cCell extends StatelessWidget {
  final int width;
  final int height;
  final Offset position;
  final Color color;
  final Color borderColor;
  final Function()? onTap;
  const Vlp32cCell({super.key, required this.width, required this.height, required this.position, required this.color, required this.borderColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width.toDouble(),
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor),
          ),
        ),
      ),
    );
  }
}

class Vlp32cScan {
  final int firingId;
  final double elevationAngle;
  final double azimuthAngle;
  final bool underAttack;

  const Vlp32cScan(this.firingId, this.elevationAngle, this.azimuthAngle, this.underAttack);

  Vlp32cScan attack() {
    return Vlp32cScan(firingId, elevationAngle, azimuthAngle, true);
  }

  Vlp32cScan unattack() {
    return Vlp32cScan(firingId, elevationAngle, azimuthAngle, false);
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Draws a clean transit badge showing the route short name only (no vehicle id).
/// Styling matches the mockup's blue pill with white text, large and readable.
Future<BitmapDescriptor> buildRouteMarker(String routeShortName, String vehicleId) async {
  // Size adapts to the text length so short numbers ("21") and long names
  // ("H Line") both look balanced.
  final label = routeShortName.length > 6
      ? routeShortName.substring(0, 6)
      : routeShortName;
  final double fontSize = label.length <= 3 ? 38.0 : label.length <= 5 ? 30.0 : 24.0;
  final double w = label.length <= 3 ? 110 : label.length <= 5 ? 150 : 170;
  const double h = 78;
  const double radius = 18;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

  // Drop shadow for depth (matches the mockup's soft shadow)
  final shadowPaint = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, w, h - 4),
      const Radius.circular(radius),
    ),
    shadowPaint,
  );

  // Main badge background — bold blue matching the app's primary
  final bgPaint = Paint()..color = const Color(0xFF1A56DB);
  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, w, h - 4),
    const Radius.circular(radius),
  );
  canvas.drawRRect(rrect, bgPaint);

  // Route short name, centered
  final routePara = (ui.ParagraphBuilder(
    ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    ),
  )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(label))
      .build()
    ..layout(ui.ParagraphConstraints(width: w));
  canvas.drawParagraph(
    routePara,
    Offset(0, ((h - 4) - routePara.height) / 2),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

/// Draws a small circular bus-stop marker (white circle, blue border).
/// Updated to use the app's primary blue to match the light theme.
Future<BitmapDescriptor> buildStopIcon() async {
  const double size = 32;
  const double r = 12;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  const center = Offset(size / 2, size / 2);

  // White outer ring
  canvas.drawCircle(center, r, Paint()..color = Colors.white);

  // Blue dot
  canvas.drawCircle(center, r - 4, Paint()..color = const Color(0xFF1A56DB));

  // Light blue border
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = const Color(0xFF1A56DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

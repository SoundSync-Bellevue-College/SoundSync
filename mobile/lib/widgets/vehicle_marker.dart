import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Draws a transit badge showing [routeShortName] (large) and [vehicleId] (small)
/// and returns a [BitmapDescriptor] suitable for a Google Maps marker icon.
Future<BitmapDescriptor> buildRouteMarker(String routeShortName, String vehicleId) async {
  const double w = 112;
  const double h = 56;
  const double radius = 12;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

  // Badge background — Sound Transit dark blue
  final bgPaint = Paint()..color = const Color(0xFF0F4C81);
  final rrect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, w, h),
    const Radius.circular(radius),
  );
  canvas.drawRRect(rrect, bgPaint);

  // White border
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );

  // Route short name — top, large
  final routeLabel = routeShortName.length > 6 ? routeShortName.substring(0, 6) : routeShortName;
  final routeFontSize = routeLabel.length <= 3 ? 22.0 : routeLabel.length <= 5 ? 17.0 : 14.0;

  final routePara = (ui.ParagraphBuilder(
    ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: routeFontSize, fontWeight: FontWeight.bold),
  )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(routeLabel))
      .build()
    ..layout(const ui.ParagraphConstraints(width: w));
  canvas.drawParagraph(routePara, Offset(0, 4));

  // Vehicle ID — bottom, small cyan
  final vidLabel = vehicleId.length > 8 ? vehicleId.substring(vehicleId.length - 8) : vehicleId;
  final vidPara = (ui.ParagraphBuilder(
    ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 11, fontWeight: FontWeight.normal),
  )
        ..pushStyle(ui.TextStyle(color: const Color(0xFF7FDBFF)))
        ..addText(vidLabel))
      .build()
    ..layout(const ui.ParagraphConstraints(width: w));
  canvas.drawParagraph(vidPara, Offset(0, h - vidPara.height - 4));

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

/// Draws a small circular bus-stop marker (white circle, cyan border).
Future<BitmapDescriptor> buildStopIcon() async {
  const double size = 32;
  const double r = 12;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

  const center = Offset(size / 2, size / 2);

  // White fill
  canvas.drawCircle(center, r, Paint()..color = Colors.white);

  // Dark navy inner fill
  canvas.drawCircle(center, r - 3.5, Paint()..color = const Color(0xFF0D1B2A));

  // Cyan border
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..color = const Color(0xFF7FDBFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

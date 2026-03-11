import 'package:flutter/material.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route $routeId')),
      body: Center(
        child: Text('Route detail view — coming soon', style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final IconData icon;

  ServiceModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  static List<ServiceModel> getMockServices() {
    return [
      ServiceModel(id: '1', name: 'Plumber', icon: Icons.plumbing),
      ServiceModel(id: '2', name: 'Electrician', icon: Icons.electrical_services),
      ServiceModel(id: '3', name: 'AC Mechanic', icon: Icons.ac_unit),
      ServiceModel(id: '4', name: 'Carpenter', icon: Icons.carpenter),
      ServiceModel(id: '5', name: 'Painter', icon: Icons.format_paint),
      ServiceModel(id: '6', name: 'Appliance Repair', icon: Icons.home_repair_service),
      ServiceModel(id: '7', name: 'Mason', icon: Icons.foundation),
      ServiceModel(id: '8', name: 'Other', icon: Icons.more_horiz),
    ];
  }
}

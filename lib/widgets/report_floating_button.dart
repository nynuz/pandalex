import 'package:flutter/material.dart';
import 'emergency_modal.dart';  // <-- CAMBIA IMPORT

class ReportFloatingButton extends StatelessWidget {
  final Widget child;
  final bool showButton;

  const ReportFloatingButton({
    super.key,
    required this.child,
    this.showButton = true,
  });

  void _openEmergencyModal(BuildContext context) {  // <-- RINOMINA
    showDialog(
      context: context,
      builder: (context) => const EmergencyModal(),  // <-- CAMBIA
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showButton) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 16,  // <-- Già a destra
          bottom: 16,
          child: FloatingActionButton.extended(  // <-- CAMBIA in extended per testo
            onPressed: () => _openEmergencyModal(context),
            backgroundColor: Colors.red,
            heroTag: 'emergency_fab',
            tooltip: 'SOS Polizia Locale',
            icon: const Icon(
              Icons.phone,
              color: Colors.white,
              size: 28,
            ),
            label: const Text(
              'SOS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ReportFloatingActionButton extends StatelessWidget {
  const ReportFloatingActionButton({super.key});

  void _openEmergencyModal(BuildContext context) {  // <-- RINOMINA
    showDialog(
      context: context,
      builder: (context) => const EmergencyModal(),  // <-- CAMBIA
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(  // <-- CAMBIA in extended
      onPressed: () => _openEmergencyModal(context),
      backgroundColor: Colors.red,
      heroTag: 'emergency_fab',
      tooltip: 'SOS Polizia Locale',
      icon: const Icon(
        Icons.phone,
        color: Colors.white,
        size: 28,
      ),
      label: const Text(
        'SOS',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
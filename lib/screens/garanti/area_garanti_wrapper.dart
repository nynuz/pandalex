import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/garante_auth_provider.dart';
import 'area_garanti_login_screen.dart';
import 'area_garanti_dashboard_screen.dart';

class AreaGarantiWrapper extends StatefulWidget {
  const AreaGarantiWrapper({Key? key}) : super(key: key);

  @override
  State<AreaGarantiWrapper> createState() => _AreaGarantiWrapperState();
}

class _AreaGarantiWrapperState extends State<AreaGarantiWrapper> {
  @override
  void initState() {
    super.initState();
    // Verifica lo stato di autenticazione all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GaranteAuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GaranteAuthProvider>(
      builder: (context, authProvider, child) {
        // Mostra loading durante il check
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Se autenticato, mostra dashboard
        if (authProvider.isAuthenticated && authProvider.currentGarante != null) {
          return const AreaGarantiDashboardScreen();
        }

        // Altrimenti mostra login
        return const AreaGarantiLoginScreen();
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/di/injection_container.dart';
import 'package:mamba_fast_tracker/core/feature_flags/feature_flags_service.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthStarted());
    _initializeFlags();
  }

  Future<void> _initializeFlags() async {
    final flagsService = sl<FeatureFlagsService>();
    try {
      await flagsService.warmUp();
      debugPrint(
        '[Splash][RemoteConfig] hasRequiredFlags=${flagsService.hasRequiredFlags} '
        'enable_dark_mode_menu=${flagsService.enableDarkModeMenu} '
        'enable_dark_mode_menu_source=${flagsService.darkModeMenuSource} '
        'enable_recover_password=${flagsService.enableRecoverPassword} '
        'enable_recover_password_source=${flagsService.recoverPasswordSource} '
        'lastFetchStatus=${flagsService.lastFetchStatus.name} '
        'lastFetchTime=${flagsService.lastFetchTime}',
      );
      if (!flagsService.hasRequiredFlags && mounted) {
        setState(() {
          _errorMessage = 'Remote Config incompleta. Usando valores padrao.';
        });
      }
    } catch (error, stackTrace) {
      debugPrint('[Splash][RemoteConfig] erro=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha ao carregar Remote Config. Usando valores padrao.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

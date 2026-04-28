import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/di/injection_container.dart';
import 'package:mamba_fast_tracker/core/feature_flags/feature_flags_service.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlagsService>();
    final authRepository = sl<AuthRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (flags.enableDarkModeMenu)
            PopupMenuButton<ThemeMode>(
              onSelected: (mode) => context.read<ThemeCubit>().setThemeMode(mode),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text('Tema do sistema'),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text('Modo claro'),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Modo escuro'),
                ),
              ],
              icon: const Icon(Icons.palette_outlined),
            ),
          IconButton(
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<AppUser?>(
        future: authRepository.getCurrentUser(),
        builder: (context, snapshot) {
          final userName = snapshot.data?.name.trim() ?? '';
          final hasName = userName.isNotEmpty;
          return Center(
            child: Text(
              hasName ? 'Olá, $userName' : 'Usuario autenticado',
            ),
          );
        },
      ),
    );
  }
}

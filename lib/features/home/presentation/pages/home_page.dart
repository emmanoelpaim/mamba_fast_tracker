import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.enableDarkModeMenu, super.key});

  final bool enableDarkModeMenu;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _currentIndex = 2;

  static const _titles = [
    'Configuração',
    'Jejum',
    'Início',
    'Registro de refeições',
    'Histórico',
  ];

  Widget _buildSettingsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.enableDarkModeMenu)
          ListTile(
            title: const Text('Tema do app'),
            trailing: PopupMenuButton<ThemeMode>(
              onSelected: (mode) =>
                  context.read<ThemeCubit>().setThemeMode(mode),
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
              child: const Icon(Icons.palette_outlined),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(child: Text(title));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildSettingsTab(context),
      _buildPlaceholder('Jejum'),
      _buildPlaceholder('Início'),
      _buildPlaceholder('Registro de refeições'),
      _buildPlaceholder('Histórico'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configuração',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Jejum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Refeições',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

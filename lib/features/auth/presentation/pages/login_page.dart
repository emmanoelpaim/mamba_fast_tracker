import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mamba_fast_tracker/core/di/injection_container.dart';
import 'package:mamba_fast_tracker/core/feature_flags/feature_flags_service.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/widgets/auth_toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlagsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthFlowStatus.error && state.errorMessage.isNotEmpty) {
            showAuthErrorToast(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthFlowStatus.loading;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthBloc>().add(
                                AuthLoginRequested(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                ),
                              );
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Entrar'),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Criar conta'),
                ),
                if (flags.enableRecoverPassword)
                  TextButton(
                    onPressed: () => context.go('/recover'),
                    child: const Text('Recuperar senha'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

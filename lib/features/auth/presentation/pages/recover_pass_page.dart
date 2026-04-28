import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/widgets/auth_toast.dart';

class RecoverPassPage extends StatefulWidget {
  const RecoverPassPage({super.key});

  @override
  State<RecoverPassPage> createState() => _RecoverPassPageState();
}

class _RecoverPassPageState extends State<RecoverPassPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthFlowStatus.passwordRecoverySent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('E-mail de recuperacao enviado')),
            );
            context.go('/login');
          } else if (state.status == AuthFlowStatus.error &&
              state.errorMessage.isNotEmpty) {
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthBloc>().add(
                                AuthRecoverPasswordRequested(
                                  _emailController.text.trim(),
                                ),
                              );
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Enviar e-mail'),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar para login'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

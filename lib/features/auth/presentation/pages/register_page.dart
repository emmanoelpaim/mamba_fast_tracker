import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mamba_fast_tracker/core/presentation/widgets/screen_blocking_loader.dart';
import 'package:mamba_fast_tracker/features/auth/domain/password_policy.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/widgets/auth_toast.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthFlowStatus.error &&
              state.errorMessage.isNotEmpty) {
            showAuthErrorToast(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthFlowStatus.loading;
          final policy = PasswordPolicyResult.evaluate(
            _passwordController.text,
          );
          final strengthLabel = PasswordPolicyResult.strengthLabel(policy);
          return ScreenBlockingLoader(
            isLoading: isLoading,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cadastro',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: policy.rulesMetCount / 3,
                          minHeight: 6,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strengthLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      _RuleRow(
                        met: policy.minLengthMet,
                        text: 'Pelo menos 8 caracteres',
                      ),
                      _RuleRow(
                        met: policy.hasUppercase,
                        text: 'Uma letra mai\u00fascula',
                      ),
                      _RuleRow(
                        met: policy.hasSpecial,
                        text: 'Um caractere especial',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                final p = PasswordPolicyResult.evaluate(
                                  _passwordController.text.trim(),
                                );
                                if (!p.isValid) {
                                  showAuthErrorToast(
                                    context,
                                    PasswordPolicyResult.missingRulesMessage(p),
                                  );
                                  return;
                                }
                                context.read<AuthBloc>().add(
                                  AuthRegisterRequested(
                                    name: _nameController.text.trim(),
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  ),
                                );
                              },
                        child: const Text('Cadastrar'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Voltar para login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: met
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).hintColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

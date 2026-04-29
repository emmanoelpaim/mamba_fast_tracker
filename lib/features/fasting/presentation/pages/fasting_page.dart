import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';

class FastingPage extends StatefulWidget {
  const FastingPage({super.key});

  @override
  State<FastingPage> createState() => _FastingPageState();
}

class _FastingPageState extends State<FastingPage> {
  @override
  void initState() {
    super.initState();
    context.read<FastingBloc>().add(const FastingInitialized());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FastingBloc, FastingState>(
      builder: (context, state) {
        final bloc = context.read<FastingBloc>();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Protocolos de jejum',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _protocolChip(context, state, FastingProtocol.preset1212),
                _protocolChip(context, state, FastingProtocol.preset168),
                _protocolChip(context, state, FastingProtocol.preset186),
                ChoiceChip(
                  label: const Text('Customizado'),
                  selected: state.protocol.isCustom,
                  onSelected: (_) async {
                    final custom = await _showCustomProtocolDialog(context);
                    if (custom != null && context.mounted) {
                      bloc.add(FastingProtocolSelected(custom));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Protocolo atual: ${state.protocol.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            _timerCard(state),
            const SizedBox(height: 16),
            _actionButtons(context, state),
            if (state.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                state.errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _protocolChip(
    BuildContext context,
    FastingState state,
    FastingProtocol protocol,
  ) {
    final selected = state.protocol == protocol;
    return ChoiceChip(
      label: Text(protocol.label),
      selected: selected,
      onSelected: (_) {
        context.read<FastingBloc>().add(FastingProtocolSelected(protocol));
      },
    );
  }

  Widget _timerCard(FastingState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _timerRow('Tempo decorrido', _formatDuration(state.elapsed)),
            const SizedBox(height: 8),
            _timerRow('Tempo restante', _formatDuration(state.remaining)),
            const SizedBox(height: 8),
            _timerRow(
              'Status',
              switch (state.session.status) {
                FastingSessionStatus.running => 'Em andamento',
                FastingSessionStatus.paused => 'Pausado',
                FastingSessionStatus.idle => 'Parado',
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionButtons(BuildContext context, FastingState state) {
    final bloc = context.read<FastingBloc>();
    final status = state.session.status;
    if (status == FastingSessionStatus.running) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => bloc.add(const FastingPaused()),
              child: const Text('Pausar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => bloc.add(const FastingStopped()),
              child: const Text('Encerrar'),
            ),
          ),
        ],
      );
    }
    if (status == FastingSessionStatus.paused) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => bloc.add(const FastingResumed()),
              child: const Text('Continuar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => bloc.add(const FastingStopped()),
              child: const Text('Encerrar'),
            ),
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () => bloc.add(const FastingStarted()),
      child: const Text('Iniciar jejum'),
    );
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours.remainder(100).toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<FastingProtocol?> _showCustomProtocolDialog(BuildContext context) async {
    final fastingController = TextEditingController();
    final eatingController = TextEditingController();
    return showDialog<FastingProtocol>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Protocolo customizado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fastingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Horas de jejum'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: eatingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Horas de alimentação'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final fastingHours = int.tryParse(fastingController.text.trim());
                final eatingHours = int.tryParse(eatingController.text.trim());
                if (fastingHours == null || eatingHours == null) return;
                if (fastingHours <= 0 || eatingHours <= 0) return;
                final label = '$fastingHours:$eatingHours';
                Navigator.of(context).pop(
                  FastingProtocol(
                    label: label,
                    fastingHours: fastingHours,
                    eatingHours: eatingHours,
                    isCustom: true,
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

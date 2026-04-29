import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/presentation/widgets/screen_blocking_loader.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_bloc.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_event.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_state.dart';

class MealPage extends StatefulWidget {
  const MealPage({super.key});

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealBloc, MealState>(
      builder: (context, state) {
        return Scaffold(
          body: ScreenBlockingLoader(
            isLoading: state.isLoading,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  (state.meals.isEmpty && !state.isLoading
                      ? 1
                      : state.meals.length) +
                  (state.errorMessage.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (state.meals.isEmpty && !state.isLoading) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Nenhuma refeição cadastrada.'),
                      ),
                    );
                  }
                  return Text(
                    state.errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                }

                if (index < state.meals.length) {
                  return _mealTile(state.meals[index]);
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    state.errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showMealDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar refeição'),
          ),
        );
      },
    );
  }

  Widget _mealTile(MealEntry meal) {
    final localTime = meal.createdAtUtc.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return Card(
      child: ListTile(
        title: Text(meal.name),
        subtitle: Text('${meal.calories} kcal - $hour:$minute'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              onPressed: () => _showMealDialog(context, editing: meal),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () =>
                  context.read<MealBloc>().add(MealDeleted(meal.id)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMealDialog(
    BuildContext context, {
    MealEntry? editing,
  }) async {
    final nameController = TextEditingController(text: editing?.name ?? '');
    final caloriesController = TextEditingController(
      text: editing?.calories.toString() ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(editing == null ? 'Nova refeição' : 'Editar refeição'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Calorias'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Horário automático: agora'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final calories = int.tryParse(caloriesController.text.trim());
                if (name.isEmpty || calories == null || calories <= 0) {
                  return;
                }
                if (editing == null) {
                  context.read<MealBloc>().add(
                    MealAdded(name: name, calories: calories),
                  );
                } else {
                  context.read<MealBloc>().add(
                    MealUpdated(
                      editing.copyWith(
                        name: name,
                        calories: calories,
                        createdAtUtc: DateTime.now().toUtc(),
                      ),
                    ),
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

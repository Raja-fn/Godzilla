import 'package:ai_health/features/nutrition/bloc/nutrition_event.dart';
import 'package:ai_health/features/nutrition/bloc/nutrition_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../bloc/nutrition_bloc.dart';
import '../models/nutrition_entry.dart';
import '../repo/nutrition_repo.dart';

class NutritionPage extends StatefulWidget {
  final String userId;

  const NutritionPage({super.key, required this.userId});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final ImagePicker _imagePicker = ImagePicker();
  DateTime _selectedDate = DateTime.now();

  // Form controllers
  final _dishNameController = TextEditingController();
  final _rotsController = TextEditingController();
  final _chawalWeightController = TextEditingController();
  final _vegetableNameController = TextEditingController();
  final _vegetableWeightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch meals for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionBloc>().add(
        NutritionFetchMealsForDate(widget.userId, _selectedDate),
      );
    });
  }

  @override
  void dispose() {
    _dishNameController.dispose();
    _rotsController.dispose();
    _chawalWeightController.dispose();
    _vegetableNameController.dispose();
    _vegetableWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (mounted) {
        context.read<NutritionBloc>().add(
          NutritionFetchMealsForDate(widget.userId, _selectedDate),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null && mounted) {
        final imageFile = File(image.path);
        context.read<NutritionBloc>().add(NutritionImageSelected(imageFile));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _addDish(BuildContext context) {
    final dishName = _dishNameController.text.trim();
    final rots = int.tryParse(_rotsController.text) ?? 0;
    final chawalWeight = double.tryParse(_chawalWeightController.text) ?? 0.0;

    if (dishName.isEmpty || (rots == 0 && chawalWeight == 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill dish details')));
      return;
    }

    final dish = DishMetadata(
      dishName: dishName,
      numberOfRots: rots,
      chawalWeight: chawalWeight,
      vegetables: [],
    );

    context.read<NutritionBloc>().add(NutritionAddDish(dish));
    _dishNameController.clear();
    _rotsController.clear();
    _chawalWeightController.clear();
  }

  void _addVegetable(BuildContext context, int dishIndex) {
    final vegetableName = _vegetableNameController.text.trim();
    final vegetableWeight =
        double.tryParse(_vegetableWeightController.text) ?? 0.0;

    if (vegetableName.isEmpty || vegetableWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill vegetable details')),
      );
      return;
    }

    final vegetable = VegetableMetadata(
      name: vegetableName,
      weight: vegetableWeight,
      unit: 'g',
    );

    context.read<NutritionBloc>().add(
      NutritionAddVegetable(dishIndex, vegetable),
    );

    _vegetableNameController.clear();
    _vegetableWeightController.clear();
  }

  void _submitNutrition() {
    context.read<NutritionBloc>().add(NutritionSubmit(widget.userId));
  }

  void _showAddMealModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddMealModal(),
    );
  }

  Widget _buildAddMealModal() {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: BlocConsumer<NutritionBloc, NutritionState>(
            listener: (context, state) {
              if (state is NutritionMealAdded) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meal added successfully!')),
                );
                // Refresh meals for selected date
                context.read<NutritionBloc>().add(
                  NutritionFetchMealsForDate(widget.userId, _selectedDate),
                );
                _resetFormFields();
              } else if (state is NutritionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final dishes = state is NutritionFormUpdated ? state.dishes : [];
              final selectedImage = state is NutritionFormUpdated
                  ? state.image
                  : null;

              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Add New Meal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Photo Section
                      const Text(
                        'Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedImage != null)
                        Stack(
                          children: [
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(selectedImage),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  context.read<NutritionBloc>().add(
                                    NutritionImageSelected(File('')),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Meal Time Section
                      const Text(
                        'Meal Time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && mounted) {
                            final now = DateTime.now();
                            final selectedTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              time.hour,
                              time.minute,
                            );
                            if (mounted) {
                              context.read<NutritionBloc>().add(
                                NutritionUpdateMealTime(selectedTime),
                              );
                            }
                          }
                        },
                        child: Text(
                          state is NutritionFormUpdated
                              ? _formatTime(state.mealTime)
                              : _formatTime(DateTime.now()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Dishes Section
                      const Text(
                        'Dishes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dishNameController,
                        decoration: InputDecoration(
                          labelText: 'Dish Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rotsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Rots',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _chawalWeightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Rice (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => _addDish(context),
                        child: const Text('Add Dish'),
                      ),
                      if (dishes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Added Dishes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...dishes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final dish = entry.value;
                          return _buildDishListItem(context, index, dish);
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Notes Section
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Additional notes...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: selectedImage == null || dishes.isEmpty
                            ? null
                            : _submitNutrition,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: state is NutritionLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Submit Meal'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDishListItem(
    BuildContext context,
    int dishIndex,
    DishMetadata dish,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.dishName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rots: ${dish.numberOfRots} | Rice: ${dish.chawalWeight}g',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<NutritionBloc>().add(
                      NutritionRemoveDish(dishIndex),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (dish.vegetables.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...dish.vegetables.map((veg) {
                final vegIndex = dish.vegetables.indexOf(veg);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '  • ${veg.name}: ${veg.weight}${veg.unit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<NutritionBloc>().add(
                            NutritionRemoveVegetable(dishIndex, vegIndex),
                          );
                        },
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (dish.vegetables.isEmpty) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _vegetableNameController,
                decoration: InputDecoration(
                  labelText: 'Add vegetable',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _vegetableWeightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (g)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => _addVegetable(context, dishIndex),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _resetFormFields() {
    _dishNameController.clear();
    _rotsController.clear();
    _chawalWeightController.clear();
    _vegetableNameController.clear();
    _vegetableWeightController.clear();
    _notesController.clear();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NutritionBloc(repository: NutritionRepository()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition Tracker'),
          centerTitle: true,
        ),
        body: BlocListener<NutritionBloc, NutritionState>(
          listener: (context, state) {
            if (state is NutritionMealDeleted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Meal deleted')));
              // Refresh meals
              context.read<NutritionBloc>().add(
                NutritionFetchMealsForDate(widget.userId, _selectedDate),
              );
            }
          },
          child: BlocBuilder<NutritionBloc, NutritionState>(
            builder: (context, state) {
              return Column(
                children: [
                  // Date Picker Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                            });
                            context.read<NutritionBloc>().add(
                              NutritionFetchMealsForDate(
                                widget.userId,
                                _selectedDate,
                              ),
                            );
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Text(
                            _formatDate(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
                            });
                            context.read<NutritionBloc>().add(
                              NutritionFetchMealsForDate(
                                widget.userId,
                                _selectedDate,
                              ),
                            );
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  // Daily Summary Card
                  if (state is NutritionMealsLoaded &&
                      state.dailyNutrition != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Summary',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNutritionItem(
                                    'Calories',
                                    '${state.dailyNutrition!.calories.toStringAsFixed(0)}',
                                    'kcal',
                                  ),
                                  _buildNutritionItem(
                                    'Protein',
                                    '${state.dailyNutrition!.protein.toStringAsFixed(1)}',
                                    'g',
                                  ),
                                  _buildNutritionItem(
                                    'Carbs',
                                    '${state.dailyNutrition!.carbohydrates.toStringAsFixed(1)}',
                                    'g',
                                  ),
                                  _buildNutritionItem(
                                    'Fat',
                                    '${state.dailyNutrition!.fat.toStringAsFixed(1)}',
                                    'g',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Meals List
                  Expanded(child: _buildMealsList(state)),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMealModal,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(unit, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMealsList(NutritionState state) {
    if (state is NutritionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NutritionMealsLoaded) {
      if (state.meals.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No meals added yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first meal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.meals.length,
        itemBuilder: (context, index) {
          final meal = state.meals[index];
          return _buildMealCard(meal);
        },
      );
    }

    if (state is NutritionError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: ${state.message}'),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMealCard(NutritionEntry meal) {
    final nutrition = meal.nutritionInfo;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(meal.mealTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal.dishes.map((d) => d.dishName).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Meal?'),
                        content: const Text(
                          'Are you sure you want to delete this meal?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<NutritionBloc>().add(
                                NutritionDeleteMeal(widget.userId, meal.id),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNutritionBadge(
                  '${nutrition.calories.toStringAsFixed(0)} kcal',
                  Colors.orange,
                ),
                _buildNutritionBadge(
                  '${nutrition.protein.toStringAsFixed(1)}g P',
                  Colors.red,
                ),
                _buildNutritionBadge(
                  '${nutrition.carbohydrates.toStringAsFixed(1)}g C',
                  Colors.blue,
                ),
                _buildNutritionBadge(
                  '${nutrition.fat.toStringAsFixed(1)}g F',
                  Colors.yellow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

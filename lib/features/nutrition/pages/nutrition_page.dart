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

class _NutritionPageState extends State<NutritionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();

  final _dishNameController = TextEditingController();
  final _rotsController = TextEditingController();
  final _chawalWeightController = TextEditingController();
  final _vegetableNameController = TextEditingController();
  final _vegetableWeightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dishNameController.dispose();
    _rotsController.dispose();
    _chawalWeightController.dispose();
    _vegetableNameController.dispose();
    _vegetableWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null && mounted) {
        final imageFile = File(image.path);
        if (mounted) {
          context.read<NutritionBloc>().add(NutritionImageSelected(imageFile));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _addDish() {
    final dishName = _dishNameController.text.trim();
    final rots = int.tryParse(_rotsController.text) ?? 0;
    final chawalWeight = double.tryParse(_chawalWeightController.text) ?? 0.0;

    if (dishName.isEmpty || rots == 0 || chawalWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all dish fields')),
      );
      return;
    }

    final dish = DishMetadata(
      dishName: dishName,
      numberOfRots: rots,
      chawalWeight: chawalWeight,
      vegetables: [],
    );

    if (mounted) {
      context.read<NutritionBloc>().add(NutritionAddDish(dish));
    }

    _dishNameController.clear();
    _rotsController.clear();
    _chawalWeightController.clear();
  }

  void _addVegetable(int dishIndex) {
    final vegetableName = _vegetableNameController.text.trim();
    final vegetableWeight =
        double.tryParse(_vegetableWeightController.text) ?? 0.0;

    if (vegetableName.isEmpty || vegetableWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all vegetable fields')),
      );
      return;
    }

    final vegetable = VegetableMetadata(
      name: vegetableName,
      weight: vegetableWeight,
      unit: 'grams',
    );

    if (mounted) {
      context.read<NutritionBloc>().add(
        NutritionAddVegetable(dishIndex, vegetable),
      );
    }

    _vegetableNameController.clear();
    _vegetableWeightController.clear();
  }

  void _submitNutrition() {
    if (mounted) {
      context.read<NutritionBloc>().add(NutritionSubmit(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NutritionBloc(repository: NutritionRepository()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition Entry'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Photo'),
              Tab(text: 'Dishes'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: BlocConsumer<NutritionBloc, NutritionState>(
          listener: (context, state) {
            if (state is NutritionSubmitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nutrition entry submitted!')),
              );
              // Reset form
              context.read<NutritionBloc>().add(NutritionReset());
              _tabController.animateTo(0);
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
            return TabBarView(
              controller: _tabController,
              children: [
                // Photo Tab
                _buildPhotoTab(context, state),
                // Dishes Tab
                _buildDishesTab(context, state),
                // Summary Tab
                _buildSummaryTab(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoTab(BuildContext context, NutritionState state) {
    File? selectedImage;
    if (state is NutritionImageSelectedState) {
      selectedImage = state.selectedImage;
    } else if (state is NutritionFormUpdated) {
      selectedImage = state.image;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Capture Food Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (selectedImage != null)
            Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(selectedImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Image selected: ${selectedImage.path.split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            )
          else
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 2),
                color: Colors.grey[100],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No image selected'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          if (selectedImage != null)
            OutlinedButton.icon(
              onPressed: () {
                context.read<NutritionBloc>().add(
                  NutritionImageSelected(
                    File(''), // Clear image
                  ),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Remove Photo'),
            ),
        ],
      ),
    );
  }

  Widget _buildDishesTab(BuildContext context, NutritionState state) {
    final dishes = state is NutritionFormUpdated
        ? state.dishes
        : <DishMetadata>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Dish Form
          const SizedBox(height: 16),
          const Text(
            'Add Dish',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dishNameController,
            decoration: InputDecoration(
              labelText: 'Dish Name',
              hintText: 'e.g., Rice and Curry',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rotsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number of Rots',
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
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _chawalWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chawal Weight (g)',
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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _addDish,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Add Dish'),
          ),
          const SizedBox(height: 24),
          // Display Added Dishes
          if (dishes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Added Dishes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...dishes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dish = entry.value;
                  return _buildDishCard(context, index, dish);
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDishCard(
    BuildContext context,
    int dishIndex,
    DishMetadata dish,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rots: ${dish.numberOfRots} | Chawal: ${dish.chawalWeight}g',
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
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            if (dish.vegetables.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Vegetables:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...dish.vegetables.asMap().entries.map((entry) {
                final vegIndex = entry.key;
                final veg = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${veg.name}: ${veg.weight}${veg.unit}'),
                      IconButton(
                        onPressed: () {
                          context.read<NutritionBloc>().add(
                            NutritionRemoveVegetable(dishIndex, vegIndex),
                          );
                        },
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _vegetableNameController,
              decoration: InputDecoration(
                labelText: 'Vegetable Name',
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
                    controller: _vegetableWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight (g)',
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
                FilledButton(
                  onPressed: () => _addVegetable(dishIndex),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Add Veg'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, NutritionState state) {
    File? selectedImage;
    final dishes = <DishMetadata>[];

    if (state is NutritionFormUpdated) {
      selectedImage = state.image;
      dishes.addAll(state.dishes);
    } else if (state is NutritionImageSelectedState) {
      selectedImage = state.selectedImage;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Review Your Entry',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  selectedImage != null
                      ? Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(selectedImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(child: Text('No photo selected')),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (dishes.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dishes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...dishes.map(
                      (dish) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dish.dishName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rots: ${dish.numberOfRots} | Chawal: ${dish.chawalWeight}g',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (dish.vegetables.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...dish.vegetables.map(
                                (veg) => Text(
                                  '  • ${veg.name}: ${veg.weight}${veg.unit}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional Notes',
              hintText: 'Add any notes about this meal...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<NutritionBloc, NutritionState>(
            builder: (context, state) {
              final isLoading = state is NutritionLoading;
              return FilledButton(
                onPressed: isLoading ? null : _submitNutrition,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
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
                    : const Text('Submit Nutrition Entry'),
              );
            },
          ),
        ],
      ),
    );
  }
}

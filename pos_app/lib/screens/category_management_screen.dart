import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().fetchCategories();
    });
  }

  void _openCategoryForm({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) {
        return CategoryFormDialog(category: category);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Categorías'),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.categories.isEmpty
              ? const Center(child: Text('No hay categorías creadas.'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: productProvider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = productProvider.categories[index];

                      return Card(
                        child: ListTile(
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(cat.description ?? 'Sin descripción'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${cat.productsCount ?? 0} Prod.',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                onPressed: () => _openCategoryForm(category: cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('¿Eliminar Categoría?'),
                                      content: Text('¿Estás seguro de eliminar la categoría "${cat.name}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            final success = await productProvider.deleteCategory(cat.id);
                                            if (success && mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Categoría eliminada.')),
                                              );
                                            } else if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('No se puede eliminar porque tiene productos asociados.'),
                                                  backgroundColor: AppTheme.error,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    final success = await context.read<ProductProvider>().saveCategory(
          data,
          id: widget.category?.id,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.category == null ? 'Categoría creada.' : 'Categoría actualizada.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nueva Categoría' : 'Editar Categoría'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Categoría'),
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

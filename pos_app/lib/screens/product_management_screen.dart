import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Abre el formulario para agregar o editar producto
  void _openProductForm({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ProductFormModal(product: product);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Inventario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Buscador
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    productProvider.fetchProducts();
                  },
                ),
              ),
              onChanged: (val) {
                productProvider.fetchProducts(search: val);
              },
            ),
            const SizedBox(height: 12),

            // Lista de Productos
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : productProvider.products.isEmpty
                      ? const Center(child: Text('No se encontraron productos.'))
                      : ListView.separated(
                          itemCount: productProvider.products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            final isLowStock = product.stock <= product.alertStock;

                            return ListTile(
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Categoría: ${product.category?.name ?? 'General'} | Barcode: ${product.barcode ?? '-'}', style: const TextStyle(fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Venta: ${_currencyFormat.format(product.price)} | Costo: ${_currencyFormat.format(product.costPrice)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? AppTheme.error.withOpacity(0.1) : AppTheme.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Stock: ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock ? AppTheme.error : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                    onPressed: () => _openProductForm(product: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('¿Eliminar Producto?'),
                                          content: Text('¿Estás seguro de eliminar el producto "${product.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                final success = await productProvider.deleteProduct(product.id);
                                                if (success && mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Producto eliminado.')),
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
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Modal de Formulario de Producto
class ProductFormModal extends StatefulWidget {
  final ProductModel? product;

  const ProductFormModal({super.key, this.product});

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _alertStockController = TextEditingController();
  
  int? _selectedCategoryId;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _barcodeController.text = p.barcode ?? '';
      _priceController.text = p.price.toString();
      _costPriceController.text = p.costPrice.toString();
      _stockController.text = p.stock.toString();
      _alertStockController.text = p.alertStock.toString();
      _selectedCategoryId = p.categoryId;
      _status = p.status;
    } else {
      _stockController.text = '0';
      _alertStockController.text = '5';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _alertStockController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una categoría.')),
      );
      return;
    }

    final productData = {
      'category_id': _selectedCategoryId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      'price': double.parse(_priceController.text),
      'cost_price': double.parse(_costPriceController.text),
      'stock': int.parse(_stockController.text),
      'alert_stock': int.parse(_alertStockController.text),
      'status': _status,
    };

    final success = await context.read<ProductProvider>().saveProduct(
          productData,
          id: widget.product?.id,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.product == null ? 'Producto creado.' : 'Producto actualizado.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Categoría Dropdown
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 10),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),

              // Código barras
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Código de barras'),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Precio Venta
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Precio de Venta', prefixText: 'S/ '),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Precio Compra (Costo)
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(labelText: 'Precio de Costo (Compra)', prefixText: 'S/ '),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Stock
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock Inicial'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Alerta Stock
                  Expanded(
                    child: TextFormField(
                      controller: _alertStockController,
                      decoration: const InputDecoration(labelText: 'Stock de Alerta'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estado del Producto:'),
                  Switch(
                    value: _status == 'active',
                    activeColor: AppTheme.accent,
                    onChanged: (val) => setState(() => _status = val ? 'active' : 'inactive'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                child: const Text('GUARDAR PRODUCTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

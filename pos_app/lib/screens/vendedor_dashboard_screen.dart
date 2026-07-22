import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/customer_model.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class VendedorDashboardScreen extends StatefulWidget {
  const VendedorDashboardScreen({super.key});

  @override
  State<VendedorDashboardScreen> createState() => _VendedorDashboardScreenState();
}

class _VendedorDashboardScreenState extends State<VendedorDashboardScreen> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    Future.microtask(() {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // Simulación de escaneo de código de barra
  void _showBarcodeScanner() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Escanear Código de Barras'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Simula el escaneo ingresando el código de barras (ej. 7750102030405 para Arroz).',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Código de barras',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final barcode = _barcodeController.text.trim();
                _barcodeController.clear();
                Navigator.pop(context);

                if (barcode.isNotEmpty) {
                  final pProvider = context.read<ProductProvider>();
                  final product = await pProvider.findByBarcode(barcode);
                  
                  if (product != null) {
                    final cartProvider = context.read<CartProvider>();
                    final added = cartProvider.addProduct(product);
                    
                    if (added && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} agregado al carrito.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock insuficiente para agregar el producto.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Producto con este código no encontrado o inactivo.'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Cuadro de diálogo para Procesar Cobro (Checkout)
  void _showCheckoutDialog() {
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.items.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return CheckoutModal(
          cartProvider: cartProvider,
          currencyFormat: _currencyFormat,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 720;

    // Contenido del catálogo (Izquierdo en split, Tab 1 en móvil)
    Widget catalogContent = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Buscador
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar producto por nombre o código...',
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

          // Catálogo de Productos
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? const Center(child: Text('No hay productos disponibles.'))
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 2 : 3,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          final isLowStock = product.stock <= product.alertStock;

                          return Card(
                            elevation: 1,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final added = cartProvider.addProduct(product);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                if (added) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} agregado al carrito.'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.accent,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Stock insuficiente para este producto.'),
                                      backgroundColor: AppTheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.category?.name ?? 'General',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (product.barcode != null)
                                      Text(
                                        'Barcode: ${product.barcode}',
                                        style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _currencyFormat.format(product.price),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLowStock
                                                ? AppTheme.error.withOpacity(0.1)
                                                : AppTheme.accent.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${product.stock} un.',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isLowStock ? AppTheme.error : AppTheme.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    // Contenido del Carrito (Derecho en split, Tab 2 en móvil)
    Widget cartContent = Column(
      children: [
        if (!isMobile) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Carrito',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (cartProvider.items.isNotEmpty)
                  TextButton(
                    onPressed: () => cartProvider.clear(),
                    child: const Text('Vaciar', style: TextStyle(color: AppTheme.error)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        if (isMobile && cartProvider.items.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 4.0),
              child: TextButton.icon(
                onPressed: () => cartProvider.clear(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppTheme.error),
                label: const Text('Vaciar Carrito', style: TextStyle(color: AppTheme.error, fontSize: 12)),
              ),
            ),
          ),

        Expanded(
          child: cartProvider.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('El carrito está vacío', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: cartProvider.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final productId = cartProvider.items.keys.elementAt(index);
                    final item = cartProvider.items[productId]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currencyFormat.format(item.product.price),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => cartProvider.updateQuantity(
                                        productId, item.quantity - 1),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final updated = cartProvider.updateQuantity(
                                          productId, item.quantity + 1);
                                      if (!updated) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Stock límite alcanzado.'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                _currencyFormat.format(item.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Op. Gravadas:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_currencyFormat.format(cartProvider.totalGravada),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IGV (18%):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(_currencyFormat.format(cartProvider.totalIgv),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    _currencyFormat.format(cartProvider.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: cartProvider.items.isEmpty ? null : _showCheckoutDialog,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.accent,
                ),
                child: const Text('COBRAR / COMPROBANTE'),
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Punto de Venta (POS)'),
            bottom: TabBar(
              tabs: [
                const Tab(icon: Icon(Icons.grid_view_rounded), text: 'Productos'),
                Tab(
                  icon: Badge(
                    label: Text('${cartProvider.itemsCount}'),
                    isLabelVisible: cartProvider.itemsCount > 0,
                    child: const Icon(Icons.shopping_cart_rounded),
                  ),
                  text: 'Carrito',
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Simular Scanner de barras',
                onPressed: _showBarcodeScanner,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Cerrar Sesión',
                onPressed: () => authProvider.logout(),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              catalogContent,
              cartContent,
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Punto de Venta (POS)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Simular Scanner de barras',
              onPressed: _showBarcodeScanner,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar Sesión',
              onPressed: () => authProvider.logout(),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: catalogContent,
            ),
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
                color: Theme.of(context).cardColor,
              ),
              child: cartContent,
            ),
          ],
        ),
      );
    }
  }
}

// Modal de Checkout / Venta y Facturación
class CheckoutModal extends StatefulWidget {
  final CartProvider cartProvider;
  final NumberFormat currencyFormat;

  const CheckoutModal({
    super.key,
    required this.cartProvider,
    required this.currencyFormat,
  });

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  String _paymentMethod = 'cash'; // cash, card, transfer
  String _documentType = 'NOTA_VENTA'; // NOTA_VENTA, BOLETA, FACTURA
  
  final _amountPaidController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();

  double _change = 0.0;
  bool _searchingCustomer = false;

  @override
  void initState() {
    super.initState();
    _amountPaidController.text = widget.cartProvider.totalAmount.toStringAsFixed(2);
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    _docNumberController.dispose();
    _customerNameController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    final total = widget.cartProvider.totalAmount;
    setState(() {
      _change = (paid >= total) ? (paid - total) : 0.0;
    });
  }

  // Buscar cliente por DNI/RUC
  void _searchCustomer() async {
    final number = _docNumberController.text.trim();
    if (number.length != 8 && number.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un DNI (8 dígitos) o RUC (11 dígitos) válido.')),
      );
      return;
    }

    setState(() {
      _searchingCustomer = true;
    });

    try {
      final response = await ApiService.get('customers/document/$number');
      if (response.statusCode == 200) {
        final cust = jsonDecode(response.body);
        setState(() {
          _customerNameController.text = cust['name'];
          _customerAddressController.text = cust['address'] ?? '';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente no registrado. Por favor, ingresa sus datos.')),
        );
      }
    } catch (_) {} finally {
      setState(() {
        _searchingCustomer = false;
      });
    }
  }

  void _processCheckout() async {
    final paid = double.tryParse(_amountPaidController.text) ?? 0.0;
    final total = widget.cartProvider.totalAmount;

    if (_paymentMethod == 'cash' && paid < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto pagado debe ser mayor o igual al total.')),
      );
      return;
    }

    CustomerModel? customer;
    if (_documentType != 'NOTA_VENTA') {
      final number = _docNumberController.text.trim();
      final name = _customerNameController.text.trim();
      
      if (number.isEmpty || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa los datos del cliente para comprobantes electrónicos.')),
        );
        return;
      }

      if (_documentType == 'FACTURA' && number.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La Factura Electrónica requiere RUC (11 dígitos).')),
        );
        return;
      }

      customer = CustomerModel(
        id: 0, // El ID se obtendrá en el backend
        name: name,
        documentType: number.length == 11 ? 'RUC' : 'DNI',
        documentNumber: number,
        address: _customerAddressController.text.trim(),
      );
    }

    final result = await widget.cartProvider.checkout(
      paymentMethod: _paymentMethod,
      amountPaid: _paymentMethod == 'cash' ? paid : total,
      documentType: _documentType,
      customer: customer,
    );

    if (result != null && result['success'] == true) {
      // Recargar catálogo
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
        Navigator.pop(context); // Cerrar modal de cobro
        _showReceiptDialog(result['sale'], result['sunat']);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Error desconocido.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // Modal de Ticket impreso y Estado de SUNAT
  void _showReceiptDialog(Map<String, dynamic> sale, Map<String, dynamic>? sunat) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isFiscal = sale['document_type'] != 'NOTA_VENTA';
        final isAccepted = sunat != null && sunat['success'] == true;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFiscal && !isAccepted ? Icons.error_outline : Icons.check_circle_outline,
                  color: isFiscal && !isAccepted ? AppTheme.warning : AppTheme.accent,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  '¡Venta Exitosa!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  isFiscal 
                      ? 'Comprobante: ${sale['document_type']} ${sale['serie']}-${sale['correlativo']}'
                      : 'Nota de Venta registrada.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                // Estado de SUNAT
                if (isFiscal) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAccepted ? AppTheme.accent.withOpacity(0.08) : AppTheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAccepted ? AppTheme.accent.withOpacity(0.3) : AppTheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isAccepted ? Icons.cloud_done : Icons.cloud_off,
                              size: 20,
                              color: isAccepted ? AppTheme.accent : AppTheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAccepted ? 'ACEPTADO POR SUNAT' : 'ERROR SUNAT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isAccepted ? AppTheme.accent : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAccepted
                              ? (sunat['cdr_description'] ?? 'Constancia de recepción recibida.')
                              : (sunat?['error_details'] ?? 'Fallo de comunicación con SUNAT.'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (isAccepted && sale['hash_sunat'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Hash: ${sale['hash_sunat']}',
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                ],
                // Ticket de Venta
                const Text(
                  'TICKET DE VENTA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                const Text('MINIMARKET LA ECONOMICA', style: TextStyle(fontSize: 11)),
                const Text('RUC: 20000000001', style: TextStyle(fontSize: 11)),
                const Text('Av. Principal 123 - Lima', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Cobrado:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    Text(
                      widget.currencyFormat.format(double.parse(sale['total_amount'].toString())),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mtodo Pago:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    Text(
                      sale['payment_method'].toString().toUpperCase(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (sale['payment_method'] == 'cash') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pago con:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text(
                        widget.currencyFormat.format(double.parse(sale['amount_paid'].toString())),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vuelto:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text(
                        widget.currencyFormat.format(double.parse(sale['change_returned'].toString())),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ENTENDIDO'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.cartProvider.totalAmount;
    final isFiscal = _documentType != 'NOTA_VENTA';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Completar Transacción',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // 1. Selección de Comprobante
            const Text(
              'Tipo de Comprobante',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Nota Venta'),
                    selected: _documentType == 'NOTA_VENTA',
                    onSelected: (val) {
                      if (val) setState(() => _documentType = 'NOTA_VENTA');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Boleta'),
                    selected: _documentType == 'BOLETA',
                    onSelected: (val) {
                      if (val) setState(() => _documentType = 'BOLETA');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Factura'),
                    selected: _documentType == 'FACTURA',
                    onSelected: (val) {
                      if (val) setState(() => _documentType = 'FACTURA');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Formulario de Cliente si es Boleta o Factura
            if (isFiscal) ...[
              Card(
                color: isDark ? AppTheme.darkBackground : Colors.grey.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _documentType == 'FACTURA' ? 'Datos del Cliente (RUC)' : 'Datos del Cliente (DNI)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _docNumberController,
                              decoration: InputDecoration(
                                labelText: _documentType == 'FACTURA' ? 'RUC (11 dígitos)' : 'DNI (8 dígitos)',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _searchingCustomer ? null : _searchCustomer,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(60, 48),
                              backgroundColor: AppTheme.primary,
                            ),
                            child: _searchingCustomer
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre / Razón Social',
                          prefixIcon: Icon(Icons.person_outline),
                          isDense: true,
                        ),
                      ),
                      if (_documentType == 'FACTURA') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customerAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección Fiscal',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Selección de Método de Pago
            const Text(
              'Método de Pago',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Efectivo'),
                    selected: _paymentMethod == 'cash',
                    onSelected: (val) {
                      if (val) setState(() => _paymentMethod = 'cash');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Tarjeta'),
                    selected: _paymentMethod == 'card',
                    onSelected: (val) {
                      if (val) setState(() => _paymentMethod = 'card');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Transfer.'),
                    selected: _paymentMethod == 'transfer',
                    onSelected: (val) {
                      if (val) setState(() => _paymentMethod = 'transfer');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Monto Pagado e Vuelto si es efectivo
            if (_paymentMethod == 'cash') ...[
              TextField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Monto Recibido',
                  prefixText: 'S/ ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Vuelto:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    widget.currencyFormat.format(_change),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 4. Detalle Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monto Total a Pagar:', style: TextStyle(fontSize: 15)),
                Text(
                  widget.currencyFormat.format(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Botón de Confirmación
            widget.cartProvider.isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processCheckout,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppTheme.accent,
                    ),
                    child: Text('CONFIRMAR VENTA (${_documentType.replaceAll('_', ' ')})'),
                  ),
          ],
        ),
      ),
    );
  }
}

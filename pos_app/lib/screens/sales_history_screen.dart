import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  String? _error;
  String _filterDocType = 'ALL'; // ALL, NOTA_VENTA, BOLETA, FACTURA
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String endpoint = 'sales';
      if (_filterDocType != 'ALL') {
        endpoint += '?document_type=$_filterDocType';
      }

      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _sales = data.map((s) => SaleModel.fromJson(s)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar el historial de ventas.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  // Mostrar el Detalle de la Venta en un Modal
  void _showSaleDetails(SaleModel sale) async {
    // Cargar detalles completos con items
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await ApiService.get('sales/${sale.id}');
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final detailedSale = SaleModel.fromJson(jsonDecode(response.body));
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return SaleDetailsModal(
                sale: detailedSale,
                currencyFormat: _currencyFormat,
                dateFormat: _dateFormat,
                onCancelSuccess: _fetchSales,
              );
            },
          );
        }
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSunatBadge(SaleModel sale) {
    if (sale.documentType == 'NOTA_VENTA') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Nota Venta',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      );
    }

    final isAccepted = sale.estadoSunat == 'ACEPTADO';
    final isError = sale.estadoSunat == 'ERROR';
    
    Color badgeColor = Colors.orange;
    String label = 'Pendiente';
    
    if (isAccepted) {
      badgeColor = Colors.green;
      label = 'Aceptado';
    } else if (isError) {
      badgeColor = Colors.red;
      label = 'Error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría de Ventas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filterDocType == 'ALL',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filterDocType = 'ALL');
                        _fetchSales();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Boletas'),
                    selected: _filterDocType == 'BOLETA',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filterDocType = 'BOLETA');
                        _fetchSales();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Facturas'),
                    selected: _filterDocType == 'FACTURA',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filterDocType = 'FACTURA');
                        _fetchSales();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Notas Venta'),
                    selected: _filterDocType == 'NOTA_VENTA',
                    onSelected: (val) {
                      if (val) {
                        setState(() => _filterDocType = 'NOTA_VENTA');
                        _fetchSales();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppTheme.error)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _fetchSales, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _sales.isEmpty
                  ? const Center(child: Text('No hay ventas registradas.'))
                  : ListView.separated(
                      itemCount: _sales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        final isCancelled = sale.status == 'cancelled';

                        return ListTile(
                          title: Row(
                            children: [
                              Text(
                                sale.documentType == 'NOTA_VENTA'
                                    ? 'Nota Venta #${sale.id}'
                                    : '${sale.documentType} ${sale.serie}-${sale.correlativo}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  color: isCancelled ? Colors.grey : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isCancelled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('ANULADO', style: TextStyle(fontSize: 8, color: AppTheme.error, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            'Fecha: ${_dateFormat.format(sale.createdAt)}\nVendedor: ${sale.user?.name ?? 'Desconocido'}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currencyFormat.format(sale.totalAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isCancelled ? Colors.grey : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildSunatBadge(sale),
                            ],
                          ),
                          onTap: () => _showSaleDetails(sale),
                        );
                      },
                    ),
    );
  }
}

// Modal de Detalles de la Venta
class SaleDetailsModal extends StatelessWidget {
  final SaleModel sale;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onCancelSuccess;

  const SaleDetailsModal({
    super.key,
    required this.sale,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onCancelSuccess,
  });

  void _cancelSale(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Anular esta venta?'),
        content: const Text(
          'Esta acción restaurará el stock de los productos vendidos y marcará el documento como anulado. ¿Proceder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final response = await ApiService.post('sales/${sale.id}/cancel', {});
                if (response.statusCode == 200 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Venta anulada e inventario restaurado.')),
                  );
                  onCancelSuccess();
                  Navigator.pop(context); // Cerrar bottom sheet
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al anular la venta.'), backgroundColor: AppTheme.error),
                  );
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final isFiscal = sale.documentType != 'NOTA_VENTA';
    final isAccepted = sale.estadoSunat == 'ACEPTADO';

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFiscal ? 'Detalle de Comprobante' : 'Detalle de Venta',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadatos de la Venta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFiscal
                                ? '${sale.documentType} ${sale.serie}-${sale.correlativo}'
                                : 'Nota de Venta #${sale.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('Fecha: ${dateFormat.format(sale.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sale.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          sale.status == 'completed' ? 'Completado' : 'Anulado',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sale.status == 'completed' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info del Cliente
                  const Text('Cliente:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(sale.customer?.name ?? 'CLIENTES VARIOS'),
                  if (sale.customer != null && sale.customer?.documentType != 'VARIOS') ...[
                    Text('${sale.customer!.documentType}: ${sale.customer!.documentNumber}'),
                    if (sale.customer!.address != null) Text('Dirección: ${sale.customer!.address}'),
                  ],
                  const Divider(height: 24),

                  // Tabla de Items
                  const Text('Detalle de Artículos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Cant.', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Precio', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Subtotal', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      ...?(sale.items?.map((item) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(item.product?.name ?? 'Producto de Prueba', style: const TextStyle(fontSize: 12)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${item.quantity}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(currencyFormat.format(item.price), style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(currencyFormat.format(item.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ),
                            ],
                          ))),
                    ],
                  ),
                  const Divider(height: 24),

                  // Resumen Financiero
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Método de Pago:', style: TextStyle(fontSize: 13)),
                      Text(sale.paymentMethod.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operaciones Gravadas:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(currencyFormat.format(sale.totalGravada), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('IGV (18%):', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(currencyFormat.format(sale.totalIgv), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(currencyFormat.format(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 18)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Bloque de Estado SUNAT / Greenter
                  if (isFiscal) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAccepted ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isAccepted ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado Facturación Electrónica (SUNAT)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isAccepted ? Icons.cloud_done : Icons.cloud_off,
                                size: 18,
                                color: isAccepted ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estado: ${sale.estadoSunat}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isAccepted ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Respuesta: ${sale.mensajeSunat ?? "-"}', style: const TextStyle(fontSize: 12)),
                          if (sale.hashSunat != null) ...[
                            const SizedBox(height: 4),
                            Text('Firma Hash: ${sale.hashSunat}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)),
                          ],
                          if (sale.xmlPath != null) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Archivos SUNAT generados en servidor:',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text('XML: ${sale.xmlPath}', style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
                            Text('CDR: ${sale.cdrPath}', style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Acciones Administrativas (Anulación)
          if (isAdmin && sale.status == 'completed') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _cancelSale(context),
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              label: const Text('ANULAR COMPROBANTE Y RESTAURAR STOCK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

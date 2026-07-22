import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'product_management_screen.dart';
import 'category_management_screen.dart';
import 'user_management_screen.dart';
import 'sales_history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _dashboardData = {};
  final _currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('dashboard');
      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar los datos del dashboard.';
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

  // Cerrar Sesión
  void _logout() {
    context.read<AuthProvider>().logout();
  }

  // Construir una Card de KPI Estilizada
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    // Definición de gradientes premium para KPIs
    final gradients = [
      const LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)]),
      const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)]),
      const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFFA726)]),
      const LinearGradient(colors: [Color(0xFFF44336), Color(0xFFEF5350)]),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración Minimarket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  authProvider.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              accountName: Text(authProvider.user?.name ?? 'Admin'),
              accountEmail: Text(authProvider.user?.email ?? 'admin@minimarket.com'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Productos (Inventario)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categorías'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Historial de Ventas / SUNAT'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline_rounded),
              title: const Text('Vendedores (Usuarios)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
              title: const Text('Cerrar Sesión', style: TextStyle(color: AppTheme.error)),
              onTap: _logout,
            ),
          ],
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
                      ElevatedButton(onPressed: _fetchDashboardData, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Panel de KPIs
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildKpiCard(
                            title: 'VENTAS HOY',
                            value: _currencyFormat.format(_dashboardData['kpis']['sales_today']),
                            icon: Icons.monetization_on_outlined,
                            color: const Color(0xFF3F51B5),
                            gradient: gradients[0],
                          ),
                          _buildKpiCard(
                            title: 'UTILIDAD MES',
                            value: _currencyFormat.format(_dashboardData['kpis']['net_profit_this_month']),
                            icon: Icons.trending_up,
                            color: const Color(0xFF00BFA5),
                            gradient: gradients[1],
                          ),
                          _buildKpiCard(
                            title: 'VENTAS MES',
                            value: _currencyFormat.format(_dashboardData['kpis']['sales_this_month']),
                            icon: Icons.calendar_month_outlined,
                            color: const Color(0xFFFF9100),
                            gradient: gradients[2],
                          ),
                          _buildKpiCard(
                            title: 'STOCK CRÍTICO',
                            value: '${_dashboardData['kpis']['low_stock_count']} Prod.',
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFF44336),
                            gradient: gradients[3],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Gráfico de Ventas de los últimos 7 días
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tendencia de Ventas (Últimos 7 días)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: BarChart(
                                  BarChartData(
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            final list = _dashboardData['charts']['daily_sales'] as List;
                                            if (index >= 0 && index < list.length) {
                                              return SideTitleWidget(
                                                meta: meta,
                                                child: Text(
                                                  list[index]['day_name'],
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: (_dashboardData['charts']['daily_sales'] as List)
                                        .asMap()
                                        .map((index, data) => MapEntry(
                                              index,
                                              BarChartGroupData(
                                                x: index,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: double.parse(data['amount'].toString()),
                                                    color: AppTheme.primary,
                                                    width: 16,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                                  )
                                                ],
                                              ),
                                            ))
                                        .values
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alertas de Stock Bajo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Productos con Stock Crítico',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _dashboardData['low_stock_alerts'].isEmpty
                                  ? const Text('¡Todos los productos tienen stock suficiente!')
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: (_dashboardData['low_stock_alerts'] as List).length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final product = _dashboardData['low_stock_alerts'][index];
                                        return ListTile(
                                          title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          subtitle: Text('Categoría: ${product['category']['name']}', style: const TextStyle(fontSize: 11)),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.error.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Stock: ${product['stock']}',
                                              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

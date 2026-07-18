<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Product;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Acceso denegado.'], 403);
        }

        $today = Carbon::today();
        $startOfWeek = Carbon::now()->startOfWeek();
        $startOfMonth = Carbon::now()->startOfMonth();

        // 1. KPI: Ventas de hoy, semana, mes
        $salesToday = Sale::where('status', 'completed')->whereDate('created_at', $today)->sum('total_amount');
        $salesThisWeek = Sale::where('status', 'completed')->where('created_at', '>=', $startOfWeek)->sum('total_amount');
        $salesThisMonth = Sale::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->sum('total_amount');

        // 2. KPI: Costo total y Ganancia Neta de este mes
        // Para calcular la ganancia de forma precisa, sumamos la diferencia (precio - cost_price) * quantity de los items vendidos este mes.
        $netProfitThisMonth = DB::table('sale_items')
            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
            ->where('sales.status', 'completed')
            ->where('sales.created_at', '>=', $startOfMonth)
            ->select(DB::raw('SUM((sale_items.price - sale_items.cost_price) * sale_items.quantity) as profit'))
            ->first()->profit ?? 0.00;

        // 3. KPI: Cantidad de transacciones hoy y este mes
        $txToday = Sale::where('status', 'completed')->whereDate('created_at', $today)->count();
        $txThisMonth = Sale::where('status', 'completed')->where('created_at', '>=', $startOfMonth)->count();

        // 4. Alertas de Stock Bajo (stock <= alert_stock)
        $lowStockProducts = Product::with('category')
            ->where('status', 'active')
            ->whereRaw('stock <= alert_stock')
            ->get();

        // 5. Productos más vendidos (Top 5) de todo el tiempo o de este mes
        $topProducts = DB::table('sale_items')
            ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
            ->join('products', 'sale_items.product_id', '=', 'products.id')
            ->where('sales.status', 'completed')
            ->select('products.name', DB::raw('SUM(sale_items.quantity) as total_qty'), DB::raw('SUM(sale_items.subtotal) as total_sales'))
            ->groupBy('products.id', 'products.name')
            ->orderBy('total_qty', 'desc')
            ->limit(5)
            ->get();

        // 6. Ventas por método de pago (este mes)
        $salesByPaymentMethod = Sale::where('status', 'completed')
            ->where('created_at', '>=', $startOfMonth)
            ->select('payment_method', DB::raw('SUM(total_amount) as total'))
            ->groupBy('payment_method')
            ->get();

        // 7. Gráfico: Historial de Ventas diarias de los últimos 7 días
        $dailySalesChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $amount = Sale::where('status', 'completed')
                ->whereDate('created_at', $date)
                ->sum('total_amount');

            $dailySalesChart[] = [
                'date' => $date->format('Y-m-d'),
                'day_name' => $this->translateDayName($date->format('l')),
                'amount' => round($amount, 2)
            ];
        }

        // 8. Gráfico: Historial de utilidades diarias de los últimos 7 días
        $dailyProfitChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $profit = DB::table('sale_items')
                ->join('sales', 'sale_items.sale_id', '=', 'sales.id')
                ->where('sales.status', 'completed')
                ->whereDate('sales.created_at', $date)
                ->select(DB::raw('SUM((sale_items.price - sale_items.cost_price) * sale_items.quantity) as profit'))
                ->first()->profit ?? 0.00;

            $dailyProfitChart[] = [
                'date' => $date->format('Y-m-d'),
                'day_name' => $this->translateDayName($date->format('l')),
                'profit' => round($profit, 2)
            ];
        }

        return response()->json([
            'kpis' => [
                'sales_today' => round($salesToday, 2),
                'sales_this_week' => round($salesThisWeek, 2),
                'sales_this_month' => round($salesThisMonth, 2),
                'net_profit_this_month' => round($netProfitThisMonth, 2),
                'transactions_today' => $txToday,
                'transactions_this_month' => $txThisMonth,
                'low_stock_count' => $lowStockProducts->count()
            ],
            'low_stock_alerts' => $lowStockProducts,
            'top_selling_products' => $topProducts,
            'sales_by_payment_method' => $salesByPaymentMethod,
            'charts' => [
                'daily_sales' => $dailySalesChart,
                'daily_profits' => $dailyProfitChart
            ]
        ]);
    }

    private function translateDayName($day)
    {
        $days = [
            'Monday'    => 'Lun',
            'Tuesday'   => 'Mar',
            'Wednesday' => 'Mié',
            'Thursday'  => 'Jue',
            'Friday'    => 'Vie',
            'Saturday'  => 'Sáb',
            'Sunday'    => 'Dom',
        ];
        return $days[$day] ?? $day;
    }
}

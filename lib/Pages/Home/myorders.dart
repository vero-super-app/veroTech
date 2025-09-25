import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vero360_app/models/order_model.dart';
import 'package:vero360_app/services/order_service.dart';
import 'package:vero360_app/toasthelper.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  final _svc = OrderService();
  final Color _brand = const Color(0xFFFF8A00);
  final _money = NumberFormat.currency(symbol: 'MK ', decimalDigits: 0);
  final _date = DateFormat('dd MMM yyyy, HH:mm');

  late TabController _tab;
  final List<OrderStatus> _statuses = const [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  final Map<OrderStatus, Future<List<OrderItem>>> _futures = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _statuses.length, vsync: this);
    for (final s in _statuses) {
      _futures[s] = _svc.getMyOrders(status: s);
    }
  }

  Future<void> _reloadCurrent() async {
    final s = _statuses[_tab.index];
    setState(() => _futures[s] = _svc.getMyOrders(status: s));
    await _futures[s];
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return _brand;
      case OrderStatus.confirmed: return Colors.blueAccent;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.redAccent;
    }
  }

  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:   return 'Pending';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  Color _paymentColor(PaymentStatus p) {
    switch (p) {
      case PaymentStatus.paid:    return Colors.green;
      case PaymentStatus.pending: return Colors.orange;
      case PaymentStatus.unpaid:  return Colors.redAccent;
    }
  }

  String _paymentLabel(PaymentStatus p) {
    switch (p) {
      case PaymentStatus.paid:    return 'PAID';
      case PaymentStatus.pending: return 'PENDING';
      case PaymentStatus.unpaid:  return 'UNPAID';
    }
  }

  Widget _chip(Color c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c.withOpacity(.95),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _cancel(OrderItem o) async {
    try {
      await _svc.cancelOrMarkCancelled(o.id);
      if (!mounted) return;
      ToastHelper.showCustomToast(context, 'Order cancelled', isSuccess: true, errorMessage: '');
      await _reloadCurrent();
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showCustomToast(context, 'Cancel failed', isSuccess: false, errorMessage: e.toString());
    }
  }

  Widget _infoRow({required IconData icon, required String text, String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B778C)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF6B778C)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(trailing, style: const TextStyle(color: Color(0xFF6B778C), fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  Widget _orderCard(OrderItem o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            spreadRadius: -8,
            offset: Offset(0, 14),
            color: Color(0x1A000000),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 82,
              height: 82,
              child: o.itemImage.isEmpty
                  ? Container(
                      color: const Color(0xFFF1F2F6),
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    )
                  : Image.network(o.itemImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First line: name + chips
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order: ${o.orderNumber}   •   ID: ${o.id}',
                            style: const TextStyle(
                              color: Color(0xFF6B778C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _chip(_statusColor(o.status), _statusLabel(o.status)),
                        const SizedBox(height: 6),
                        _chip(_paymentColor(o.paymentStatus), _paymentLabel(o.paymentStatus)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                // Merchant
                _infoRow(
                  icon: Icons.store_mall_directory_outlined,
                  text: '${o.merchantName ?? 'Merchant'}  •  ${o.merchantPhone ?? '—'}',
                  trailing: (o.merchantAvgRating != null) ? '⭐ ${o.merchantAvgRating!.toStringAsFixed(1)}' : null,
                ),

                const SizedBox(height: 6),
                // Address
                _infoRow(
                  icon: Icons.location_on_outlined,
                  text: [
                    if ((o.addressCity ?? '').isNotEmpty) o.addressCity,
                    if ((o.addressDescription ?? '').isNotEmpty) o.addressDescription,
                  ].whereType<String>().join(' — ').trim().isEmpty
                      ? 'No address'
                      : [
                          if ((o.addressCity ?? '').isNotEmpty) o.addressCity,
                          if ((o.addressDescription ?? '').isNotEmpty) o.addressDescription,
                        ].whereType<String>().join(' — '),
                ),

                const SizedBox(height: 6),
                if (o.orderDate != null)
                  _infoRow(
                    icon: Icons.schedule_outlined,
                    text: _date.format(o.orderDate!.toLocal()),
                  ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_money.format(o.price)}  ×  ${o.quantity}',
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money.format(o.total),
                      style: TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.black12.withOpacity(.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _reloadCurrent(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 10),
                    if (o.status == OrderStatus.pending)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _cancel(o),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBody(OrderStatus s) {
    final fut = _futures[s]!;
    return RefreshIndicator(
      onRefresh: _reloadCurrent,
      child: FutureBuilder<List<OrderItem>>(
        future: fut,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Error: ${snap.error}', textAlign: TextAlign.center),
                  ),
                ),
              ],
            );
          }
          final items = snap.data ?? const <OrderItem>[];
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 90),
                Center(child: Text('No orders in this status')),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            itemBuilder: (_, i) => _orderCard(items[i]),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        title: const Text('My Orders'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: _brand,
          unselectedLabelColor: const Color(0xFF6B778C),
          indicatorColor: _brand,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _statuses.map(_tabBody).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';

Color _statusColor(String s) => switch (s.toUpperCase()) {
  'PENDING' => const Color(0xFFFB8C00),
  'PREPARING' => const Color(0xFF1E88E5),
  'READY' => const Color(0xFF43A047),
  'DELIVERED' => const Color(0xFF546E7A),
  'CANCELLED' => const Color(0xFFE53935),
  _ => const Color(0xFF9E9E9E),
};

IconData _statusIcon(String s) => switch (s.toUpperCase()) {
  'PENDING' => Icons.schedule,
  'PREPARING' => Icons.restaurant,
  'READY' => Icons.check_circle_outline,
  'DELIVERED' => Icons.done_all,
  'CANCELLED' => Icons.cancel_outlined,
  _ => Icons.help_outline,
};

typedef _ItemData = ({
  String name,
  String category,
  double price,
  String? description,
  String? imageUrl,
});

// ── AdminPage ──────────────────────────────────────────────────────────────

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() {
    return Future.wait([
      context.read<OrderProvider>().loadOrders(),
      context.read<MenuProvider>().loadItems(),
    ]);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  void _showItemForm({MenuItem? item}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ItemFormSheet(
        item: item,
        onSave: (data) => _saveItem(item?.id, data),
      ),
    );
  }

  Future<void> _saveItem(int? id, _ItemData data) async {
    final provider = context.read<MenuProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (id == null) {
      await provider.createItem(
        name: data.name,
        category: data.category,
        price: data.price,
        description: data.description,
        imageUrl: data.imageUrl,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Item adicionado!')));
    } else {
      await provider.updateItem(
        id,
        name: data.name,
        category: data.category,
        price: data.price,
        description: data.description,
        imageUrl: data.imageUrl,
      );
      messenger.showSnackBar(const SnackBar(content: Text('Item atualizado!')));
    }
  }

  void _confirmDelete(MenuItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir item'),
        content: Text('Remover "${item.name}" do cardápio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!context.mounted) return;
              final provider = context.read<MenuProvider>();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await provider.deleteItem(item.id);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Item excluído')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final orders = context.watch<OrderProvider>().orders;
    final menuItems = context.watch<MenuProvider>().items;

    final now = DateTime.now();
    final todayOrders = orders.where((o) {
      final d = o.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    final revenue = todayOrders.fold<double>(0, (s, o) => s + o.totalValue);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton(
              onPressed: () => _showItemForm(),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              tooltip: 'Novo item',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _Header(
            user: user,
            onBack: () => Navigator.pop(context),
            onLogout: _logout,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.receipt_long,
                  label: 'Pedidos hoje',
                  value: '${todayOrders.length}',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.restaurant_menu,
                  label: 'Itens',
                  value: '${menuItems.length}',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.attach_money,
                  label: 'Receita hoje',
                  value:
                      'R\$ ${revenue.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
              ],
            ),
          ),
          ColoredBox(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: const Color(0xFFE53935),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFE53935),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Pedidos'),
                Tab(text: 'Cardápio'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OrdersTab(orders: orders, onRefresh: _load),
                _MenuTab(
                  items: menuItems,
                  onEdit: (item) => _showItemForm(item: item),
                  onDelete: _confirmDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final dynamic user;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  const _Header({
    required this.user,
    required this.onBack,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final initial = (user?.fullName as String?)?.isNotEmpty == true
        ? (user.fullName as String)[0].toUpperCase()
        : 'A';

    return Container(
      padding: EdgeInsets.fromLTRB(4, top + 4, 4, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            tooltip: 'Sair',
          ),
        ],
      ),
    );
  }
}

// ── StatCard ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFFE53935)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── OrdersTab ──────────────────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  final List<OrderResponse> orders;
  final Future<void> Function() onRefresh;
  const _OrdersTab({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum pedido',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE53935),
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: orders.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AdminOrderCard(order: orders[i]),
        ),
      ),
    );
  }
}

// ── AdminOrderCard ─────────────────────────────────────────────────────────

class _AdminOrderCard extends StatefulWidget {
  final OrderResponse order;
  const _AdminOrderCard({required this.order});

  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _expanded = false;

  void _showStatusPicker() {
    const options = [
      ('PENDING', 'Pendente'),
      ('PREPARING', 'Em preparo'),
      ('READY', 'Pronto'),
      ('DELIVERED', 'Entregue'),
      ('CANCELLED', 'Cancelado'),
    ];

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Status — Pedido #${widget.order.id}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Divider(height: 8),
          ...options.map((opt) {
            final isCurrent = widget.order.status.toUpperCase() == opt.$1;
            return ListTile(
              leading: Icon(_statusIcon(opt.$1), color: _statusColor(opt.$1)),
              title: Text(opt.$2),
              trailing: isCurrent
                  ? const Icon(Icons.check_circle, color: Color(0xFFE53935))
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                if (!context.mounted) return;
                final provider = context.read<OrderProvider>();
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await provider.updateOrderStatus(widget.order.id, opt.$1);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final fmt = DateFormat("dd/MM 'às' HH:mm");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmt.format(order.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} '
                          '${order.items.length == 1 ? 'item' : 'itens'} · '
                          'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showStatusPicker,
                    child: _StatusBadge(order: order),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}× ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.itemName ?? 'Item #${item.itemId}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            'R\$ ${item.total.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Alterar status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showStatusPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE53935,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Mudar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── MenuTab ────────────────────────────────────────────────────────────────

class _MenuTab extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(MenuItem) onEdit;
  final void Function(MenuItem) onDelete;
  const _MenuTab({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum item no cardápio',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Text(
              'Toque em + para adicionar',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fastfood,
                color: Color(0xFFE53935),
                size: 22,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => onEdit(item),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
                IconButton(
                  onPressed: () => onDelete(item),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── ItemFormSheet ──────────────────────────────────────────────────────────

class _ItemFormSheet extends StatefulWidget {
  final MenuItem? item;
  final Future<void> Function(_ItemData) onSave;
  const _ItemFormSheet({this.item, required this.onSave});

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _desc;
  late final TextEditingController _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _name = TextEditingController(text: it?.name ?? '');
    _category = TextEditingController(text: it?.category ?? '');
    _price = TextEditingController(
      text: it != null ? it.price.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _desc = TextEditingController(text: it?.description ?? '');
    _image = TextEditingController(text: it?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _desc.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final price = double.parse(_price.text.trim().replaceAll(',', '.'));
    final data = (
      name: _name.text.trim(),
      category: _category.text.trim(),
      price: price,
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      imageUrl: _image.text.trim().isEmpty ? null : _image.text.trim(),
    );

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await widget.onSave(data);
      nav.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              isEditing ? 'Editar item' : 'Novo item',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    _field(
                      controller: _name,
                      label: 'Nome',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: _category,
                            label: 'Categoria',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Obrigatório'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            controller: _price,
                            label: 'Preço (R\$)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Obrigatório';
                              }
                              final p = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              return (p == null || p <= 0) ? 'Inválido' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _desc,
                      label: 'Descrição (opcional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _image,
                      label: 'URL da imagem (opcional)',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                isEditing
                                    ? 'Salvar alterações'
                                    : 'Adicionar item',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }
}

// ── StatusBadge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final OrderResponse order;
  const _StatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: order.statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(order.statusIcon, size: 12, color: order.statusColor),
          const SizedBox(width: 4),
          Text(
            order.statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: order.statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool loading = false;
  String searchTerm = '';

  late List<MenuSection> allSections;
  late List<MenuSection> filteredSections;

  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    allSections = _mockSections();
    filteredSections = allSections;
    _buildSectionKeys();
  }

  void _buildSectionKeys() {
    _sectionKeys.clear();
    for (final section in filteredSections) {
      _sectionKeys[section.name] = GlobalKey();
    }
  }

  void _filterItems(String value) {
    setState(() {
      searchTerm = value.trim().toLowerCase();

      if (searchTerm.isEmpty) {
        filteredSections = allSections;
      } else {
        filteredSections = allSections
            .map((section) {
              final items = section.items.where((item) {
                return item.name.toLowerCase().contains(searchTerm) ||
                    item.description.toLowerCase().contains(searchTerm);
              }).toList();

              if (items.isEmpty) return null;

              return MenuSection(
                name: section.name,
                color: section.color,
                icon: section.icon,
                items: items,
              );
            })
            .whereType<MenuSection>()
            .toList();
      }

      _buildSectionKeys();
    });
  }

  Future<void> _scrollToSection(String sectionName) async {
    final key = _sectionKeys[sectionName];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }
  }

  void _openItemDetailsDialog(MenuItem item, MenuSection section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: section.color.withOpacity(0.14),
                  child: item.imageUrl == null || item.imageUrl!.isEmpty
                      ? Icon(Icons.fastfood, size: 60, color: section.color)
                      : Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.fastfood,
                            size: 60,
                            color: section.color,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addQuickItem(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addQuickItem(MenuItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} adicionado ao carrinho'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : filteredSections.isEmpty
                ? Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Nenhum produto disponível no momento.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildTopBar()),
                      SliverToBoxAdapter(child: _buildSectionList()),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFFF6F6F6),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filteredSections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final section = filteredSections[index];
                  return OutlinedButton(
                    onPressed: () => _scrollToSection(section.name),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      section.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE53935)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: filteredSections.map((section) {
          return Container(
            key: _sectionKeys[section.name],
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(section),
                const SizedBox(height: 14),
                ...section.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildItemCard(item, section),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(MenuSection section) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: section.color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(section.icon, color: section.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${section.items.length} ${section.items.length == 1 ? 'item' : 'itens'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(MenuItem item, MenuSection section) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openItemDetailsDialog(item, section),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: Container(
                width: 110,
                height: 110,
                color: section.color.withOpacity(0.16),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(Icons.fastfood, color: section.color, size: 36)
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.fastfood,
                          color: section.color,
                          size: 36,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () => _addQuickItem(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
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

  List<MenuSection> _mockSections() {
    return [
      MenuSection(
        name: 'Hambúrgueres',
        color: const Color(0xFFE53935),
        icon: Icons.lunch_dining,
        items: [
          MenuItem(
            name: 'X-Burger',
            description: 'Pão, hambúrguer, queijo e molho especial.',
            price: 22.90,
          ),
          MenuItem(
            name: 'X-Salada',
            description: 'Hambúrguer, queijo, alface, tomate e maionese.',
            price: 25.90,
          ),
          MenuItem(
            name: 'Bacon Burger',
            description: 'Hambúrguer artesanal, cheddar e bacon crocante.',
            price: 29.90,
          ),
        ],
      ),
      MenuSection(
        name: 'Pizzas',
        color: const Color(0xFFFB8C00),
        icon: Icons.local_pizza,
        items: [
          MenuItem(
            name: 'Calabresa',
            description: 'Molho, queijo, calabresa e cebola.',
            price: 49.90,
          ),
          MenuItem(
            name: 'Frango com Catupiry',
            description: 'Frango desfiado, catupiry e queijo.',
            price: 54.90,
          ),
        ],
      ),
      MenuSection(
        name: 'Bebidas',
        color: const Color(0xFF1E88E5),
        icon: Icons.local_drink,
        items: [
          MenuItem(
            name: 'Coca-Cola 350ml',
            description: 'Lata gelada.',
            price: 6.00,
          ),
          MenuItem(
            name: 'Suco Natural',
            description: 'Suco natural de laranja 500ml.',
            price: 8.50,
          ),
        ],
      ),
      MenuSection(
        name: 'Sobremesas',
        color: const Color(0xFF8E24AA),
        icon: Icons.icecream,
        items: [
          MenuItem(
            name: 'Petit Gateau',
            description: 'Bolo quente com sorvete de creme.',
            price: 18.90,
          ),
        ],
      ),
    ];
  }
}

class MenuSection {
  final String name;
  final Color color;
  final IconData icon;
  final List<MenuItem> items;

  MenuSection({
    required this.name,
    required this.color,
    required this.icon,
    required this.items,
  });
}

class MenuItem {
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  MenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });
}
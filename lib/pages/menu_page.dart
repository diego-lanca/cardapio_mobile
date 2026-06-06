import 'package:cardapio_mobile/models/menu_item.dart';
import 'package:cardapio_mobile/providers/cart_provider.dart';
import 'package:cardapio_mobile/providers/menu_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedSection = 'Todos';
  bool _isAutoScrolling = false;

  String searchTerm = '';
  List<MenuSection> allSections = [];
  List<MenuSection> filteredSections = [];

  MenuProvider? _menuProvider;
  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuProvider = context.read<MenuProvider>();
      _menuProvider!.addListener(_onMenuChanged);
      if (_menuProvider!.items.isEmpty) {
        _menuProvider!.loadItems();
      } else {
        _onMenuChanged();
      }
    });
  }

  @override
  void dispose() {
    _menuProvider?.removeListener(_onMenuChanged);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMenuChanged() {
    if (!mounted) return;
    setState(() {
      allSections = _buildSectionsFromItems(_menuProvider!.items);
      _filterItems(searchTerm);
    });
  }

  List<MenuSection> _buildSectionsFromItems(List<MenuItem> items) {
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in items) {
      (grouped[item.category] ??= []).add(item);
    }
    return grouped.entries.map((e) {
      final (color, icon) = _categoryThemeFor(e.key);
      return MenuSection(name: e.key, color: color, icon: icon, items: e.value);
    }).toList();
  }

  static (Color, IconData) _categoryThemeFor(String category) {
    final key = category.toLowerCase();
    if (key.contains('hambúrguer') ||
        key.contains('hamburguer') ||
        key.contains('burger')) {
      return (const Color(0xFFE53935), Icons.lunch_dining);
    }
    if (key.contains('pizza')) {
      return (const Color(0xFFFB8C00), Icons.local_pizza);
    }
    if (key.contains('bebida') || key.contains('drink')) {
      return (const Color(0xFF1E88E5), Icons.local_drink);
    }
    if (key.contains('sobremesa') || key.contains('doce')) {
      return (const Color(0xFF8E24AA), Icons.icecream);
    }
    if (key.contains('lanche')) {
      return (const Color(0xFF43A047), Icons.fastfood);
    }
    if (key.contains('porção') || key.contains('porcao')) {
      return (const Color(0xFF8D6E63), Icons.set_meal);
    }
    return (const Color(0xFF546E7A), Icons.restaurant_menu);
  }

  void _handleScroll() {
    if (_isAutoScrolling) return;
    if (filteredSections.isEmpty) return;

    String currentSection = filteredSections.first.name;
    double closestTop = double.infinity;

    for (final section in filteredSections) {
      final key = _sectionKeys[section.name];
      final context = key?.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero);
      final distanceFromTop = (position.dy - 220).abs();

      if (position.dy <= 220 && distanceFromTop < closestTop) {
        closestTop = distanceFromTop;
        currentSection = section.name;
      }
    }

    if (_selectedSection != currentSection) {
      setState(() {
        _selectedSection = currentSection;
      });
    }
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
    if (sectionName == 'Todos') {
      _isAutoScrolling = true;
      setState(() {
        _selectedSection = 'Todos';
      });

      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

      _isAutoScrolling = false;
      return;
    }

    final key = _sectionKeys[sectionName];
    if (key?.currentContext != null) {
      _isAutoScrolling = true;

      setState(() {
        _selectedSection = sectionName;
      });

      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );

      _isAutoScrolling = false;
    }
  }

  void _openItemDetailsDialog(MenuItem item, MenuSection section) {
    final observationController = TextEditingController();
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totalPrice = item.price * quantity;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 190,
                        width: double.infinity,
                        color: section.color.withValues(alpha: 0.14),
                        child: item.imageUrl == null || item.imageUrl!.isEmpty
                            ? Icon(
                                Icons.fastfood,
                                size: 64,
                                color: section.color,
                              )
                            : Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.fastfood,
                                  size: 64,
                                  color: section.color,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Preço unitário',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'R\$ ${item.price.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: observationController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Ex: sem cebola, molho à parte, ponto da carne...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          borderSide: BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text(
                          'Quantidade',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 1
                                    ? () {
                                        setModalState(() {
                                          quantity--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    quantity++;
                                  });
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          for (int i = 0; i < quantity; i++) {
                            _addQuickItem(item);
                          }

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${item.name} x$quantity adicionado ao carrinho',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Adicionar • R\$ ${totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addQuickItem(MenuItem item) {
    context.read<CartProvider>().addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} adicionado ao carrinho'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();

    if (menu.isLoading && allSections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (menu.error != null && allSections.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              menu.error!,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _menuProvider?.loadItems(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (filteredSections.isEmpty && !menu.isLoading) {
      return Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Center(
              child: Text(
                searchTerm.isEmpty
                    ? 'Nenhum produto disponível no momento.'
                    : 'Nenhum resultado para "$searchTerm".',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: _MainHeader()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _MenuTopBarDelegate(
            minHeight: 116,
            maxHeight: 116,
            child: _buildTopBar(),
          ),
        ),
        SliverToBoxAdapter(child: _buildSectionList()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildTopBar() {
    final categoryNames = [
      'Todos',
      ...filteredSections.map((section) => section.name),
    ];

    return Container(
      color: const Color(0xFFF6F6F6),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoryNames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categoryNames[index];
                final isSelected = _selectedSection == category;

                return GestureDetector(
                  onTap: () => _scrollToSection(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterItems(value);
                setState(() {});
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar no cardápio...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.grey,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(color: Color(0xFFE53935), width: 1.5),
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
            color: section.color.withValues(alpha: 0.14),
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
              color: Colors.black.withValues(alpha: 0.04),
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
                color: section.color.withValues(alpha: 0.16),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(Icons.fastfood, color: section.color, size: 36)
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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

class _MainHeader extends StatelessWidget {
  const _MainHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrega e retirada disponíveis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha seus itens no cardápio e acompanhe seu pedido.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderInfoChip(
                icon: Icons.circle,
                text: 'Aberto agora',
                iconColor: Colors.green,
              ),
              _HeaderInfoChip(
                icon: Icons.access_time_rounded,
                text: '30-40 min',
              ),
              _HeaderInfoChip(
                icon: Icons.star_rounded,
                text: '4.8 de avaliação',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTopBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _MenuTopBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF6F6F6), child: child);
  }

  @override
  bool shouldRebuild(covariant _MenuTopBarDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

class _HeaderInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _HeaderInfoChip({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

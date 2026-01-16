import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/service_locator.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import 'qr_scanner_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Product> _products = [];
  User? _currentUser;
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _perPage = 10;

  final TextEditingController _searchController = TextEditingController();
  bool _onlyInStock = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProducts(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  }

  Future<void> _loadUser() async {
    try {
      final user = await ServiceLocator.authService.getMe();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadProducts(refresh: true);
    });
  }

  void _toggleStockFilter(bool value) {
    setState(() {
      _onlyInStock = value;
    });
    _loadProducts(refresh: true);
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _products.clear();
      });
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newProducts = await ServiceLocator.productService.getProducts(
        query: _searchController.text,
        inStock: _onlyInStock ? true : null,
        page: _page,
        perPage: _perPage,
      );

      setState(() {
        if (newProducts.length < _perPage) {
          _hasMore = false;
        }
        _products.addAll(newProducts);
        _page++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.primary,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      Color(0xFF004B7D),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hoşgeldin,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentUser?.name ?? 'Misafir',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.person, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Ürünlerde ara...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _toggleStockFilter(!_onlyInStock),
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: _onlyInStock ? colorScheme.secondary : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: _onlyInStock ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.qr_code_scanner,
                      label: 'QR Tara',
                      color: colorScheme.secondary,
                      onTap: () {
                         Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.history,
                      label: 'Geçmiş',
                      color: const Color(0xFFE94E77),
                      onTap: () {
                         Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ürünler',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                   Text(
                    '${_products.length} Sonuç',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_products.isEmpty && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    Text('Ürün bulunamadı', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _products.length) return null;   
                    
                    final product = _products[index];
                    return _buildProductCard(context, product);
                  },
                  childCount: _products.length,
                ),
              ),
            ),

          if (_isLoading)
             const SliverToBoxAdapter(
               child: Padding(
                 padding: EdgeInsets.all(20),
                 child: Center(child: CircularProgressIndicator()),
               ),
             ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Expanded(
            flex: 5,
             child: Stack(
               fit: StackFit.expand,
               children: [
                 Container(
                   color: Colors.grey[50],
                   child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Icon(Icons.broken_image, color: Colors.grey[300]),
                          )
                        : Icon(Icons.image, color: Colors.grey[300]),
                 ),
                 if (!product.inStock)
                   Container(
                     color: Colors.white.withOpacity(0.7),
                     child: Center(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                         decoration: BoxDecoration(
                           color: Colors.red,
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: const Text('Tükendi', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                       )
                     ),
                   ),
               ],
             ),
           ),
           Expanded(
             flex: 4,
             child: Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         product.name,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                         style: const TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 15,
                           color: Color(0xFF1E1E2C),
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         product.description ?? '',
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                         style: TextStyle(
                           color: Colors.grey[500],
                           fontSize: 11,
                           height: 1.2,
                         ),
                       ),
                     ],
                   ),
                   Row(
                     children: [
                       Text(
                         '₺${product.price}',
                         style: TextStyle(
                           fontWeight: FontWeight.bold,
                           fontSize: 18,
                           color: Theme.of(context).colorScheme.secondary,
                         ),
                       ),
                     ],
                   )
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }
}

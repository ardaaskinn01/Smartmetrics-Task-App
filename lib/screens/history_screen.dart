import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/service_locator.dart';
import '../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<History> _history = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _perPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _history.clear();
      });
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newHistory = await ServiceLocator.historyService.getHistory(
        page: _page,
        perPage: _perPage,
      );

      setState(() {
        if (newHistory.length < _perPage) {
          _hasMore = false;
        }
        _history.addAll(newHistory);
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest, 
      appBar: AppBar(
        title: const Text(
          'İşlem Geçmişi', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.secondary),
            onPressed: () => _loadHistory(refresh: true),
          ),
        ],
      ),
      body: _history.isEmpty && !_isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         )
                       ]
                     ),
                     child: Icon(Icons.history_edu, size: 64, color: colorScheme.secondary.withOpacity(0.5)),
                   ),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz işlem bulunmuyor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _loadHistory(refresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _history.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _history.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final item = _history[index];
                final isPositive = item.amount >= 0;
                
                bool showHeader = false;
                if (index == 0) {
                  showHeader = true;
                } else {
                  final prevItem = _history[index - 1];
                  if (!_isSameDay(item.createdAt, prevItem.createdAt)) {
                    showHeader = true;
                  }
                }

                String headerText = '';
                if (showHeader) {
                  final now = DateTime.now();
                  if (_isSameDay(item.createdAt, now)) {
                    headerText = 'Bugün';
                  } else if (_isSameDay(item.createdAt, now.subtract(const Duration(days: 1)))) {
                    headerText = 'Dün';
                  } else {
                    headerText = DateFormat('d MMMM yyyy', 'tr_TR').format(item.createdAt);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: Text(
                          headerText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isPositive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isPositive ? Colors.green : Colors.red).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isPositive ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('HH:mm').format(item.createdAt),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isPositive ? '+' : ''}${item.amount.toStringAsFixed(2)} ₺',
                                      style: TextStyle(
                                        color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

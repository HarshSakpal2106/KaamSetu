import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/category_model.dart';
import '../models/worker_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../widgets/worker_card.dart';
import 'worker_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;

  const ExploreScreen({super.key, this.initialCategory});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MockWorkerRepository _repository = MockWorkerRepository();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedCategory;
  bool _availableOnly = false;
  double? _minRating;
  String _sortBy = 'recommended'; // 'recommended', 'nearest', 'rating', 'charge_low'

  List<CategoryModel> _categories = [];
  List<WorkerModel> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'all';
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    _categories = _repository.getCategories();
    _workers = await _repository.getWorkers(
      categoryId: _selectedCategory,
      query: _searchController.text,
      availableOnly: _availableOnly ? true : null,
      minRating: _minRating,
      sortBy: _sortBy,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(String catId) {
    setState(() {
      _selectedCategory = catId;
    });
    _loadData();
  }

  void _onSearchChanged(String _) {
    _loadData();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort Workers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _availableOnly = false;
                            _minRating = null;
                            _sortBy = 'recommended';
                          });
                          setState(() {});
                          _loadData();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Sort By
                  const Text('Sort By',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Recommended'),
                        selected: _sortBy == 'recommended',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'recommended');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('📍 Nearest'),
                        selected: _sortBy == 'nearest',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'nearest');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('⭐ Highest Rated'),
                        selected: _sortBy == 'rating',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'rating');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('₹ Lowest Visit Fee'),
                        selected: _sortBy == 'charge_low',
                        onSelected: (val) {
                          setModalState(() => _sortBy = 'charge_low');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Availability Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Available Workers Only'),
                    subtitle: const Text('Filter out workers currently busy'),
                    value: _availableOnly,
                    onChanged: (val) {
                      setModalState(() => _availableOnly = val);
                    },
                  ),

                  // Rating Filter
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rating 4.0 & Above Only'),
                    value: _minRating == 4.0,
                    onChanged: (val) {
                      setModalState(() => _minRating = (val == true) ? 4.0 : null);
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                        _loadData();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Find Workers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter & Sort',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search electrician, plumber, AC...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Horizontal Category Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('all', 'All Services', '🛠️'),
                  ..._categories.map((cat) =>
                      _buildCategoryChip(cat.id, cat.title, cat.iconEmoji)),
                ],
              ),
            ),
          ),

          // Active Filter Indicators / Summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_workers.length} Workers Available',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_availableOnly || _minRating != null || _sortBy != 'recommended')
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _availableOnly = false;
                        _minRating = null;
                        _sortBy = 'recommended';
                      });
                      _loadData();
                    },
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Workers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _workers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_search_outlined,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No workers found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try changing your filters or searching another service.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCategory = 'all';
                                  _availableOnly = false;
                                  _minRating = null;
                                  _sortBy = 'recommended';
                                });
                                _loadData();
                              },
                              child: const Text('Reset All'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _workers.length,
                          itemBuilder: (context, index) {
                            final worker = _workers[index];
                            return WorkerCard(
                              worker: worker,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerDetailScreen(
                                      worker: worker,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label, String emoji) {
    final isSelected = _selectedCategory.toLowerCase() == id.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        onSelected: (_) => _onCategorySelected(id),
      ),
    );
  }
}

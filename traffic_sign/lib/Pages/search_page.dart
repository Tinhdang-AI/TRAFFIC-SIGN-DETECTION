import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../apps/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tất cả';
  bool _hasSearched = false;
  String _searchQuery = '';

  final List<String> _filters = ['Tất cả', 'Cấm', 'Nguy hiểm', 'Hiệu lệnh', 'Chỉ dẫn'];

  final List<String> _recentSearches = [
    'Biển báo cấm rẽ trái',
    'Tốc độ tối đa 60km/h',
    'Đường ưu tiên',
  ];

  final List<Map<String, dynamic>> _allSigns = [
    {
      'code': 'P.102',
      'name': 'Biển cấm đi ngược chiều',
      'description': 'Cấm tất cả các loại xe (cơ giới và thô sơ) đi vào theo chiều đặt biển.',
      'type': 'Cấm',
      'color': AppColors.danger,
      'bgColor': AppColors.dangerLight,
      'icon': Icons.do_not_disturb_alt_rounded,
    },
    {
      'code': 'P.127',
      'name': 'Tốc độ tối da cho phép',
      'description': 'Cấm tất cả các loại xe cơ giới chạy với tốc độ tối đa...',
      'type': 'Cấm',
      'color': AppColors.danger,
      'bgColor': AppColors.dangerLight,
      'icon': Icons.speed_rounded,
    },
    {
      'code': 'W.207',
      'name': 'Đường trơn',
      'description': 'Báo trước sắp đến đoạn đường có thể xảy ra trơn...',
      'type': 'Nguy hiểm',
      'color': AppColors.warning,
      'bgColor': AppColors.warningLight,
      'icon': Icons.warning_amber_rounded,
    },
    {
      'code': 'R.301',
      'name': 'Đường ưu tiên',
      'description': 'Báo cho người lái xe biết đang đi trên đường ưu tiên...',
      'type': 'Hiệu lệnh',
      'color': AppColors.info,
      'bgColor': AppColors.infoLight,
      'icon': Icons.priority_high_rounded,
    },
    {
      'code': 'I.420',
      'name': 'Trạm y tế',
      'description': 'Chỉ dẫn nơi có trạm y tế gần đó để người lái xe...',
      'type': 'Chỉ dẫn',
      'color': AppColors.success,
      'bgColor': AppColors.successLight,
      'icon': Icons.local_hospital_rounded,
    },
    {
      'code': 'P.117',
      'name': 'Cấm quay đầu xe',
      'description': 'Cấm quay đầu xe tại vị trí đặt biển...',
      'type': 'Cấm',
      'color': AppColors.danger,
      'bgColor': AppColors.dangerLight,
      'icon': Icons.u_turn_left_rounded,
    },
  ];

  List<Map<String, dynamic>> get _filteredSigns {
    return _allSigns.where((sign) {
      final matchFilter = _selectedFilter == 'Tất cả' || sign['type'] == _selectedFilter;
      final matchQuery = _searchQuery.isEmpty ||
          (sign['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (sign['code'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.traffic_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Traffic Sign Detection',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _hasSearched = val.isNotEmpty;
              }),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm biển báo...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _hasSearched = false;
                        }),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Filter chips
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: _filters.map((f) => _buildFilterChip(f)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _hasSearched || _selectedFilter != 'Tất cả'
                ? _buildSearchResults()
                : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedFilter = filter;
          _hasSearched = _searchQuery.isNotEmpty || filter != 'Tất cả';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            filter,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          Row(
            children: [
              Text(
                'Tìm kiếm gần đây',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Xóa tất cả',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _recentSearches.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.text = item;
                          _searchQuery = item;
                          _hasSearched = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 18, color: AppColors.textTertiary),
                            const SizedBox(width: 10),
                            Text(
                              item,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < _recentSearches.length - 1)
                      const Divider(height: 1, indent: 42, endIndent: 14),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Popular signs
          Text(
            'Kết quả tìm kiếm',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ..._allSigns.take(3).map((sign) => _buildSignCard(sign)),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredSigns;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy biển báo',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thử tìm kiếm từ khóa khác',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: results.map((sign) => _buildSignCard(sign)).toList(),
    );
  }

  Widget _buildSignCard(Map<String, dynamic> sign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (sign['bgColor'] as Color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sign['icon'] as IconData,
                  color: sign['color'] as Color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sign['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (sign['bgColor'] as Color),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sign['type'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sign['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sign['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                'Chi tiết',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(Icons.bookmark_border_rounded,
                              size: 18, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

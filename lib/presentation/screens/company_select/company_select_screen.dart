import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/time_periods.dart';
import '../../../data/datasources/local/app_database.dart';
import '../../../data/models/company.dart';
import '../../providers/app_providers.dart';

class CompanySelectScreen extends ConsumerStatefulWidget {
  final String missionId;
  final String eraId;

  const CompanySelectScreen({
    super.key,
    required this.missionId,
    required this.eraId,
  });

  @override
  ConsumerState<CompanySelectScreen> createState() =>
      _CompanySelectScreenState();
}

class _CompanySelectScreenState extends ConsumerState<CompanySelectScreen> {
  String? _selectedCategory;
  final Set<String> _selectedSymbols = {};
  bool _isCreatingSession = false;

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final missionAsync = ref.watch(
      missionsProvider.select(
        (value) => value.whenData(
          (missions) => missions.firstWhere(
            (m) => m.id == widget.missionId,
            orElse: () => throw Exception('mission not found'),
          ),
        ),
      ),
    );

    final maxCompanies = missionAsync.valueOrNull?.maxCompanies ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('会社を選ぼう')),
      bottomNavigationBar: _selectedSymbols.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _isCreatingSession ? null : _startSimulation,
                  child: _isCreatingSession
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'この会社で投資スタート！（${_selectedSymbols.length}社選択中）',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // カテゴリフィルター
          categoriesAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox(height: 48),
            data: (categories) => _CategoryFilterBar(
              categories: categories,
              selectedCategory: _selectedCategory,
              onSelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
          ),
          // 選択上限の案内
          if (_selectedSymbols.length >= maxCompanies)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'このミッションは最大$maxCompanies社まで選べます',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          // 会社グリッド
          Expanded(
            child: companiesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('エラー: $e')),
              data: (companies) {
                final filtered = _selectedCategory == null
                    ? companies
                    : companies
                        .where((c) => c.category == _selectedCategory)
                        .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final company = filtered[i];
                    final isSelected =
                        _selectedSymbols.contains(company.symbol);
                    final canSelect = isSelected ||
                        _selectedSymbols.length < maxCompanies;
                    return _CompanyCard(
                      company: company,
                      isSelected: isSelected,
                      isDisabled: !canSelect,
                      onTap: canSelect
                          ? () => _toggleSelection(company.symbol)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(String symbol) {
    setState(() {
      if (_selectedSymbols.contains(symbol)) {
        _selectedSymbols.remove(symbol);
      } else {
        _selectedSymbols.add(symbol);
      }
    });
  }

  Future<void> _startSimulation() async {
    if (_selectedSymbols.isEmpty) return;

    setState(() => _isCreatingSession = true);

    try {
      final era = TimePeriods.findById(widget.eraId);
      if (era == null) throw Exception('era not found: ${widget.eraId}');

      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now();
      final sessionId = await db.createSession(
        SimulationSessionTableCompanion.insert(
          missionId: widget.missionId,
          eraId: widget.eraId,
          startDate: era.startDate,
          endDate: era.endDate,
          selectedSymbolsJson: jsonEncode(_selectedSymbols.toList()),
          initialCash: 1000000.0,
          currentCash: 1000000.0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (mounted) {
        context.push('/simulation?session_id=$sessionId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('セッション作成エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingSession = false);
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return FilterChip(
              label: const Text('すべて'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final cat = categories[i - 1];
          return FilterChip(
            label: Text(cat),
            selected: selectedCategory == cat,
            selectedColor:
                AppColors.categoryColors[cat]?.withValues(alpha: 0.2),
            onSelected: (_) =>
                onSelected(selectedCategory == cat ? null : cat),
          );
        },
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _CompanyCard({
    required this.company,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled && !isSelected ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? company.categoryColor.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? company.categoryColor
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (company.isSample)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'サンプル',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: company.categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      company.nameJa.substring(0, 1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: company.categoryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  company.nameJa,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  company.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: company.categoryColor,
                        fontSize: 10,
                      ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child:
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';

enum DateFilterType {
  all,
  today,
  thisWeek,
  thisMonth,
  custom,
}

enum RecordSortOrder {
  newestFirst,
  oldestFirst,
}

/// ViewModel managing historical records display, search, date filtering, sorting, summary stats, and deletion.
class RecordsViewModel extends ChangeNotifier {
  final HealthRecordService _recordService;
  final OnboardingService _onboardingService;

  RecordsViewModel({
    HealthRecordService? recordService,
    OnboardingService? onboardingService,
  })  : _recordService = recordService ?? HealthRecordService(),
        _onboardingService = onboardingService ?? OnboardingService() {
    loadRecords();
  }

  List<HealthRecord> _allRecords = [];
  DailyGoals? _goals;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter & Search states
  DateFilterType _selectedFilter = DateFilterType.all;
  DateTime? _customSelectedDate;
  DateTimeRange? _customDateRange;
  String _searchQuery = '';
  RecordSortOrder _sortOrder = RecordSortOrder.newestFirst;

  // Getters
  DailyGoals get goals => _goals ?? DailyGoals.defaults();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateFilterType get selectedFilter => _selectedFilter;
  DateTime? get customSelectedDate => _customSelectedDate;
  DateTimeRange? get customDateRange => _customDateRange;
  String get searchQuery => _searchQuery;
  RecordSortOrder get sortOrder => _sortOrder;

  /// Returns the records matching the active search query, date filter, and sort order.
  List<HealthRecord> get filteredRecords {
    final now = DateTime.now();
    List<HealthRecord> list = List.from(_allRecords);

    // 1. Apply Date Filter
    switch (_selectedFilter) {
      case DateFilterType.all:
        break;
      case DateFilterType.today:
        final todayStr = DateFormatter.toIsoDateString(now);
        list = list.where((r) => r.date == todayStr).toList();
        break;
      case DateFilterType.thisWeek:
        // Monday (1) to Sunday (7)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final mondayDate = DateTime(monday.year, monday.month, monday.day);
        final sundayDate = mondayDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

        list = list.where((r) {
          final d = r.dateTime;
          return d.isAfter(mondayDate.subtract(const Duration(seconds: 1))) &&
              d.isBefore(sundayDate.add(const Duration(seconds: 1)));
        }).toList();
        break;
      case DateFilterType.thisMonth:
        list = list.where((r) {
          final d = r.dateTime;
          return d.year == now.year && d.month == now.month;
        }).toList();
        break;
      case DateFilterType.custom:
        if (_customDateRange != null) {
          final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
          final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
          list = list.where((r) {
            final d = r.dateTime;
            return (d.isAfter(start.subtract(const Duration(seconds: 1)))) &&
                (d.isBefore(end.add(const Duration(seconds: 1))));
          }).toList();
        } else if (_customSelectedDate != null) {
          final targetStr = DateFormatter.toIsoDateString(_customSelectedDate!);
          list = list.where((r) => r.date == targetStr).toList();
        }
        break;
    }

    // 2. Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        final d = r.dateTime;
        final iso = r.date.toLowerCase();
        final fullDate = DateFormatter.formatFullDate(d).toLowerCase(); // "24 october 2026"
        final shortDate = DateFormat('MMM d').format(d).toLowerCase(); // "oct 24"
        final shortDateReverse = DateFormat('d MMM').format(d).toLowerCase(); // "24 oct"
        final monthName = DateFormat('MMMM').format(d).toLowerCase(); // "october"
        final monthAbbr = DateFormat('MMM').format(d).toLowerCase(); // "oct"
        final weekday = DateFormat('EEEE').format(d).toLowerCase(); // "saturday"
        final year = d.year.toString();
        final day = d.day.toString();

        return iso.contains(query) ||
            fullDate.contains(query) ||
            shortDate.contains(query) ||
            shortDateReverse.contains(query) ||
            monthName.contains(query) ||
            monthAbbr.contains(query) ||
            weekday.contains(query) ||
            year.contains(query) ||
            day == query;
      }).toList();
    }

    // 3. Apply Sorting by stored activity date
    list.sort((a, b) {
      if (_sortOrder == RecordSortOrder.newestFirst) {
        return b.date.compareTo(a.date);
      } else {
        return a.date.compareTo(b.date);
      }
    });

    return list;
  }

  // Summary Statistics (calculated dynamically on filteredRecords)
  int get totalRecordsCount => filteredRecords.length;

  int get averageSteps => _recordService.calculateAverageSteps(filteredRecords);

  double get totalWaterLitres => _recordService.calculateTotalWaterLitres(filteredRecords);

  String get totalWaterFormatted => _recordService.formatWaterLitres(totalWaterLitres);

  bool get hasActiveFilterOrSearch =>
      _selectedFilter != DateFilterType.all || _searchQuery.trim().isNotEmpty;

  String get filterButtonLabel {
    if (_selectedFilter == DateFilterType.custom) {
      if (_customDateRange != null) {
        final start = DateFormat('MMM d').format(_customDateRange!.start);
        final end = DateFormat('MMM d').format(_customDateRange!.end);
        return '$start - $end';
      } else if (_customSelectedDate != null) {
        return DateFormat('MMM d').format(_customSelectedDate!);
      }
    }
    return 'Filter by date';
  }

  RecordGoalStatus getRecordStatus(HealthRecord record) {
    return _recordService.evaluateGoalStatus(record, goals);
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _onboardingService.getGoals();
      _allRecords = await _recordService.getAllRecords();
    } catch (e) {
      _errorMessage = 'Could not load records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(DateFilterType filter) {
    _selectedFilter = filter;
    if (filter != DateFilterType.custom) {
      _customSelectedDate = null;
      _customDateRange = null;
    }
    notifyListeners();
  }

  void setCustomDate(DateTime date) {
    _selectedFilter = DateFilterType.custom;
    _customSelectedDate = date;
    _customDateRange = null;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange range) {
    _selectedFilter = DateFilterType.custom;
    _customDateRange = range;
    _customSelectedDate = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortOrder = _sortOrder == RecordSortOrder.newestFirst
        ? RecordSortOrder.oldestFirst
        : RecordSortOrder.newestFirst;
    notifyListeners();
  }

  void setSortOrder(RecordSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void resetFilters() {
    _selectedFilter = DateFilterType.all;
    _customSelectedDate = null;
    _customDateRange = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> deleteRecord(int id) async {
    try {
      await _recordService.deleteRecord(id);
      await loadRecords();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete record.';
      notifyListeners();
      return false;
    }
  }
}

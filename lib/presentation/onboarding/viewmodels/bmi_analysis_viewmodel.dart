import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/bmi_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing BMI analysis calculation, interpretation, and display state.
class BmiAnalysisViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;
  final BmiService _bmiService;

  BmiAnalysisViewModel({
    OnboardingService? onboardingService,
    BmiService? bmiService,
  })  : _onboardingService = onboardingService ?? OnboardingService(),
        _bmiService = bmiService ?? BmiService() {
    loadData();
  }

  UserProfile? _profile;
  BmiResult _bmiResult = BmiResult.empty();
  bool _isLoading = true;

  UserProfile? get profile => _profile;
  BmiResult get bmiResult => _bmiResult;
  bool get isLoading => _isLoading;

  double get bmi => _bmiResult.bmi;
  String get formattedBmi => _bmiResult.bmi.toStringAsFixed(1);
  String get categoryLabel => _bmiResult.categoryLabel;
  Color get categoryColor => _bmiResult.category.color;
  Color get categoryBadgeBg => _bmiResult.category.badgeBackground;
  double get gaugePosition => _bmiResult.gaugePosition;
  String get explanation => _bmiResult.explanation;
  String get disclaimer => _bmiResult.disclaimer;

  String get heightSummary =>
      _profile != null ? '${_profile!.heightCm.toStringAsFixed(0)} cm' : '--';

  String get weightSummary =>
      _profile != null ? '${_profile!.weightKg.toStringAsFixed(0)} kg' : '--';

  String get ageSummary =>
      _profile != null ? _profile!.ageShortLabel : '--';

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _onboardingService.getProfile();
      if (_profile != null) {
        _bmiResult = _bmiService.assess(_profile!);
      }
    } catch (_) {
      _bmiResult = BmiResult.empty();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

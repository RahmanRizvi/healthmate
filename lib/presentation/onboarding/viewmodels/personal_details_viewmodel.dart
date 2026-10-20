import 'package:flutter/material.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing the Personal Details form state, validation, and persistence.
class PersonalDetailsViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;

  PersonalDetailsViewModel({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService() {
    _loadExistingProfile();
  }

  String _fullName = '';
  DateTime? _dateOfBirth;
  int? _age;
  String _gender = 'Female';
  double? _heightCm;
  double? _weightKg;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  String get fullName => _fullName;
  DateTime? get dateOfBirth => _dateOfBirth;
  int? get age => _age;
  String get gender => _gender;
  double? get heightCm => _heightCm;
  double? get weightKg => _weightKg;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<String> genderOptions = const [
    'Female',
    'Male',
    'Prefer not to say',
  ];

  bool get isFullNameValid => _fullName.trim().length >= 2;
  bool get isDateOfBirthValid => _dateOfBirth != null && _dateOfBirth!.isBefore(DateTime.now());
  bool get isHeightValid => _heightCm != null && _heightCm! > 30 && _heightCm! < 300;
  bool get isWeightValid => _weightKg != null && _weightKg! > 10 && _weightKg! < 500;

  bool get isFormValid =>
      isFullNameValid &&
      isDateOfBirthValid &&
      isHeightValid &&
      isWeightValid;

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _onboardingService.getProfile();
      if (profile != null) {
        _fullName = profile.fullName;
        _dateOfBirth = profile.dateOfBirth;
        _age = AgeCalculator.calculateAge(profile.dateOfBirth);
        _gender = profile.gender;
        _heightCm = profile.heightCm;
        _weightKg = profile.weightKg;
        notifyListeners();
      }
    } catch (_) {
      // Ignore load error during init
    }
  }

  void setFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  void setDateOfBirth(DateTime date) {
    _dateOfBirth = date;
    _age = AgeCalculator.calculateAge(date);
    notifyListeners();
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
  }

  void setHeight(String value) {
    _heightCm = double.tryParse(value.trim());
    notifyListeners();
  }

  void setWeight(String value) {
    _weightKg = double.tryParse(value.trim());
    notifyListeners();
  }

  /// Validates and saves the entered profile to SQLite.
  Future<bool> saveProfile() async {
    if (!isFormValid) {
      if (!isFullNameValid) {
        _errorMessage = 'Please enter your full name';
      } else if (!isDateOfBirthValid) {
        _errorMessage = 'Please select a valid date of birth';
      } else if (!isHeightValid) {
        _errorMessage = 'Please enter a valid height in cm (e.g. 172)';
      } else if (!isWeightValid) {
        _errorMessage = 'Please enter a valid weight in kg (e.g. 68)';
      }
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 1,
        fullName: _fullName.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender,
        heightCm: _heightCm!,
        weightKg: _weightKg!,
        createdAt: now,
        updatedAt: now,
      );

      await _onboardingService.saveProfile(profile);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to save details. Please try again.';
      notifyListeners();
      return false;
    }
  }
}

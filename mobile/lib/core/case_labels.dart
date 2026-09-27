import 'package:flutter/material.dart';

import 'theme.dart';

/// Человекочитаемые подписи и цвета для статусов дела и права.
class Labels {
  static const Map<String, String> caseStatus = {
    'draft': 'Черновик',
    'eligibility': 'Проверка права',
    'capturing': 'Сбор доказательств',
    'review': 'На проверке',
    'ready': 'Готово к отправке',
    'submitted': 'Отправлено',
    'escalated': 'Эскалация',
    'stopped': 'Остановлено',
  };

  static const Map<String, String> eligibility = {
    'pending': 'Не проверено',
    'green': 'Можно упрощённо',
    'yellow': 'Требует внимания',
    'red': 'Упрощённо нельзя',
  };

  static String caseStatusLabel(String code) => caseStatus[code] ?? code;
  static String eligibilityLabel(String code) => eligibility[code] ?? code;

  static Color eligibilityColor(String code) => switch (code) {
        'green' => AppTheme.green,
        'red' => AppTheme.red,
        'yellow' => AppTheme.amber,
        _ => AppTheme.muted,
      };

  static Color caseStatusColor(String code) => switch (code) {
        'ready' || 'submitted' => AppTheme.green,
        'stopped' || 'escalated' => AppTheme.red,
        'review' => AppTheme.amber,
        _ => AppTheme.accent,
      };

  /// Категории доказательств для гида по съёмке.
  static const List<(String, String)> evidenceCategories = [
    ('scene', 'Общий план места'),
    ('damage', 'Повреждения'),
    ('plate', 'Госномера'),
    ('documents', 'Документы / права'),
    ('vin', 'VIN / кузов'),
  ];

  static String evidenceCategoryLabel(String code) => evidenceCategories
      .firstWhere((e) => e.$1 == code, orElse: () => (code, code))
      .$2;
}

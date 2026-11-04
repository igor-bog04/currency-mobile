/// Проверка суммы, введённой пользователем.
library;

class AmountValidation {
  const AmountValidation.valid(double this.value) : error = null;
  const AmountValidation.invalid(String this.error) : value = null;

  final double? value;
  final String? error;

  bool get isValid => value != null;
}

class AmountValidator {
  static final _number = RegExp(r'^\d+([.,]\d+)?$');
  static final _fraction = RegExp(r'[.,](\d+)$');

  /// Принимает только цифры и один разделитель (точку или запятую), до 2 знаков после него.
  static AmountValidation validate(String input) {
    final text = input.trim();
    if (text.isEmpty) return const AmountValidation.invalid('Введите сумму');
    if (text.startsWith('-')) return const AmountValidation.invalid('Сумма должна быть больше нуля');
    if (!_number.hasMatch(text)) {
      return RegExp(r'\d').hasMatch(text)
          ? const AmountValidation.invalid('Только цифры и один разделитель: точка или запятая')
          : const AmountValidation.invalid('Введите число');
    }
    final fraction = _fraction.firstMatch(text);
    if (fraction != null && fraction.group(1)!.length > 2) {
      return const AmountValidation.invalid('Не более 2 знаков после запятой');
    }
    final value = double.parse(text.replaceAll(',', '.'));
    if (value <= 0) return const AmountValidation.invalid('Сумма должна быть больше нуля');
    return AmountValidation.valid(value);
  }
}

import 'package:currency_mobile/domain/amount_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('valid amounts', () {
    for (final (input, expected) in [('100', 100.0), ('10.5', 10.5), ('10,25', 10.25), ('  7 ', 7.0), ('0.01', 0.01)]) {
      test('"$input" -> $expected', () {
        final result = AmountValidator.validate(input);
        expect(result.isValid, isTrue);
        expect(result.value, expected);
      });
    }
  });

  group('invalid amounts', () {
    for (final (input, message) in [
      ('', 'Введите сумму'),
      ('   ', 'Введите сумму'),
      ('abc', 'Введите число'),
      ('0', 'Сумма должна быть больше нуля'),
      ('0.00', 'Сумма должна быть больше нуля'),
      ('-5', 'Сумма должна быть больше нуля'),
      ('1.234', 'Не более 2 знаков после запятой'),
      ('1 000', 'Только цифры и один разделитель: точка или запятая'),
      ('1.000,50', 'Только цифры и один разделитель: точка или запятая'),
      ('1e5', 'Только цифры и один разделитель: точка или запятая'),
      ('12a', 'Только цифры и один разделитель: точка или запятая'),
    ]) {
      test('"$input" -> $message', () {
        final result = AmountValidator.validate(input);
        expect(result.isValid, isFalse);
        expect(result.error, message);
      });
    }
  });
}

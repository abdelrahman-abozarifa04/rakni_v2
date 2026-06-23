import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakni_v2/core/utils/input_formatters.dart';

void main() {
  group('DateInputFormatter Tests', () {
    late DateInputFormatter formatter;

    setUp(() {
      formatter = DateInputFormatter();
    });

    test('should allow empty input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue.empty;
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('should format clean digits correctly', () {
      // 1 digit
      var result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '0',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, '0');

      // 2 digits
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '06',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '06');

      // 3 digits (auto-inserts first slash)
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '060',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '06/0');
      expect(result.selection.end, 4);

      // 4 digits
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '06/09',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(result.text, '06/09');

      // 5 digits (auto-inserts second slash)
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '06/092',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result.text, '06/09/2');
      expect(result.selection.end, 7);

      // Full date (8 digits)
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(
          text: '06/09/2001',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      expect(result.text, '06/09/2001');
    });

    test('should strip non-digits', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '06-09a2001',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      expect(result.text, '06/09/2001');
    });

    test('should limit length to 8 digits / 10 characters', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '06/09/2001',
          selection: TextSelection.collapsed(offset: 10),
        ),
        const TextEditingValue(
          text: '06/09/20015',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(result.text, '06/09/2001');
    });

    test('should handle backspace / deleting characters correctly', () {
      // Deleting the last digit of 06/09/2001
      var result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '06/09/2001',
          selection: TextSelection.collapsed(offset: 10),
        ),
        const TextEditingValue(
          text: '06/09/200',
          selection: TextSelection.collapsed(offset: 9),
        ),
      );
      expect(result.text, '06/09/200');
      expect(result.selection.end, 9);

      // Deleting digit right after a slash: 06/09/2 -> 06/09
      result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '06/09/2',
          selection: TextSelection.collapsed(offset: 7),
        ),
        const TextEditingValue(
          text: '06/09/',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result.text, '06/09');
      expect(result.selection.end, 5);

      // Deleting digit right after first slash: 06/0 -> 06
      result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '06/0',
          selection: TextSelection.collapsed(offset: 4),
        ),
        const TextEditingValue(
          text: '06/',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '06');
      expect(result.selection.end, 2);
    });

    group('Cursor Position Tests', () {
      test('should adjust cursor position when modifying middle characters', () {
        // e.g., if user has 06/09/2001 and edits '9' to '8'
        final result = formatter.formatEditUpdate(
          const TextEditingValue(
            text: '06/09/2001',
            selection: TextSelection.collapsed(offset: 5), // cursor after '9'
          ),
          const TextEditingValue(
            text: '06/08/2001',
            selection: TextSelection.collapsed(offset: 5), // cursor after '8'
          ),
        );
        expect(result.text, '06/08/2001');
        expect(result.selection.end, 5);
      });
    });
  });
}

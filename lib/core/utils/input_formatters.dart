import 'package:flutter/services.dart';

/// Formats text input automatically to the DD/MM/YYYY format as the user types digits.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Strip out all non-digits
    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 8 digits (DDMMYYYY)
    final digits = cleanText.substring(
      0,
      cleanText.length > 8 ? 8 : cleanText.length,
    );

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final index = i + 1;
      if ((index == 2 || index == 4) && index < digits.length) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();

    int selectionIndex = newValue.selection.end;

    if (newValue.selection.end == newValue.text.length) {
      selectionIndex = formatted.length;
    } else {
      int digitCount = 0;
      for (int i = 0; i < newValue.selection.end; i++) {
        if (RegExp(r'\d').hasMatch(newValue.text[i])) {
          digitCount++;
        }
      }

      int formattedIndex = 0;
      int formattedDigitCount = 0;
      while (formattedIndex < formatted.length &&
          formattedDigitCount < digitCount) {
        if (RegExp(r'\d').hasMatch(formatted[formattedIndex])) {
          formattedDigitCount++;
        }
        formattedIndex++;
      }
      selectionIndex = formattedIndex;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

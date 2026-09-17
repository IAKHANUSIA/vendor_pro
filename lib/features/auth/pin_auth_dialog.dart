import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PinAuthDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String expectedPin;
  final String roleBadge;
  final ValueChanged<bool>? onVerified;

  const PinAuthDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.expectedPin,
    this.roleBadge = '🔐 PIN વેરિફિકેશન',
    this.onVerified,
  });

  static Future<bool> verify(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String expectedPin,
    String roleBadge = '🔐 PIN વેરિફિકેશન',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PinAuthDialog(
        title: title,
        subtitle: subtitle,
        expectedPin: expectedPin,
        roleBadge: roleBadge,
      ),
    );
    return result == true;
  }

  @override
  State<PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<PinAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _pinController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'કૃપા કરીને PIN નાખો.';
      });
      return;
    }

    if (input.length < 4 || input.length > 8) {
      setState(() {
        _errorMessage = 'PIN ૪ થી ૮ આંકડાનો હોવો જોઈએ.';
      });
      return;
    }

    if (input == widget.expectedPin.trim()) {
      widget.onVerified?.call(true);
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'ખોટો PIN! ફરીથી સાચો PIN નાખો.';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderDark),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
              ),
              child: Text(
                widget.roleBadge,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ),
            ),
            const SizedBox(height: 14),

            // Title & Subtitle
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // PIN input field (4 to 8 digits)
            TextFormField(
              controller: _pinController,
              autofocus: true,
              obscureText: _obscureText,
              maxLength: 8,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppColors.accentGold,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: const TextStyle(fontSize: 22, letterSpacing: 6, color: AppColors.textMutedDark),
                filled: true,
                fillColor: AppColors.surfaceDark,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorderDark),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textMutedDark,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: AppColors.errorRed),
                    const SizedBox(width: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11, color: AppColors.errorRed, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            const Text(
              '💡 ૪ થી ૮ આંકડાનો PIN માન્ય છે.',
              style: TextStyle(fontSize: 11, color: AppColors.textMutedDark),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('રદ કરો (Cancel)'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('અનલૉક કરો (Unlock)'),
        ),
      ],
    );
  }
}

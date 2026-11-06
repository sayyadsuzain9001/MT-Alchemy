import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'commerce_prototype_store.dart';
import 'stripe_checkout.dart';

/// Outcome returned by the payment step.
class PaymentResult {
  const PaymentResult({
    required this.status,
    required this.method,
    required this.reference,
    this.message,
  });

  /// 'Paid' (successful), 'Failed', 'Pending', or 'Redirect' when the
  /// customer continues to Stripe Checkout.
  final String status;
  final String method;
  final String reference;
  final String? message;

  bool get successful => status == 'Paid';
}

/// Test-mode payment gateway.
///
/// It behaves like a hosted payment page: card, online banking (FPX) or
/// bank transfer, returning Successful, Failed or Pending. No card data is
/// stored: only the brand and last four digits are kept on the order. A
/// production deployment must replace this with a real provider (Stripe,
/// Billplz, iPay88) confirmed by a server-side webhook.
Future<PaymentResult?> showPaymentGateway(
  BuildContext context, {
  required double amount,
  required String description,
}) => showDialog<PaymentResult>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PaymentDialog(amount: amount, description: description),
);

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.amount, required this.description});
  final double amount;
  final String description;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _form = GlobalKey<FormState>();
  String _method = 'Card';
  final _cardName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  String? _bank;
  bool _processing = false;

  static const banks = [
    'Maybank2u',
    'CIMB Clicks',
    'Public Bank',
    'RHB Now',
    'Hong Leong Connect',
  ];

  @override
  void dispose() {
    for (final c in [_cardName, _cardNumber, _expiry, _cvc]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _digits => _cardNumber.text.replaceAll(RegExp(r'\D'), '');

  static bool luhn(String digits) {
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      var d = int.parse(digits[digits.length - 1 - i]);
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }
    return digits.length >= 13 && sum % 10 == 0;
  }

  String? _validateExpiry(String? v) {
    final m = RegExp(r'^(\d{2})\s*/\s*(\d{2})$').firstMatch(v ?? '');
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m[1]!);
    final year = 2000 + int.parse(m[2]!);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    if (DateTime(year, month + 1).isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    return null;
  }

  bool get _stripe => _method == 'Card' && StripeCheckout.enabled;

  Future<void> _pay() async {
    if (_stripe) {
      Navigator.pop(
        context,
        const PaymentResult(
          status: 'Redirect',
          method: 'Card (Stripe Checkout)',
          reference: 'stripe',
        ),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final ref =
        'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
    late PaymentResult result;
    switch (_method) {
      case 'Card':
        final last4 = _digits.substring(_digits.length - 4);
        // Test cards: ...0002 is declined, ...3155 needs bank approval.
        if (_digits.endsWith('0002')) {
          result = PaymentResult(
            status: 'Failed',
            method: 'Card •••• $last4',
            reference: ref,
            message: 'Your card was declined. No money was taken.',
          );
        } else if (_digits.endsWith('3155')) {
          result = PaymentResult(
            status: 'Pending',
            method: 'Card •••• $last4',
            reference: ref,
            message: 'Your bank is still confirming this payment.',
          );
        } else {
          result = PaymentResult(
            status: 'Paid',
            method: 'Card •••• $last4',
            reference: ref,
          );
        }
      case 'FPX':
        result = PaymentResult(
          status: 'Paid',
          method: 'FPX · $_bank',
          reference: ref,
        );
      default:
        result = PaymentResult(
          status: 'Pending',
          method: 'Bank transfer',
          reference: ref,
          message:
              'Transfer the amount quoting $ref. We confirm transfers within one working day.',
        );
    }
    Navigator.pop(context, result);
  }

  InputDecoration _dec(String label, {IconData? icon, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [deepBlue, royalBlue]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: softYellow),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${widget.description} · ${money(widget.amount)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cancel payment',
              color: Colors.white,
              onPressed: _processing ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4CC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    StripeCheckout.enabled
                        ? 'Stripe test mode: no real money is charged. On the Stripe page use card 4242 4242 4242 4242, any future expiry and any CVC.'
                        : 'Test mode: no real money is charged. Use card 4242 4242 4242 4242 for success, 4000 0000 0000 0002 for a decline, or 4000 0025 0000 3155 for a pending payment.',
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'Card',
                      icon: const Icon(Icons.credit_card),
                      label: Text(narrow ? 'Card' : 'Card'),
                    ),
                    const ButtonSegment(
                      value: 'FPX',
                      icon: Icon(Icons.account_balance_outlined),
                      label: Text('FPX'),
                    ),
                    ButtonSegment(
                      value: 'Transfer',
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text(narrow ? 'Transfer' : 'Bank transfer'),
                    ),
                  ],
                  selected: {_method},
                  showSelectedIcon: false,
                  onSelectionChanged: _processing
                      ? null
                      : (s) => setState(() => _method = s.first),
                ),
                const SizedBox(height: 18),
                if (_stripe)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined, color: purple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You will continue to Stripe\'s secure checkout page to enter your card. Card details never touch MT Alchemy\'s servers.',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ],
                  )
                else if (_method == 'Card') ...[
                  TextFormField(
                    controller: _cardName,
                    decoration: _dec(
                      'Name on card',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Enter the cardholder name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      LengthLimitingTextInputFormatter(23),
                    ],
                    decoration: _dec(
                      'Card number',
                      icon: Icons.credit_card,
                      hint: '4242 4242 4242 4242',
                    ),
                    validator: (_) =>
                        luhn(_digits) ? null : 'Enter a valid card number',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiry,
                          keyboardType: TextInputType.datetime,
                          decoration: _dec('Expiry', hint: 'MM/YY'),
                          validator: _validateExpiry,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvc,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: _dec('CVC'),
                          validator: (v) =>
                              RegExp(r'^\d{3,4}$').hasMatch(v ?? '')
                              ? null
                              : '3 or 4 digits',
                        ),
                      ),
                    ],
                  ),
                ] else if (_method == 'FPX')
                  DropdownButtonFormField<String>(
                    initialValue: _bank,
                    isExpanded: true,
                    decoration: _dec(
                      'Your bank',
                      icon: Icons.account_balance_outlined,
                    ),
                    items: [
                      for (final b in banks)
                        DropdownMenuItem(value: b, child: Text(b)),
                    ],
                    onChanged: (v) => setState(() => _bank = v),
                    validator: (v) => v == null ? 'Select your bank' : null,
                  )
                else
                  const Text(
                    'Your order is created now and marked Pending. Our team confirms the transfer and updates the status.',
                    style: TextStyle(height: 1.45),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _processing ? null : _pay,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_outline, size: 18),
            label: Text(
              _processing
                  ? 'Processing…'
                  : _method == 'Transfer'
                  ? 'Confirm order'
                  : _stripe
                  ? 'Continue to Stripe · ${money(widget.amount)}'
                  : 'Pay ${money(widget.amount)}',
            ),
          ),
        ),
      ],
    );
  }
}

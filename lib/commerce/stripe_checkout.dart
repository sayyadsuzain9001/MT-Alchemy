import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../backend/app_config.dart';
import '../data/progress_store.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/portal_components.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_prototype_store.dart';

/// Stripe Checkout through the MT Alchemy payment server
/// (`payments_server/`), which holds the Stripe secret key.
class StripeCheckout {
  static http.Client client = http.Client();

  static bool get enabled => AppConfig.paymentsApiUrl.isNotEmpty;

  static Uri _api(String path) => Uri.parse('${AppConfig.paymentsApiUrl}$path');

  static String get returnUrl =>
      '${Uri.base.origin}${Uri.base.path}#/payment-return';

  /// Creates a hosted checkout page for [order] and returns its URL.
  static Future<String> createSession(ShopOrder order) async {
    final response = await client
        .post(
          _api('/api/checkout-session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderNumber': order.number,
            'customerEmail': order.customerEmail,
            'returnUrl': returnUrl,
            'lines': [
              for (final l in order.lines)
                {
                  'name': l.product.name,
                  'unitAmount': l.product.price,
                  'quantity': l.quantity,
                },
              if (order.hasPhysical)
                {'name': 'Shipping', 'unitAmount': 10, 'quantity': 1},
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['url'] == null) {
      throw StateError(data['error'] as String? ?? 'Checkout unavailable');
    }
    return data['url'] as String;
  }

  /// Asks the server (and so Stripe) whether a checkout session was paid.
  static Future<Map<String, dynamic>> verify(String sessionId) async {
    final response = await client
        .get(_api('/api/checkout-session/${Uri.encodeComponent(sessionId)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw StateError('Session not found');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Saves the pending order, then sends the browser to Stripe.
  static Future<void> payOrder(BuildContext context, ShopOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await CommercePrototypeStore.instance.flush();
      final url = await createSession(order);
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Card payment is unavailable right now. Order ${order.number} is saved as Pending; you can pay later from My orders.',
          ),
        ),
      );
    }
  }
}

/// Stripe sends the customer back here: `/payment-return?order=&status=&session_id=`.
class PaymentReturnPage extends StatefulWidget {
  const PaymentReturnPage({
    super.key,
    required this.orderNumber,
    required this.sessionId,
    required this.status,
  });
  final String? orderNumber;
  final String? sessionId;
  final String? status;

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  String _state = 'checking'; // checking | paid | unpaid | cancelled | error
  String? _card;

  ShopOrder? get _order =>
      CommercePrototypeStore.instance.orderByNumber(widget.orderNumber);

  @override
  void initState() {
    super.initState();
    _confirm();
  }

  Future<void> _confirm() async {
    if (widget.status == 'cancelled' || widget.sessionId == null) {
      setState(() => _state = 'cancelled');
      return;
    }
    try {
      final result = await StripeCheckout.verify(widget.sessionId!);
      if (result['orderNumber'] != widget.orderNumber) {
        throw StateError('Order mismatch');
      }
      if (result['paymentStatus'] == 'paid') {
        _card = result['card'] as String?;
        final store = CommercePrototypeStore.instance;
        await store.confirmCustomerPayment(
          widget.orderNumber!,
          'Stripe · ${_card ?? 'card'} · ${result['paymentIntent'] ?? widget.sessionId}',
        );
        final order = _order;
        if (order != null) {
          for (final line in order.lines.where(
            CommercePrototypeStore.isCourseLine,
          )) {
            if (AuthPrototypeStore.instance.role == 'Learner') {
              enrollCourse(line.product.id.substring('course:'.length));
            }
          }
        }
        if (mounted) setState(() => _state = 'paid');
      } else {
        if (mounted) setState(() => _state = 'unpaid');
      }
    } catch (_) {
      if (mounted) setState(() => _state = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final hasCourse =
        order?.lines.any(CommercePrototypeStore.isCourseLine) ?? false;
    final employer = AuthPrototypeStore.instance.role == 'Employer';
    final (icon, color, title, body) = switch (_state) {
      'checking' => (
        Icons.hourglass_top_rounded,
        purple,
        'Confirming your payment…',
        'We are checking with Stripe. This takes a moment.',
      ),
      'paid' => (
        Icons.check_circle,
        const Color(0xFF2E7D32),
        'Payment successful',
        'Thank you! Order ${widget.orderNumber} is paid${_card == null ? '' : ' with $_card'}.',
      ),
      'cancelled' => (
        Icons.cancel_outlined,
        const Color(0xFFB7791F),
        'Payment cancelled',
        'No money was taken. Order ${widget.orderNumber ?? ''} is still Pending, so you can try again.',
      ),
      'unpaid' => (
        Icons.error_outline,
        const Color(0xFFC62828),
        'Payment not completed',
        'Stripe has not confirmed this payment. You can try again.',
      ),
      _ => (
        Icons.cloud_off,
        const Color(0xFFC62828),
        'We could not confirm the payment',
        'Check your connection and refresh this page. If you were charged, contact MT Alchemy with order ${widget.orderNumber ?? ''}.',
      ),
    };
    return PortalPage(
      title: 'Payment',
      eyebrow: 'Secure checkout',
      showTitle: false,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: InfoCard(
              child: Column(
                children: [
                  if (_state == 'checking')
                    const SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(),
                    )
                  else
                    Icon(icon, size: 60, color: color),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(body, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (_state == 'paid' && hasCourse && !employer)
                        FilledButton.icon(
                          onPressed: () => go(context, '/dashboard'),
                          icon: const Icon(Icons.play_lesson_outlined),
                          label: const Text('Start learning'),
                        ),
                      if (_state == 'paid' && hasCourse && employer)
                        FilledButton.icon(
                          onPressed: () => go(context, '/assign-course'),
                          icon: const Icon(Icons.assignment_add),
                          label: const Text('Assign your seats'),
                        ),
                      if (_state == 'paid' && !hasCourse && order != null)
                        FilledButton.icon(
                          onPressed: () => go(
                            context,
                            '/order-confirmation',
                            arguments: order.number,
                          ),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('View order'),
                        ),
                      if ((_state == 'cancelled' || _state == 'unpaid') &&
                          order != null &&
                          order.paymentStatus != 'Paid')
                        FilledButton.icon(
                          onPressed: () =>
                              StripeCheckout.payOrder(context, order),
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Try payment again'),
                        ),
                      OutlinedButton(
                        onPressed: () => go(context, '/orders'),
                        child: const Text('My orders'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.black45),
                      SizedBox(width: 6),
                      Text(
                        'Payments are processed by Stripe',
                        style: TextStyle(fontSize: 12.5, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

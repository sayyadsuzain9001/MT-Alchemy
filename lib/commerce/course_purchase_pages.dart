import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/progress_store.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/portal_components.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_prototype_store.dart';
import 'payment_gateway.dart';
import 'stripe_checkout.dart';

ShopOrder? _buyCourse({
  required Course course,
  required int seats,
  required PaymentResult payment,
}) {
  final auth = AuthPrototypeStore.instance;
  final profile = auth.profile;
  return CommercePrototypeStore.instance.placeOrder(
    customerName: auth.displayName ?? auth.email ?? 'Customer',
    customerEmail: auth.email!,
    customerPhone: '${profile['phone'] ?? '-'}',
    billingAddress: '${profile['country'] ?? 'Malaysia'}',
    address: '',
    paymentMethod: payment.status == 'Redirect'
        ? payment.method
        : '${payment.method} · ${payment.reference}',
    paymentStatus: payment.status == 'Redirect' ? 'Pending' : payment.status,
    items: [
      CartLine(
        product: CommercePrototypeStore.courseProduct(
          courseId: course.id,
          title: course.title,
          price: course.price,
        ),
        quantity: seats,
      ),
    ],
  );
}

/// Journey A step "Pay → Enrolment": an individual buys a course, then is
/// enrolled. Free, already-paid and employer-assigned courses enrol directly.
class CourseEnrolScreen extends StatefulWidget {
  const CourseEnrolScreen({super.key, required this.courseId});
  final String courseId;

  @override
  State<CourseEnrolScreen> createState() => _CourseEnrolScreenState();
}

class _CourseEnrolScreenState extends State<CourseEnrolScreen> {
  bool _busy = false;
  String? _notice;

  Course get _course => mockCourses.firstWhere(
    (c) => c.id == widget.courseId,
    orElse: () => mockCourses.first,
  );

  bool get _entitled {
    final email = AuthPrototypeStore.instance.email ?? '';
    final store = CommercePrototypeStore.instance;
    return _course.price <= 0 ||
        enrolledCourses.contains(_course.id) ||
        store.paidCourseIdsFor(email).contains(_course.id) ||
        store.assignedCoursesFor(email).contains(_course.title);
  }

  @override
  void initState() {
    super.initState();
    if (_entitled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enrolAndOpen());
    }
  }

  void _enrolAndOpen() {
    enrollCourse(_course.id);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are enrolled in ${_course.title}.')),
    );
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    final payment = await showPaymentGateway(
      context,
      amount: _course.price,
      description: _course.title,
    );
    if (!mounted) return;
    if (payment == null) {
      setState(() => _busy = false);
      return;
    }
    final order = _buyCourse(course: _course, seats: 1, payment: payment);
    if (payment.status == 'Redirect' && order != null) {
      await StripeCheckout.payOrder(context, order);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (payment.successful) {
      _enrolAndOpen();
      return;
    }
    setState(() {
      _busy = false;
      _notice = payment.status == 'Pending'
          ? 'Payment pending: ${payment.message ?? ''} You will be enrolled automatically once it is confirmed.'
          : payment.message ?? 'Payment failed. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    final employer = AuthPrototypeStore.instance.role == 'Employer';
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/hub'),
        title: const Text('Enrol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _entitled
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            course.imageAsset,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${course.modules.length} modules · ${course.duration} · ${course.level} · certificate on passing',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Course fee',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              money(course.price),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Lifetime access to lessons, quiz retakes and your certificate.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        if (_notice != null) ...[
                          const SizedBox(height: 16),
                          InfoCard(
                            color: const Color(0xFFFFF4E5),
                            child: Text(_notice!),
                          ),
                        ],
                        const SizedBox(height: 22),
                        if (employer)
                          FilledButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/purchase-courses',
                            ),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Buy seats for your team'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _busy ? null : _pay,
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: Text('Pay ${money(course.price)} and enrol'),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Journey D step "Purchase Course": an employer buys course seats, which
/// are then used when assigning the course to employees.
class PurchaseCoursesPage extends StatefulWidget {
  const PurchaseCoursesPage({super.key});

  @override
  State<PurchaseCoursesPage> createState() => _PurchaseCoursesPageState();
}

class _PurchaseCoursesPageState extends State<PurchaseCoursesPage> {
  final Map<String, int> _seats = {};
  String? _busyCourse;

  Future<void> _buy(Course course) async {
    final seats = _seats[course.id] ?? 5;
    setState(() => _busyCourse = course.id);
    final payment = await showPaymentGateway(
      context,
      amount: course.price * seats,
      description: '${course.title} × $seats seats',
    );
    if (!mounted) return;
    setState(() => _busyCourse = null);
    if (payment == null) return;
    final order = _buyCourse(course: course, seats: seats, payment: payment);
    if (order == null) return;
    if (payment.status == 'Redirect') {
      await StripeCheckout.payOrder(context, order);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          payment.successful
              ? '$seats seats of ${course.title} are ready to assign.'
              : payment.status == 'Pending'
              ? 'Order ${order.number} is pending. Seats become available once payment is confirmed.'
              : payment.message ?? 'Payment failed.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CommercePrototypeStore.instance,
    builder: (context, _) {
      final store = CommercePrototypeStore.instance;
      final owned = store.purchasedSeats();
      return PortalPage(
        eyebrow: 'Employer · Purchase courses',
        title: 'Buy learning for your team.',
        children: [
          const Text(
            'Purchase course seats, then assign them to employees from Assign course. Paid seats are available immediately.',
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minWidth: 300,
            children: [
              for (final course in publishedCourses)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${money(course.price)} per seat · ${course.duration}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seats: ${owned[course.title] ?? 0} purchased · ${store.assignedSeats(course.title)} assigned',
                        style: const TextStyle(
                          color: purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: 'Fewer seats for ${course.title}',
                            onPressed: (_seats[course.id] ?? 5) <= 1
                                ? null
                                : () => setState(
                                    () => _seats[course.id] =
                                        (_seats[course.id] ?? 5) - 1,
                                  ),
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${_seats[course.id] ?? 5} seats',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'More seats for ${course.title}',
                            onPressed: () => setState(
                              () => _seats[course.id] =
                                  ((_seats[course.id] ?? 5) + 1).clamp(1, 500),
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _busyCourse != null
                            ? null
                            : () => _buy(course),
                        child: Text(
                          'Buy ${_seats[course.id] ?? 5} seats · ${money(course.price * (_seats[course.id] ?? 5))}',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}

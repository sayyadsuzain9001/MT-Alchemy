import 'package:flutter/material.dart';
import '../shared/notifications.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/portal_components.dart';
import '../theme.dart';
import '../widgets.dart';
import 'commerce_prototype_store.dart';

final _store = CommercePrototypeStore.instance;

class QuoteRequestPage extends StatefulWidget {
  const QuoteRequestPage({super.key, this.productId});
  final String? productId;

  @override
  State<QuoteRequestPage> createState() => _QuoteRequestPageState();
}

class _QuoteRequestPageState extends State<QuoteRequestPage> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController(
    text: AuthPrototypeStore.instance.email ?? '',
  );
  final _phone = TextEditingController();
  final _requirements = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _email.dispose();
    _phone.dispose();
    _requirements.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Please complete this field'
      : null;

  @override
  Widget build(BuildContext context) {
    final directProduct = widget.productId == null
        ? null
        : _store.productById(widget.productId!);
    final lines = directProduct == null
        ? (_store.cartLines.isEmpty
              ? [
                  CartLine(
                    product: const ShopProduct(
                      id: 'tailored-programme',
                      name: 'Tailored corporate programme / service',
                      description:
                          'Scope and pricing to be confirmed after reviewing requirements.',
                      price: 0,
                      category: 'Service',
                      icon: Icons.groups,
                      digital: true,
                    ),
                    quantity: _quantity,
                  ),
                ]
              : _store.cartLines)
        : [CartLine(product: directProduct, quantity: _quantity)];
    return PortalPage(
      title: 'Tell us what your organisation needs.',
      eyebrow: 'Business quotation',
      children: [
        const InfoCard(
          color: Color(0xFFFFF8DE),
          child: Text(
            'Request pricing for bulk learning materials or a tailored programme. This request does not place an order or charge a payment. Our team reviews every request and replies here under My quote requests.',
            style: TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        if (lines.isEmpty)
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your cart is empty. Choose products first, or browse the store.',
                ),
                TextButton(
                  onPressed: () => go(context, '/store'),
                  child: const Text('Browse store'),
                ),
              ],
            ),
          )
        else ...[
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items for quotation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${line.product.name} · ${line.product.category}',
                          ),
                        ),
                        if (directProduct != null ||
                            line.product.category == 'Service')
                          IconButton(
                            tooltip: 'Decrease quantity',
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        Text('× ${line.quantity}'),
                        if (directProduct != null ||
                            line.product.category == 'Service')
                          IconButton(
                            tooltip: 'Increase quantity',
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                      ],
                    ),
                  ),
                const Text(
                  'Final pricing, bulk discounts, delivery and programme scope are confirmed by the MT Alchemy team.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InfoCard(
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your contact details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Your name'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _organization,
                    decoration: const InputDecoration(
                      labelText: 'Organization',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Business email',
                    ),
                    validator: (value) =>
                        value == null ||
                            !RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value.trim())
                        ? 'Enter a valid email address'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _requirements,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Requirements',
                      hintText:
                          'Team size, preferred dates, delivery location, customisation or questions',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (!_key.currentState!.validate() || lines.isEmpty) {
                        return;
                      }
                      final quote = _store.createQuoteRequest(
                        customerName: _name.text.trim(),
                        organizationName: _organization.text.trim(),
                        email: _email.text.trim(),
                        phone: _phone.text.trim(),
                        lines: lines,
                        requirements: _requirements.text.trim(),
                      );
                      go(
                        context,
                        '/quote-confirmation',
                        arguments: quote.reference,
                      );
                    },
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Submit quotation request'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class QuoteConfirmationPage extends StatelessWidget {
  const QuoteConfirmationPage({super.key, this.reference});
  final String? reference;

  @override
  Widget build(BuildContext context) {
    QuoteRequest? quote;
    for (final request in _store.quoteRequests) {
      if (request.reference == reference) {
        quote = request;
      }
    }
    return PortalPage(
      title: 'Your request is with our team.',
      eyebrow: 'Quotation request received',
      children: [
        InfoCard(
          color: const Color(0xFFFFF8DE),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: purple,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                quote == null
                    ? 'Request submitted'
                    : 'Reference ${quote.reference}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                quote == null
                    ? 'Your quotation request has been sent to our team.'
                    : 'Status: ${quote.status} · Organization: ${quote.organizationName}',
              ),
              const SizedBox(height: 8),
              const Text(
                'No order or payment has been created. Our team will review your request and you can follow its status under My quote requests.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () => go(context, '/store'),
                    child: const Text('Continue browsing'),
                  ),
                  if (AuthPrototypeStore.instance.hasRole('Employer'))
                    FilledButton(
                      onPressed: () => go(context, '/quote-requests'),
                      child: const Text('My quote requests'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MyQuoteRequestsPage extends StatelessWidget {
  const MyQuoteRequestsPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) {
      final requests = _store.quoteRequestsFor(
        AuthPrototypeStore.instance.email ?? '',
      );
      return PortalPage(
        title: 'Follow your organisation’s quote requests.',
        eyebrow: 'Employer portal · quotations',
        children: [
          if (requests.isEmpty)
            const InfoCard(
              child: Text(
                'No quotation requests are linked to this account yet. Submit one from a product page or from your cart.',
              ),
            )
          else
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.reference,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Chip(label: Text(request.status)),
                        ],
                      ),
                      Text(
                        '${request.organizationName} · ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                      ),
                      const SizedBox(height: 8),
                      for (final line in request.lines)
                        Text('${line.product.name} × ${line.quantity}'),
                      const SizedBox(height: 8),
                      Text(request.requirements),
                      if (request.quotedTotal != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Indicative quote: ${money(request.quotedTotal!)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      if (request.adminNote != null &&
                          request.adminNote!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Team response: ${request.adminNote}'),
                        ),
                    ],
                  ),
                ),
              ),
          OutlinedButton(
            onPressed: () => go(context, '/store'),
            child: const Text('Browse store'),
          ),
        ],
      );
    },
  );
}

class QuoteManagementPage extends StatelessWidget {
  const QuoteManagementPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'Review business enquiries and prepare a response.',
      eyebrow: 'Admin · quotation requests',
      children: [
        const InfoCard(
          color: Color(0xFFFFF8DE),
          child: Text(
            'Workflow: New → In Review → Quoted → Accepted or Declined. Saving a quote updates the employer\'s view immediately; it does not email the customer.',
          ),
        ),
        const SizedBox(height: 16),
        if (_store.quoteRequests.isEmpty)
          const InfoCard(
            child: Text(
              'No quote requests yet. Business visitors can request pricing from a product page or shopping cart.',
            ),
          )
        else
          for (final request in _store.quoteRequests)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${request.organizationName} · ${request.reference}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Chip(label: Text(request.status)),
                      ],
                    ),
                    Text(
                      '${request.customerName} · ${request.email} · ${request.phone}',
                    ),
                    const SizedBox(height: 8),
                    for (final line in request.lines)
                      Text('${line.product.name} × ${line.quantity}'),
                    const SizedBox(height: 8),
                    Text('Requirements: ${request.requirements}'),
                    if (request.quotedTotal != null)
                      Text('Quote: ${money(request.quotedTotal!)}'),
                    if (request.adminNote?.isNotEmpty == true)
                      Text('Response note: ${request.adminNote}'),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _editQuote(context, request),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Update status / prepare quote'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}

Future<void> _editQuote(BuildContext context, QuoteRequest request) =>
    showDialog<void>(
      context: context,
      builder: (_) => _QuoteEditDialog(request: request),
    );

class _QuoteEditDialog extends StatefulWidget {
  const _QuoteEditDialog({required this.request});
  final QuoteRequest request;

  @override
  State<_QuoteEditDialog> createState() => _QuoteEditDialogState();
}

class _QuoteEditDialogState extends State<_QuoteEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _total;
  late final TextEditingController _note;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.request.status;
    _total = TextEditingController(
      text: widget.request.quotedTotal?.toStringAsFixed(2) ?? '',
    );
    _note = TextEditingController(text: widget.request.adminNote ?? '');
  }

  @override
  void dispose() {
    _total.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _store.updateQuoteRequest(
      widget.request.reference,
      status: _status,
      quotedTotal: double.tryParse(_total.text),
      adminNote: _note.text.trim(),
    );
    NotificationService.send(
      recipient: widget.request.ownerEmail ?? widget.request.email,
      title: 'Quote ${widget.request.reference}: $_status',
      body: 'MT Alchemy updated your quotation request.',
      route: '/quote-requests',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Update ${widget.request.reference}'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(context).height * .58,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Request status'),
                items: const [
                  DropdownMenuItem(value: 'New', child: Text('New')),
                  DropdownMenuItem(
                    value: 'In Review',
                    child: Text('In Review'),
                  ),
                  DropdownMenuItem(value: 'Quoted', child: Text('Quoted')),
                  DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
                  DropdownMenuItem(value: 'Declined', child: Text('Declined')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _total,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Indicative total (RM)',
                  helperText: 'Required when status is Quoted',
                ),
                validator: (value) {
                  if (_status != 'Quoted' &&
                      (value == null || value.trim().isEmpty)) {
                    return null;
                  }
                  final parsed = double.tryParse(value ?? '');
                  return parsed == null || parsed < 0
                      ? 'Enter a valid amount'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Response / internal note',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save response')),
    ],
  );
}

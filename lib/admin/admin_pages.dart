import '../data/mock_data.dart';
import '../shared/notifications.dart';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../commerce/commerce_prototype_store.dart';
import '../shared/portal_components.dart';
import '../theme.dart';
import '../shared/charts.dart';
import '../shared/ui_kit.dart';
import '../widgets.dart';

final _store = CommercePrototypeStore.instance;

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) {
      final orders = _store.orders;
      final paid = orders.where((o) => o.paymentStatus == 'Paid').toList();
      final revenue = paid.fold<double>(0, (t, o) => t + o.total);
      final today = DateTime.now();
      final days = [
        for (var i = 6; i >= 0; i--)
          DateTime(today.year, today.month, today.day - i),
      ];
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final revenueByDay = [
        for (final d in days)
          (
            weekdays[d.weekday - 1],
            paid
                .where(
                  (o) =>
                      o.date.year == d.year &&
                      o.date.month == d.month &&
                      o.date.day == d.day,
                )
                .fold<double>(0, (t, o) => t + o.total),
          ),
      ];
      final lowStock = _store.products
          .where((p) => !p.digital && p.stock < 10)
          .toList();
      final pendingPayments = orders
          .where((o) => o.paymentStatus == 'Pending')
          .toList();
      final openQuotes = _store.quoteRequests
          .where((q) => q.status != 'Accepted' && q.status != 'Declined')
          .toList();
      final newEnquiries = _store.contactEnquiries
          .where((e) => e.status == 'New')
          .toList();
      final wide = MediaQuery.sizeOf(context).width >= 980;
      Widget twoUp(Widget a, Widget b) => wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: a),
                const SizedBox(width: 20),
                Expanded(child: b),
              ],
            )
          : Column(children: [a, const SizedBox(height: 20), b]);
      Widget alert(IconData icon, Color color, String text, String route) =>
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color),
            title: Text(text),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => go(context, route),
          );
      return PortalPage(
        title: 'Platform operations at a glance.',
        eyebrow: 'MT Alchemy admin',
        showTitle: false,
        children: [
          DashboardHeader(
            eyebrow: 'MT Alchemy admin',
            title: 'Platform operations at a glance.',
            subtitle:
                'Users, courses, products, orders, payments and enquiries in one place.',
            image: 'assets/images/stock/analytics.jpg',
            actions: [
              HeaderButton(
                label: 'Manage users',
                icon: Icons.manage_accounts_outlined,
                primary: true,
                onPressed: () => go(context, '/admin/users'),
              ),
              HeaderButton(
                label: 'Orders',
                icon: Icons.receipt_long_outlined,
                onPressed: () => go(context, '/admin/orders'),
              ),
              HeaderButton(
                label: 'Courses',
                icon: Icons.school_outlined,
                onPressed: () => go(context, '/admin/courses'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TileGrid(
            maxColumns: 4,
            minTileWidth: 200,
            minColumns: 2,
            children: [
              StatTile(
                icon: Icons.payments_outlined,
                value: money(revenue),
                label: 'Revenue (paid orders)',
                color: const Color(0xFF2E7D32),
              ),
              StatTile(
                icon: Icons.receipt_long_outlined,
                value: '${orders.length}',
                label: 'Orders',
                color: royalBlue,
                caption: '${pendingPayments.length} awaiting payment',
              ),
              StatTile(
                icon: Icons.school_outlined,
                value: '${mockCourses.length}',
                label: 'Courses',
                caption: '${publishedCourses.length} published',
              ),
              StatTile(
                icon: Icons.inventory_2_outlined,
                value: '${_store.products.length}',
                label: 'Products',
                color: const Color(0xFF0E7490),
                caption:
                    '${_store.products.where((p) => !p.digital).fold<int>(0, (t, p) => t + p.stock)} units in stock',
              ),
              StatTile(
                icon: Icons.warning_amber_rounded,
                value: '${lowStock.length}',
                label: 'Low-stock items',
                color: const Color(0xFFC2410C),
              ),
              StatTile(
                icon: Icons.request_quote_outlined,
                value: '${openQuotes.length}',
                label: 'Open quote requests',
                color: const Color(0xFFB7791F),
              ),
              StatTile(
                icon: Icons.mark_email_unread_outlined,
                value: '${newEnquiries.length}',
                label: 'New enquiries',
                color: purple,
              ),
              StatTile(
                icon: Icons.picture_as_pdf_outlined,
                value: '${mockCourses.where((c) => c.pdfName != null).length}',
                label: 'PDF resources',
                color: royalBlue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          twoUp(
            DashboardPanel(
              title: 'Revenue, last 7 days',
              subtitle: 'Paid orders (RM)',
              icon: Icons.show_chart,
              child: LabelledBarChart(
                values: revenueByDay,
                color: const Color(0xFF2E7D32),
              ),
            ),
            DashboardPanel(
              title: 'Orders by payment status',
              icon: Icons.donut_large_outlined,
              child: StatusDonut(
                centerLabel: 'orders',
                values: {
                  'Paid': paid.length,
                  'Pending': pendingPayments.length,
                  'Failed': orders
                      .where((o) => o.paymentStatus == 'Failed')
                      .length,
                },
                colors: const [
                  Color(0xFF2E7D32),
                  Color(0xFFB7791F),
                  Color(0xFFC62828),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DashboardPanel(
            title: 'Needs attention',
            icon: Icons.notifications_active_outlined,
            child:
                lowStock.isEmpty &&
                    pendingPayments.isEmpty &&
                    openQuotes.isEmpty &&
                    newEnquiries.isEmpty
                ? const Text('All clear. Nothing is waiting for you.')
                : Column(
                    children: [
                      for (final p in lowStock)
                        alert(
                          Icons.inventory_2_outlined,
                          const Color(0xFFC2410C),
                          'Low stock: ${p.name} (${p.stock} left)',
                          '/admin/products',
                        ),
                      if (pendingPayments.isNotEmpty)
                        alert(
                          Icons.payments_outlined,
                          const Color(0xFFB7791F),
                          '${pendingPayments.length} order(s) awaiting payment confirmation',
                          '/admin/orders',
                        ),
                      if (openQuotes.isNotEmpty)
                        alert(
                          Icons.request_quote_outlined,
                          purple,
                          '${openQuotes.length} quote request(s) to answer',
                          '/admin/quotes',
                        ),
                      if (newEnquiries.isNotEmpty)
                        alert(
                          Icons.mark_email_unread_outlined,
                          royalBlue,
                          '${newEnquiries.length} new contact enquiry(ies)',
                          '/admin/enquiries',
                        ),
                    ],
                  ),
          ),
          const SectionTitle(
            'Training and administration',
            eyebrow: 'Quick actions',
          ),
          ResponsiveGrid(
            children: [
              PortalAction(
                title: 'Users',
                subtitle:
                    'Create accounts, change roles, suspend or remove users.',
                icon: Icons.manage_accounts_outlined,
                route: '/admin/users',
              ),
              PortalAction(
                title: 'Organizations',
                subtitle: 'Employer accounts, staff numbers and assignments.',
                icon: Icons.apartment_outlined,
                route: '/admin/organizations',
              ),
              PortalAction(
                title: 'Course management',
                subtitle: 'Create courses, upload PDFs and build quizzes.',
                icon: Icons.school_outlined,
                route: '/admin/courses',
              ),
              PortalAction(
                title: 'Product management',
                subtitle: 'Add products, set stock and publish items.',
                icon: Icons.inventory_2_outlined,
                route: '/admin/products',
              ),
              PortalAction(
                title: 'Order management',
                subtitle: 'Review payment and fulfilment status.',
                icon: Icons.local_shipping_outlined,
                route: '/admin/orders',
              ),
              PortalAction(
                title: 'Business quote requests',
                subtitle:
                    'Review enquiries, prepare prices and update request status.',
                icon: Icons.request_quote_outlined,
                route: '/admin/quotes',
              ),
              PortalAction(
                title: 'Contact enquiry inbox',
                subtitle:
                    'Retrieve website contact form submissions for review.',
                icon: Icons.inbox_outlined,
                route: '/admin/enquiries',
              ),
              PortalAction(
                title: 'Inventory',
                subtitle: 'Check the current physical product stock.',
                icon: Icons.warehouse_outlined,
                route: '/admin/products',
              ),
              PortalAction(
                title: 'My learning',
                subtitle: 'Open your personal training dashboard.',
                icon: Icons.business_outlined,
                route: '/dashboard',
              ),
            ],
          ),
          const SectionTitle(
            'Shared platform modules',
            eyebrow: 'Integration points',
          ),
          const Text(
            'All data is stored in Firebase and shared live across roles. Manage PDFs, assessments and prerequisites in Course management; employer accounts manage their own employees, assignments and reports.',
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Reset demo data?'),
                  content: const Text(
                    'This clears test orders and restores the starter products, employees and assignments for another walkthrough.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Reset demo data'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _store.resetDemoData();
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset demo data'),
          ),
        ],
      );
    },
  );
}

class ProductManagementPage extends StatelessWidget {
  const ProductManagementPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'Keep the catalogue up to date.',
      eyebrow: 'Admin · product management',
      children: [
        FilledButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const _ProductEditorDialog(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
        const SizedBox(height: 18),
        if (_store.products.isEmpty)
          const InfoCard(
            child: Text(
              'No products yet. Add a product to populate the store.',
            ),
          )
        else
          for (final product in _store.products)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final image = product.imagePath;
                    final artwork = ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: image == null
                            ? ColoredBox(
                                color: const Color(0xFFECE9F7),
                                child: Icon(product.icon, color: purple),
                              )
                            : Image.asset(image, fit: BoxFit.cover),
                      ),
                    );
                    final details = Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${product.digital ? 'Digital' : 'Physical'} · ${money(product.price)} · ${product.digital ? 'Download file selected' : 'Stock: ${product.stock}'}',
                          ),
                          if (!product.digital)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('Adjust stock'),
                                IconButton(
                                  tooltip: 'Decrease stock of ${product.name}',
                                  onPressed: () =>
                                      _store.adjustStock(product.id, -1),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                IconButton(
                                  tooltip: 'Increase stock of ${product.name}',
                                  onPressed: () =>
                                      _store.adjustStock(product.id, 1),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          Text(
                            product.published ? 'Published' : 'Unpublished',
                            style: TextStyle(
                              color: product.published
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      _ProductEditorDialog(product: product),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(
                                  'Edit',
                                  semanticsLabel: 'Edit ${product.name}',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    _deleteProduct(context, product),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  'Delete',
                                  semanticsLabel: 'Delete ${product.name}',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    final toggle = Semantics(
                      label: 'Published: ${product.name}',
                      child: Switch(
                        value: product.published,
                        onChanged: (_) =>
                            _store.toggleProductPublished(product.id),
                        activeThumbColor: purple,
                      ),
                    );
                    return constraints.maxWidth < 560
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  artwork,
                                  const SizedBox(width: 12),
                                  details,
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: toggle,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              artwork,
                              const SizedBox(width: 14),
                              details,
                              toggle,
                            ],
                          );
                  },
                ),
              ),
            ),
      ],
    ),
  );
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({this.product});
  final ShopProduct? product;
  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  bool digital = false;
  String? selectedImage;
  Uint8List? selectedImageBytes;
  String selectedDownload = 'assets/downloads/emotional_clarity_workbook.txt';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) {
      _stock.text = '10';
      return;
    }
    _name.text = product.name;
    _description.text = product.description;
    _price.text = product.price.toStringAsFixed(2);
    _stock.text = product.stock.toString();
    digital = product.digital;
    selectedImage = product.imagePath;
    selectedImageBytes = product.imageBytes;
    selectedDownload = product.downloadAssetPath ?? selectedDownload;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose an image smaller than 10 MB.')),
        );
      }
      return;
    }
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read that image. Choose another file.'),
          ),
        );
      }
      return;
    }
    setState(() {
      selectedImageBytes = file.bytes;
      selectedImage = null;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.inventory_2_outlined, color: deepBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(widget.product == null ? 'Add product' : 'Edit product'),
        ),
      ],
    ),
    content: SizedBox(
      width: 540,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .65,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    hintText: 'For example, Emotional Clarity Workbook',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Product description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a description'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (RM)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    return value == null || value <= 0
                        ? 'Enter a price above RM 0'
                        : null;
                  },
                ),
                if (!digital) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock quantity',
                    ),
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      return quantity == null || quantity < 0
                          ? 'Enter zero or more'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Product type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.inventory_2_outlined),
                      label: Text('Physical'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.download_outlined),
                      label: Text('Digital'),
                    ),
                  ],
                  selected: {digital},
                  onSelectionChanged: (selection) => setState(() {
                    final nextDigital = selection.first;
                    if (nextDigital != digital) {
                      selectedImage = null;
                      selectedImageBytes = null;
                    }
                    digital = nextDigital;
                    if (digital) _stock.text = '0';
                    if (!digital && _stock.text == '0') _stock.text = '10';
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  digital
                      ? 'Digital products have no stock or delivery address. Access is released after payment.'
                      : 'Physical products show stock below and require a shipping address at checkout.',
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Product image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Choose image from this device'),
                    ),
                    if (selectedImage != null || selectedImageBytes != null)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          selectedImage = null;
                          selectedImageBytes = null;
                        }),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove image'),
                      ),
                  ],
                ),
                if (selectedImageBytes != null) ...[
                  const SizedBox(height: 6),
                  const Text('Selected from your device. Preview below.'),
                ],
                if (!digital && selectedImageBytes == null) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedImage,
                    decoration: const InputDecoration(
                      labelText: 'Or use an image supplied with the project',
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Use branded product artwork'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'assets/images/workshop_team_creativity.jpeg',
                        child: Text('Team workshop photo'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'assets/images/workshop_group_discussion.jpeg',
                        child: Text('Group discussion photo'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'assets/images/impact_teachers_retreat.jpeg',
                        child: Text('Teachers retreat photo'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'assets/images/workshop_group_activity.jpeg',
                        child: Text('Workshop activity photo'),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedImage = value),
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : selectedImage != null
                        ? Image.asset(selectedImage!, fit: BoxFit.cover)
                        : _ProductImagePlaceholder(
                            name: _name.text,
                            digital: digital,
                          ),
                  ),
                ),
                if (digital) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDownload,
                    decoration: const InputDecoration(
                      labelText: 'Downloadable resource',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value:
                            'assets/downloads/emotional_clarity_workbook.txt',
                        child: Text('Emotional Clarity Workbook'),
                      ),
                      DropdownMenuItem(
                        value:
                            'assets/downloads/facilitator_reflection_guide.txt',
                        child: Text('Facilitator Reflection Guide'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => selectedDownload = value ?? selectedDownload,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_key.currentState!.validate()) {
            final current = widget.product;
            if (current == null) {
              _store.addProduct(
                name: _name.text.trim(),
                description: _description.text.trim(),
                price: double.parse(_price.text),
                digital: digital,
                imagePath: selectedImage,
                imageBytes: selectedImageBytes,
                downloadAssetPath: digital ? selectedDownload : null,
                stock: digital ? 0 : int.parse(_stock.text),
              );
            } else {
              _store.updateProduct(
                id: current.id,
                name: _name.text.trim(),
                description: _description.text.trim(),
                price: double.parse(_price.text),
                digital: digital,
                imagePath: selectedImageBytes == null
                    ? selectedImage ?? ''
                    : '',
                imageBytes: selectedImageBytes,
                downloadAssetPath: digital ? selectedDownload : null,
                stock: digital ? 0 : int.parse(_stock.text),
              );
            }
            Navigator.pop(context);
          }
        },
        child: Text(widget.product == null ? 'Add product' : 'Save changes'),
      ),
    ],
  );
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder({required this.name, required this.digital});
  final String name;
  final bool digital;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [deepBlue, purple]),
    ),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          digital ? Icons.menu_book_outlined : Icons.inventory_2_outlined,
          color: softYellow,
          size: 38,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            name.trim().isEmpty ? 'Product artwork preview' : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteProduct(BuildContext context, ShopProduct product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete product?'),
      content: Text(
        'Remove ${product.name} from the store catalogue? Existing orders keep their item record.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) _store.deleteProduct(product.id);
}

class OrderManagementPage extends StatelessWidget {
  const OrderManagementPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'Prepare each order for the customer.',
      eyebrow: 'Admin · order management',
      children: [
        const InfoCard(
          color: Color(0xFFFFF8DE),
          child: Text(
            'Order lifecycle: Pending → Paid → Processing → Shipped → Delivered. Digital items become available after payment confirmation.',
            style: TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        if (_store.orders.isEmpty)
          const InfoCard(
            child: Text(
              'No customer orders yet. New orders appear here as soon as customers check out.',
            ),
          )
        else
          for (final order in _store.orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          order.number,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          money(order.total),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Text(
                      '${order.customerName} · ${order.date.day}/${order.date.month}/${order.date.year}',
                    ),
                    if (order.customerEmail.isNotEmpty)
                      Text('${order.customerEmail} · ${order.customerPhone}'),
                    if (order.billingAddress != null)
                      Text('Bill to: ${order.billingAddress}'),
                    if (order.shippingAddress != null)
                      Text('Ship to: ${order.shippingAddress}'),
                    if (order.trackingNumber != null)
                      SelectableText('Tracking: ${order.trackingNumber}'),
                    const SizedBox(height: 8),
                    for (final line in order.lines)
                      Text(
                        '${line.product.name} × ${line.quantity} (${line.product.digital ? 'Digital' : 'Physical'})',
                      ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'payment-${order.number}-${order.paymentStatus}',
                      ),
                      initialValue: order.paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Payment status',
                      ),
                      items: _paymentOptions(order)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            _store.updatePaymentStatus(order.number, value)) {
                          NotificationService.send(
                            recipient: order.customerEmail,
                            title: 'Payment $value',
                            body:
                                'Order ${order.number} payment is now $value.',
                            route: '/orders',
                          );
                        } else if (value != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment status was not changed. Check available stock or order state.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: order.fulfilmentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Fulfilment status',
                      ),
                      items: _fulfilmentOptions(order)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _store.updateOrderStatus(order.number, value);
                          NotificationService.send(
                            recipient: order.customerEmail,
                            title: 'Order $value',
                            body: 'Order ${order.number} is now $value.',
                            route: '/orders',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}

List<String> _paymentOptions(ShopOrder order) => switch (order.paymentStatus) {
  'Paid' => ['Paid'],
  'Failed' => ['Failed', 'Pending', 'Paid'],
  _ => ['Pending', 'Paid', 'Failed'],
};

List<String> _fulfilmentOptions(ShopOrder order) {
  if (!order.hasPhysical) {
    return order.paymentStatus == 'Paid' ? ['Available'] : ['Pending'];
  }
  if (order.paymentStatus != 'Paid') return ['Pending'];
  return switch (order.fulfilmentStatus) {
    'Pending' => ['Pending', 'Processing'],
    'Processing' => ['Processing', 'Shipped'],
    'Shipped' => ['Shipped', 'Delivered'],
    'Delivered' => ['Delivered'],
    _ => ['Pending'],
  };
}

class ContactEnquiriesPage extends StatelessWidget {
  const ContactEnquiriesPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'Website enquiries in one place.',
      eyebrow: 'Admin · contact inbox',
      children: [
        const InfoCard(
          color: Color(0xFFFFF8DE),
          child: Text(
            'Website enquiries are stored securely in the database. Update the status and add notes as you follow up.',
          ),
        ),
        const SizedBox(height: 16),
        if (_store.contactEnquiries.isEmpty)
          const InfoCard(
            child: Text(
              'No contact submissions yet. Submit the website Contact form to create one.',
            ),
          )
        else
          for (final enquiry in _store.contactEnquiries)
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
                            '${enquiry.enquiryType} · ${enquiry.reference}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Chip(label: Text(enquiry.status)),
                      ],
                    ),
                    Text(
                      '${enquiry.name} · ${enquiry.email} · ${enquiry.phone}',
                    ),
                    if (enquiry.organization.isNotEmpty)
                      Text('Organization: ${enquiry.organization}'),
                    const SizedBox(height: 8),
                    Text(enquiry.message),
                    if (enquiry.adminNote?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Team note: ${enquiry.adminNote}'),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<String>(
                            initialValue: enquiry.status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'New',
                                child: Text('New'),
                              ),
                              DropdownMenuItem(
                                value: 'In Review',
                                child: Text('In Review'),
                              ),
                              DropdownMenuItem(
                                value: 'Ready to contact',
                                child: Text('Ready to contact'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _store.updateContactEnquiry(
                                  enquiry.reference,
                                  status: value,
                                  adminNote: enquiry.adminNote,
                                );
                              }
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _editContactNote(context, enquiry),
                          icon: const Icon(Icons.note_alt_outlined),
                          label: const Text('Add team note'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    ),
  );
}

Future<void> _editContactNote(BuildContext context, ContactEnquiry enquiry) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ContactNoteDialog(enquiry: enquiry),
    );

class _ContactNoteDialog extends StatefulWidget {
  const _ContactNoteDialog({required this.enquiry});
  final ContactEnquiry enquiry;

  @override
  State<_ContactNoteDialog> createState() => _ContactNoteDialogState();
}

class _ContactNoteDialogState extends State<_ContactNoteDialog> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.enquiry.adminNote ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Team note · ${widget.enquiry.reference}'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 440,
        maxHeight: MediaQuery.sizeOf(context).height * .55,
      ),
      child: SingleChildScrollView(
        child: TextField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Internal follow-up note',
            alignLabelWithHint: true,
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          _store.updateContactEnquiry(
            widget.enquiry.reference,
            status: widget.enquiry.status,
            adminNote: _note.text.trim(),
          );
          Navigator.pop(context);
        },
        child: const Text('Save note'),
      ),
    ],
  );
}

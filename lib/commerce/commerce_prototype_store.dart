import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../backend/backend.dart';
import '../backend/collection_sync.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Sample catalogue records for the Member 3 prototype. Replace these with
/// Firestore records during the functional project phase.
class ShopProduct {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'icon': icon.codePoint,
    'imagePath': imagePath,
    'imageBytes': imageBytes == null ? null : base64Encode(imageBytes!),
    'downloadAssetPath': downloadAssetPath,
    'digital': digital,
    'stock': stock,
    'published': published,
  };
  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String,
    icon:
        const [
          Icons.menu_book_outlined,
          Icons.auto_stories_outlined,
          Icons.style_outlined,
          Icons.groups_2_outlined,
          Icons.download_outlined,
          Icons.inventory_2_outlined,
        ].firstWhere(
          (icon) => icon.codePoint == json['icon'],
          orElse: () => Icons.inventory_2_outlined,
        ),
    imagePath: json['imagePath'] as String?,
    imageBytes: json['imageBytes'] == null
        ? null
        : base64Decode(json['imageBytes'] as String),
    downloadAssetPath: json['downloadAssetPath'] as String?,
    digital: json['digital'] as bool,
    stock: json['stock'] as int,
    published: json['published'] as bool,
    position: (json['position'] as num?)?.toInt() ?? 0,
  );

  const ShopProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    this.imagePath,
    this.imageBytes,
    this.downloadAssetPath,
    this.digital = false,
    this.stock = 20,
    this.published = true,
    this.position = 0,
  });

  /// Display order in the catalogue (Firestore only).
  final int position;

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final IconData icon;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? downloadAssetPath;
  final bool digital;
  final int stock;
  final bool published;

  ShopProduct copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    bool? digital,
    int? stock,
    bool? published,
    String? imagePath,
    Uint8List? imageBytes,
    bool clearImagePath = false,
    bool clearImageBytes = false,
    String? downloadAssetPath,
  }) => ShopProduct(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    category: category ?? this.category,
    icon: icon,
    imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    imageBytes: clearImageBytes ? null : imageBytes ?? this.imageBytes,
    downloadAssetPath: digital == false
        ? null
        : downloadAssetPath ?? this.downloadAssetPath,
    digital: digital ?? this.digital,
    stock: stock ?? this.stock,
    published: published ?? this.published,
    position: position,
  );
}

class CartLine {
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    product: ShopProduct.fromJson(
      Map<String, dynamic>.from(json['product'] as Map),
    ),
    quantity: json['quantity'] as int,
  );

  const CartLine({required this.product, required this.quantity});
  final ShopProduct product;
  final int quantity;
  double get subtotal => product.price * quantity;
}

class ShopOrder {
  Map<String, dynamic> toJson() => {
    'number': number,
    'date': date.toIso8601String(),
    'lines': lines.map((e) => e.toJson()).toList(),
    'total': total,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'fulfilmentStatus': fulfilmentStatus,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'billingAddress': billingAddress,
    'shippingAddress': shippingAddress,
    'trackingNumber': trackingNumber,
    'stockReserved': stockReserved,
  };
  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    number: json['number'] as String,
    date: DateTime.parse(json['date'] as String),
    lines: (json['lines'] as List)
        .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    total: (json['total'] as num).toDouble(),
    paymentStatus: json['paymentStatus'] as String,
    paymentMethod: json['paymentMethod'] as String,
    fulfilmentStatus: json['fulfilmentStatus'] as String,
    customerName: json['customerName'] as String,
    customerEmail: json['customerEmail'] as String,
    customerPhone: json['customerPhone'] as String,
    billingAddress: json['billingAddress'] as String?,
    shippingAddress: json['shippingAddress'] as String?,
    trackingNumber: json['trackingNumber'] as String?,
    stockReserved: json['stockReserved'] as bool,
  );

  const ShopOrder({
    required this.number,
    required this.date,
    required this.lines,
    required this.total,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.fulfilmentStatus,
    required this.customerName,
    this.customerEmail = '',
    this.customerPhone = '',
    this.billingAddress,
    this.shippingAddress,
    this.trackingNumber,
    this.stockReserved = false,
  });

  final String number;
  final DateTime date;
  final List<CartLine> lines;
  final double total;
  final String paymentStatus;
  final String paymentMethod;
  final String fulfilmentStatus;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? billingAddress;
  final String? shippingAddress;
  final String? trackingNumber;
  final bool stockReserved;
  bool get hasDigital => lines.any((line) => line.product.digital);
  bool get hasPhysical => lines.any((line) => !line.product.digital);
}

class QuoteRequest {
  Map<String, dynamic> toJson() => {
    'reference': reference,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
    'organizationName': organizationName,
    'email': email,
    'phone': phone,
    'lines': lines.map((e) => e.toJson()).toList(),
    'requirements': requirements,
    'status': status,
    'quotedTotal': quotedTotal,
    'adminNote': adminNote,
    'ownerEmail': ownerEmail,
  };
  factory QuoteRequest.fromJson(Map<String, dynamic> json) => QuoteRequest(
    reference: json['reference'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    customerName: json['customerName'] as String,
    organizationName: json['organizationName'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    lines: (json['lines'] as List)
        .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    requirements: json['requirements'] as String,
    status: json['status'] as String,
    quotedTotal: (json['quotedTotal'] as num?)?.toDouble(),
    adminNote: json['adminNote'] as String?,
    ownerEmail: json['ownerEmail'] as String?,
  );

  const QuoteRequest({
    required this.reference,
    required this.createdAt,
    required this.customerName,
    required this.organizationName,
    required this.email,
    required this.phone,
    required this.lines,
    required this.requirements,
    this.status = 'New',
    this.quotedTotal,
    this.adminNote,
    this.ownerEmail,
  });

  final String reference;
  final DateTime createdAt;
  final String customerName;

  /// Account that submitted the request; controls who may read it.
  final String? ownerEmail;
  final String organizationName;
  final String email;
  final String phone;
  final List<CartLine> lines;
  final String requirements;
  final String status;
  final double? quotedTotal;
  final String? adminNote;

  QuoteRequest copyWith({
    String? status,
    double? quotedTotal,
    String? adminNote,
  }) => QuoteRequest(
    reference: reference,
    createdAt: createdAt,
    customerName: customerName,
    organizationName: organizationName,
    email: email,
    phone: phone,
    lines: lines,
    requirements: requirements,
    status: status ?? this.status,
    quotedTotal: quotedTotal ?? this.quotedTotal,
    adminNote: adminNote ?? this.adminNote,
    ownerEmail: ownerEmail,
  );
}

class ContactEnquiry {
  Map<String, dynamic> toJson() => {
    'reference': reference,
    'createdAt': createdAt.toIso8601String(),
    'name': name,
    'email': email,
    'phone': phone,
    'enquiryType': enquiryType,
    'message': message,
    'organization': organization,
    'status': status,
    'adminNote': adminNote,
  };
  factory ContactEnquiry.fromJson(Map<String, dynamic> json) => ContactEnquiry(
    reference: json['reference'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    enquiryType: json['enquiryType'] as String,
    message: json['message'] as String,
    organization: json['organization'] as String,
    status: json['status'] as String,
    adminNote: json['adminNote'] as String?,
  );

  const ContactEnquiry({
    required this.reference,
    required this.createdAt,
    required this.name,
    required this.email,
    required this.phone,
    required this.enquiryType,
    required this.message,
    this.organization = '',
    this.status = 'New',
    this.adminNote,
  });

  final String reference;
  final DateTime createdAt;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final String enquiryType;
  final String message;
  final String status;
  final String? adminNote;

  ContactEnquiry copyWith({String? status, String? adminNote}) =>
      ContactEnquiry(
        reference: reference,
        createdAt: createdAt,
        name: name,
        email: email,
        phone: phone,
        organization: organization,
        enquiryType: enquiryType,
        message: message,
        status: status ?? this.status,
        adminNote: adminNote ?? this.adminNote,
      );
}

/// Commerce, enquiry and employer records backed by Cloud Firestore.
///
/// Screens keep using the synchronous getters and mutators below. Each
/// mutation updates memory immediately and then writes only the changed
/// documents; live snapshot listeners keep every signed-in role up to date.
class CommercePrototypeStore extends ChangeNotifier {
  CommercePrototypeStore._();
  static final CommercePrototypeStore instance = CommercePrototypeStore._();

  static const cartKey = 'alchemy_cart_v2';

  final _productSync = CollectionSync('products');
  final _orderSync = CollectionSync('orders');
  final _quoteSync = CollectionSync('quotes');
  final _enquirySync = CollectionSync('enquiries');
  final _employeeSync = CollectionSync('employees');
  final _assignmentSync = CollectionSync('assignments');

  SharedPreferences? _preferences;
  final _saves = SerialQueue();
  String? storageError;
  bool _applyingRemote = false;
  String? _role;
  String? _email;
  final Map<String, Completer<void>> _firstSnapshot = {};

  /// Loads the device cart and subscribes to the public catalogue.
  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final raw = _preferences!.getString(cartKey);
      _cart.clear();
      if (raw != null) {
        _cart.addAll(Map<String, int>.from(jsonDecode(raw) as Map));
      }
    } catch (_) {
      /* The cart is a convenience; continue with an empty one. */
    }
    await attach(role: _role, email: _email);
  }

  void _listen<T>(
    CollectionSync sync,
    Query<Map<String, dynamic>>? Function(
      CollectionReference<Map<String, dynamic>> ref,
    )
    query,
    List<T> target,
    T Function(Map<String, dynamic>) decode,
    int Function(T a, T b)? compare,
  ) {
    final ready = _firstSnapshot[sync.collection] = Completer<void>();
    sync.listen(
      query,
      onData: (docs) {
        if (_saves.busy && ready.isCompleted) {
          // Local writes are still queued: apply this snapshot once they
          // finish so it cannot roll back a newer in-memory change.
          _deferred[sync.collection] = () =>
              _apply(docs, target, decode, compare);
          return;
        }
        _apply(docs, target, decode, compare);
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object error) {
        storageError =
            'Live data for ${sync.collection} is unavailable. Check your connection or permissions.';
        if (!ready.isCompleted) ready.complete();
        super.notifyListeners();
      },
    );
  }

  final Map<String, void Function()> _deferred = {};

  void _apply<T>(
    List<Map<String, dynamic>> docs,
    List<T> target,
    T Function(Map<String, dynamic>) decode,
    int Function(T a, T b)? compare,
  ) {
    final items = <T>[];
    for (final doc in docs) {
      try {
        items.add(decode(doc));
      } catch (_) {
        /* Skip a malformed record instead of breaking the screen. */
      }
    }
    if (compare != null) items.sort(compare);
    _applyingRemote = true;
    target
      ..clear()
      ..addAll(items);
    _applyingRemote = false;
    super.notifyListeners();
  }

  /// Re-subscribes to the records the given account may read and waits for
  /// the first result of each subscription.
  Future<void> attach({String? role, String? email}) async {
    if (!Backend.isReady) return;
    _role = role;
    _email = email?.toLowerCase();
    activeEmployer = role == 'Employer' ? _email : null;
    storageError = null;
    final admin = role == 'Admin';
    final signedIn = _email != null;

    _listen<ShopProduct>(
      _productSync,
      (ref) => ref,
      _products,
      ShopProduct.fromJson,
      (a, b) => a.position.compareTo(b.position),
    );
    _listen<ShopOrder>(
      _orderSync,
      (ref) => admin
          ? ref
          : signedIn
          ? ref.where('customerEmail', isEqualTo: _email)
          : null,
      _orders,
      ShopOrder.fromJson,
      (a, b) => b.date.compareTo(a.date),
    );
    _listen<QuoteRequest>(
      _quoteSync,
      (ref) => admin
          ? ref
          : signedIn
          ? ref.where('ownerEmail', isEqualTo: _email)
          : null,
      _quoteRequests,
      QuoteRequest.fromJson,
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    _listen<ContactEnquiry>(
      _enquirySync,
      (ref) => admin ? ref : null,
      _contactEnquiries,
      ContactEnquiry.fromJson,
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    _listen<Map<String, String>>(
      _employeeSync,
      (ref) => admin
          ? ref
          : role == 'Employer'
          ? ref.where('organization', isEqualTo: _email)
          : null,
      _employees,
      (doc) => {
        for (final e in doc.entries)
          if (e.value is String) e.key: e.value as String,
      },
      (a, b) => (a['addedAt'] ?? '').compareTo(b['addedAt'] ?? ''),
    );
    _listen<Map<String, Object>>(
      _assignmentSync,
      (ref) => admin
          ? ref
          : role == 'Employer'
          ? ref.where('organization', isEqualTo: _email)
          : signedIn
          ? ref.where('employee', isEqualTo: _email)
          : null,
      _assignments,
      (doc) => {
        for (final e in doc.entries)
          if (e.value != null) e.key: e.value as Object,
      },
      (a, b) =>
          '${b['assignedAt'] ?? ''}'.compareTo('${a['assignedAt'] ?? ''}'),
    );
    await Future.wait(
      _firstSnapshot.values.map(
        (c) => c.future.timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            storageError ??=
                'The database is taking longer than usual to respond.';
          },
        ),
      ),
    );
  }

  /// Drops private records after sign-out; only the catalogue stays live.
  Future<void> detach() => attach();

  Future<void> flush() => _saves.idle;

  /// Rebuilds listeners without writing anything.
  void refresh() => super.notifyListeners();

  static String employeeDocId(Map record) =>
      '${record['organization']}__${record['email']}';
  static String assignmentDocId(Map record) =>
      '${record['organization']}__${record['employee']}__${record['course']}';

  Map<String, dynamic> _orderDoc(ShopOrder order) {
    final json = order.toJson();
    // Keep order documents small: product images live on the product.
    for (final line in json['lines'] as List) {
      (line['product'] as Map)['imageBytes'] = null;
    }
    return json;
  }

  /// Captures what to write at mutation time, so a later remote snapshot
  /// cannot change the payload of a queued write.
  List<(CollectionSync, Map<String, Map<String, dynamic>>, bool)> _payload() =>
      [
        if (_role == 'Admin')
          (
            _productSync,
            {
              for (final (i, p) in _products.indexed)
                p.id: {...p.toJson(), 'position': i},
            },
            true,
          ),
        (_orderSync, {for (final o in _orders) o.number: _orderDoc(o)}, true),
        (
          _quoteSync,
          {for (final q in _quoteRequests) q.reference: q.toJson()},
          true,
        ),
        (
          _enquirySync,
          {for (final e in _contactEnquiries) e.reference: e.toJson()},
          _role == 'Admin',
        ),
        (
          _employeeSync,
          {for (final e in _employees) employeeDocId(e): Map.of(e)},
          true,
        ),
        (
          _assignmentSync,
          {for (final a in _assignments) assignmentDocId(a): Map.of(a)},
          true,
        ),
      ];

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_applyingRemote) return;
    final cart = jsonEncode(_cart);
    final payload = Backend.isReady
        ? _payload()
        : <(CollectionSync, Map<String, Map<String, dynamic>>, bool)>[];
    _saves.add(() async {
      try {
        await _preferences?.setString(cartKey, cart);
        await Future.wait(<Future<int>>[
          for (final (sync, docs, deleteMissing) in payload)
            sync.push(docs, deleteMissing: deleteMissing),
        ]);
        storageError = null;
      } on FirebaseException catch (e) {
        storageError = e.code == 'permission-denied'
            ? 'You do not have permission to make that change.'
            : 'Changes could not be saved to the database (${e.code}).';
        _deferred.clear();
        // Re-read the authoritative records after a rejected write.
        await attach(role: _role, email: _email);
      } catch (_) {
        storageError = 'Changes could not be saved to the database.';
      }
      if (!_saves.busyAfterThis) {
        final pending = _deferred.values.toList();
        _deferred.clear();
        for (final apply in pending) {
          apply();
        }
      }
      super.notifyListeners();
    });
  }

  /// Starter records restored by the admin and loaded by the seed script.
  static List<ShopProduct> get starterProducts => _starterProducts;
  static List<Map<String, String>> get starterEmployees => [
    for (final (i, e) in _starterEmployees.indexed)
      {
        ...e,
        'organization': 'employer@mtalchemy.demo',
        'addedAt': '2026-09-0${i + 1}T09:00:00.000',
      },
  ];
  static List<Map<String, Object>> get starterAssignments => [
    for (final (i, a) in _starterAssignments.indexed)
      {
        ...a,
        'organization': 'employer@mtalchemy.demo',
        'assignedAt': '2026-09-1${i + 1}T09:00:00.000',
      },
  ];

  static const _starterProducts = <ShopProduct>[
    ShopProduct(
      id: 'clarity-workbook',
      name: 'Emotional Clarity Workbook',
      description:
          'A guided digital workbook with reflection prompts for emotional awareness and deliberate responses.',
      price: 29,
      category: 'Digital',
      icon: Icons.menu_book_outlined,
      digital: true,
      downloadAssetPath: 'assets/downloads/emotional_clarity_workbook.txt',
    ),
    ShopProduct(
      id: 'mindful-journal',
      name: 'Mindful Reflection Journal',
      description:
          'A printed journal designed to help individuals build a steady reflection practice.',
      price: 48,
      category: 'Physical',
      icon: Icons.auto_stories_outlined,
      imagePath: 'assets/images/impact_teachers_retreat.jpeg',
      stock: 35,
    ),
    ShopProduct(
      id: 'conversation-cards',
      name: 'Conversation Prompt Cards',
      description:
          'A physical set of prompts for connection and constructive team dialogue.',
      price: 65,
      category: 'Physical',
      icon: Icons.style_outlined,
      imagePath: 'assets/images/workshop_group_discussion.jpeg',
      stock: 18,
    ),
    ShopProduct(
      id: 'team-learning-kit',
      name: 'Team Learning Kit',
      description:
          'A practical activity kit for facilitated team learning and shared reflection.',
      price: 120,
      category: 'Physical',
      icon: Icons.groups_2_outlined,
      imagePath: 'assets/images/workshop_team_creativity.jpeg',
      stock: 12,
    ),
    ShopProduct(
      id: 'facilitator-guide',
      name: 'Facilitator Reflection Guide',
      description:
          'A downloadable guide with session planning notes and debrief questions.',
      price: 39,
      category: 'Digital',
      icon: Icons.description_outlined,
      digital: true,
      downloadAssetPath: 'assets/downloads/facilitator_reflection_guide.txt',
    ),
  ];
  static const _starterEmployees = <Map<String, String>>[
    {
      'name': 'Alicia Wong',
      'department': 'Human Resources',
      'email': 'alicia@example.com',
      'status': 'Active',
    },
    {
      'name': 'Daniel Lee',
      'department': 'Finance',
      'email': 'daniel@example.com',
      'status': 'Active',
    },
    {
      'name': 'Farah Nordin',
      'department': 'Management',
      'email': 'farah@example.com',
      'status': 'Active',
    },
  ];
  static const _starterAssignments = <Map<String, Object>>[
    {
      'course': 'Emotional Intelligence Fundamentals',
      'team': 'Human Resources',
      'employee': 'alicia@example.com',
      'due': '30 Oct 2026',
      'progress': 68,
      'score': 82,
      'hours': 12,
    },
    {
      'course': 'Leadership Essentials',
      'team': 'Management',
      'employee': 'farah@example.com',
      'due': '14 Nov 2026',
      'progress': 42,
      'score': 76,
      'hours': 8,
    },
  ];
  final List<ShopProduct> _products = [];
  final Map<String, int> _cart = {};
  final List<ShopOrder> _orders = [];
  final List<QuoteRequest> _quoteRequests = [];
  final List<ContactEnquiry> _contactEnquiries = [];
  final List<Map<String, String>> _employees = [];
  final List<Map<String, Object>> _assignments = [];

  List<ShopProduct> get products => List.unmodifiable(_products);
  List<ShopProduct> get publishedProducts =>
      _products.where((product) => product.published).toList();
  List<ShopOrder> get orders => List.unmodifiable(_orders);
  List<QuoteRequest> get quoteRequests => List.unmodifiable(_quoteRequests);
  List<ContactEnquiry> get contactEnquiries =>
      List.unmodifiable(_contactEnquiries);
  List<QuoteRequest> quoteRequestsFor(String email) => List.unmodifiable(
    _quoteRequests.where(
      (quote) =>
          (quote.ownerEmail ?? quote.email).toLowerCase() ==
          email.toLowerCase(),
    ),
  );
  List<ShopOrder> ordersFor(String email) => List.unmodifiable(
    _orders.where(
      (order) => order.customerEmail.toLowerCase() == email.toLowerCase(),
    ),
  );
  List<String> assignedCoursesFor(String email) => _assignments
      .where(
        (a) => (a['employee'] as String).toLowerCase() == email.toLowerCase(),
      )
      .map((a) => a['course'] as String)
      .toList();

  void updateLearningProgress(
    String email,
    String course,
    int progress, {
    int? score,
  }) {
    var changed = false;
    for (final assignment in _assignments) {
      if ((assignment['employee'] as String).toLowerCase() ==
              email.toLowerCase() &&
          assignment['course'] == course) {
        assignment['progress'] = progress;
        if (score != null) assignment['score'] = score;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  String? activeEmployer;
  bool _belongsToEmployer(Map record) =>
      (record['organization'] ?? 'employer@mtalchemy.demo') == activeEmployer;

  /// Every loaded record regardless of organization (admin views).
  List<Map<String, String>> get allEmployees => List.unmodifiable(_employees);
  List<Map<String, Object>> get allAssignments =>
      List.unmodifiable(_assignments);
  List<Map<String, String>> get employees =>
      List.unmodifiable(_employees.where(_belongsToEmployer));
  List<Map<String, Object>> get assignments =>
      List.unmodifiable(_assignments.where(_belongsToEmployer));
  int get cartCount => _cart.values.fold(0, (n, quantity) => n + quantity);
  int cartQuantityFor(String id) => _cart[id] ?? 0;
  bool canAddToCart(String id) {
    final product = productById(id);
    return product != null &&
        product.published &&
        (product.digital || cartQuantityFor(id) < product.stock);
  }

  List<CartLine> get cartLines => _cart.entries
      .map((entry) {
        final product = productById(entry.key);
        return product == null
            ? null
            : CartLine(product: product, quantity: entry.value);
      })
      .whereType<CartLine>()
      .toList();
  double get subtotal => cartLines.fold(0, (acc, line) => acc + line.subtotal);
  bool get cartHasPhysical => cartLines.any((line) => !line.product.digital);
  double get shipping => cartHasPhysical && cartLines.isNotEmpty ? 10 : 0;
  double get total => subtotal + shipping;
  List<ShopOrder> get digitalOrders => _orders
      .where((order) => order.hasDigital && order.paymentStatus == 'Paid')
      .toList();
  List<ShopOrder> digitalOrdersFor(String email) => _orders
      .where(
        (order) =>
            order.customerEmail.toLowerCase() == email.toLowerCase() &&
            order.lines.any((l) => l.product.digital && !isCourseLine(l)) &&
            order.paymentStatus == 'Paid',
      )
      .toList();

  ShopOrder? orderByNumber(String? number) {
    for (final order in _orders) {
      if (order.number == number) return order;
    }
    return null;
  }

  /// A course sold as a digital line item (individual purchase or seats).
  static ShopProduct courseProduct({
    required String courseId,
    required String title,
    required double price,
  }) => ShopProduct(
    id: 'course:$courseId',
    name: title,
    description: 'Online course: $title',
    price: price,
    category: 'Course',
    icon: Icons.school_outlined,
    digital: true,
    stock: 0,
  );

  static bool isCourseLine(CartLine line) => line.product.category == 'Course';

  /// Course ids the account has paid for.
  Set<String> paidCourseIdsFor(String email) => {
    for (final o in ordersFor(email))
      if (o.paymentStatus == 'Paid')
        for (final l in o.lines)
          if (isCourseLine(l)) l.product.id.substring('course:'.length),
  };

  /// Paid seats per course title for the active employer.
  Map<String, int> purchasedSeats() {
    final seats = <String, int>{};
    final employer = activeEmployer;
    if (employer == null) return seats;
    for (final o in ordersFor(employer)) {
      if (o.paymentStatus != 'Paid') continue;
      for (final l in o.lines.where(isCourseLine)) {
        seats[l.product.name] = (seats[l.product.name] ?? 0) + l.quantity;
      }
    }
    return seats;
  }

  int assignedSeats(String courseTitle) =>
      assignments.where((a) => a['course'] == courseTitle).length;

  ShopProduct? productById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  QuoteRequest createQuoteRequest({
    required String customerName,
    required String organizationName,
    required String email,
    required String phone,
    required List<CartLine> lines,
    required String requirements,
    String? ownerEmail,
  }) {
    final quote = QuoteRequest(
      reference:
          'QT${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      createdAt: DateTime.now(),
      customerName: customerName,
      organizationName: organizationName,
      email: email,
      phone: phone,
      lines: List.unmodifiable(lines),
      requirements: requirements,
      ownerEmail: ownerEmail?.toLowerCase() ?? _email,
    );
    _quoteRequests.insert(0, quote);
    notifyListeners();
    return quote;
  }

  void updateQuoteRequest(
    String reference, {
    required String status,
    double? quotedTotal,
    String? adminNote,
  }) {
    final index = _quoteRequests.indexWhere(
      (quote) => quote.reference == reference,
    );
    if (index < 0) return;
    _quoteRequests[index] = _quoteRequests[index].copyWith(
      status: status,
      quotedTotal: quotedTotal,
      adminNote: adminNote,
    );
    notifyListeners();
  }

  ContactEnquiry createContactEnquiry({
    required String name,
    required String email,
    required String phone,
    required String organization,
    required String enquiryType,
    required String message,
  }) {
    final now = DateTime.now();
    final enquiry = ContactEnquiry(
      reference: 'EN${now.millisecondsSinceEpoch.toString().substring(5)}',
      createdAt: now,
      name: name,
      email: email,
      phone: phone,
      organization: organization,
      enquiryType: enquiryType,
      message: message,
    );
    _contactEnquiries.insert(0, enquiry);
    notifyListeners();
    return enquiry;
  }

  void updateContactEnquiry(
    String reference, {
    required String status,
    String? adminNote,
  }) {
    final index = _contactEnquiries.indexWhere(
      (enquiry) => enquiry.reference == reference,
    );
    if (index < 0) return;
    _contactEnquiries[index] = _contactEnquiries[index].copyWith(
      status: status,
      adminNote: adminNote,
    );
    notifyListeners();
  }

  void addToCart(String id) {
    final product = productById(id);
    if (!canAddToCart(id) || product == null) return;
    final count = _cart[id] ?? 0;
    if (!product.digital && count >= product.stock) return;
    _cart[id] = count + 1;
    notifyListeners();
  }

  void setQuantity(String id, int quantity) {
    if (quantity <= 0) {
      _cart.remove(id);
    } else {
      final product = productById(id);
      if (product == null) return;
      if (!product.digital && product.stock <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = product.digital
            ? quantity
            : quantity.clamp(1, product.stock).toInt();
      }
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cart.remove(id);
    notifyListeners();
  }

  ShopOrder? placeOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String billingAddress,
    required String address,
    required String paymentMethod,
    String paymentStatus = 'Pending',
    List<CartLine>? items,
  }) {
    // [items] buys something outside the cart (a course or course seats).
    final fromCart = items == null;
    final lines = items ?? cartLines;
    if (lines.isEmpty) return null;
    final hasPhysical = lines.any((line) => !line.product.digital);
    final subtotalAmount = lines.fold<double>(0, (t, l) => t + l.subtotal);
    final failed = paymentStatus == 'Failed';
    final paid = paymentStatus == 'Paid';
    if (lines.any(
      (line) =>
          !line.product.published ||
          (!line.product.digital && line.quantity > line.product.stock),
    )) {
      return null;
    }
    final order = ShopOrder(
      number: 'MA${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
      lines: List.unmodifiable(lines),
      total: subtotalAmount + (hasPhysical ? 10 : 0),
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      fulfilmentStatus: paid
          ? (hasPhysical ? 'Processing' : 'Available')
          : 'Pending',
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      billingAddress: billingAddress,
      shippingAddress: hasPhysical ? address : null,
      stockReserved: hasPhysical && !failed,
    );
    for (final line in lines.where(
      (line) => !line.product.digital && !failed,
    )) {
      final index = _products.indexWhere(
        (product) => product.id == line.product.id,
      );
      if (index >= 0) {
        _products[index] = _products[index].copyWith(
          stock: _products[index].stock - line.quantity,
        );
      }
    }
    _orders.insert(0, order);
    // A failed payment keeps the cart so the customer can try again.
    if (fromCart && !failed) _cart.clear();
    if (Backend.isReady && _role != 'Admin') {
      // Customers create the order and reserve stock in one atomic batch;
      // a stock decrement that would go below zero rejects the whole order.
      final doc = _orderDoc(order);
      _orderSync.markSynced(order.number, doc);
      final physical = failed
          ? <CartLine>[]
          : lines.where((line) => !line.product.digital).toList();
      _saves.add(() async {
        try {
          final batch = Backend.db.batch();
          batch.set(
            _orderSync.ref.doc(CollectionSync.docId(order.number)),
            doc,
          );
          for (final line in physical) {
            batch.update(_productSync.ref.doc(line.product.id), {
              'stock': FieldValue.increment(-line.quantity),
            });
          }
          await batch.commit();
        } on FirebaseException catch (e) {
          storageError = e.code == 'permission-denied'
              ? 'Your order could not be placed because an item is out of stock. Please review your cart.'
              : 'Your order could not be saved (${e.code}). Please try again.';
          await attach(role: _role, email: _email);
        }
      });
    }
    notifyListeners();
    return order;
  }

  void addEmployee({
    required String name,
    required String department,
    required String email,
  }) {
    if (activeEmployer == null ||
        employees.any(
          (e) => e['email']!.toLowerCase() == email.trim().toLowerCase(),
        )) {
      return;
    }
    _employees.add({
      'organization': activeEmployer!,
      'name': name,
      'department': department,
      'email': email.trim().toLowerCase(),
      'status': 'Invited',
      'addedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void removeEmployee(String email) {
    _employees.removeWhere(
      (employee) => employee['email'] == email && _belongsToEmployer(employee),
    );
    _assignments.removeWhere(
      (assignment) =>
          assignment['employee'] == email && _belongsToEmployer(assignment),
    );
    notifyListeners();
  }

  void assignCourse({
    required String course,
    required String team,
    required String due,
    required String employeeEmail,
  }) {
    if (activeEmployer == null ||
        !employees.any((e) => e['email'] == employeeEmail)) {
      return;
    }
    if (assignments.any(
      (a) => a['employee'] == employeeEmail && a['course'] == course,
    )) {
      return;
    }
    _assignments.insert(0, {
      'organization': activeEmployer!,
      'course': course,
      'team': team,
      'due': due,
      'employee': employeeEmail,
      'progress': 0,
      'score': 0,
      'hours': 0,
      'assignedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void toggleProductPublished(String id) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    _products[index] = _products[index].copyWith(
      published: !_products[index].published,
    );
    if (!_products[index].published) _cart.remove(id);
    notifyListeners();
  }

  void adjustStock(String id, int amount) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index < 0 || _products[index].digital) return;
    _products[index] = _products[index].copyWith(
      stock: (_products[index].stock + amount).clamp(0, 9999).toInt(),
    );
    notifyListeners();
  }

  void addProduct({
    required String name,
    required double price,
    required bool digital,
    String? imagePath,
    Uint8List? imageBytes,
    String? downloadAssetPath,
    String? description,
    int stock = 10,
  }) {
    _products.add(
      ShopProduct(
        id: 'product-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description:
            description ??
            'A new ${digital ? 'digital' : 'physical'} MT Alchemy product.',
        price: price,
        category: digital ? 'Digital' : 'Physical',
        icon: digital ? Icons.download_outlined : Icons.inventory_2_outlined,
        imagePath: imagePath,
        imageBytes: imageBytes,
        downloadAssetPath: digital ? downloadAssetPath : null,
        digital: digital,
        stock: digital ? 0 : stock,
      ),
    );
    notifyListeners();
  }

  void updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required bool digital,
    required String imagePath,
    Uint8List? imageBytes,
    required String? downloadAssetPath,
    required int stock,
  }) {
    final index = _products.indexWhere((product) => product.id == id);
    if (index < 0) return;
    final current = _products[index];
    _products[index] = current.copyWith(
      name: name,
      description: description,
      price: price,
      category: digital ? 'Digital' : 'Physical',
      digital: digital,
      imagePath: imagePath,
      imageBytes: imageBytes,
      clearImagePath: imagePath.isEmpty,
      clearImageBytes: imageBytes == null,
      downloadAssetPath: downloadAssetPath,
      stock: digital ? 0 : stock,
    );
    notifyListeners();
  }

  void deleteProduct(String id) {
    _products.removeWhere((product) => product.id == id);
    _cart.remove(id);
    notifyListeners();
  }

  void resetDemoData() {
    _products
      ..clear()
      ..addAll(_starterProducts);
    _cart.clear();
    _orders.clear();
    _quoteRequests.clear();
    _contactEnquiries.clear();
    _employees
      ..clear()
      ..addAll(starterEmployees);
    _assignments
      ..clear()
      ..addAll(starterAssignments);
    notifyListeners();
  }

  void updateOrderStatus(String number, String status) {
    final index = _orders.indexWhere((order) => order.number == number);
    if (index < 0) return;
    final previous = _orders[index];
    if (previous.hasPhysical) {
      final allowed = switch (previous.fulfilmentStatus) {
        'Pending' => {'Pending', 'Processing'},
        'Processing' => {'Processing', 'Shipped'},
        'Shipped' => {'Shipped', 'Delivered'},
        'Delivered' => {'Delivered'},
        _ => <String>{},
      };
      if (previous.paymentStatus != 'Paid' && status != 'Pending') return;
      if (!allowed.contains(status)) return;
    } else if (status != 'Pending' && status != 'Available') {
      return;
    }
    _orders[index] = ShopOrder(
      number: previous.number,
      date: previous.date,
      lines: previous.lines,
      total: previous.total,
      paymentStatus: previous.paymentStatus,
      paymentMethod: previous.paymentMethod,
      fulfilmentStatus: status,
      customerName: previous.customerName,
      customerEmail: previous.customerEmail,
      customerPhone: previous.customerPhone,
      billingAddress: previous.billingAddress,
      shippingAddress: previous.shippingAddress,
      trackingNumber: status == 'Shipped'
          ? 'MT-${number.substring(number.length - 6)}'
          : previous.trackingNumber,
      stockReserved: previous.stockReserved,
    );
    notifyListeners();
  }

  /// Marks the signed-in customer's own pending order as paid once the
  /// payment server has confirmed it with Stripe.
  Future<bool> confirmCustomerPayment(String number, String method) async {
    final index = _orders.indexWhere((order) => order.number == number);
    if (index < 0) return false;
    final o = _orders[index];
    if (o.paymentStatus == 'Paid') return true;
    final fulfilment = o.hasPhysical ? 'Processing' : 'Available';
    final updated = ShopOrder(
      number: o.number,
      date: o.date,
      lines: o.lines,
      total: o.total,
      paymentStatus: 'Paid',
      paymentMethod: method,
      fulfilmentStatus: fulfilment,
      customerName: o.customerName,
      customerEmail: o.customerEmail,
      customerPhone: o.customerPhone,
      billingAddress: o.billingAddress,
      shippingAddress: o.shippingAddress,
      trackingNumber: o.trackingNumber,
      stockReserved: o.stockReserved,
    );
    _orders[index] = updated;
    _orderSync.markSynced(number, _orderDoc(updated));
    super.notifyListeners();
    if (!Backend.isReady) return true;
    try {
      await _orderSync.ref.doc(CollectionSync.docId(number)).update({
        'paymentStatus': 'Paid',
        'fulfilmentStatus': fulfilment,
        'paymentMethod': method,
      });
      return true;
    } catch (_) {
      storageError =
          'Your payment succeeded but the order could not be updated. Contact MT Alchemy with order $number.';
      super.notifyListeners();
      return false;
    }
  }

  bool updatePaymentStatus(String number, String status) {
    final index = _orders.indexWhere((order) => order.number == number);
    if (index < 0) return false;
    final previous = _orders[index];
    // A paid order cannot be downgraded in this prototype: refunds and
    // post-dispatch stock adjustments require a real payment/fulfilment flow.
    if (previous.paymentStatus == 'Paid' && status != 'Paid') return false;
    if (!{'Pending', 'Paid', 'Failed'}.contains(status)) return false;
    var stockReserved = previous.stockReserved;
    if (previous.hasPhysical && status == 'Failed' && stockReserved) {
      for (final line in previous.lines.where(
        (line) => !line.product.digital,
      )) {
        final productIndex = _products.indexWhere(
          (product) => product.id == line.product.id,
        );
        if (productIndex >= 0) {
          _products[productIndex] = _products[productIndex].copyWith(
            stock: _products[productIndex].stock + line.quantity,
          );
        }
      }
      stockReserved = false;
    } else if (previous.hasPhysical && status != 'Failed' && !stockReserved) {
      final physicalLines = previous.lines
          .where((line) => !line.product.digital)
          .toList();
      final canReserve = physicalLines.every((line) {
        final product = productById(line.product.id);
        return product != null && product.stock >= line.quantity;
      });
      if (!canReserve) {
        // Rebuild dropdowns from the persisted status after a rejected change.
        notifyListeners();
        return false;
      }
      for (final line in physicalLines) {
        final productIndex = _products.indexWhere(
          (product) => product.id == line.product.id,
        );
        if (productIndex >= 0) {
          _products[productIndex] = _products[productIndex].copyWith(
            stock: _products[productIndex].stock - line.quantity,
          );
        }
      }
      stockReserved = true;
    }
    final nextFulfilment = status == 'Paid'
        ? previous.paymentStatus == 'Paid'
              ? previous.fulfilmentStatus
              : previous.hasPhysical
              ? 'Processing'
              : 'Available'
        : status == 'Failed'
        ? 'Pending'
        : previous.fulfilmentStatus;
    _orders[index] = ShopOrder(
      number: previous.number,
      date: previous.date,
      lines: previous.lines,
      total: previous.total,
      paymentStatus: status,
      paymentMethod: previous.paymentMethod,
      fulfilmentStatus: nextFulfilment,
      customerName: previous.customerName,
      customerEmail: previous.customerEmail,
      customerPhone: previous.customerPhone,
      billingAddress: previous.billingAddress,
      shippingAddress: previous.shippingAddress,
      trackingNumber: previous.trackingNumber,
      stockReserved: stockReserved,
    );
    notifyListeners();
    return true;
  }
}

String money(double value) => 'RM ${value.toStringAsFixed(2)}';

import 'package:flutter/material.dart';

import '../../backend/backend.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Records an issued certificate so anyone can verify it by ID or QR code.
Future<void> recordCertificate({
  required String certificateId,
  required String learnerName,
  required String learnerEmail,
  required String courseId,
  required String courseTitle,
  required String trainer,
  required String completedOn,
}) async {
  if (!Backend.isReady) return;
  try {
    await Backend.db.collection('certificates').doc(certificateId).set({
      'certificateId': certificateId,
      'learnerName': learnerName,
      'learnerEmail': learnerEmail,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'trainer': trainer,
      'completedOn': completedOn,
      'issuer': 'MT Alchemy',
      'issuedAt': DateTime.now().toIso8601String(),
    });
  } catch (_) {
    /* Already recorded, or offline: the certificate still displays. */
  }
}

String certificateVerifyUrl(String id) {
  final base = Uri.base;
  return '${base.origin}${base.path}#/verify?id=${Uri.encodeComponent(id)}';
}

/// Public certificate verification page (`/verify?id=...`).
class CertificateVerifyPage extends StatefulWidget {
  const CertificateVerifyPage({super.key, this.initialId});
  final String? initialId;

  @override
  State<CertificateVerifyPage> createState() => _CertificateVerifyPageState();
}

class _CertificateVerifyPageState extends State<CertificateVerifyPage> {
  late final _id = TextEditingController(text: widget.initialId ?? '');
  Map<String, dynamic>? _result;
  bool _checked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialId ?? '').isNotEmpty) _check();
  }

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final id = _id.text.trim().toUpperCase();
    if (id.isEmpty) return;
    setState(() => _busy = true);
    Map<String, dynamic>? data;
    try {
      data = (await Backend.db.collection('certificates').doc(id).get()).data();
    } catch (_) {
      data = null;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _checked = true;
      _result = data;
    });
  }

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Eyebrow('Certificate verification'),
              const SizedBox(height: 10),
              Text(
                'Check an MT Alchemy certificate.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _id,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Certificate ID',
                        hintText: 'MTA-2026-…',
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                      onSubmitted: (_) => _check(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _busy ? null : _check,
                    child: Text(_busy ? 'Checking…' : 'Verify'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_checked)
                _result == null
                    ? const InfoCard(
                        color: Color(0xFFFDECEC),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              color: Color(0xFFB3261E),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No certificate was found with this ID. Check the ID and try again.',
                              ),
                            ),
                          ],
                        ),
                      )
                    : InfoCard(
                        color: const Color(0xFFE6F4EA),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Color(0xFF1E6B34)),
                                SizedBox(width: 10),
                                Text(
                                  'Valid certificate',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E6B34),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            for (final (label, key) in const [
                              ('Awarded to', 'learnerName'),
                              ('Course', 'courseTitle'),
                              ('Completed on', 'completedOn'),
                              ('Trainer', 'trainer'),
                              ('Issued by', 'issuer'),
                              ('Certificate ID', 'certificateId'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$label: ',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${_result![key] ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: deepBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
            ],
          ),
        ),
      ),
    ),
  );
}

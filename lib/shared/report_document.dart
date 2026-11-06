import 'dart:convert';
import 'dart:typed_data';

/// Creates a multi-page PDF report using the built-in Helvetica text font.
Uint8List createReportPdf(List<String> reportLines) {
  String clean(String value) => value
      .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ')
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');

  final wrapped = reportLines.expand((line) {
    final printable = clean(line);
    if (printable.length <= 90) return [printable];
    return [
      for (var start = 0; start < printable.length; start += 90)
        printable.substring(
          start,
          (start + 90).clamp(0, printable.length).toInt(),
        ),
    ];
  }).toList();
  final title = wrapped.isEmpty ? 'MT Alchemy Report' : wrapped.first;
  final rows = wrapped.skip(1).toList();
  final pageCount = rows.isEmpty ? 1 : (rows.length / 42).ceil();
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [${List.generate(pageCount, (i) => '${3 + i * 3} 0 R').join(' ')}] /Count $pageCount >>',
  ];

  for (var page = 0; page < pageCount; page++) {
    final pageId = 3 + page * 3;
    final fontId = pageId + 1;
    final streamId = pageId + 2;
    final pageRows = rows.skip(page * 42).take(42);
    final content = StringBuffer('BT\n/F1 16 Tf\n48 790 Td\n')
      ..writeln('(${page == 0 ? title : '$title - continued'}) Tj')
      ..writeln('/F1 9 Tf\n0 -24 Td');
    for (final row in pageRows) {
      content
        ..writeln('(${row.isEmpty ? ' ' : row}) Tj')
        ..writeln('0 -16 Td');
    }
    content.write('ET');
    final stream = content.toString();
    objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 $fontId 0 R >> >> /Contents $streamId 0 R >>',
    );
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
    objects.add(
      '<< /Length ${ascii.encode(stream).length} >>\nstream\n$stream\nendstream',
    );
  }

  final output = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(ascii.encode(output.toString()).length);
    output.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xrefOffset = ascii.encode(output.toString()).length;
  output.write('xref\n0 ${objects.length + 1}\n');
  output.write('0000000000 65535 f \n');
  for (final offset in offsets.skip(1)) {
    output.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  output.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF',
  );
  return Uint8List.fromList(ascii.encode(output.toString()));
}

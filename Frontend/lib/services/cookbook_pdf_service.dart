import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/meal_detail.dart';
import '../screens/cooking_mode_screen.dart' show splitInstructionsIntoSteps;

/// A single recipe ready to be rendered into the cookbook.
class CookbookRecipe {
  final MealDetail detail;
  final String noteTitle;
  final String noteBody;
  final Uint8List? imageBytes;

  const CookbookRecipe({
    required this.detail,
    required this.noteTitle,
    required this.noteBody,
    this.imageBytes,
  });
}

/// Builds the cookbook PDF and fetches the image bytes for each recipe.
///
/// The layout is editorial — a cover page, a table of contents, then one
/// flowing spread per recipe with running headers and page numbers.
class CookbookPdfService {
  Future<Uint8List?> fetchImageBytes(String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> buildPdf(List<CookbookRecipe> recipes) async {
    final theme = pw.ThemeData(
      defaultTextStyle: pw.TextStyle(color: _ink, fontSize: 11, lineSpacing: 3),
    );

    final doc = pw.Document(
      title: 'My TerraBite Cookbook',
      author: 'TerraBite',
      theme: theme,
    );

    doc.addPage(_buildCover(recipes.length));
    if (recipes.isNotEmpty) {
      doc.addPage(_buildTableOfContents(recipes));
    }
    for (var i = 0; i < recipes.length; i++) {
      doc.addPage(_buildRecipe(recipes[i], i + 1, recipes.length));
    }
    return doc.save();
  }

  // ── Cover page ─────────────────────────────────────────────────────────

  pw.Page _buildCover(int count) {
    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            // Cream background
            pw.Positioned.fill(child: pw.Container(color: _cream)),

            // Dark corner band — gives the cover an editorial feel.
            pw.Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: pw.Container(height: 240, color: _ink),
            ),

            // Orange accent ribbon between the dark band and the body.
            pw.Positioned(
              top: 240,
              left: 0,
              right: 0,
              child: pw.Container(height: 6, color: _orange),
            ),

            // Top brand mark
            pw.Positioned(
              top: 60,
              left: 56,
              right: 56,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TERRABITE',
                    style: pw.TextStyle(
                      color: _lime,
                      fontSize: 14,
                      letterSpacing: 3,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(width: 8, height: 8, color: _lime),
                ],
              ),
            ),

            // Body
            pw.Positioned(
              top: 300,
              left: 56,
              right: 56,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'A PERSONAL COLLECTION',
                    style: pw.TextStyle(
                      color: _orange,
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Text(
                    'My Cookbook',
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 72,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.timesBold(),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(width: 80, height: 4, color: _orange),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    '$count ${count == 1 ? 'recipe' : 'recipes'} '
                    'curated by you — printed from TerraBite.',
                    style: pw.TextStyle(
                      color: _muted,
                      fontSize: 14,
                      lineSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            pw.Positioned(
              left: 56,
              right: 56,
              bottom: 60,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 60, height: 2, color: _ink),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PREMIUM RECIPES · NO SHORTCUTS',
                        style: pw.TextStyle(
                          color: _ink,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        _today(),
                        style: pw.TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Table of contents ──────────────────────────────────────────────────

  pw.Page _buildTableOfContents(List<CookbookRecipe> recipes) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(56, 56, 56, 56),
      header: (c) => _runningHeader('Contents'),
      footer: _footer,
      build: (context) => [
        pw.Text(
          'CONTENTS',
          style: pw.TextStyle(
            color: _orange,
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Recipes',
          style: pw.TextStyle(
            color: _ink,
            fontSize: 42,
            fontWeight: pw.FontWeight.bold,
            font: pw.Font.timesBold(),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(width: 60, height: 3, color: _orange),
        pw.SizedBox(height: 28),
        for (var i = 0; i < recipes.length; i++)
          _tocRow(i + 1, recipes[i]),
      ],
    );
  }

  pw.Widget _tocRow(int n, CookbookRecipe r) {
    final subtitle = [
      if (r.detail.category.isNotEmpty) r.detail.category,
      if (r.detail.area.isNotEmpty) r.detail.area,
    ].join(' · ');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 36,
            child: pw.Text(
              n.toString().padLeft(2, '0'),
              style: pw.TextStyle(
                color: _orange,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                font: pw.Font.timesBold(),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  r.detail.name,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recipe page ────────────────────────────────────────────────────────

  pw.Page _buildRecipe(CookbookRecipe r, int index, int total) {
    final d = r.detail;
    final steps = splitInstructionsIntoSteps(d.instructions);
    final eyebrow = [
      'Recipe No. ${index.toString().padLeft(2, '0')}',
      if (d.category.isNotEmpty) d.category.toUpperCase(),
    ].join('  ·  ');

    return pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(56, 48, 56, 48),
      header: (c) => _runningHeader(d.name),
      footer: _footer,
      build: (context) => [
        // Hero image
        if (r.imageBytes != null) ...[
          pw.ClipRRect(
            horizontalRadius: 10,
            verticalRadius: 10,
            child: pw.Image(
              pw.MemoryImage(r.imageBytes!),
              fit: pw.BoxFit.cover,
              height: 230,
              width: double.infinity,
            ),
          ),
          pw.SizedBox(height: 22),
        ],

        // Eyebrow
        pw.Text(
          eyebrow,
          style: pw.TextStyle(
            color: _orange,
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),

        // Title
        pw.Text(
          d.name,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 34,
            fontWeight: pw.FontWeight.bold,
            font: pw.Font.timesBold(),
            lineSpacing: 2,
          ),
        ),

        // Subtitle
        if (d.area.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            d.area,
            style: pw.TextStyle(
              color: _muted,
              fontSize: 13,
              font: pw.Font.timesItalic(),
            ),
          ),
        ],

        pw.SizedBox(height: 14),
        pw.Container(width: 50, height: 2, color: _ink),

        // Notes block
        if (r.noteTitle.isNotEmpty || r.noteBody.isNotEmpty) ...[
          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(18, 14, 14, 14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF9F4E8),
              border: pw.Border(
                left: pw.BorderSide(color: _orange, width: 3),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'YOUR NOTES',
                  style: pw.TextStyle(
                    color: _orange,
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (r.noteTitle.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    r.noteTitle,
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
                if (r.noteBody.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    r.noteBody,
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 11,
                      lineSpacing: 4,
                      font: pw.Font.timesItalic(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // INGREDIENTS — two columns
        pw.SizedBox(height: 28),
        _sectionHeading('Ingredients'),
        pw.SizedBox(height: 12),
        _ingredientsColumns(d.ingredients.map((i) => i.toString()).toList()),

        // METHOD — numbered steps
        pw.SizedBox(height: 28),
        _sectionHeading('Method'),
        pw.SizedBox(height: 12),
        if (steps.isEmpty)
          pw.Text(
            d.instructions,
            style: pw.TextStyle(color: _ink, fontSize: 11, lineSpacing: 4),
          )
        else
          for (var i = 0; i < steps.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 28,
                    height: 28,
                    margin: const pw.EdgeInsets.only(right: 14),
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: _orange,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Text(
                      '${i + 1}',
                      style: pw.TextStyle(
                        color: _cream,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.timesBold(),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        steps[i],
                        style: pw.TextStyle(
                          color: _ink,
                          fontSize: 11,
                          lineSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  /// Ingredients laid out across two balanced columns.
  pw.Widget _ingredientsColumns(List<String> items) {
    if (items.isEmpty) return pw.SizedBox.shrink();
    final mid = (items.length / 2).ceil();
    final left = items.sublist(0, mid);
    final right = items.length > mid ? items.sublist(mid) : <String>[];

    pw.Widget col(List<String> entries) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final ing in entries)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5, right: 8),
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(
                    color: _orange,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    ing,
                    style: pw.TextStyle(
                      color: _ink,
                      fontSize: 11,
                      lineSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: col(left)),
        pw.SizedBox(width: 20),
        pw.Expanded(child: col(right)),
      ],
    );
  }

  pw.Widget _sectionHeading(String label) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            font: pw.Font.timesBold(),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(height: 1, color: PdfColor.fromInt(0xFFD9CFB6)),
        ),
      ],
    );
  }

  // ── Running header / footer ────────────────────────────────────────────

  pw.Widget _runningHeader(String rightLabel) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 18),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9CFB6),
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TERRABITE COOKBOOK',
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            rightLabel.toUpperCase(),
            style: pw.TextStyle(
              color: _muted,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromInt(0xFFD9CFB6),
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TerraBite',
            style: pw.TextStyle(
              color: _muted,
              fontSize: 9,
              font: pw.Font.timesItalic(),
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(color: _muted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _today() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final d = DateTime.now();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Palette ────────────────────────────────────────────────────────────
const PdfColor _ink = PdfColor.fromInt(0xFF1A1208);
const PdfColor _cream = PdfColor.fromInt(0xFFF5F0E8);
const PdfColor _muted = PdfColor.fromInt(0xFF7A6A50);
const PdfColor _orange = PdfColor.fromInt(0xFFB23A1F);
const PdfColor _lime = PdfColor.fromInt(0xFFC9D640);

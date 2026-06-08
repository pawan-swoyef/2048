// Pushes the Play Store listing (title, short + full description) AND the
// listing graphics (icon, feature graphic, screenshots) to the Google Play
// Console via the Play Developer API (androidpublisher v3), in one atomic edit.
//
// Sources of truth:
//   - text:   docs/store-listing.md
//   - images: docs/store-assets/  (see that folder's README for names/sizes)
//
// What it does NOT touch: category, content rating, data safety, privacy-policy
// URL — those aren't part of the API and must be set in the Play Console UI.
//
// Usage (from this folder, tool/play_publish):
//   dart pub get
//   dart run bin/push_listing.dart            # dry-run: validate only, no network
//   dart run bin/push_listing.dart --commit   # authenticate and actually push
//   dart run bin/push_listing.dart --commit --no-images   # text only
//
// See README.md in this folder for the one-time Play Console / GCP setup.

import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:googleapis/androidpublisher/v3.dart'; // also exports Media
import 'package:googleapis_auth/auth_io.dart';
import 'package:image/image.dart' as img;

// Play's required exact size for the hi-res store icon.
const int kIconSide = 512;

// Play Console hard limits for the en-US listing text fields.
const int kTitleMax = 30;
const int kShortMax = 80;
const int kFullMax = 4000;

/// One uploadable image slot in the store listing.
class ImageSlot {
  ImageSlot(this.imageType, this.files, {this.expected});

  /// Play API imageType: icon, featureGraphic, phoneScreenshots, etc.
  final String imageType;

  /// Files to upload, already in display order.
  final List<File> files;

  /// Required exact dimensions for single-image slots, else null.
  final ({int w, int h})? expected;
}

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('key',
        help: 'Path to the service-account JSON key.',
        defaultsTo: '../../secretandstunts-e3a3e3c488d4.json')
    ..addOption('listing',
        help: 'Path to the store-listing markdown.',
        defaultsTo: '../../docs/store-listing.md')
    ..addOption('assets',
        help: 'Folder with listing graphics.',
        defaultsTo: '../../docs/store-assets')
    ..addOption('package',
        help: 'Android applicationId.', defaultsTo: 'com.number.twofoureight')
    ..addOption('language',
        help: 'BCP-47 listing language.', defaultsTo: 'en-US')
    ..addFlag('commit',
        negatable: false,
        help: 'Actually push to Play. Without this it only validates.')
    ..addFlag('no-images',
        negatable: false, help: 'Push the text listing only, skip graphics.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (args['help'] as bool) {
    stdout.writeln('Push the Play Store listing (text + graphics).\n');
    stdout.writeln(parser.usage);
    return;
  }

  // ---- Parse + validate the text listing ----
  final listingPath = args['listing'] as String;
  final listingFile = File(listingPath);
  if (!listingFile.existsSync()) {
    _fail('Listing file not found: $listingPath');
  }
  final listing = _parseListing(listingFile.readAsStringSync());

  final problems = <String>[];
  _check(problems, 'App title', listing.title, kTitleMax);
  _check(problems, 'Short description', listing.shortDescription, kShortMax);
  _check(problems, 'Full description', listing.fullDescription, kFullMax);
  if (problems.isNotEmpty) {
    _fail('Listing content is invalid:\n  - ${problems.join('\n  - ')}');
  }

  final pkg = args['package'] as String;
  final lang = args['language'] as String;

  stdout.writeln('Listing parsed OK from $listingPath');
  stdout.writeln('  package:  $pkg');
  stdout.writeln('  language: $lang');
  stdout.writeln('  title         (${listing.title!.length}/$kTitleMax): '
      '${listing.title}');
  stdout.writeln('  short desc    (${listing.shortDescription!.length}/'
      '$kShortMax): ${listing.shortDescription}');
  stdout.writeln(
      '  full desc     (${listing.fullDescription!.length}/$kFullMax chars)');

  // ---- Collect + report the images ----
  final includeImages = !(args['no-images'] as bool);
  var slots = <ImageSlot>[];
  if (includeImages) {
    slots = _collectImages(args['assets'] as String);
    _reportImages(args['assets'] as String, slots);
  } else {
    stdout.writeln('\nImages: skipped (--no-images).');
  }

  if (!(args['commit'] as bool)) {
    stdout.writeln(
        '\nDRY RUN — nothing sent. Re-run with --commit to push to Play.');
    return;
  }

  // ---- Real push from here on ----
  final keyPath = args['key'] as String;
  final keyFile = File(keyPath);
  if (!keyFile.existsSync()) {
    _fail('Service-account key not found: $keyPath');
  }
  final credentials =
      ServiceAccountCredentials.fromJson(keyFile.readAsStringSync());

  stdout.writeln('\nAuthenticating with Google...');
  final client = await clientViaServiceAccount(
      credentials, [AndroidPublisherApi.androidpublisherScope]);

  try {
    final api = AndroidPublisherApi(client);

    stdout.writeln('Opening a new edit for $pkg...');
    final edit = await api.edits.insert(AppEdit(), pkg);
    final editId = edit.id!;

    stdout.writeln('Updating the $lang listing text...');
    listing.language = lang;
    await api.edits.listings.update(listing, pkg, editId, lang);

    if (slots.isNotEmpty) {
      for (final slot in slots) {
        // Replace whatever is currently in this slot, then upload in order.
        await api.edits.images.deleteall(pkg, editId, lang, slot.imageType);
        for (final file in slot.files) {
          stdout.writeln(
              '  uploading ${slot.imageType}: ${_short(file.path)}');
          final (bytes, contentType) = _bytesForUpload(slot, file);
          final media =
              Media(Stream.value(bytes), bytes.length, contentType: contentType);
          await api.edits.images
              .upload(pkg, editId, lang, slot.imageType, uploadMedia: media);
        }
      }
    }

    stdout.writeln('Committing the edit...');
    await api.edits.commit(pkg, editId);

    stdout.writeln('\n✅ Done — store listing pushed to Play Console.');
    stdout.writeln('   Open Play Console > Grow > Store presence > '
        'Main store listing to review.');
  } on DetailedApiRequestError catch (e) {
    _handleApiError(e, pkg);
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Text listing
// ---------------------------------------------------------------------------

/// Extracts the title / short / full sections from the listing markdown.
Listing _parseListing(String md) {
  final lines = md.split('\n');
  final sections = <String, List<String>>{};
  String? current;

  for (final line in lines) {
    final heading = _headingText(line);
    if (heading != null) {
      current = _labelFor(heading);
      if (current != null) sections[current] = <String>[];
      continue;
    }
    if (current != null && sections.containsKey(current)) {
      sections[current]!.add(line);
    }
  }

  String? body(String label) {
    final raw = sections[label];
    if (raw == null) return null;
    final text = raw.join('\n').trim();
    return text.isEmpty ? null : text;
  }

  final title = body('title');
  final short = body('short');
  final full = body('full');

  final missing = <String>[
    if (title == null) 'App title',
    if (short == null) 'Short description',
    if (full == null) 'Full description',
  ];
  if (missing.isNotEmpty) {
    _fail('Could not find these sections in the markdown: '
        '${missing.join(', ')}.\n'
        'Expected "## App title", "## Short description", '
        '"## Full description" headings.');
  }

  return Listing()
    ..title = title
    ..shortDescription = short
    ..fullDescription = full;
}

String? _headingText(String line) {
  final m = RegExp(r'^#{2,6}\s+(.*)$').firstMatch(line.trimRight());
  return m?.group(1)?.trim();
}

String? _labelFor(String heading) {
  final h = heading.toLowerCase();
  if (h.startsWith('app title') || h.startsWith('title')) return 'title';
  if (h.startsWith('short description')) return 'short';
  if (h.startsWith('full description')) return 'full';
  return null;
}

void _check(List<String> out, String name, String? value, int max) {
  if (value == null || value.isEmpty) {
    out.add('$name is empty.');
    return;
  }
  if (value.length > max) {
    out.add('$name is ${value.length} chars (max $max).');
  }
}

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

/// Finds the listing graphics under [assetsDir] and groups them into slots.
List<ImageSlot> _collectImages(String assetsDir) {
  final dir = Directory(assetsDir);
  if (!dir.existsSync()) return const [];

  final slots = <ImageSlot>[];

  final icon = _single(assetsDir, 'icon');
  if (icon != null) {
    slots.add(ImageSlot('icon', [icon], expected: (w: 512, h: 512)));
  }

  // Accept either the documented `feature-graphic.*` or a plain `feature.*`.
  final feature =
      _single(assetsDir, 'feature-graphic') ?? _single(assetsDir, 'feature');
  if (feature != null) {
    slots.add(
        ImageSlot('featureGraphic', [feature], expected: (w: 1024, h: 500)));
  }

  // Screenshots: accept a subfolder (phone/01.jpg) AND flat files (phone1.jpg).
  for (final entry in const [
    ('phone', 'phoneScreenshots'),
    ('seven-inch', 'sevenInchScreenshots'),
    ('ten-inch', 'tenInchScreenshots'),
  ]) {
    final shots = _screenshots(assetsDir, entry.$1);
    if (shots.isNotEmpty) slots.add(ImageSlot(entry.$2, shots));
  }

  return slots;
}

/// First image file named [base].(png|jpg|jpeg) in [dirPath].
File? _single(String dirPath, String base) {
  for (final ext in const ['png', 'jpg', 'jpeg']) {
    final f = File('$dirPath/$base.$ext');
    if (f.existsSync()) return f;
  }
  return null;
}

/// Collects screenshots for a category from both a `<prefix>/` subfolder and
/// flat `<prefix>N.*` files in the assets root, naturally sorted by number.
List<File> _screenshots(String assetsDir, String prefix) {
  final found = <File>[];

  final sub = Directory('$assetsDir/$prefix');
  if (sub.existsSync()) {
    found.addAll(sub.listSync().whereType<File>().where((f) => _isImage(f.path)));
  }

  final root = Directory(assetsDir);
  if (root.existsSync()) {
    final re = RegExp('^' + RegExp.escape(prefix) + r'[-_ ]?\d+\.(png|jpe?g)$',
        caseSensitive: false);
    found.addAll(root
        .listSync()
        .whereType<File>()
        .where((f) => re.hasMatch(_short(f.path))));
  }

  found.sort((a, b) => _numIn(a.path).compareTo(_numIn(b.path)));
  return found;
}

/// Trailing integer in a filename (phone10 -> 10), for natural ordering.
int _numIn(String path) {
  final m = RegExp(r'(\d+)\.[^.]+$').firstMatch(_short(path));
  return m == null ? 0 : int.parse(m.group(1)!);
}

void _reportImages(String assetsDir, List<ImageSlot> slots) {
  stdout.writeln('\nImages from $assetsDir:');
  if (slots.isEmpty) {
    stdout.writeln('  (none found — add files per docs/store-assets/README.md, '
        'or pass --no-images)');
    return;
  }
  for (final slot in slots) {
    for (final file in slot.files) {
      final size = _imageSize(file);
      final dim = size == null ? 'unknown size' : '${size.w}×${size.h}';
      final note = size == null ? '' : _imageNote(slot, size);
      stdout.writeln('  ${slot.imageType.padRight(20)} '
          '${_short(file.path).padRight(28)} $dim$note');
    }
  }
}

/// A human note for the dry-run report describing any auto-fix we'll apply.
String _imageNote(ImageSlot slot, ({int w, int h}) size) {
  switch (slot.imageType) {
    case 'icon':
      if (size.w == kIconSide && size.h == kIconSide) return '';
      return '  → will fit to $kIconSide×$kIconSide';
    case 'featureGraphic':
      if (size.w == 1024 && size.h == 500) return '';
      return '  → will fit to 1024×500 (center-crop)';
    default:
      final long = size.w > size.h ? size.w : size.h;
      final short = size.w > size.h ? size.h : size.w;
      if (long > short * 2) return '  ⚠ ratio over 2:1 — Play may reject';
      return '';
  }
}

/// Returns the (bytes, contentType) to upload for a slot file. The icon and
/// feature graphic are fitted to Play's exact required sizes in memory; other
/// images are sent as-is. Never modifies files on disk.
(List<int>, String) _bytesForUpload(ImageSlot slot, File file) {
  final raw = file.readAsBytesSync();
  final size = _imageSize(file);

  if (slot.imageType == 'icon' &&
      !(size != null && size.w == kIconSide && size.h == kIconSide)) {
    return (img.encodePng(_fitCover(_decode(file, raw), kIconSide, kIconSide)),
        'image/png');
  }
  if (slot.imageType == 'featureGraphic' &&
      !(size != null && size.w == 1024 && size.h == 500)) {
    return (
      img.encodeJpg(_fitCover(_decode(file, raw), 1024, 500), quality: 90),
      'image/jpeg'
    );
  }
  return (raw, _contentType(file.path));
}

img.Image _decode(File file, Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) _fail('Could not decode image: ${file.path}');
  return decoded;
}

/// Scales [src] to fully cover [w]×[h], then center-crops to exactly that size.
img.Image _fitCover(img.Image src, int w, int h) {
  final scale = (w / src.width) > (h / src.height)
      ? (w / src.width)
      : (h / src.height);
  final rw = (src.width * scale).round();
  final rh = (src.height * scale).round();
  final resized = img.copyResize(src,
      width: rw, height: rh, interpolation: img.Interpolation.cubic);
  final x = ((rw - w) / 2).round();
  final y = ((rh - h) / 2).round();
  return img.copyCrop(resized, x: x, y: y, width: w, height: h);
}

bool _isImage(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg');
}

String _contentType(String path) =>
    path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

String _short(String path) => path.split(RegExp(r'[\\/]')).last;

/// Reads width/height from PNG or JPEG headers; null if it can't.
({int w, int h})? _imageSize(File file) {
  final b = file.readAsBytesSync();
  // PNG: 8-byte signature, then IHDR with width@16, height@20 (big-endian).
  if (b.length >= 24 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    final w = (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
    final h = (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23];
    return (w: w, h: h);
  }
  // JPEG: scan segments for a Start-Of-Frame marker.
  if (b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = b[i + 1];
      final isSof = (marker >= 0xC0 && marker <= 0xCF) &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isSof) {
        final h = (b[i + 5] << 8) | b[i + 6];
        final w = (b[i + 7] << 8) | b[i + 8];
        return (w: w, h: h);
      }
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2) break;
      i += 2 + len;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------

void _handleApiError(DetailedApiRequestError e, String pkg) {
  stderr.writeln('\n❌ Play API error ${e.status}: ${e.message}');
  switch (e.status) {
    case 401:
    case 403:
      stderr.writeln(
          'The service account is authenticated but not authorised to edit\n'
          'this app. In Play Console > Users and permissions, invite\n'
          'the service-account email and grant "Edit store listing & images"\n'
          '(or Admin) for $pkg. Also confirm the Google Play Android Developer\n'
          'API is enabled in the GCP project.');
      break;
    case 404:
      stderr.writeln(
          'App "$pkg" was not found. The app must already exist in Play\n'
          'Console AND have its first app bundle (AAB) uploaded to a track —\n'
          'that is what registers the package name with the API. The package\n'
          'name must also match exactly.');
      break;
    default:
      stderr.writeln('See https://developers.google.com/android-publisher for '
          'this status code.');
  }
  exit(1);
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

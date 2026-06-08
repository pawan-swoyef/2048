// Uploads the signed AAB to Google Play and rolls it out to the Internal
// testing track, via the Play Developer API (androidpublisher v3).
//
// Prereqs (same as push_listing.dart — see README.md):
//   - the app already exists in Play Console for the package,
//   - the service account is linked there with release permissions,
//   - the AAB is already built (flutter build appbundle --release).
//
// Usage (from tool/play_publish):
//   dart run bin/publish_internal.dart            # dry-run: checks only
//   dart run bin/publish_internal.dart --commit   # upload + roll out to internal
//
// Note: Google may reject the FIRST release until the app's content
// declarations (privacy policy, ads, content rating, target audience, data
// safety) are completed in the Play Console — those are not settable via API.

import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('key',
        help: 'Service-account JSON key.',
        defaultsTo: '../../secretandstunts-e3a3e3c488d4.json')
    ..addOption('package',
        help: 'Android applicationId.', defaultsTo: 'com.number.twofoureight')
    ..addOption('aab',
        help: 'Path to the .aab to upload.',
        defaultsTo: '../../build/app/outputs/bundle/release/app-release.aab')
    ..addOption('track', help: 'Release track.', defaultsTo: 'internal')
    ..addFlag('commit',
        negatable: false, help: 'Actually upload and roll out.')
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
    stdout.writeln('Upload the AAB and roll out to a testing track.\n');
    stdout.writeln(parser.usage);
    return;
  }

  final pkg = args['package'] as String;
  final track = args['track'] as String;
  final aabPath = args['aab'] as String;
  final aab = File(aabPath);
  if (!aab.existsSync()) {
    stderr.writeln('Error: AAB not found: $aabPath\n'
        'Build it first: flutter build appbundle --release');
    exit(1);
  }

  final sizeMb = (aab.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
  stdout.writeln('Package: $pkg');
  stdout.writeln('Track:   $track');
  stdout.writeln('AAB:     $aabPath ($sizeMb MB)');

  if (!(args['commit'] as bool)) {
    stdout.writeln('\nDRY RUN — nothing uploaded. '
        'Re-run with --commit to publish.');
    return;
  }

  final keyFile = File(args['key'] as String);
  if (!keyFile.existsSync()) {
    stderr.writeln('Error: key not found: ${args['key']}');
    exit(1);
  }
  final credentials =
      ServiceAccountCredentials.fromJson(keyFile.readAsStringSync());

  stdout.writeln('\nAuthenticating with Google...');
  final client = await clientViaServiceAccount(
      credentials, [AndroidPublisherApi.androidpublisherScope]);

  try {
    final api = AndroidPublisherApi(client);

    stdout.writeln('Opening a new edit...');
    final edit = await api.edits.insert(AppEdit(), pkg);
    final editId = edit.id!;

    stdout.writeln('Uploading AAB ($sizeMb MB)...');
    final media = Media(aab.openRead(), aab.lengthSync(),
        contentType: 'application/octet-stream');
    final bundle = await api.edits.bundles.upload(pkg, editId,
        uploadMedia: media, uploadOptions: UploadOptions.resumable);
    final versionCode = bundle.versionCode!;
    stdout.writeln('Uploaded versionCode $versionCode.');

    stdout.writeln('Assigning versionCode $versionCode to "$track"...');
    final trackUpdate = Track()
      ..track = track
      ..releases = [
        TrackRelease()
          ..status = 'completed'
          ..versionCodes = [versionCode.toString()]
      ];
    await api.edits.tracks.update(trackUpdate, pkg, editId, track);

    stdout.writeln('Committing...');
    await api.edits.commit(pkg, editId);

    stdout.writeln('\n✅ Done — AAB uploaded and rolled out to "$track".');
    stdout.writeln('   Play Console > Testing > Internal testing to verify.');
  } on DetailedApiRequestError catch (e) {
    _handleApiError(e, pkg);
  } finally {
    client.close();
  }
}

void _handleApiError(DetailedApiRequestError e, String pkg) {
  stderr.writeln('\n❌ Play API error ${e.status}: ${e.message}');
  if (e.errors.isNotEmpty) {
    for (final err in e.errors) {
      stderr.writeln('   - ${err.reason ?? ''}: ${err.message ?? ''}');
    }
  }
  switch (e.status) {
    case 401:
    case 403:
      stderr.writeln(
          'The service account is authenticated but not authorised to publish\n'
          'this app. In Play Console > Users and permissions, grant the\n'
          'service account "Release to testing tracks" (or Admin) for $pkg.');
      break;
    case 404:
      stderr.writeln(
          'App "$pkg" was not found. You must create the app in Play Console\n'
          'first (the API cannot create apps), and the service account must be\n'
          'linked to it.');
      break;
    default:
      stderr.writeln(
          'If this is the first release, finish the app content declarations\n'
          '(privacy policy, ads, content rating, target audience, data safety)\n'
          'in the Play Console — those gate releases and are not set via API.');
  }
  exit(1);
}

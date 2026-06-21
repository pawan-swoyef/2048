// Lists the live in-app products + subscriptions via the Play Developer API
// and checks that the exact IDs the app queries exist and are active.

import 'dart:io';

import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';

const _pkg = 'com.number.twofoureight';
const _key = '../../secretandstunts-e3a3e3c488d4.json';

// The IDs the app queries (see lib/iap/iap_service.dart _kProductIds).
const _wantManaged = {'lifetime'};
const _wantSubs = {'monthly', 'yearly'};

void main() async {
  final creds = ServiceAccountCredentials.fromJson(File(_key).readAsStringSync());
  final client =
      await clientViaServiceAccount(creds, [AndroidPublisherApi.androidpublisherScope]);
  final api = AndroidPublisherApi(client);

  final found = <String>{};

  try {
    stdout.writeln('=== Managed (one-time) products ===');
    final list = await api.inappproducts.list(_pkg);
    for (final p in list.inappproduct ?? <InAppProduct>[]) {
      found.add(p.sku ?? '');
      stdout.writeln('  ${p.sku}  [${p.status}]  '
          '${p.defaultPrice?.currency} ${p.defaultPrice?.priceMicros}');
    }
    if ((list.inappproduct ?? []).isEmpty) stdout.writeln('  (none)');
  } on DetailedApiRequestError catch (e) {
    stdout.writeln('  ⚠ could not list managed products: ${e.status} ${e.message}');
  }

  try {
    stdout.writeln('\n=== Subscriptions ===');
    final subs = await api.monetization.subscriptions.list(_pkg);
    for (final s in subs.subscriptions ?? <Subscription>[]) {
      found.add(s.productId ?? '');
      final plans = (s.basePlans ?? [])
          .map((b) => '${b.basePlanId}:${b.state}')
          .join(', ');
      stdout.writeln('  ${s.productId}  basePlans[$plans]');
    }
    if ((subs.subscriptions ?? []).isEmpty) stdout.writeln('  (none)');
  } on DetailedApiRequestError catch (e) {
    stdout.writeln('  ⚠ could not list subscriptions: ${e.status} ${e.message}');
  }

  stdout.writeln('\n=== App expects ===');
  for (final id in {..._wantManaged, ..._wantSubs}) {
    stdout.writeln('  ${found.contains(id) ? '✅' : '❌ MISSING'}  $id');
  }

  client.close();
}

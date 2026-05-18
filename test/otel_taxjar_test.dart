// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_taxjar/otel_taxjar.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_taxjar-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('taxes.calculate records state + nexus + source', () async {
    await tracedTaxjar<String>(
      operation: 'taxes.calculate',
      invoke: () async => const TaxjarCallResult(
        value: 'ok',
        result: TaxjarResult(
          totalTaxMinor: 837,
          shippingTaxMinor: 0,
          freightTaxable: false,
          toCountry: 'US',
          toState: 'CA',
          hasNexus: true,
          taxSource: 'destination',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('taxjar taxes.calculate')!);
    expect(a['taxjar.to.country'], 'US');
    expect(a['taxjar.to.state'], 'CA');
    expect(a['taxjar.has_nexus'], true);
    expect(a['taxjar.tax_source'], 'destination');
    expect(a['taxjar.tax.total.minor'], 837);
  });

  test('suppression skips spans', () async {
    await runWithoutTaxjarInstrumentationAsync(() async {
      await tracedTaxjar<String>(
        operation: 'nexus.regions',
        invoke: () async => const TaxjarCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('taxjar '), isEmpty);
  });
}

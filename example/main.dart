// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_taxjar/otel_taxjar.dart';

/// Traces TaxJar calls with OpenTelemetry.
///
/// `otel_taxjar` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each TaxJar call in
/// [tracedTaxjar]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'taxjar-example');

  // Wraps a TaxJar API call in a CLIENT span.
  final taxjarId = await tracedTaxjar<String>(
    operation: 'orders.create',
    invoke: () async {
      // Make the TaxJar call here, then report what it returned.
      const id = 'taxjar_8f3a2c';
      return const TaxjarCallResult(
          value: id,
          result: TaxjarResult(
              orderTransactionId: 'transaction_id',
              itemCount: 3,
              totalTaxMinor: 1,
              shippingTaxMinor: 1,
              freightTaxable: true,
              toCountry: 'example',
              toState: 'active',
              hasNexus: true,
              taxSource: 'origin',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedTaxjar orders.create returned $taxjarId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutTaxjarInstrumentationAsync.
  await runWithoutTaxjarInstrumentationAsync(
    () => tracedTaxjar<String>(
      operation: 'orders.create',
      invoke: () async {
        const id = 'taxjar_8f3a2c';
        return const TaxjarCallResult(
            value: id,
            result: TaxjarResult(
                orderTransactionId: 'transaction_id',
                itemCount: 3,
                totalTaxMinor: 1,
                shippingTaxMinor: 1,
                freightTaxable: true,
                toCountry: 'example',
                toState: 'active',
                hasNexus: true,
                taxSource: 'origin',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}

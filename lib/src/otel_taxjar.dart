// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_taxjar_suppression.dart';

const _tracerName = 'dartastic_otel_libs_taxjar';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class TaxjarResult {
  /// Creates a result.
  const TaxjarResult({
    this.orderTransactionId,
    this.itemCount,
    this.totalTaxMinor,
    this.shippingTaxMinor,
    this.freightTaxable,
    this.toCountry,
    this.toState,
    this.hasNexus,
    this.taxSource,
    this.requestId,
    this.statusCode,
  });

  /// `transaction_id` (customer-supplied).
  final String? orderTransactionId;

  /// Items returned for list endpoints.
  final int? itemCount;

  /// Total tax in minor units. `amount_to_collect` * 100.
  final int? totalTaxMinor;

  /// Shipping tax in minor units.
  final int? shippingTaxMinor;

  /// Whether freight is taxable for this jurisdiction.
  final bool? freightTaxable;

  /// ISO 3166 ship-to country.
  final String? toCountry;

  /// US state code (ship-to) — primary tax-jurisdiction dim.
  final String? toState;

  /// Whether the seller has nexus in the ship-to jurisdiction.
  final bool? hasNexus;

  /// `origin` / `destination` — tax-sourcing rule applied.
  final String? taxSource;

  /// `X-TaxJar-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class TaxjarCallResult<T> {
  /// Creates a call result.
  const TaxjarCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final TaxjarResult? result;
}

/// Wraps a TaxJar API call in a CLIENT span. [operation] is one of
/// `taxes.calculate`, `orders.list`, `orders.show`, `orders.create`,
/// `orders.update`, `orders.delete`, `refunds.list`, `refunds.create`,
/// `customers.list`, `customers.create`, `nexus.regions`,
/// `validations.address`, `validations.vat`, `rates.show`,
/// `summary.rates`.
Future<T> tracedTaxjar<T>({
  required String operation,
  required Future<TaxjarCallResult<T>> Function() invoke,
}) async {
  if (taxjarInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'taxjar',
    'rpc.method': operation,
    'taxjar.operation': operation,
  };

  final span = _tracer().startSpan(
    'taxjar $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.orderTransactionId != null) {
        extras.add(OTelAPI.attributeString(
          'taxjar.transaction.id',
          r.result!.orderTransactionId!,
        ));
      }
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'taxjar.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalTaxMinor != null) {
        extras.add(OTelAPI.attributeInt(
          'taxjar.tax.total.minor',
          r.result!.totalTaxMinor!,
        ));
      }
      if (r.result!.shippingTaxMinor != null) {
        extras.add(OTelAPI.attributeInt(
          'taxjar.tax.shipping.minor',
          r.result!.shippingTaxMinor!,
        ));
      }
      if (r.result!.freightTaxable != null) {
        extras.add(OTelAPI.attributeBool(
          'taxjar.freight_taxable',
          r.result!.freightTaxable!,
        ));
      }
      if (r.result!.toCountry != null) {
        extras.add(OTelAPI.attributeString(
          'taxjar.to.country',
          r.result!.toCountry!,
        ));
      }
      if (r.result!.toState != null) {
        extras.add(OTelAPI.attributeString(
          'taxjar.to.state',
          r.result!.toState!,
        ));
      }
      if (r.result!.hasNexus != null) {
        extras.add(OTelAPI.attributeBool(
          'taxjar.has_nexus',
          r.result!.hasNexus!,
        ));
      }
      if (r.result!.taxSource != null) {
        extras.add(OTelAPI.attributeString(
          'taxjar.tax_source',
          r.result!.taxSource!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'taxjar.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'TaxJar HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

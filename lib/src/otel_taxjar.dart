// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_taxjar_suppression.dart';

const _tracerName = 'dartastic_otel_libs_taxjar';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class TaxjarResult {
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

class TaxjarCallResult<T> {
  const TaxjarCallResult({required this.value, this.result});
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
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.orderTransactionId != null) {
        extras.add(OTel.attributeString(
          'taxjar.transaction.id',
          r.result!.orderTransactionId!,
        ));
      }
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'taxjar.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalTaxMinor != null) {
        extras.add(OTel.attributeInt(
          'taxjar.tax.total.minor',
          r.result!.totalTaxMinor!,
        ));
      }
      if (r.result!.shippingTaxMinor != null) {
        extras.add(OTel.attributeInt(
          'taxjar.tax.shipping.minor',
          r.result!.shippingTaxMinor!,
        ));
      }
      if (r.result!.freightTaxable != null) {
        extras.add(OTel.attributeBool(
          'taxjar.freight_taxable',
          r.result!.freightTaxable!,
        ));
      }
      if (r.result!.toCountry != null) {
        extras.add(OTel.attributeString(
          'taxjar.to.country',
          r.result!.toCountry!,
        ));
      }
      if (r.result!.toState != null) {
        extras.add(OTel.attributeString(
          'taxjar.to.state',
          r.result!.toState!,
        ));
      }
      if (r.result!.hasNexus != null) {
        extras.add(OTel.attributeBool(
          'taxjar.has_nexus',
          r.result!.hasNexus!,
        ));
      }
      if (r.result!.taxSource != null) {
        extras.add(OTel.attributeString(
          'taxjar.tax_source',
          r.result!.taxSource!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'taxjar.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
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
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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

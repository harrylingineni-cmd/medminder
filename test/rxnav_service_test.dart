import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:med_app/rxnav_service.dart';

http.Response jsonResponse(Object body, {int statusCode = 200}) =>
    http.Response(jsonEncode(body), statusCode);

void main() {
  test(
    'an exact RxNorm match can be shown without extra confirmation',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/REST/rxcui.json') {
          return jsonResponse({
            'idGroup': {
              'rxnormId': ['153010'],
            },
          });
        }
        if (request.url.path == '/REST/rxcui/153010/related.json') {
          return jsonResponse({
            'relatedGroup': {
              'conceptGroup': [
                {
                  'tty': 'IN',
                  'conceptProperties': [
                    {'name': 'ibuprofen'},
                  ],
                },
              ],
            },
          });
        }
        return jsonResponse({}, statusCode: 404);
      });

      final result = await RxNavService.lookupGeneric('Advil', client: client);

      expect(result.outcome, RxNavLookupOutcome.found);
      expect(result.genericName, 'Ibuprofen');
      expect(result.matchedMedicineName, 'Advil');
      expect(result.requiresMatchConfirmation, isFalse);
    },
  );

  test(
    'an approximate match returns its name for manual confirmation',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/REST/rxcui.json') {
          return jsonResponse({
            'idGroup': {'rxnormId': <String>[]},
          });
        }
        if (request.url.path == '/REST/approximateTerm.json') {
          expect(request.url.queryParameters['option'], '1');
          return jsonResponse({
            'approximateGroup': {
              'candidate': [
                {
                  'rxcui': '104490',
                  'rank': '1',
                  'source': 'RXNORM',
                  'name': 'Simvastatin 10 MG Oral Tablet [Zocor]',
                },
              ],
            },
          });
        }
        if (request.url.path == '/REST/rxcui/104490/related.json') {
          return jsonResponse({
            'relatedGroup': {
              'conceptGroup': [
                {
                  'tty': 'IN',
                  'conceptProperties': [
                    {'name': 'simvastatin'},
                  ],
                },
              ],
            },
          });
        }
        return jsonResponse({}, statusCode: 404);
      });

      final result = await RxNavService.lookupGeneric('Zocorr', client: client);

      expect(result.outcome, RxNavLookupOutcome.found);
      expect(result.genericName, 'Simvastatin');
      expect(
        result.matchedMedicineName,
        'Simvastatin 10 MG Oral Tablet [Zocor]',
      );
      expect(result.requiresMatchConfirmation, isTrue);
    },
  );

  test('a nameless approximate atom uses the canonical concept name', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/REST/rxcui.json') {
        return jsonResponse({
          'idGroup': {'rxnormId': <String>[]},
        });
      }
      if (request.url.path == '/REST/approximateTerm.json') {
        return jsonResponse({
          'approximateGroup': {
            'candidate': [
              {'rxcui': '6809', 'rank': '1', 'source': 'GS'},
            ],
          },
        });
      }
      if (request.url.path == '/REST/rxcui/6809/properties.json') {
        return jsonResponse({
          'properties': {'name': 'Metformin'},
        });
      }
      if (request.url.path == '/REST/rxcui/6809/related.json') {
        return jsonResponse({
          'relatedGroup': {
            'conceptGroup': [
              {
                'tty': 'IN',
                'conceptProperties': [
                  {'name': 'metformin'},
                ],
              },
            ],
          },
        });
      }
      return jsonResponse({}, statusCode: 404);
    });

    final result = await RxNavService.lookupGeneric('Metformn', client: client);

    expect(result.matchedMedicineName, 'Metformin');
    expect(result.requiresMatchConfirmation, isTrue);
  });

  test('service and malformed-response failures are recoverable', () async {
    final unavailable = MockClient(
      (_) async => jsonResponse({}, statusCode: 503),
    );
    final malformed = MockClient((_) async => http.Response('not-json', 200));

    expect(
      (await RxNavService.lookupGeneric('Advil', client: unavailable)).outcome,
      RxNavLookupOutcome.networkError,
    );
    expect(
      (await RxNavService.lookupGeneric('Advil', client: malformed)).outcome,
      RxNavLookupOutcome.networkError,
    );
  });
}

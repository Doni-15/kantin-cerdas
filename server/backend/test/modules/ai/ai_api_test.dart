import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/data/ai_http_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/data/gemini_ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/data/supabase_ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_models.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_provider_config.dart';
import 'package:kantin_cerdas_backend/src/modules/ai/domain/ai_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _custId = '11111111-1111-1111-1111-111111111111';
const _adminId = '22222222-2222-2222-2222-222222222222';
const _ownerId = '33333333-3333-3333-3333-333333333333';

const _stallOpenId = '44444444-4444-4444-4444-444444444444';
const _stallClosedId = '55555555-5555-5555-5555-555555555555';
const _stallInactiveOwnerId = '66666666-6666-6666-6666-666666666666';

const _menuOrderableId = '77777777-7777-7777-7777-777777777771';
const _menuExpensiveId = '77777777-7777-7777-7777-777777777772';
const _menuHabisId = '77777777-7777-7777-7777-777777777773';
const _menuArchivedId = '77777777-7777-7777-7777-777777777774';
const _menuClosedStallId = '77777777-7777-7777-7777-777777777775';
const _menuInactiveOwnerId = '77777777-7777-7777-7777-777777777776';
const _hallucinatedMenuId = '99999999-9999-9999-9999-999999999999';

void main() {
  late _FakeAuthGateway auth;
  late _FakeAvatarStore avatars;
  late _FakeAiStore aiStore;

  AppConfig makeConfig() => AppConfig.fromEnv(
    EnvConfig.fromMap(
      validEnvironment(
        overrides: {
          'RATE_LIMIT_ENABLED': 'false',
          'LOG_REQUEST_ENABLED': 'false',
        },
      ),
    ),
  );

  Handler buildApp({
    required AiProviderConfig aiConfig,
    required AiProvider aiProvider,
  }) => buildAppHandlerWithAllModulesAndAi(
    makeConfig(),
    aiConfig: aiConfig,
    authGateway: auth,
    avatarStore: avatars,
    catalogStore: _StubCatalogStore(),
    ownerStore: _StubOwnerStore(),
    ownerMediaStore: _StubMediaStore(),
    customerStore: _StubCustomerStore(),
    adminStore: _StubAdminStore(),
    aiStore: aiStore,
    aiProvider: aiProvider,
  );

  setUp(() {
    auth = _FakeAuthGateway();
    avatars = _FakeAvatarStore();
    aiStore = _FakeAiStore();
  });

  group('AiProviderConfig activation safety gates', () {
    test(
      'defaults to disabled and blocks dummy .invalid URL & missing creds',
      () {
        final defaultCfg = AiProviderConfig.fromEnv(
          EnvConfig.fromMap(const {}),
        );
        expect(defaultCfg.enabled, isFalse);
        expect(defaultCfg.baseUrl, isEmpty);
        expect(defaultCfg.apiKey, isEmpty);
        expect(defaultCfg.model, 'gemini-3.5-flash-lite');
        expect(defaultCfg.validateActivation().isValid, isFalse);

        final dummyUrlCfg = AiProviderConfig.fromEnv(
          EnvConfig.fromMap({
            'AI_PROVIDER_ENABLED': 'true',
            'AI_FREE_TIER_VERIFIED': 'true',
            'AI_PRIVACY_AUDIENCE_VERIFIED': 'true',
            'AI_PROJECT_DAILY_CAP': '50',
            'GEMINI_API_KEY': 'test-only-key',
            'GEMINI_API_BASE_URL':
                'https://kantin-ai-future-7x9q.invalid/v1beta/models/gemini-3.5-flash-lite:generateContent',
          }),
        );
        expect(dummyUrlCfg.resolveEndpointUri(), isNull);
        expect(dummyUrlCfg.validateActivation().isValid, isFalse);
        expect(dummyUrlCfg.validateActivation().reasonCode, 'invalid_base_url');

        final emptyKeyCfg = AiProviderConfig.fromEnv(
          EnvConfig.fromMap({
            'AI_PROVIDER_ENABLED': 'true',
            'AI_FREE_TIER_VERIFIED': 'true',
            'AI_PRIVACY_AUDIENCE_VERIFIED': 'true',
            'AI_PROJECT_DAILY_CAP': '50',
            'GEMINI_API_BASE_URL':
                'https://generativelanguage.example.test/v1beta',
          }),
        );
        expect(emptyKeyCfg.validateActivation().isValid, isFalse);
        expect(emptyKeyCfg.validateActivation().reasonCode, 'missing_api_key');

        final paidModelCfg = AiProviderConfig.fromEnv(
          EnvConfig.fromMap({
            'AI_PROVIDER_ENABLED': 'true',
            'AI_FREE_TIER_VERIFIED': 'true',
            'AI_PRIVACY_AUDIENCE_VERIFIED': 'true',
            'AI_PROJECT_DAILY_CAP': '50',
            'GEMINI_API_KEY': 'test-only-key',
            'GEMINI_MODEL': 'gemini-2.5-pro',
            'GEMINI_API_BASE_URL':
                'https://generativelanguage.example.test/v1beta',
          }),
        );
        expect(paidModelCfg.validateActivation().isValid, isFalse);
        expect(
          paidModelCfg.validateActivation().reasonCode,
          'model_not_approved',
        );
      },
    );
  });

  group('Disabled Gemini / Catalog Fallback Mode', () {
    test(
      'enforces auth, works via catalog fallback with 0 HTTP calls, budget cap, and read-only rules',
      () async {
        final fakeTransport = FakeAiHttpTransport(
          (_, _, _) => throw StateError(
            'Dummy or disabled provider must never call transport',
          ),
        );
        const cfg = AiProviderConfig.disabled();
        final app = buildApp(
          aiConfig: cfg,
          aiProvider: GeminiAiProvider(config: cfg, transport: fakeTransport),
        );

        expect((await _send(app, 'GET', '/ai/status')).statusCode, 401);
        expect(
          (await _send(
            app,
            'GET',
            '/ai/status',
            bearer: 'tok-admin',
          )).statusCode,
          403,
        );

        final statusRes = await _send(
          app,
          'GET',
          '/ai/status',
          bearer: 'tok-cust',
        );
        expect(statusRes.statusCode, 200);
        final statusData = await _data(statusRes);
        expect(statusData['provider_enabled'], isFalse);
        expect(statusData['provider_ready'], isFalse);
        expect(statusData['fallback_active'], isTrue);
        expect(statusData.containsKey('api_key'), isFalse);

        // General culinary query when disabled returns honest ai_unavailable, NOT fake recipe, 0 quota used.
        final recipeRes = await _send(
          app,
          'POST',
          '/ai/chat',
          bearer: 'tok-cust',
          body: {'message': 'Beri resep cara membuat ayam geprek'},
        );
        expect(recipeRes.statusCode, 200);
        final recipeData = await _data(recipeRes);
        expect(recipeData['status'], 'ai_unavailable');
        expect(recipeData['is_general_culinary'], isFalse);
        expect((recipeData['quota'] as Map)['used_today'], 0);

        // Catalog query enforces <= 20000, hides 25000 & archived & unavailable by default.
        final chatRes = await _send(
          app,
          'POST',
          '/ai/chat',
          bearer: 'tok-cust',
          body: {'message': 'Carikan ayam maksimal Rp20.000'},
        );
        expect(chatRes.statusCode, 200);
        final chatData = await _data(chatRes);
        expect(chatData['status'], 'catalog_fallback');
        expect(chatData['applied_max_budget'], 20000);
        final recs = chatData['recommendations'] as List;
        expect(recs.length, 1);
        expect((recs.first as Map)['id'], _menuOrderableId);
        expect((recs.first as Map)['price'], 18000);
        expect((chatData['quota'] as Map)['used_today'], 0);

        // Include unavailable shows Habis/Tutup/Owner nonaktif with clear labels, NEVER Archived.
        final infoRes = await _send(
          app,
          'POST',
          '/ai/chat',
          bearer: 'tok-cust',
          body: {
            'message': 'Ada menu tutup atau habis?',
            'include_unavailable': true,
          },
        );
        final infoData = await _data(infoRes);
        final infoRecs = infoData['recommendations'] as List;
        final returnedIds = infoRecs.map((e) => (e as Map)['id']).toSet();
        expect(returnedIds.contains(_menuArchivedId), isFalse);
        expect(returnedIds.contains(_menuHabisId), isTrue);
        expect(returnedIds.contains(_menuClosedStallId), isTrue);
        expect(returnedIds.contains(_menuInactiveOwnerId), isTrue);
        for (final r in infoRecs.cast<Map<String, dynamic>>()) {
          if (r['id'] == _menuHabisId ||
              r['id'] == _menuClosedStallId ||
              r['id'] == _menuInactiveOwnerId) {
            expect(r['is_orderable'], isFalse);
          } else {
            expect(r['is_orderable'], isTrue);
          }
        }

        // Allergen/nutrition query always produces uncertainty disclaimer.
        final allergenRes = await _send(
          app,
          'POST',
          '/ai/chat',
          bearer: 'tok-cust',
          body: {'message': 'Apakah ayam geprek bebas alergi kacang?'},
        );
        final allergenData = await _data(allergenRes);
        expect(allergenData['has_uncertainty_notice'], isTrue);
        expect(
          (allergenData['reply'] as String).toLowerCase(),
          contains('belum tersedia terverifikasi'),
        );

        // Transaction attempt stays read-only & 0 quota consumed.
        final orderIntentRes = await _send(
          app,
          'POST',
          '/ai/chat',
          bearer: 'tok-cust',
          body: {'message': 'Tolong pesan dan checkout ayam geprek 2 porsi'},
        );
        final orderIntentData = await _data(orderIntentRes);
        expect(
          (orderIntentData['transaction_capabilities'] as Map)['can_checkout'],
          isFalse,
        );
        expect(
          orderIntentData['fallback_reason'],
          'read_only_transaction_boundary',
        );

        // Pure catalog recommendation endpoint consumes 0 quota.
        final recEndpoint = await _send(
          app,
          'GET',
          '/ai/recommendations?q=ayam&max_budget=20000',
          bearer: 'tok-cust',
        );
        expect(recEndpoint.statusCode, 200);
        expect(((await _data(recEndpoint))['items'] as List).length, 1);

        expect(fakeTransport.recordedRequests, isEmpty);
        expect(aiStore.reserveCallsCount, 0);
      },
    );
  });

  group(
    'Enabled Gemini via FakeAiHttpTransport: Grounding, Quota, Concurrency, Failures',
    () {
      AiProviderConfig enabledTestConfig() => const AiProviderConfig(
        enabled: true,
        apiKey: 'fake-test-secret',
        baseUrl: 'https://generativelanguage.example.test/v1beta',
        model: 'gemini-3.5-flash-lite',
        freeTierVerified: true,
        audiencePrivacyVerified: true,
        dailyUserLimit: 10,
        projectDailyCap: 100,
        projectRpmLimit: 50,
        circuitBreakerThreshold: 5,
        circuitBreakerCooldown: Duration(minutes: 5),
        requestTimeout: Duration(milliseconds: 200),
      );

      test(
        'drops hallucinated IDs, keeps DB prices, blocks PII, blocks unverified safety claims',
        () async {
          final fakeTransport = FakeAiHttpTransport((_, headers, body) {
            expect(headers['x-goog-api-key'], 'fake-test-secret');
            // Ensure Gemini tries to hallucinate an ID, include expensive menu over 20k, and claim allergy safe.
            return AiHttpResponse(
              statusCode: 200,
              body: jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'summary_text':
                                'Ayam geprek Rp5.000 pasti aman tanpa alergi kacang.',
                            'recommended_menu_ids': [
                              _hallucinatedMenuId,
                              _menuExpensiveId,
                              _menuArchivedId,
                              _menuOrderableId,
                            ],
                            'is_general_culinary': false,
                            'has_uncertainty_notice': false,
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
            );
          });

          final cfg = enabledTestConfig();
          final app = buildApp(
            aiConfig: cfg,
            aiProvider: GeminiAiProvider(config: cfg, transport: fakeTransport),
          );

          // Sensitive PII must NEVER reach fakeTransport.
          final piiRes = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {
              'message':
                  'Email saya mahasiswa@usu.test HP 081234567890 cari ayam',
            },
          );
          expect(piiRes.statusCode, 200);
          expect(
            (await _data(piiRes))['fallback_reason'],
            'sensitive_input_blocked',
          );
          expect(fakeTransport.recordedRequests, isEmpty);

          // Valid request reaches fakeTransport once, verifies IDs/prices from DB, strips unsafe safety guarantee!
          final res = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {
              'message': 'Rekomendasi ayam pedas max 20000 aman alergi kacang?',
            },
          );
          expect(res.statusCode, 200);
          final data = await _data(res);
          expect(data['status'], 'ai_response');
          expect(data['has_uncertainty_notice'], isTrue);
          expect(
            (data['reply'] as String).toLowerCase(),
            isNot(contains('pasti aman')),
          );
          final recs = (data['recommendations'] as List)
              .cast<Map<String, dynamic>>();
          expect(recs.length, 1);
          expect(recs.first['id'], _menuOrderableId);
          expect(
            recs.first['price'],
            18000,
          ); // DB authoritative price preserved
          expect((data['quota'] as Map)['used_today'], 1);
          expect(fakeTransport.recordedRequests.length, 1);
        },
      );

      test(
        'enforces 10/day quota, concurrent last-slot race, and Jakarta midnight reset',
        () async {
          final fakeTransport = FakeAiHttpTransport((_, _, _) {
            return AiHttpResponse(
              statusCode: 200,
              body: jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'summary_text': 'Saran kuliner umum siap dicoba.',
                            'recommended_menu_ids': <String>[],
                            'is_general_culinary': true,
                            'has_uncertainty_notice': false,
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
            );
          });

          final cfg = enabledTestConfig();
          var fakeClock = DateTime.utc(2026, 11, 22, 16, 59, 0); // 23:59 WIB
          final app = buildAppHandlerWithAllModulesAndAi(
            makeConfig(),
            aiConfig: cfg,
            authGateway: auth,
            avatarStore: avatars,
            catalogStore: _StubCatalogStore(),
            ownerStore: _StubOwnerStore(),
            ownerMediaStore: _StubMediaStore(),
            customerStore: _StubCustomerStore(),
            adminStore: _StubAdminStore(),
            aiStore: aiStore,
            aiProvider: GeminiAiProvider(config: cfg, transport: fakeTransport),
          );
          // Pre-consume 9 calls via store at day 1 WIB.
          aiStore.clockOverride = () => fakeClock;
          for (var i = 0; i < 9; i++) {
            await _send(
              app,
              'POST',
              '/ai/chat',
              bearer: 'tok-cust',
              body: {'message': 'Resep #$i'},
            );
          }

          // Send 2 concurrent requests when only 1 call remains -> strictly 1 succeeds, 1 blocked!
          final responses = await Future.wait([
            _send(
              app,
              'POST',
              '/ai/chat',
              bearer: 'tok-cust',
              body: {'message': 'Resep paralel 1'},
            ),
            _send(
              app,
              'POST',
              '/ai/chat',
              bearer: 'tok-cust',
              body: {'message': 'Resep paralel 2'},
            ),
          ]);
          final bodies = await Future.wait(responses.map(_data));
          final statuses = bodies.map((b) => b['status']).toList();
          expect(statuses.where((s) => s == 'ai_response').length, 1);
          expect(statuses.where((s) => s == 'quota_exhausted').length, 1);

          // Even 11th sequential call stays quota_exhausted while Customer cart stays accessible!
          final eleventh = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {'message': 'Resep ke 11'},
          );
          expect((await _data(eleventh))['status'], 'quota_exhausted');
          expect(
            (await _send(
              app,
              'GET',
              '/customer/cart',
              bearer: 'tok-cust',
            )).statusCode,
            200,
          );

          // Advance clock 2 minutes past 00:00 WIB -> quota resets cleanly!
          fakeClock = DateTime.utc(2026, 11, 22, 17, 1, 0);
          final afterReset = await _send(
            app,
            'GET',
            '/ai/status',
            bearer: 'tok-cust',
          );
          final quotaReset =
              (await _data(afterReset))['quota'] as Map<String, dynamic>;
          expect(quotaReset['jakarta_date'], '2026-11-23');
          expect(quotaReset['used_today'], 0);
          expect(quotaReset['remaining_today'], 10);
        },
      );

      test(
        'counts dispatched timeout/uncertain & 5xx/429/invalid_output into fallback cleanly',
        () async {
          var mode = 'timeout';
          final fakeTransport = FakeAiHttpTransport((_, _, _) async {
            if (mode == 'timeout') {
              throw TimeoutException('Simulated timeout');
            }
            if (mode == 'invalid_json') {
              return const AiHttpResponse(
                statusCode: 200,
                body:
                    '{"candidates":[{"content":{"parts":[{"text":"not-json"}]}}]}',
              );
            }
            return const AiHttpResponse(statusCode: 429, body: '{}');
          });

          final cfg = enabledTestConfig();
          final app = buildApp(
            aiConfig: cfg,
            aiProvider: GeminiAiProvider(config: cfg, transport: fakeTransport),
          );

          final tRes = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {'message': 'Cari ayam'},
          );
          final tData = await _data(tRes);
          expect(tData['status'], 'ai_unavailable');
          expect(tData['fallback_used'], isTrue);
          expect(
            (tData['quota'] as Map)['used_today'],
            1,
          ); // Uncertain still counted!
          expect(aiStore.attemptStatuses.last, 'uncertain');

          mode = 'invalid_json';
          final invRes = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {'message': 'Cari ayam'},
          );
          expect((await _data(invRes))['status'], 'ai_unavailable');
          expect(aiStore.attemptStatuses.last, 'invalid_output');

          mode = 'rate_limit';
          final r429 = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {'message': 'Cari ayam'},
          );
          expect((await _data(r429))['status'], 'ai_unavailable');
          expect(aiStore.attemptStatuses.last, 'provider_error');

          // Circuit breaker is now open after 429 -> subsequent request immediately uses fallback with 0 new calls!
          final beforeCircuitCount = fakeTransport.recordedRequests.length;
          final afterOpen = await _send(
            app,
            'POST',
            '/ai/chat',
            bearer: 'tok-cust',
            body: {'message': 'Cari ayam'},
          );
          expect(
            (await _data(afterOpen))['fallback_reason'],
            'circuit_or_rpm_limited',
          );
          expect(fakeTransport.recordedRequests.length, beforeCircuitCount);
        },
      );
    },
  );

  group('SupabaseAiStore PostgREST failure mapping', () {
    test('maps PostgreSQL error codes accurately', () async {
      final rpcStore = SupabaseAiStore(
        SupabaseClientFactory(config: makeConfig().supabase),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': 'P0001',
              'details': 'KC_AI_CUSTOMER_REQUIRED',
              'message': 'KC_AI_CUSTOMER_REQUIRED',
            }),
            400,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      await expectLater(
        () => rpcStore.getQuotaStatus(
          _adminId,
          dailyLimit: 10,
          projectDailyCap: 0,
        ),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.code,
            'code',
            AiFailureCode.customerRoleRequired,
          ),
        ),
      );
    });
  });
}

Future<Response> _send(
  Handler handler,
  String method,
  String path, {
  String? bearer,
  Object? body,
}) {
  return Future.sync(
    () => handler(
      Request(
        method,
        Uri.parse('https://api.example.test/v1$path'),
        headers: {
          'host': 'api.example.test',
          if (bearer != null) 'authorization': 'Bearer $bearer',
          if (body != null) 'content-type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    ),
  );
}

Future<Map<String, dynamic>> _data(Response response) async {
  final json =
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  return json['data'] as Map<String, dynamic>;
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthAccount> account(String accessToken) async {
    return switch (accessToken) {
      'tok-cust' => const AuthAccount(
        id: _custId,
        email: 'cust@example.test',
        displayName: 'Cust Uji',
        role: AccountRole.customer,
      ),
      'tok-owner' => const AuthAccount(
        id: _ownerId,
        email: 'owner@example.test',
        displayName: 'Owner Uji',
        role: AccountRole.owner,
      ),
      'tok-admin' => const AuthAccount(
        id: _adminId,
        email: 'admin@example.test',
        displayName: 'Admin Uji',
        role: AccountRole.admin,
      ),
      _ => throw AuthFailure.invalidSession,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  @override
  Future<bool> exists(String userId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAiStore implements AiStore {
  final Map<(String, String), int> _userCounts = {};
  final Map<String, int> _projectCounts = {};
  final Map<
    String,
    ({String customerId, String date, String status, bool counted})
  >
  _attempts = {};
  final List<String> attemptStatuses = [];
  int reserveCallsCount = 0;
  var _seq = 0;
  DateTime Function()? clockOverride;

  final List<_CatalogRow> _rows = const [
    _CatalogRow(
      id: _menuOrderableId,
      name: 'Nasi Ayam Geprek',
      description: 'Pedas gurih nikmat',
      category: 'Makanan Berat',
      price: 18000,
      isAvailable: true,
      isArchived: false,
      stallId: _stallOpenId,
      stallName: 'Kantin Segar',
      stallBlock: 'Blok A',
      stallIsOpen: true,
      ownerIsActive: true,
    ),
    _CatalogRow(
      id: _menuExpensiveId,
      name: 'Ayam Bakar Jumbo',
      description: 'Porsi besar pedas',
      category: 'Makanan Berat',
      price: 25000,
      isAvailable: true,
      isArchived: false,
      stallId: _stallOpenId,
      stallName: 'Kantin Segar',
      stallBlock: 'Blok A',
      stallIsOpen: true,
      ownerIsActive: true,
    ),
    _CatalogRow(
      id: _menuHabisId,
      name: 'Ayam Penyet Spesial',
      description: 'Sambal pedas',
      category: 'Makanan Berat',
      price: 19000,
      isAvailable: false,
      isArchived: false,
      stallId: _stallOpenId,
      stallName: 'Kantin Segar',
      stallBlock: 'Blok A',
      stallIsOpen: true,
      ownerIsActive: true,
    ),
    _CatalogRow(
      id: _menuArchivedId,
      name: 'Ayam Arsip Lama',
      description: 'Arsip',
      category: 'Makanan Berat',
      price: 15000,
      isAvailable: true,
      isArchived: true,
      stallId: _stallOpenId,
      stallName: 'Kantin Segar',
      stallBlock: 'Blok A',
      stallIsOpen: true,
      ownerIsActive: true,
    ),
    _CatalogRow(
      id: _menuClosedStallId,
      name: 'Ayam Goreng Malam',
      description: 'Ayam renyah',
      category: 'Makanan Berat',
      price: 16000,
      isAvailable: true,
      isArchived: false,
      stallId: _stallClosedId,
      stallName: 'Warung Tutup',
      stallBlock: 'Blok B',
      stallIsOpen: false,
      ownerIsActive: true,
    ),
    _CatalogRow(
      id: _menuInactiveOwnerId,
      name: 'Soto Ayam Nonaktif',
      description: 'Soto kuah',
      category: 'Makanan Berat',
      price: 14000,
      isAvailable: true,
      isArchived: false,
      stallId: _stallInactiveOwnerId,
      stallName: 'Stan Nonaktif',
      stallBlock: 'Blok C',
      stallIsOpen: true,
      ownerIsActive: false,
    ),
  ];

  String _jakartaDate(DateTime? now) {
    final effective = (clockOverride?.call() ?? now ?? DateTime.now()).toUtc();
    final wib = effective.add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${wib.year}-${two(wib.month)}-${two(wib.day)}';
  }

  @override
  Future<AiQuotaSnapshot> getQuotaStatus(
    String customerId, {
    required int dailyLimit,
    required int projectDailyCap,
    DateTime? now,
  }) async {
    final d = _jakartaDate(now);
    final used = _userCounts[(customerId, d)] ?? 0;
    final projUsed = _projectCounts[d] ?? 0;
    return AiQuotaSnapshot(
      jakartaDate: d,
      dailyLimit: dailyLimit,
      usedToday: used,
      remainingToday: (dailyLimit - used).clamp(0, dailyLimit),
      projectCapConfigured: projectDailyCap > 0,
      projectQuotaKnown: projectDailyCap > 0,
      projectDailyCap: projectDailyCap > 0 ? projectDailyCap : null,
      projectRemainingToday: projectDailyCap > 0
          ? (projectDailyCap - projUsed).clamp(0, projectDailyCap)
          : null,
    );
  }

  @override
  Future<AiQuotaReservation> reserveCall(
    String customerId, {
    required String requestKind,
    required String providerModel,
    required int dailyLimit,
    required int projectDailyCap,
    DateTime? now,
  }) async {
    reserveCallsCount += 1;
    final d = _jakartaDate(now);
    if (projectDailyCap <= 0) {
      return AiQuotaReservation(
        reserved: false,
        reason: 'project_cap_unverified',
        quota: await getQuotaStatus(
          customerId,
          dailyLimit: dailyLimit,
          projectDailyCap: projectDailyCap,
          now: now,
        ),
      );
    }
    final projUsed = _projectCounts[d] ?? 0;
    if (projUsed >= projectDailyCap) {
      return AiQuotaReservation(
        reserved: false,
        reason: 'project_quota_exhausted',
        quota: await getQuotaStatus(
          customerId,
          dailyLimit: dailyLimit,
          projectDailyCap: projectDailyCap,
          now: now,
        ),
      );
    }
    final userUsed = _userCounts[(customerId, d)] ?? 0;
    if (userUsed >= dailyLimit) {
      return AiQuotaReservation(
        reserved: false,
        reason: 'user_quota_exhausted',
        quota: await getQuotaStatus(
          customerId,
          dailyLimit: dailyLimit,
          projectDailyCap: projectDailyCap,
          now: now,
        ),
      );
    }
    _projectCounts[d] = projUsed + 1;
    _userCounts[(customerId, d)] = userUsed + 1;
    final id = 'att-${++_seq}';
    _attempts[id] = (
      customerId: customerId,
      date: d,
      status: 'reserved',
      counted: true,
    );
    return AiQuotaReservation(
      reserved: true,
      reason: 'reserved',
      attemptId: id,
      quota: await getQuotaStatus(
        customerId,
        dailyLimit: dailyLimit,
        projectDailyCap: projectDailyCap,
        now: now,
      ),
    );
  }

  @override
  Future<void> finalizeAttempt(
    String customerId, {
    required String attemptId,
    required String status,
  }) async {
    final current = _attempts[attemptId];
    if (current == null) return;
    attemptStatuses.add(status);
    _attempts[attemptId] = (
      customerId: current.customerId,
      date: current.date,
      status: status,
      counted: current.counted,
    );
  }

  @override
  Future<List<AiMenuRecommendation>> searchCatalog({
    required String query,
    int? maxPrice,
    bool includeUnavailable = false,
    int limit = 24,
  }) async {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.length >= 2)
        .toList();
    return _rows
        .where((r) {
          if (r.isArchived) return false;
          if (maxPrice != null && r.price > maxPrice) return false;
          if (!includeUnavailable && !r.isOrderable) return false;
          if (tokens.isEmpty) return true;
          final hay = '${r.name} ${r.category} ${r.description} ${r.stallName}'
              .toLowerCase();
          return tokens.any(hay.contains);
        })
        .take(limit)
        .map((r) => r.toModel())
        .toList();
  }

  @override
  Future<List<AiMenuRecommendation>> verifyMenuCandidates(
    List<String> menuIds, {
    int? maxPrice,
    bool includeUnavailable = false,
  }) async {
    final set = menuIds.toSet();
    return _rows
        .where((r) {
          if (!set.contains(r.id) || r.isArchived) return false;
          if (maxPrice != null && r.price > maxPrice) return false;
          if (!includeUnavailable && !r.isOrderable) return false;
          return true;
        })
        .map((r) => r.toModel())
        .toList();
  }
}

class _CatalogRow {
  const _CatalogRow({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.isArchived,
    required this.stallId,
    required this.stallName,
    required this.stallBlock,
    required this.stallIsOpen,
    required this.ownerIsActive,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final bool isAvailable;
  final bool isArchived;
  final String stallId;
  final String stallName;
  final String stallBlock;
  final bool stallIsOpen;
  final bool ownerIsActive;

  bool get isOrderable =>
      ownerIsActive && stallIsOpen && !isArchived && isAvailable;

  String? get unavailableReason {
    if (!ownerIsActive) return 'owner_inactive';
    if (!stallIsOpen) return 'stall_closed';
    if (!isAvailable) return 'menu_unavailable';
    return null;
  }

  AiMenuRecommendation toModel() => AiMenuRecommendation(
    id: id,
    name: name,
    description: description,
    category: category,
    price: price,
    hasPhoto: false,
    isAvailable: isAvailable,
    isOrderable: isOrderable,
    unavailableReason: unavailableReason,
    stall: AiStallSummary(
      id: stallId,
      name: stallName,
      block: stallBlock,
      waitMinutes: 10,
      isOpen: stallIsOpen,
      ownerIsActive: ownerIsActive,
    ),
  );
}

class _StubCatalogStore implements CatalogStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubOwnerStore implements OwnerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubMediaStore implements OwnerMediaStore {
  @override
  Future<Uint8List?> read(String objectPath) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCustomerStore implements CustomerStore {
  @override
  Future<Map<String, Object?>> getCart(String customerId) async => const {
    'stall': null,
    'items': <Object?>[],
    'general_note': '',
    'draft_version': 1,
    'subtotal': 0,
    'total_quantity': 0,
    'has_blocking_issues': false,
    'price_changed': false,
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubAdminStore implements AdminStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

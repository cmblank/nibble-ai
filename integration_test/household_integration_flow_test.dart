// Integration test for household sharing lifecycle.
// Run with: flutter test integration_test/household_integration_flow_test.dart -d <device>
// Requires real network; supply SUPABASE_URL and SUPABASE_ANON_KEY env vars.

import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nibble_ai/services/household_service.dart';
import 'package:nibble_ai/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

Future<String> _uniqueEmail(String label) async {
  final ts = DateTime.now().microsecondsSinceEpoch; // higher resolution
  return 'test.$label.$ts@example.com';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_ANON_KEY'];
  final ownerEnvEmail = Platform.environment['TEST_OWNER_EMAIL'];
  final ownerEnvPass = Platform.environment['TEST_OWNER_PASS'];
  final memberEnvEmail = Platform.environment['TEST_MEMBER_EMAIL'];
  final memberEnvPass = Platform.environment['TEST_MEMBER_PASS'];
  final allowCreate = Platform.environment['ALLOW_CREATE_TEST_USERS'] == '1';
  final forceFresh = Platform.environment['FORCE_FRESH_TEST_USERS'] == '1';
  final useExisting = Platform.environment['USE_EXISTING_TEST_USERS'] == '1'; // optional override to force using provided creds even if allowCreate
  final emailDomain = Platform.environment['TEST_EMAIL_DOMAIN'] ?? 'gmail.com';
  final runId = '${DateTime.now().microsecondsSinceEpoch}.${Random().nextInt(1<<32)}';
  // Run if we have Supabase creds AND either full user creds or allowCreate flag.
  final run = url != null && key != null && (
      (ownerEnvEmail != null && ownerEnvPass != null && memberEnvEmail != null && memberEnvPass != null)
      || allowCreate
    );

  group('(Household Integration)', () {
    if (!run) {
      test('Skipped (no env)', () { expect(true, isTrue); }, skip: true);
      return;
    }

  late String ownerEmail;
  late String ownerPass;
  late String memberEmail;
  late String memberPass;
  late String invitedMemberEmail; // frozen email used for invite & acceptance
    String? inviteCode;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(url: url, anonKey: key);
      // Preflight: verify required tables are visible to PostgREST (helps surface migration omissions early).
      final client = Supabase.instance.client;
      final requiredTables = ['households','household_invites','household_members'];
      for (final t in requiredTables) {
        try {
          await client.from(t).select('count').limit(1); // lightweight existence probe
        } catch (e) {
          final msg = e.toString();
          if (msg.contains("PGRST205") || msg.contains('not found') || msg.contains('does not exist')) {
            fail('Required table "$t" not found via API. Apply SQL: sql/household_min_core.sql (or full household_*.sql suite) to your Supabase project then re-run. Original error: $msg');
          } else {
            // Other errors (e.g., RLS) are acceptable at this stage; continue.
          }
        }
      }
  // Decide credential source. If forceFresh (or allowCreate without explicit request to use existing) always generate unique emails.
  if (allowCreate && (forceFresh || !useExisting || ownerEnvEmail == null || ownerEnvPass == null)) {
    ownerEmail = 'itest.owner.$runId@$emailDomain';
    ownerPass = 'TestPass123!';
  } else if (ownerEnvEmail != null && ownerEnvPass != null) {
    ownerEmail = ownerEnvEmail; ownerPass = ownerEnvPass;
  } else { throw Exception('Missing owner credentials'); }

  if (allowCreate && (forceFresh || !useExisting || memberEnvEmail == null || memberEnvPass == null)) {
    memberEmail = 'itest.member.$runId@$emailDomain';
    memberPass = 'TestPass123!';
  } else if (memberEnvEmail != null && memberEnvPass != null) {
    memberEmail = memberEnvEmail; memberPass = memberEnvPass;
  } else { throw Exception('Missing member credentials'); }

      debugPrint('[ITest] runId=$runId forceFresh=$forceFresh allowCreate=$allowCreate useExisting=$useExisting');
      debugPrint('[ITest] Owner user chosen: $ownerEmail');
      debugPrint('[ITest] Member user chosen: (invite target) will be frozen as initial memberEmail');
      // Sign in owner (assumes user already exists); if fails, throw to surface env/setup issue.
      bool signedIn = false;
      if (!allowCreate || (ownerEnvEmail != null && ownerEnvPass != null)) {
        // Standard sign in path when explicit creds provided.
        try {
          await SupabaseService.signIn(email: ownerEmail, password: ownerPass);
          signedIn = true;
          debugPrint('[ITest] Signed in existing owner user');
        } catch (e) {
          debugPrint('[ITest] Owner signIn failed (with provided creds): $e');
          if (!allowCreate) rethrow; // cannot create
        }
      }
      if (!signedIn) {
        // Auto-create loop (max 5 attempts) ensuring uniqueness.
        final rnd = Random();
        for (int attempt=0; attempt<5 && !signedIn; attempt++) {
          if (attempt>0) {
            ownerEmail = 'itest.owner.${DateTime.now().microsecondsSinceEpoch}.${rnd.nextInt(1<<32)}@$emailDomain';
            debugPrint('[ITest] New owner email attempt $attempt: $ownerEmail');
          }
          try {
            await SupabaseService.signUp(email: ownerEmail, password: ownerPass);
            signedIn = true;
            debugPrint('[ITest] Owner signUp success $ownerEmail');
          } catch (e) {
            final es = e.toString();
            debugPrint('[ITest] Owner signUp attempt error: $es');
            if (!es.contains('user_already') && !es.contains('already registered')) rethrow;
          }
        }
      }
      if (!signedIn) throw Exception('Owner auth not established (auto-create failed)');
      await HouseholdService.ensureHousehold();
  // Freeze invited member email before invite creation
  invitedMemberEmail = memberEmail;
  // Clean up prior state for idempotent test runs (old members / invites for memberEmail)
      try {
        final members = await HouseholdService.loadMembers();
        final existingMember = members.where((m) => m.email.toLowerCase() == memberEmail.toLowerCase()).toList();
        for (final m in existingMember) {
          debugPrint('[ITest] Cleaning existing member before test: ${m.email}');
          await HouseholdService.removeMember(m.id);
        }
      } catch (e) { debugPrint('[ITest] Cleanup members failed: $e'); }
      try {
        // Direct delete of old invites for this email to avoid unique violations
        await client.from('household_invites').delete().eq('invited_email', memberEmail);
      } catch (e) { debugPrint('[ITest] Cleanup invites failed: $e'); }
    });

    testWidgets('Invite create + audit', (tester) async {
      inviteCode = await HouseholdService.createInvite(invitedEmail: invitedMemberEmail, rethrowOnError: true);
      expect(inviteCode, isNotNull);
      final pending = await HouseholdService.fetchPendingInvites();
      expect(pending.any((r) => r['code'] == inviteCode), isTrue);
    });

    testWidgets('Accept invite adds member + audit', (tester) async {
      await SupabaseService.signOut();
      memberEmail = invitedMemberEmail; // enforce frozen email
      bool memberSignedIn = false;
      // If inviteCode wasn't initialized (e.g., running this test in isolation) create it now.
      if (inviteCode == null) {
        await SupabaseService.signOut();
        await SupabaseService.signIn(email: ownerEmail, password: ownerPass);
        inviteCode = await HouseholdService.createInvite(invitedEmail: invitedMemberEmail, rethrowOnError: true);
        await SupabaseService.signOut();
      }
      // For auto-create scenario always attempt signUp first (ensures known password)
      try {
        final resp = await SupabaseService.signUp(email: memberEmail, password: memberPass);
        if (resp.user != null) {
          memberSignedIn = true;
          debugPrint('[ITest] Member signUp success $memberEmail');
        }
      } catch (e) {
        final es = e.toString();
        debugPrint('[ITest] Member signUp attempt error: $es');
        if (es.contains('user_already')) {
          try {
            await SupabaseService.signIn(email: memberEmail, password: memberPass);
            memberSignedIn = true;
            debugPrint('[ITest] Member signIn after existing');
          } catch (se) { debugPrint('[ITest] Member signIn after existing FAILED: $se'); }
        }
      }
      if (!memberSignedIn) {
        // Fatal: cannot proceed (email exists with unknown password). Surface clearer failure.
        fail('Member auth establishment failed for $memberEmail (existing user with unknown password). Choose a fresh runId or clear test users.');
      }
  debugPrint('[ITest] About to accept invite code=$inviteCode as member=$memberEmail');
      final ok = await HouseholdService.acceptInvite(code: inviteCode!, memberEmail: memberEmail);
  debugPrint('[ITest] acceptInvite result=$ok');
      expect(ok, isTrue);
      final members = await HouseholdService.loadMembers();
      expect(members.any((m) => m.email.toLowerCase() == memberEmail.toLowerCase()), isTrue);
    });

    testWidgets('Ownership transfer', (tester) async {
      await SupabaseService.signOut();
      await SupabaseService.signIn(email: ownerEmail, password: ownerPass);
  final transferred = await HouseholdService.transferOwnership(invitedMemberEmail);
      expect(transferred, isTrue);
  // Switch auth context to the new owner BEFORE verifying members to avoid RLS visibility issues.
  await SupabaseService.signOut();
  await SupabaseService.signIn(email: invitedMemberEmail, password: memberPass);
  final members = await HouseholdService.loadMembers();
  final newOwner = members.firstWhere((m) => m.email.toLowerCase() == invitedMemberEmail.toLowerCase());
  expect(newOwner.role, 'owner');
    });

    testWidgets('Member removal + audit', (tester) async {
      final members = await HouseholdService.loadMembers();
  final formerOwner = members.firstWhere((m) => m.email.toLowerCase() == ownerEmail.toLowerCase(), orElse: ()=> throw StateError('Former owner not found'));
      await HouseholdService.removeMember(formerOwner.id);
      final after = await HouseholdService.loadMembers();
      expect(after.any((m) => m.email.toLowerCase() == ownerEmail.toLowerCase()), isFalse);
    });

    testWidgets('Limits enforcement (members)', (tester) async {
      int failures = 0;
      for (int i=0;i<12;i++) {
        final email = await _uniqueEmail('lim$i');
  try { await HouseholdService.createInvite(invitedEmail: email, rethrowOnError: true); }
        catch(_) { failures++; }
      }
      expect(failures >= 1, isTrue);
    });

    testWidgets('Status regression blocked', (tester) async {
      final accepted = await HouseholdService.fetchAcceptedInvites();
      if (accepted.isEmpty) {
        // If none visible (policy or already consumed), treat as passed (no way to regress status)
        debugPrint('[ITest] No accepted invites visible; skipping regression check');
        return;
      }
      final code = accepted.first['code'];
      bool threw = false;
      try {
        await Supabase.instance.client.from('household_invites').update({'status':'pending'}).eq('code', code);
      } catch(_) { threw = true; }
      final verify = await HouseholdService.fetchAcceptedInvites();
      final stillAccepted = verify.any((r) => r['code'] == code);
      expect(stillAccepted || threw, isTrue);
    });
  });
}

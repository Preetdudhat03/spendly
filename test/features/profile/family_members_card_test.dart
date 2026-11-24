import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/core/theme/app_theme.dart';
import 'package:spendly/features/profile/widgets/family_members_card.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';

void main() {
  final family = Family(
    id: 'fam-1',
    name: 'Dudhat Family',
    familyCode: 'FAM-1234',
    createdBy: 'u-admin',
    createdAt: DateTime(2026, 1, 1),
  );

  final members = [
    FamilyMember(
      id: 'm1',
      familyId: 'fam-1',
      userId: 'u-member',
      role: 'member',
      joinedAt: DateTime(2026, 2, 10),
      displayName: 'Keya',
    ),
    FamilyMember(
      id: 'm2',
      familyId: 'fam-1',
      userId: 'u-admin',
      role: 'admin',
      joinedAt: DateTime(2026, 1, 1),
      displayName: 'Preet',
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Admin sees clean member rows without 3-dot menu and opens Request to Leave Family sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FamilyMembersCard(
                family: family,
                members: members,
                currentUserId: 'u-admin',
                currentUserName: 'Preet',
                isCurrentUserAdmin: true,
                accentColor: const Color(0xFF4F46E5),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3-dots menu must NOT exist
    expect(find.byIcon(Icons.more_vert), findsNothing);
    // Admin hint & chevron on non-admin member only
    expect(find.text('Tap member to manage'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.text('(You)'), findsOneWidget);

    // Tap member row -> opens bottom sheet with "Request to Leave Family"
    await tester.tap(find.text('Keya'));
    await tester.pumpAndSettle();

    expect(find.text('Request to Leave Family'), findsOneWidget);
    expect(find.text('Remove from Family'), findsNothing);
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('Non-admin member does not see management actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FamilyMembersCard(
                family: family,
                members: members,
                currentUserId: 'u-member',
                currentUserName: 'Keya',
                isCurrentUserAdmin: false,
                accentColor: const Color(0xFF818CF8),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.text('Tap member to manage'), findsNothing);
  });
}

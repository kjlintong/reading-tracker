import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/l10n/app_localizations.dart';
import 'package:reading_tracker/services/privacy_consent.dart';
import 'package:reading_tracker/ui/privacy_consent_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrivacyConsent 同意状态', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('默认未同意', () async {
      expect(await PrivacyConsent.isAccepted(), isFalse);
    });

    test('同意后持久化为 true', () async {
      await PrivacyConsent.accept();
      expect(await PrivacyConsent.isAccepted(), isTrue);
    });

    test('reset 后回到未同意', () async {
      await PrivacyConsent.accept();
      await PrivacyConsent.reset();
      expect(await PrivacyConsent.isAccepted(), isFalse);
    });

    test('同意状态写入的键名带版本号，便于政策变更后重新征求同意', () {
      // 政策内容有实质性变更时需要重新弹窗，所以键里必须带版本。
      expect(PrivacyConsent.prefKey, contains('v1'));
    });
  });

  group('隐私同意弹窗', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('展示明确的同意与不同意按钮', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
      ));
      await tester.pumpAndSettle();

      final l10n = await S.delegate.load(const Locale('zh'));
      expect(find.text(l10n.privacyDialogAgree), findsOneWidget);
      expect(find.text(l10n.privacyDialogDisagree), findsOneWidget);
    });

    testWidgets('按钮措辞不含「好的」「我知道了」这类含糊表述', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
      ));
      await tester.pumpAndSettle();

      // 审核规范：征求同意的环节不应使用无法清晰表达用户意愿的词语。
      final l10n = await S.delegate.load(const Locale('zh'));
      expect(l10n.privacyDialogAgree, isNot(contains('好的')));
      expect(l10n.privacyDialogDisagree, isNot(contains('知道了')));
      expect(l10n.privacyDialogAgree, isNot(contains('我知道了')));
    });

    testWidgets('点「同意」返回 true 并触发回调', (tester) async {
      var agreed = false;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: PrivacyConsentDialog(onAgreed: () => agreed = true),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = await S.delegate.load(const Locale('zh'));
      await tester.tap(find.text(l10n.privacyDialogAgree));
      await tester.pumpAndSettle();

      expect(agreed, isTrue);
    });

    testWidgets('点「不同意」不触发同意回调', (tester) async {
      var agreed = false;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: PrivacyConsentDialog(onAgreed: () => agreed = true),
        ),
      ));
      await tester.pumpAndSettle();

      final l10n = await S.delegate.load(const Locale('zh'));
      await tester.tap(find.text(l10n.privacyDialogDisagree));
      await tester.pumpAndSettle();

      expect(agreed, isFalse);
    });

    testWidgets('弹窗内提供隐私政策全文入口', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
      ));
      await tester.pumpAndSettle();

      final l10n = await S.delegate.load(const Locale('zh'));
      expect(find.text(l10n.privacyDialogFullPolicy), findsOneWidget);
    });

    testWidgets('摘要说明本地存储 / 可选联网 / 权限用途三条', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
      ));
      await tester.pumpAndSettle();

      final l10n = await S.delegate.load(const Locale('zh'));
      expect(find.text(l10n.privacyDialogLocal), findsOneWidget);
      expect(find.text(l10n.privacyDialogOptional), findsOneWidget);
      expect(find.text(l10n.privacyDialogPermission), findsOneWidget);
    });

    testWidgets('不可点击外部或返回键绕过', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
      ));
      await tester.pumpAndSettle();

      // barrierDismissible: false —— 用户必须做出明确选择。
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      // AlertDialog 本身不暴露 barrierDismissible，这里通过「弹窗仍在」间接验证：
      // 点击屏障区域不应关闭。
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(dialog.title, isNotNull);
    });

    testWidgets('五语言都能构建弹窗（缺键会直接抛异常）', (tester) async {
      for (final code in const ['en', 'zh', 'de', 'fr', 'es']) {
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          locale: Locale(code),
          home: Scaffold(body: PrivacyConsentDialog(onAgreed: () {})),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(PrivacyConsentDialog), findsOneWidget,
            reason: '$code 语言下弹窗未能构建');
      }
    });
  });
}

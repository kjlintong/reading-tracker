import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('zh')
  ];

  /// Application title shown on the home screen and task switcher
  ///
  /// In en, this message translates to:
  /// **'Readnest'**
  String get appTitle;

  /// Bottom navigation: bookshelf
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get navShelf;

  /// Bottom sheet: add-a-book title
  ///
  /// In en, this message translates to:
  /// **'Add a book'**
  String get addBookSheetTitle;

  /// Add-book sheet: manual entry
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get addBookManualTitle;

  /// Add-book sheet: manual entry description
  ///
  /// In en, this message translates to:
  /// **'Type in the title and author yourself — no account or file needed.'**
  String get addBookManualDesc;

  /// Bottom navigation: statistics
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Bottom navigation: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Settings section title for tipping the developer
  ///
  /// In en, this message translates to:
  /// **'Support the Developer'**
  String get supportDev;

  /// Explanation under the tipping section
  ///
  /// In en, this message translates to:
  /// **'Every feature is free to use, with no ads and no in-app purchases. If the app helps with your reading, you can buy me a coffee — entirely optional, and nothing changes either way.'**
  String get supportDevDesc;

  /// Button to open the developer tip page
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee · Ko-fi'**
  String get openTipPage;

  /// No description provided for @openTipDomestic.
  ///
  /// In en, this message translates to:
  /// **'Support · Afdian (China)'**
  String get openTipDomestic;

  /// No description provided for @openTipForeign.
  ///
  /// In en, this message translates to:
  /// **'Support · Ko-fi (International)'**
  String get openTipForeign;

  /// Settings section title for app/developer information
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Explanation under the About section
  ///
  /// In en, this message translates to:
  /// **'Developer details and related links.'**
  String get aboutDesc;

  /// No description provided for @appIntroPage.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get appIntroPage;

  /// Label for the row opening the developer's website
  ///
  /// In en, this message translates to:
  /// **'Developer website'**
  String get developerHomepage;

  /// Label for the row opening the privacy policy in the current language
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @reportDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this report? This can\'t be undone.'**
  String get reportDeleteConfirm;

  /// No description provided for @reportDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reportDelete;

  /// Shows the app version number
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersionLabel({required String version});

  /// Import card title for Goodreads CSV
  ///
  /// In en, this message translates to:
  /// **'Goodreads / Library CSV import'**
  String get goodreadsImport;

  /// Import card description for Goodreads CSV
  ///
  /// In en, this message translates to:
  /// **'Import a library CSV exported from Goodreads and similar services (title, author, rating, shelf status).'**
  String get goodreadsImportDesc;

  /// Error when CSV lacks a Title column
  ///
  /// In en, this message translates to:
  /// **'No \"Title\" column found in the CSV'**
  String get goodreadsImportEmpty;

  /// Import card title for catalog search
  ///
  /// In en, this message translates to:
  /// **'Open Library / Google Books search import'**
  String get openLibraryImport;

  /// Import card description for catalog search
  ///
  /// In en, this message translates to:
  /// **'Search public catalogs by title or ISBN and import with enriched metadata (author, publisher, cover).'**
  String get openLibraryImportDesc;

  /// AppBar title of the public catalog search page
  ///
  /// In en, this message translates to:
  /// **'Catalog search'**
  String get catalogSearchTitle;

  /// Hint text of the search field on the catalog search page
  ///
  /// In en, this message translates to:
  /// **'Enter a title or ISBN'**
  String get catalogSearchHint;

  /// Label of the search button on the catalog search page
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get catalogSearchAction;

  /// Empty-state blurb shown before the first catalog search
  ///
  /// In en, this message translates to:
  /// **'Search public catalogs on Google Books and Open Library. Selected books are added with author, publisher, cover and page count.'**
  String get catalogSearchInitial;

  /// Shown when the catalog search returns no results
  ///
  /// In en, this message translates to:
  /// **'No matching books found — try a different keyword.'**
  String get catalogNoResult;

  /// Shown when the catalog search request throws
  ///
  /// In en, this message translates to:
  /// **'Search failed: {e}'**
  String catalogSearchFailed({required Object e});

  /// Title of the consent dialog shown before uploading a shelf screenshot to the user's AI service
  ///
  /// In en, this message translates to:
  /// **'Send bookshelf screenshot to AI service?'**
  String get imageUploadConsentTitle;

  /// Explains the screenshot will leave the device and go to a third-party AI service
  ///
  /// In en, this message translates to:
  /// **'To let the AI read your entire shelf screenshot, this image is sent to the AI service you configured in Settings (a third party). It contains no note text, but does include book titles and covers. Allow this upload?'**
  String get imageUploadConsentBody;

  /// Confirm button label on the consent dialog
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Cancel button label on the consent dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'WeRead API key not configured'**
  String get s_178329ba;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[\\s·・\\-—_:：,，。.·（）()\\[\\]【】]'**
  String get s_dd204792;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'LLM API key not configured'**
  String get s_ad86a5ca;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Fill it in under Settings → LLM'**
  String get s_8a853cbe;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No model selected'**
  String get s_7d704c88;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tap \"Fetch models\" to pick one from your account\'s available list'**
  String get s_4508cedd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Output valid JSON only — no explanatory text, no markdown code blocks.'**
  String get s_1b5140db;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model service returned an error: {apiError}'**
  String s_c94c96fc({required Object apiError});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Raw response: {head}\nFirst check the address and model name under Settings → LLM using \"Fetch models\". An unpaid balance or a model that isn\'t enabled will also land here.'**
  String s_3b43c7c4({required Object head});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model\'s response couldn\'t be parsed'**
  String get s_231cf54a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Raw response: {head}\nThe gateway returned a non-standard structure. Try another model or protocol; sending us this raw text also helps us add support for it.'**
  String s_90747d4c({required Object head});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The message is empty and can\'t be sent'**
  String get s_9d9714af;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model refused this request'**
  String get s_f44ff25c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The content was flagged as inappropriate. Rephrase it or try another model.'**
  String get s_cad5bf6e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'API key not configured'**
  String get s_0f7b54a1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Enter the key before fetching models'**
  String get s_345e9547;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The service returned an empty model list'**
  String get s_3a5d4cca;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch models: {apiError}'**
  String s_cea80527({required Object apiError});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You can enter the model name manually'**
  String get s_4674d953;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Raw response: {raw}'**
  String s_749fc40e({required Object raw});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This service doesn\'t provide a model-list endpoint (404)'**
  String get s_8add575d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Just type the model name in, e.g. deepseek-chat / claude-sonnet-5'**
  String get s_53fb436d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No model name entered'**
  String get s_438a5695;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tap \"Fetch models\" first, or type one in'**
  String get s_1da90e20;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reply with two characters: OK'**
  String get s_2abb6b8a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You are a book cataloguing assistant. Output JSON only, no explanations.'**
  String get s_ad736a74;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Known title \"{title}\"{author}.\nPlease fill in:\n- categoryPrimary: must be one of: {vocab}\n- description: a neutral 80–150 character summary of the book\'s content, stating facts without evaluation\n- tags: 3–5 keyword tags\n- authors: an array if the author can be determined, otherwise an empty array\nOutput format: {\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}'**
  String s_4304f539({required Object author, required Object title, required Object vocab});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You are a reading-profile analyst. Output JSON only, no explanations.'**
  String get s_cbe8aa6b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Here is my reading data (JSON):\n{summary}\n\nGive me 10 personality tags, each 2–6 words, like the nicknames a book club gives people.\nRequirements:\n1. Every tag must be supported by the data above — don\'t make things up\n2. Style reference: Learning Is My Joy / In Tune with Nature / Beauty Above All / Erudite Across the Ages / The Lonely Sage\n3. Don\'t use empty words like \"reader\", \"enthusiast\" or \"aficionado\"\n4. No explanations, no markdown code blocks\nOutput format: {\"tags\":[\"tag1\",\"tag2\"]}'**
  String s_3864d3b4({required Object summary});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You are a personal reading advisor. Analyse the data objectively, avoid vague praise, and point out the structural problems that are being overlooked.'**
  String get s_99acf9a4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Connection timed out: couldn\'t reach {host} within 20 seconds'**
  String s_46e5ebef({required Object host});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Check the network or the base URL; some overseas services need a proxy from mainland China'**
  String get s_3c836870;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Send timed out'**
  String get s_84264711;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The upstream connection is unstable; try again later'**
  String get s_225ed2e1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Response timed out: the model didn\'t respond within 180 seconds'**
  String get s_b265cf86;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Try a faster model, or shorten the report period and retry'**
  String get s_cc12eea3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'HTTPS certificate validation failed'**
  String get s_d711b259;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'For a self-hosted or intranet endpoint, switch to a trusted certificate'**
  String get s_4722b0f8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get s_07a2b144;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Network unreachable: can\'t connect to {host}'**
  String s_8ae0b0e4({required Object host});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'① Check the phone\'s network; ② make sure the base URL is complete (including /v1); ③ check whether the service needs a proxy; ④ a local service (Ollama) can\'t be reached from the phone via the computer\'s localhost'**
  String get s_0a9425b8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The connection was interrupted'**
  String get s_554d5235;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Usually a blocked network permission, or a proxy or firewall dropping the connection; plaintext HTTP may also be unsupported. Retry later or switch networks.'**
  String get s_020fe21a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Network request failed'**
  String get s_dfde23b1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Check the base URL, proxy settings and network'**
  String get s_2ae4f5fe;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Request rejected (400){detail}'**
  String s_d6ac5952({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Most likely the model name is wrong, or the model doesn\'t support the current parameters'**
  String get s_cb980461;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Authentication failed (401){detail}'**
  String s_d9775d22({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The API key is invalid or expired — copy a fresh one'**
  String get s_c4198142;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Insufficient account balance (402)'**
  String get s_e06ab1cc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No permission (403){detail}'**
  String s_05b3ec8b({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The key has no permission to call this model, or the account isn\'t verified/enabled'**
  String get s_f00f6ff2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Endpoint or model not found (404){detail}'**
  String s_016f7576({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Check whether the base URL is filled in up to /v1; use \"Fetch models\" to get the model name'**
  String get s_a8aa2c59;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Invalid parameters (422){detail}'**
  String s_9688a257({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Rate limited (429)'**
  String get s_1b3daaa3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Try again shortly, or upgrade your plan'**
  String get s_2a564df1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Server error ({code})'**
  String s_6627221e({required int? code});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A problem on the remote side; try again later'**
  String get s_2fe391dd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Request failed{code}{detail}'**
  String s_679e6c2e({required Object code, required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'(empty response body)'**
  String get s_0cf0a499;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Network request failed. Check the phone\'s network and the base URL under Settings → LLM.'**
  String get s_9ed7e745;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible'**
  String get s_2ad3b6ba;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Enter the base URL up to /v1, e.g. https://api.deepseek.com/v1'**
  String get s_e2213e87;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The base URL is usually https://api.anthropic.com (without /v1)'**
  String get s_17a4ba0f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'SenseNova'**
  String get s_f1ea3335;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Qwen'**
  String get s_e522fe39;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Zhipu GLM'**
  String get s_7e12f8b4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Moonshot Kimi'**
  String get s_c3d30bc2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'SiliconFlow'**
  String get s_8e941e27;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Ollama (local)'**
  String get s_c800478c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Any non-empty string'**
  String get s_0babfa89;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading days are days manually recorded as read'**
  String get s_e74f752c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading time and days come from WeRead\'s {year} yearly statistics (full-year basis)'**
  String s_9ea3cbae({required Object year});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'WeRead only provides yearly figures, so reading days for this range can\'t be given precisely; time is aggregated at month granularity'**
  String get s_f676228c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Unrated'**
  String get s_06225788;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{i} stars'**
  String s_89cfaca8({required Object i});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get s_e7a2db51;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{y}'**
  String s_a87cfcc9({required Object y});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Last {n} months'**
  String s_62654321({required Object n});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading time and days are aggregated at month/year granularity'**
  String get s_41f3af95;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Start your next book and this list gets its first number.'**
  String get s_e8a43314;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The shelf is still empty — every reading history starts here.'**
  String get s_af03278c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{streak} days of consecutive reading — the rhythm has taken hold.'**
  String s_f53eead8({required Object streak});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A {streak}-day streak — don\'t let it break today.'**
  String s_ff1565a3({required Object streak});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{streak} days in a row — a habit worth more than any reading list.'**
  String s_1736f17e({required Object streak});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{finished} books finished — swap speed for rhythm and you\'ll go further.'**
  String s_9a3fb5e5({required Object finished});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{finished} books finished. Look back now and then at which ones really stuck.'**
  String s_9d430ad3({required Object finished});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{finished} books finished in this stretch — every one counts.'**
  String s_597f7c05({required Object finished});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{finished} books finished. Pick up one you already started next.'**
  String s_1c87153f({required Object finished});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes read in this stretch — make half an hour a daily habit and that\'s 180 hours a year.'**
  String s_41db17b9({required Object minutes});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes logged already. Add a little more today?'**
  String s_6a57c553({required Object minutes});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your shelf is ready — start today\'s ten minutes with a light short story.'**
  String get s_152a88d7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Pick a book you\'ve already started — ten minutes counts as a win.'**
  String get s_795806c0;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to read a lot in one go — opening any book today counts.'**
  String get s_aa51bf46;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get s_363c6a0c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Learning Is My Joy'**
  String get s_420a7ac1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Personal Growth'**
  String get s_bcd278a6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} personal-growth books · {pct}'**
  String s_3702d226({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Romantic and Poetic'**
  String get s_6672b3fa;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get s_d422d33c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} literature books · {pct}'**
  String s_40ba4ecb({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The Lonely Sage'**
  String get s_ea2eaec4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Philosophy'**
  String get s_5da32671;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} philosophy books · {pct}'**
  String s_0f80a135({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Lessons from History'**
  String get s_111ec0f6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get s_07f288e9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} history books · {pct}'**
  String s_abeb8e3d({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Looks Inward'**
  String get s_5e336507;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Psychology'**
  String get s_4307c7a8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} psychology books · {pct}'**
  String s_cfce6d52({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tech Elite'**
  String get s_d5e26f37;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Computing'**
  String get s_8612fa7f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} computing books · {pct}'**
  String s_d6bdf44e({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Beauty Above All'**
  String get s_00dcb308;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get s_b31e932c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} art books · {pct}'**
  String s_aee18737({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Rational and Practical'**
  String get s_2ddd554c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get s_56734d39;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get s_5974bf24;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} economics & business books · {toStringAsFixed}%'**
  String s_066faf9c({required Object cat, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Worldly Wise'**
  String get s_d574ffeb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Social Science'**
  String get s_086ac5bf;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} social-science books · {pct}'**
  String s_5a276724({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Insatiably Curious'**
  String get s_d81bab36;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Popular Science'**
  String get s_41fa5c70;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get s_fcc3102d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{n} popular-science and tech books'**
  String s_76c118d0({required Object n});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Learns from Others'**
  String get s_2b65326c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get s_f85fa7d4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} biographies · {pct}'**
  String s_b2e9db16({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Healthy Living'**
  String get s_9e49409c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get s_c21b69a8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} medicine & health books'**
  String s_1dd31356({required Object cat});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Pragmatic Borrower'**
  String get s_77e32253;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Law'**
  String get s_0323f1bb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} law books'**
  String s_82364cc8({required Object cat});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Self-Entertained'**
  String get s_ea038731;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Comic'**
  String get s_dbb1c112;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Children\'s Books'**
  String get s_6398a679;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} comics and children\'s books'**
  String s_a1b1d26a({required Object cat});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'In Tune with Nature'**
  String get s_94f8d7c2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get s_30412ad5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} religion books'**
  String s_d00fbfe6({required Object cat});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Knows How to Live'**
  String get s_52c36d65;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get s_06e23c48;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} lifestyle books · {pct}'**
  String s_e3a3f18e({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Teacher at Heart'**
  String get s_dc2e94c1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get s_235af603;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{cat} education books · {pct}'**
  String s_be73b4a0({required Object cat, required Object pct});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Erudite Across the Ages'**
  String get s_7ea6e8a9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your library spans {categoryKinds} categories — a bit of everything'**
  String s_938fd6ec({required Object categoryKinds});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Deep Focus'**
  String get s_41a09d04;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{total} books fall into only {categoryKinds} categories'**
  String s_c61130ac({required Object categoryKinds, required Object total});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Finisher'**
  String get s_431dc47d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Finish rate {toStringAsFixed}% ({finished}/{total})'**
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tsundoku Master'**
  String get s_6b51050c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{wish} want-to-read, but only {finished} finished'**
  String s_55413cd8({required Object finished, required Object wish});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Cuts Losses Fast'**
  String get s_e60e931c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{abandoned} dropped · {toStringAsFixed}% — you put down what doesn\'t grab you'**
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Serial Starter'**
  String get s_4be15f8c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{stalled} books in progress but under 15%'**
  String s_b0a853cf({required Object stalled});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Gentle Spirit'**
  String get s_10b9bddd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your {ratedCount} rated books average {toStringAsFixed}'**
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sharp-Tongued Critic'**
  String get s_e67694db;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your {ratedCount} rated books average only {toStringAsFixed}'**
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Strong Opinions'**
  String get s_fe4567e4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Rating standard deviation {toStringAsFixed} — your good and bad are far apart'**
  String s_b1d69175({required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Revisits and Renews'**
  String get s_fbad19d5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reread} books read twice or more'**
  String s_8d62979c({required Object reread});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Immersive Reader'**
  String get s_54302bb2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{round} minutes per active day on average'**
  String s_bc9dbced({required Object round});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Digital Native'**
  String get s_e9eddf51;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{weread} from WeRead · {toStringAsFixed}%'**
  String s_df5bbdba({required Object toStringAsFixed, required Object weread});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Paper and Digital'**
  String get s_ce6517f9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'plus {libraryCount} borrowed and {paper} paper books'**
  String s_75c2fd5a({required Object libraryCount, required Object paper});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reads with Ears'**
  String get s_8cac22b7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{audio} audiobooks'**
  String s_72b826e9({required Object audio});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Visual Reader'**
  String get s_7caeab27;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{comic} comics'**
  String s_a5a44a39({required Object comic});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{m}/{y}'**
  String s_0e59d960({required Object m, required Object y});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Month {month}'**
  String s_1a2e873e({required Object month});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Image preprocessing failed; using the original image: {e}'**
  String s_5583162a({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Failed to convert to JPEG: {e}'**
  String s_628c2132({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Parsing the layout structure…'**
  String get s_ebf4bdfb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Cleaning up recognition results with the LLM…'**
  String get s_ba1038b1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Verifying titles…'**
  String get s_6292a274;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[\\s《》「」『』…⋯.\\-—_:：]'**
  String get s_427e1f0d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Title completed'**
  String get s_af041a1b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reason}, title completed'**
  String s_988dd5cb({required Object reason});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[、,，;/]'**
  String get s_a746d189;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'\"{title}\": {e}'**
  String s_a4ec75fd({required Object e, required Object title});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Multimodal recognition'**
  String get s_d2bbf7ce;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This is a screenshot of a shelf or reading list'**
  String get s_381ca835;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This is a screenshot of a single book\'s cover or detail page'**
  String get s_fce28e56;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{scene}.\n\nOutput a JSON array only, each item shaped like:\n{\"title\":\"title\",\"author\":\"author\",\"progress\":a number from 0-100 or null,\"status\":\"one of unread/reading/finished or null\",\"confidence\":a number from 0-1}\n\nRequirements:\n1. Only output books that are **actually visible** in the image; don\'t add books you assume should be there;\n2. Ignore UI text (filters, search, sort, All, Shelf, N books, etc.);\n3. Copy titles exactly as shown, including ones cut off by an ellipsis — don\'t complete them yourself;\n4. Leave author as an empty string if it can\'t be read; don\'t guess;\n5. Only fill in author when it really is written in the image.\n{n}'**
  String s_ba5425c5({required Object n, required Object scene});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'You extract information from bookshelf screenshots. Output a JSON array only, with no explanatory text.'**
  String get s_951042c3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'LLM cleanup'**
  String get s_29dbdb32;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A photo of a book cover or spine'**
  String get s_9cd6567e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A screenshot of an e-book app\'s shelf'**
  String get s_a6db1cf4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Below are the text lines OCR\'d from {scene}, in top-to-bottom order.\n\nExtract the **real book titles** from them, ignoring all UI text (search box, filters, categories, status bar, page numbers, chapter headings, buttons, statistics).\n\nRules:\n1. Only output books that actually appear in the image. Don\'t add books you assume should be there.\n2. If a title is truncated by an ellipsis in the UI (for example \"Deep…\"), complete it into the full title.\n3. progress takes an integer percentage from 0–100; leave it an empty string if it can\'t be read. Note that \"0.8%\" is 0.8, not 80.\n4. status must be one of \"unread / reading / finished / dropped\"; leave it an empty string if it can\'t be read.\n5. Only fill in author when it clearly appears in the image; otherwise leave it blank. Don\'t guess.\n6. Skip lines you\'re unsure about. Better to miss one book than to add a fake one.\n\nOutput a JSON array only, with elements shaped like:\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nOCR text lines:\n\"\"\"\n{ocrText}\n\"\"\"'**
  String s_43fca769({required Object ocrText, required Object scene});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[\\s《》「」『』]'**
  String get s_cbb756f7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get s_95222176;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Want to read'**
  String get s_5a833930;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get s_b9bf9b53;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Currently reading'**
  String get s_be5492a5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Finished reading'**
  String get s_44c14529;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get s_0872b5b7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get s_300a32bd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Dropped (merged into Shelved)'**
  String get s_0f4d9c68;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'\\s*(著|编著|译|著译)\$'**
  String get s_7675d229;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[，。；、？！：）」』]\$'**
  String get s_285bb37e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'(著|编著|译|著译)\$'**
  String get s_8f936d11;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[（《·“]\$'**
  String get s_d0c345ec;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[）》」』”]\$'**
  String get s_2d3c83a7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Largest text on cover'**
  String get s_0686f279;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Secondary cover text'**
  String get s_5514105a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Contains Chinese'**
  String get s_174faffb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Has progress or status'**
  String get s_b13a1237;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Has author'**
  String get s_24745e9d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reasonable length'**
  String get s_0cedc3f4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get s_5bdfa6ae;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get s_58171266;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Columns left-aligned'**
  String get s_1e8c236b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Cover lettering'**
  String get s_89ac54fb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Too-short English'**
  String get s_132a750b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[，。；、？！]\$'**
  String get s_6af25a96;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sentence-ending punctuation'**
  String get s_a335b25f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'％'**
  String get s_885dd894;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'《'**
  String get s_620b459e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'》'**
  String get s_150c7508;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Has title marks'**
  String get s_67df3afd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get s_5a09ed37;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Looks like an English UI word'**
  String get s_6b631636;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Adjacent line'**
  String get s_1dd3f274;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **', merged line break'**
  String get s_f547232b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get s_fc39b00e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Shelved'**
  String get s_eba88d83;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Ebook'**
  String get s_b6fe7962;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get s_c7673d27;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Audiobook'**
  String get s_02a1a8ed;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'WeRead'**
  String get s_fe152225;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'iReader Select'**
  String get s_2032cbd7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'JD Read'**
  String get s_12ed007e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'BOOX'**
  String get s_570bb7c8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get s_36bfef2d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get s_4139f3b5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get s_88cdd7e4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Thought'**
  String get s_6abc44a8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get s_67585b8a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading report'**
  String get s_96009a7e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generating in the background: {join}'**
  String s_4343b7b3({required Object join});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Automatically generated {ok} reports'**
  String s_a6c57a43({required Object ok});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generated {ok}, failed {failed} (you can retry manually)'**
  String s_f71dea06({required Object failed, required Object ok});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Connected · {model} · {latencyMs} ms'**
  String s_e93308dd({required Object latencyMs, required Object model});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model returned empty content'**
  String get s_d2a3748e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model may not support the current parameters, or content filtering was triggered. Try another model.'**
  String get s_3abdc334;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No LLM key configured. Fill one in under Settings → LLM and test the connection first'**
  String get s_cc72f973;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No model selected. Go to Settings → LLM and use \"Fetch models\" to pick one'**
  String get s_9e51ce93;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No books match in this period; try a different one'**
  String get s_c6e18e89;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Report period'**
  String get s_8bb45b34;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose a yearly or monthly report'**
  String get s_8bd59fb2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Filed by calendar year / month; once generated you can revisit it anytime. The current month\'s report is only generated next month.'**
  String get s_53bea04d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get s_1f048ed9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get s_38fb1115;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generating… (long text takes about a minute)'**
  String get s_a14e36dc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get s_b36c173d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sends this period\'s book list (title / author / category / rating) and aggregate statistics so the report can name specific books; note text and highlights are not uploaded.'**
  String get s_c94ade95;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get s_5e05e92a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{total} books'**
  String s_be9a1551({required Object total});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{finished} books'**
  String s_ce115766({required Object finished});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reading} books'**
  String s_8b46a11f({required Object reading});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{wish} books'**
  String s_81e94993({required Object wish});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get s_09b589b4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Report content · {label}'**
  String s_0825e123({required Object label});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get s_049eca89;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard'**
  String get s_50bf9961;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Auto-generate'**
  String get s_772cbfcf;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'When this is on, opening this page automatically generates any missing yearly report and last month\'s monthly report.'**
  String get s_01955ddf;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Auto-generate missing'**
  String get s_b2a52a3d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get s_b233138e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get s_877b864d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Past reports'**
  String get s_a3dfa2a6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Export reading data'**
  String get s_66772db6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get s_6b198f0b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Exported to: {saved}\n\n{counts}'**
  String s_a101fbdd({required Object counts, required Object saved});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Export failed: {e}'**
  String s_6ec2d38e({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file'**
  String get s_c699263b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read this file: {e}'**
  String s_e34bdbcb({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a backup file exported by this app (missing format marker, or newer than the current app)'**
  String get s_1dedeaa2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This file contains no restorable data'**
  String get s_103c5811;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restore now?'**
  String get s_674a7957;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This will overwrite this device\'s data with the backup:\n\n{length}\n\nRecords with the same name are overwritten whole — restoring means \"go back to the moment of the backup\", with no field-level merging. Books added after the backup will not be deleted.'**
  String s_94094e0d({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get s_a0451c97;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get s_ec7085ab;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restore complete{first}\n\n{counts}'**
  String s_2296b134({required Object counts, required Object first});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {e}'**
  String s_e669bac1({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{books} books'**
  String s_7c0be1cd({required int? books});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{notes} notes'**
  String s_dd2321ce({required int? notes});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reading_logs} reading logs'**
  String s_d48aa751({required int? reading_logs});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{llm_reports} AI reports'**
  String s_d044717e({required int? llm_reports});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{settings} settings entries'**
  String s_f4d248a7({required int? settings});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Data export & restore'**
  String get s_8719bf89;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'What\'s exported'**
  String get s_8fe27f12;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A full JSON snapshot: books, notes, reading logs, AI reports and settings. It saves as a single file — use it to restore on another device.'**
  String get s_5d9af0a7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Export as a JSON file'**
  String get s_582f4cb6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get s_091ad5f4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose a previously exported .json file. Records with the same name are overwritten whole, not merged field by field — this means \"go back to the moment of the backup\", not \"take the union\".'**
  String get s_3a36f742;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file and restore'**
  String get s_6f9ab88c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get s_f24f63da;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get s_ecbd7449;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get s_f98a79dc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get s_05712ea1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'A quote, a thought, or a review…'**
  String get s_e3fdcb7e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Chapter / page'**
  String get s_c8d8fada;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get s_f80f4749;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get s_abfe9512;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This book doesn\'t exist or has been deleted'**
  String get s_a647c2e0;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Author: {join}'**
  String s_154ada37({required Object join});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Translator: {join}'**
  String s_904feb6c({required Object join});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Publisher: {publisher}'**
  String s_1e4c61f8({required Object publisher});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Published: {first}'**
  String s_bf93bf6d({required Object first});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Category: {categoryPrimary}'**
  String s_def61e8c({required Object categoryPrimary});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get s_d9bdf56b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Progress {toStringAsFixed}%'**
  String s_94b27e86({required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get s_8331377a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get s_205eb716;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Record what this book is about'**
  String get s_b5e2aa8a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get s_3ec1ca86;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your thoughts and reviews'**
  String get s_aa5a5d3e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Notes · {length}'**
  String s_fb47d52b({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Jot one down when something strikes you — it\'ll be material for your year in review.'**
  String get s_18dd30c5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get s_4b7d48f2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Due: {dueAt}'**
  String s_5e52b06a({required String? dueAt});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get s_ad207008;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'、'**
  String get s_f5d99c16;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Title can\'t be empty'**
  String get s_65983593;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[,，、;；]'**
  String get s_1f0939bc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get s_6c7a6cc5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add a book manually'**
  String get s_31e2aa97;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get s_eda73905;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add to shelf'**
  String get s_71b10e99;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose a local cover'**
  String get s_2dae8ba5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Set cover'**
  String get s_5be7901d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get s_a59912dd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get s_e2b6c0de;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get s_22760472;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Separate multiple authors with commas'**
  String get s_5f70e9dd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get s_759fb403;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get s_da1c08d9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get s_5ce4e16d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Description / summary'**
  String get s_b0d7b0de;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Categories are normalized to a controlled vocabulary — typing \"Business & Motivation\" also merges into \"Business\", so statistics won\'t split into two separate buckets.'**
  String get s_d0dd45ac;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get s_b32f0afe;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get s_87635298;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get s_5aa23087;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {e}'**
  String s_573b6694({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Enhancing image…'**
  String get s_28690759;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No title recognized; try another image'**
  String get s_d5155b2d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading the image with a multimodal model…'**
  String get s_e20dac78;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The multimodal model couldn\'t read a title from this image. Check that the selected model accepts image input (text-only models reject it outright), or set Settings → Screenshot recognition → Recognition mode back to \"Auto\" to fall back to on-device OCR.'**
  String get s_5fea0487;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Multimodal returned nothing; falling back to on-device OCR…'**
  String get s_cdda9381;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Image upload not allowed; falling back to on-device OCR…'**
  String get s_b85e4cbc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Recognizing text…'**
  String get s_a9698571;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No text was found in this image. Try a different angle, get the text sharper, or just take a screenshot (screenshots are cleaner than photos).'**
  String get s_7ef6b42d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No title-like text found. If this is an inside page the title usually isn\'t on it — try \"Import shelf screenshot\" or photograph the cover instead.'**
  String get s_319b9488;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No title could be read from this image. Try cropping out the surrounding UI and retry.'**
  String get s_37588c9c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get s_04a1b347;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No \"Title\" column found in the CSV'**
  String get s_a9fe3793;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get s_3db59388;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get s_9e160a69;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Parsed {length} books. Import them?'**
  String s_d4b7c3c7({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading your WeRead shelf…'**
  String get s_649320a3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The shelf is empty, or the API returned no data'**
  String get s_e53774ba;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your WeRead shelf has {length} books. Import them?'**
  String s_8151aa42({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Completing metadata and saving…'**
  String get s_9b37038a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Import complete: {added} added, {duplicated} updated{failed}'**
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No WeRead books on this device yet — sync the shelf first'**
  String get s_28ab46d9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Syncing reading progress…'**
  String get s_6d61442b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Updated reading progress for {updated} of {length} books'**
  String s_a26c53db({required Object length, required Object updated});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The connection was interrupted. Check your network and retry.'**
  String get s_3a0cf870;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get s_1cbe2507;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get s_1df9fbd5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'WeRead API key'**
  String get s_874053cb;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code in WeChat to open weread.qq.com/r/weread-skills,\nthen copy the key shown on the page (it starts with \"wrk-\"). The key is stored on this device only.'**
  String get s_58652b51;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Import shelf screenshot'**
  String get s_cb2558f7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Pick a screenshot of your shelf and read each cell\'s title and progress. Results can be off — check before saving.'**
  String get s_24b715f3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Import shelf photo'**
  String get s_4f062f79;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Photograph a cover, spine or page; the title is detected and the rest of the metadata filled in. Results can be off — check before saving.'**
  String get s_6e464c0e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sync shelf from channels'**
  String get s_a5452d46;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reads your shelf and reading status through the official API of your configured channels — no screenshots needed. WeRead is supported today; more channels are on the way.'**
  String get s_d40e2a14;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sync reading progress'**
  String get s_af94a367;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Fetches each book\'s reading percentage and accumulated time. Some channel shelf endpoints omit progress, so it needs a separate request per book.'**
  String get s_59d2efab;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'CSV / Notion import'**
  String get s_fa52186c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'One-click migration from a Notion CSV export: column names are detected automatically and custom fields are preserved.'**
  String get s_2c78f2b8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get s_238b14fc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} books couldn\'t be imported'**
  String s_ed4b0551({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'…and {length} more'**
  String s_ec50ebde({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get s_18307d56;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} books recognized'**
  String s_cc0eef03({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get s_0f466d7a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get s_42b2fafa;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Read {totalLines} lines of text, kept {keptLines} books{usedLlm}{repairedTitles}'**
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Items marked \"completed\" or \"inferred\" are not verbatim from the image — please check them before importing. You can tap any title or author to edit it.'**
  String get s_4d52323f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add one manually (missed by OCR)'**
  String get s_0f40975c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Import the {length} selected'**
  String s_fdc0acd1({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The original image was truncated'**
  String get s_4443bd2c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Progress {progressPercent}%'**
  String s_7af46a28({required Object progressPercent});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Confidence {toStringAsFixed}%'**
  String s_4737de25({required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Original image: {rawText}'**
  String s_2df91ffc({required Object rawText});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Author (optional)'**
  String get s_7bbe0f10;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Delete this one'**
  String get s_bd13cf0b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Statistics range'**
  String get s_c048f107;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Total books'**
  String get s_89c61e4a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Status breakdown'**
  String get s_9da15a74;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get s_130a42ae;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Source breakdown'**
  String get s_98f42577;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Format breakdown'**
  String get s_5e8ebbe6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get s_5182e58a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Books rated'**
  String get s_50bcc778;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading time (minutes)'**
  String get s_59c5e73a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Days with reading activity'**
  String get s_48529b9f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No LLM key configured. Fill one in under Settings → LLM to generate.'**
  String get s_7be1388c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The model returned no usable tags; try another model'**
  String get s_992d7786;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Replace with this set?'**
  String get s_eead3bcd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your current {length} tags will be replaced with these {length_1}. You can still edit or delete them one by one afterwards.'**
  String s_b9da6464({required Object length, required Object length_1});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get s_89829921;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Replaced with the main tags'**
  String get s_0f8acec9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'That tag is already listed above'**
  String get s_93aebfd1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Added to the main tags'**
  String get s_bca518fd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Removed \"{text}\"'**
  String s_284dfaab({required Object text});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get s_8eb8d18d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This is a tag you wrote yourself; there\'s no automatic basis for it.'**
  String get s_35c48d07;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get s_724386f0;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tags you write yourself aren\'t validated and won\'t be overwritten by recomputation.'**
  String get s_fdd8c684;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reset tags to default?'**
  String get s_7b328e58;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Your manual edits will be cleared and the tags will be inferred again from your current library.'**
  String get s_b9a4d4ef;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Restored to tags inferred from your library'**
  String get s_0fcef2c8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'My reading profile'**
  String get s_e97565e5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the share image: {e}'**
  String s_783e43af({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generate share image'**
  String get s_14f92b04;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Saved to your photos'**
  String get s_a17c4e02;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {e}'**
  String s_3f81d5b6({required Object e});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Image ready'**
  String get s_c6d1e7a3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Save image to this device'**
  String get s_b8e4c9a1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Recompute'**
  String get s_51ebc0d1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'My reading personality tags'**
  String get s_6c64acc5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Inferred from {length} books'**
  String s_03bf36af({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'All the tags have been deleted. Tap \"Add\" below to write your own, or reset to default and let the app infer them again.'**
  String get s_a789d74f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get s_a1d885c1;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tap a tag to rename or delete it. For rule-inferred tags, the numbers behind them are visible in the edit dialog.'**
  String get s_64bff158;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get s_84bf2c49;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generate another set with AI'**
  String get s_5a251fee;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get s_18be3bbe;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading preferences'**
  String get s_7ae84af3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} categories'**
  String s_aeed65e7({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The circle\'s area is proportional to the number of books (so the radius is the square root of the count — using the count directly as the radius would exaggerate differences and mislead).'**
  String get s_f2a9e2a4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'AI generated · {stamp}'**
  String s_abd0dab0({required Object stamp});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Replace main tags'**
  String get s_7ea8e671;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Tap a single tag to add it to the main tags, or replace the whole set. This set is generated by the model from aggregate statistics, so its basis is less explicit than the rule-based one.'**
  String get s_d1a58b2f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No books in this range yet'**
  String get s_a38881a0;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Try another time range, or import some books first'**
  String get s_20fde694;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No category data yet'**
  String get s_9fe34cff;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{rangeLabel} · {bookCount} books'**
  String s_d9579b73({required Object bookCount, required Object rangeLabel});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Personality tags'**
  String get s_bfc50de8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading preferences'**
  String get s_ab5cc063;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading tracker · My shelf'**
  String get s_9de44e0f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Choose statistics range'**
  String get s_20a63774;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get s_d507abff;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get s_ff31410d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Configuration saved locally'**
  String get s_72cca1f6;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Filled in {name}; the API key is still needed'**
  String s_b6477017({required Object name});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Fetching model list…'**
  String get s_533f5118;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Selected model: {id}'**
  String s_648219b9({required Object id});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} models available (none selected)'**
  String s_baf95794({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Testing the connection…'**
  String get s_e37cab47;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Connected · {model}\nTook {latencyMs} ms; the model replied \"{reply}\"'**
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Verifying WeRead key…'**
  String get s_5df0d12b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Key is valid; the shelf currently has {n} books'**
  String s_bd245b07({required Object n});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach {host}\nCheck your network, whether the base URL is complete (including /v1), and whether the service needs a proxy'**
  String s_73f89115({required Object host});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'The endpoint timed out (180 seconds)'**
  String get s_9038e16e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Service returned {statusCode}: {e}'**
  String s_e0710bf5({required Object e, required int? statusCode});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Request failed: {name}'**
  String s_24d6c7ae({required Object name});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get s_4d3eb2b3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} in total'**
  String s_17d94005({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Clicking a suggestion writes the model name in'**
  String get s_a48ae43a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get s_b5c7b82d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Used to sync your shelf and reading progress. Scan the QR code to open weread.qq.com/r/weread-skills to get one.'**
  String get s_bc90fa59;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Verify key'**
  String get s_e44e9f26;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'LLM'**
  String get s_75bf6943;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Used for metadata fallback, screenshot recognition cleanup and reading reports.'**
  String get s_9e8f6691;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Provider presets'**
  String get s_cc3c9556;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Selecting one fills in the address and model'**
  String get s_9021b9f9;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get s_1fd51aaa;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Use \"Fetch models\" to pick from the list your account actually has'**
  String get s_209e1f28;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Fetch models'**
  String get s_ab135d7c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get s_a46a5664;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get s_e4f7e107;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get s_b13be56e;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Test and Fetch both save your entries first.'**
  String get s_9ac01f6b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Screenshot recognition'**
  String get s_0001747c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Determines how well photo and screenshot imports are recognized.'**
  String get s_3f5cbdbf;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Image enhancement preprocessing'**
  String get s_9130a4ed;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Enlarges and sharpens the image first, so small titles are recognized better.'**
  String get s_b79fc99c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Use the LLM to clean up recognition results'**
  String get s_9695a603;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Let the LLM clean up the recognized titles. Needs an LLM key and uses tokens.'**
  String get s_267118b5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Recognition mode'**
  String get s_6d7e1f9f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Auto (multimodal first, falls back to on-device)'**
  String get s_ed144a76;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Multimodal LLM reads the image directly'**
  String get s_c7bab837;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'On-device OCR (offline, free)'**
  String get s_d8f3da2a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'On-device OCR works offline but may miss titles; the multimodal model reads the layout but needs a network and may invent one. \"Auto\" uses both.'**
  String get s_f22e4cd2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get s_67677b3d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Export the whole database as JSON to move to another device. A fresh install starts with an empty shelf; add books from the Import tab to get going.'**
  String get s_d596ba9b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'One-tap export / restore'**
  String get s_39239742;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'All changes are saved to this device\'s database automatically — no manual save needed.'**
  String get s_3c21597a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Keys are stored only in this device\'s database; they are never bundled with the app or uploaded.'**
  String get s_68885a92;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get s_9b3c95d4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Recently finished'**
  String get s_97428491;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get s_8f38c041;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Most progress'**
  String get s_50a7317f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Title A–Z'**
  String get s_b5538557;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\"'**
  String s_e3cd14ba({required Object title});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get s_296fc9b4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get s_a444b428;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Switch to list'**
  String get s_fa0a5cdd;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Switch to cover grid'**
  String get s_cb4a4231;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Search title / author / publisher'**
  String get s_78966c42;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No books match these filters'**
  String get s_8ed41c6c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No books yet — add some from the Import tab'**
  String get s_bd33274a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} books'**
  String s_0cd6d0f8({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reading} reading · {finished} read'**
  String s_ff7e02df({required Object finished, required Object reading});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get s_68022ee7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'More filters'**
  String get s_542b67cc;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get s_ec977df0;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get s_50d471b2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Chart visibility'**
  String get s_37361909;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get s_b1288e4a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Hide all'**
  String get s_6b2b7015;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Show only the charts you care about; hide the rest.'**
  String get s_e91a9228;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get s_fe93ef35;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'[《》「」]'**
  String get s_0d65fca2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Due in {daysUntilDue} days'**
  String s_9380d869({required int? daysUntilDue});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get s_0e13c16f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading profile'**
  String get s_3ad4c4c8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'This period · {label}'**
  String s_7c6c253b({required Object label});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Attributed by each book\'s completion or activity date'**
  String get s_88c0b751;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get s_50ba5fd5;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Books added'**
  String get s_cc4556af;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get s_3509a9f8;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get s_a7e9ff0f;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Current shelf'**
  String get s_58d90b89;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Snapshot figures, unaffected by the time filter above'**
  String get s_c3bb899b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Total books'**
  String get s_563edd9d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading streak'**
  String get s_0d8d3eb3;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Started but stalled'**
  String get s_4ab30c5b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Structure · {label}'**
  String s_b563f985({required Object label});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} books included'**
  String s_a7e09561({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Status breakdown'**
  String get s_c6cc650b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Top 8 categories'**
  String get s_8137585d;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} categories'**
  String s_f92480e2({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Reading per month'**
  String get s_50feb68a;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No reading activity in this range yet'**
  String get s_750a3b1c;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Monthly reading time'**
  String get s_4d7dd157;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Shown after importing WeRead yearly statistics'**
  String get s_5a78dc03;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Rating distribution'**
  String get s_5b37ad6b;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Average {toStringAsFixed} · {unratedCount} unrated'**
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get s_3c1cb8ee;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'In-progress distribution'**
  String get s_01d886c7;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{readingInRange} in progress'**
  String s_ecf53f5a({required Object readingInRange});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No books in progress in this range'**
  String get s_faf98ba4;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{length} platforms'**
  String s_77030fdc({required Object length});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{first}'**
  String s_cea9cf70({required Object first});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{first}–{last}'**
  String s_c4e530bb({required Object first, required Object last});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{scope} · {toStringAsFixed} h total'**
  String s_00fbaae1({required Object scope, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'WeRead yearly statistics only cover {join}, so this chart is drawn by calendar year; the finished-books chart above uses the most recent 12 months.'**
  String s_e7b115df({required Object join});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{name}\n{toInt} books'**
  String s_9ef861db({required Object name, required Object toInt});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{i} · {toInt} books'**
  String s_2cf3ef4e({required Object i, required Object toInt});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{i} · {toStringAsFixed} h'**
  String s_e241a8ef({required Object i, required Object toStringAsFixed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'AI reading report'**
  String get s_1597bc27;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'{reportCount} archived · filed by year / month, revisit anytime'**
  String s_5024726e({required Object reportCount});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generate a yearly / monthly reading summary; open one to create it'**
  String get s_73f01b82;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get s_530f5951;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get s_d51cd7ae;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get s_f8525cf2;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **', by {author}'**
  String s_854a34ca({required Object author});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **': {detail}'**
  String s_edf331af({required Object detail});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'\nAdditional context: {hint}\n'**
  String s_50018e2c({required Object hint});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **'(backed up on {first})'**
  String s_a537d6ac({required Object first});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **', {failed} failed'**
  String s_acd7a061({required Object failed});

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **' · cleaned up with the LLM'**
  String get s_da4d4d27;

  /// auto-extracted
  ///
  /// In en, this message translates to:
  /// **' · completed {repairedTitles} truncated titles'**
  String s_af735e5a({required Object repairedTitles});

  /// Bottom navigation: notes + reading plans merged into one column
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navNotes;

  /// Notes page: chronological view
  ///
  /// In en, this message translates to:
  /// **'By time'**
  String get notesViewByTime;

  /// Notes page: grouped-by-book view
  ///
  /// In en, this message translates to:
  /// **'By book'**
  String get notesViewByBook;

  /// Notes page: book filter dropdown label
  ///
  /// In en, this message translates to:
  /// **'Filter by book'**
  String get notesFilterByBook;

  /// Notes page: book filter option meaning no filter
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get notesAllBooks;

  /// Notes page: placeholder when the note's book was deleted
  ///
  /// In en, this message translates to:
  /// **'Book removed'**
  String get notesBookMissing;

  /// Notes page: summary line
  ///
  /// In en, this message translates to:
  /// **'{count} notes · across {books} books'**
  String notesOverview({required int count, required int books});

  /// Notes page: hidden note count in a book card
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String notesMoreCount({required int count});

  /// Notes page: empty state title
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesEmptyTitle;

  /// Notes page: empty state guidance
  ///
  /// In en, this message translates to:
  /// **'Open any book and add a highlight or thought at the bottom of its detail page — they will collect here.'**
  String get notesEmptyDesc;

  /// Notes page: empty state title when a book filter yields nothing
  ///
  /// In en, this message translates to:
  /// **'No notes for this book yet'**
  String get notesEmptyFilteredTitle;

  /// Notes page: empty state guidance when filtered
  ///
  /// In en, this message translates to:
  /// **'Pick another book, or clear the filter to see the rest.'**
  String get notesEmptyFilteredDesc;

  /// Notes page: clear the book filter
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get notesClearFilter;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by the app. Defaults to your system setting.'**
  String get settingsLanguageDesc;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsCategoryPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get settingsCategoryPick;

  /// No description provided for @settingsCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories left — add one, or restore the defaults.'**
  String get settingsCategoryEmpty;

  /// No description provided for @langZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get langDe;

  /// No description provided for @langFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get langFr;

  /// No description provided for @langEs.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get langEs;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a theme and a light or dark mode.'**
  String get settingsAppearanceDesc;

  /// No description provided for @statusWishHint.
  ///
  /// In en, this message translates to:
  /// **'Not started yet.'**
  String get statusWishHint;

  /// No description provided for @statusReadingHint.
  ///
  /// In en, this message translates to:
  /// **'Currently reading. Reaches 100% progress it becomes Finished automatically.'**
  String get statusReadingHint;

  /// No description provided for @statusFinishedHint.
  ///
  /// In en, this message translates to:
  /// **'Finished. Slide progress to 100% and it is marked automatically.'**
  String get statusFinishedHint;

  /// No description provided for @statusShelvedHint.
  ///
  /// In en, this message translates to:
  /// **'Started but not planning to continue for now. Switch back to Reading to pick it up again.'**
  String get statusShelvedHint;

  /// No description provided for @borrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get borrowTitle;

  /// No description provided for @borrowDesc.
  ///
  /// In en, this message translates to:
  /// **'Mark the book as borrowed, with a lender and a due date.'**
  String get borrowDesc;

  /// No description provided for @borrowFlag.
  ///
  /// In en, this message translates to:
  /// **'This book is borrowed'**
  String get borrowFlag;

  /// No description provided for @borrowFrom.
  ///
  /// In en, this message translates to:
  /// **'Borrowed from'**
  String get borrowFrom;

  /// No description provided for @borrowFromHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. City Library, a colleague'**
  String get borrowFromHint;

  /// No description provided for @borrowDue.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get borrowDue;

  /// No description provided for @borrowDueUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get borrowDueUnset;

  /// No description provided for @borrowDueIn.
  ///
  /// In en, this message translates to:
  /// **'{days} days until due'**
  String borrowDueIn({required int days});

  /// No description provided for @borrowOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String borrowOverdue({required int days});

  /// No description provided for @borrowClearDue.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get borrowClearDue;

  /// No description provided for @borrowReturn.
  ///
  /// In en, this message translates to:
  /// **'Mark as returned'**
  String get borrowReturn;

  /// No description provided for @borrowReturnDesc.
  ///
  /// In en, this message translates to:
  /// **'This clears the loan flag, the lender and the due date, and cancels the return reminder.'**
  String get borrowReturnDesc;

  /// No description provided for @borrowReturned.
  ///
  /// In en, this message translates to:
  /// **'Marked as returned'**
  String get borrowReturned;

  /// No description provided for @statusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading status'**
  String get statusSectionTitle;

  /// No description provided for @planSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading plans'**
  String get planSectionTitle;

  /// No description provided for @planSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a goal you can actually keep. Plans stay on this device.'**
  String get planSectionDesc;

  /// No description provided for @planEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans yet. Start small — 20 minutes a day.'**
  String get planEmpty;

  /// No description provided for @planAdd.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get planAdd;

  /// No description provided for @planEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get planEdit;

  /// No description provided for @planKindDaily.
  ///
  /// In en, this message translates to:
  /// **'Read every day'**
  String get planKindDaily;

  /// No description provided for @planKindFinishBook.
  ///
  /// In en, this message translates to:
  /// **'Finish a book'**
  String get planKindFinishBook;

  /// No description provided for @planKindDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a daily reading time; judged on your daily average.'**
  String get planKindDailyDesc;

  /// No description provided for @planKindFinishBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a book and a deadline. Reaching 100% completes it.'**
  String get planKindFinishBookDesc;

  /// No description provided for @planDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get planDailyTarget;

  /// No description provided for @planMinutesUnit.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String planMinutesUnit({required int n});

  /// No description provided for @planPickBook.
  ///
  /// In en, this message translates to:
  /// **'Pick a book'**
  String get planPickBook;

  /// No description provided for @planDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get planDueLabel;

  /// No description provided for @planDueUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get planDueUnset;

  /// No description provided for @planRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me before the deadline'**
  String get planRemind;

  /// No description provided for @planRemindOff.
  ///
  /// In en, this message translates to:
  /// **'Turning this on asks for notification permission. The reminder cancels itself once the plan is done.'**
  String get planRemindOff;

  /// No description provided for @planTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan name (optional)'**
  String get planTitleLabel;

  /// No description provided for @planTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the default name'**
  String get planTitleHint;

  /// No description provided for @planSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planSave;

  /// No description provided for @planDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get planDelete;

  /// No description provided for @planDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this plan? Your reading records are not affected.'**
  String get planDeleteConfirm;

  /// No description provided for @planMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get planMarkDone;

  /// No description provided for @planAchieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved'**
  String get planAchieved;

  /// No description provided for @planMarkToday.
  ///
  /// In en, this message translates to:
  /// **'Read today'**
  String get planMarkToday;

  /// No description provided for @planDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get planDoneToday;

  /// No description provided for @planDailyCycleHint.
  ///
  /// In en, this message translates to:
  /// **'Every day is a fresh start — ticking it only counts for today, and the reminder comes back tomorrow.'**
  String get planDailyCycleHint;

  /// No description provided for @planReminderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The system couldn\'t schedule the reminder (power-saving may have blocked it). Your plan was still saved.'**
  String get planReminderUnavailable;

  /// No description provided for @planProgressDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily average {current} / {target} min'**
  String planProgressDaily({required String current, required String target});

  /// No description provided for @planProgressBook.
  ///
  /// In en, this message translates to:
  /// **'Progress {current}% · target 100%'**
  String planProgressBook({required int current});

  /// No description provided for @planDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String planDaysLeft({required int days});

  /// No description provided for @planOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String planOverdue({required int days});

  /// No description provided for @planStreak.
  ///
  /// In en, this message translates to:
  /// **'{n}-day check-in streak'**
  String planStreak({required int n});

  /// No description provided for @planDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get planDueToday;

  /// No description provided for @planBookGone.
  ///
  /// In en, this message translates to:
  /// **'The target book is no longer on your shelf'**
  String get planBookGone;

  /// No description provided for @planDoneSection.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get planDoneSection;

  /// No description provided for @planReminderDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied, so reminders cannot be delivered. Enable it in system settings.'**
  String get planReminderDenied;

  /// No description provided for @planReminderDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reading goal is not done yet'**
  String get planReminderDailyTitle;

  /// No description provided for @planReminderDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Your goal is {minutes} minutes — there is still time.'**
  String planReminderDailyBody({required int minutes});

  /// No description provided for @planReminderBookTitle.
  ///
  /// In en, this message translates to:
  /// **'A reading deadline is coming up'**
  String get planReminderBookTitle;

  /// No description provided for @planReminderBookBody.
  ///
  /// In en, this message translates to:
  /// **'Your plan is due in {days} days. A good time to finish it.'**
  String planReminderBookBody({required int days});

  /// No description provided for @settingsPlanReminder.
  ///
  /// In en, this message translates to:
  /// **'Reading reminders'**
  String get settingsPlanReminder;

  /// No description provided for @reportSettings.
  ///
  /// In en, this message translates to:
  /// **'Report settings'**
  String get reportSettings;

  /// No description provided for @reportBackfill.
  ///
  /// In en, this message translates to:
  /// **'Generate missing reports'**
  String get reportBackfill;

  /// No description provided for @reportNothingToBackfill.
  ///
  /// In en, this message translates to:
  /// **'Every report that should exist is already here.'**
  String get reportNothingToBackfill;

  /// No description provided for @reportHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports yet. Pick a period and generate your first one below.'**
  String get reportHistoryEmpty;

  /// No description provided for @reportNoKey.
  ///
  /// In en, this message translates to:
  /// **'No model configured, so reports cannot be generated. Add a key in Settings first.'**
  String get reportNoKey;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Light or dark'**
  String get settingsBrightness;

  /// No description provided for @brightnessSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get brightnessSystem;

  /// No description provided for @brightnessLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get brightnessLight;

  /// No description provided for @brightnessDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get brightnessDark;

  /// No description provided for @themeGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get themeGreen;

  /// No description provided for @themeInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get themeInk;

  /// No description provided for @themeBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get themeBlue;

  /// No description provided for @themePlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get themePlum;

  /// No description provided for @themeLagoon.
  ///
  /// In en, this message translates to:
  /// **'Lagoon'**
  String get themeLagoon;

  /// No description provided for @themeBerry.
  ///
  /// In en, this message translates to:
  /// **'Berry'**
  String get themeBerry;

  /// No description provided for @settingsChannels.
  ///
  /// In en, this message translates to:
  /// **'Connected services'**
  String get settingsChannels;

  /// No description provided for @settingsChannelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync your shelf and progress from other reading platforms. WeRead is supported today; more platforms will be added as they open their APIs.'**
  String get settingsChannelsDesc;

  /// No description provided for @settingsChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Keys are stored only in this device\'s system keychain and are never uploaded.'**
  String get settingsChannelsHint;

  /// No description provided for @settingsChannelAddHint.
  ///
  /// In en, this message translates to:
  /// **'More services are on the way.'**
  String get settingsChannelAddHint;

  /// No description provided for @importAccuracyTitle.
  ///
  /// In en, this message translates to:
  /// **'Results may be inaccurate'**
  String get importAccuracyTitle;

  /// No description provided for @importAccuracyDesc.
  ///
  /// In en, this message translates to:
  /// **'Titles and authors are inferred by OCR and AI models, so they can misread a word or pick the wrong book. Please review before saving.'**
  String get importAccuracyDesc;

  /// No description provided for @importFromImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from screenshot'**
  String get importFromImageTitle;

  /// No description provided for @importFromImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a screenshot of your shelf and detect the books on it.'**
  String get importFromImageDesc;

  /// No description provided for @importFromCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Import by camera'**
  String get importFromCameraTitle;

  /// No description provided for @importFromCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your shelf and detect the books on it.'**
  String get importFromCameraDesc;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @insightsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your long-term reading profile, plus reports by month and year.'**
  String get insightsDesc;

  /// No description provided for @chronology.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get chronology;

  /// No description provided for @chronologyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your reading month by month. Tap a card to open the book.'**
  String get chronologyDesc;

  /// No description provided for @chronologyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing finished or in progress this year yet.'**
  String get chronologyEmpty;

  /// No description provided for @chronologyFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get chronologyFinished;

  /// No description provided for @chronologyReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get chronologyReading;

  /// No description provided for @chronologyShelved.
  ///
  /// In en, this message translates to:
  /// **'Shelved'**
  String get chronologyShelved;

  /// No description provided for @chronologyWish.
  ///
  /// In en, this message translates to:
  /// **'Want to read'**
  String get chronologyWish;

  /// No description provided for @chronologyMore.
  ///
  /// In en, this message translates to:
  /// **'{n} more — see the whole month'**
  String chronologyMore({required int n});

  /// No description provided for @reportStyle.
  ///
  /// In en, this message translates to:
  /// **'Report style'**
  String get reportStyle;

  /// No description provided for @reportStyleDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the tone and structure of generated reports, or write your own prompt.'**
  String get reportStyleDesc;

  /// No description provided for @reportStyleRational.
  ///
  /// In en, this message translates to:
  /// **'Plain facts'**
  String get reportStyleRational;

  /// No description provided for @reportStyleRationalDesc.
  ///
  /// In en, this message translates to:
  /// **'States the data objectively: no praise, no prodding, clearly itemised.'**
  String get reportStyleRationalDesc;

  /// No description provided for @reportStyleWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm encouragement'**
  String get reportStyleWarm;

  /// No description provided for @reportStyleWarmDesc.
  ///
  /// In en, this message translates to:
  /// **'Acknowledges your consistency and offers advice gently.'**
  String get reportStyleWarmDesc;

  /// No description provided for @reportStyleDirect.
  ///
  /// In en, this message translates to:
  /// **'Straight talk'**
  String get reportStyleDirect;

  /// No description provided for @reportStyleDirectDesc.
  ///
  /// In en, this message translates to:
  /// **'Names the problems without softening, for readers who want it plain.'**
  String get reportStyleDirectDesc;

  /// No description provided for @reportStyleConcise.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get reportStyleConcise;

  /// No description provided for @reportStyleConciseDesc.
  ///
  /// In en, this message translates to:
  /// **'Conclusions only, as short as possible.'**
  String get reportStyleConciseDesc;

  /// No description provided for @reportStyleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reportStyleCustom;

  /// No description provided for @reportStyleCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Write the prompt yourself and control exactly how reports read.'**
  String get reportStyleCustomDesc;

  /// No description provided for @reportStyleCustomHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Talk to me in second person, like a friend commenting on my reading.'**
  String get reportStyleCustomHint;

  /// No description provided for @reportReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read full report'**
  String get reportReadMore;

  /// No description provided for @reportNoContent.
  ///
  /// In en, this message translates to:
  /// **'(this report has no body text)'**
  String get reportNoContent;

  /// No description provided for @s_9f2c1d4e.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get s_9f2c1d4e;

  /// No description provided for @s_0f2b6c1a.
  ///
  /// In en, this message translates to:
  /// **'Reading this period'**
  String get s_0f2b6c1a;

  /// No description provided for @s_7d1a4e35.
  ///
  /// In en, this message translates to:
  /// **'Shelf structure'**
  String get s_7d1a4e35;

  /// No description provided for @s_3c58b0d2.
  ///
  /// In en, this message translates to:
  /// **'Reading habits'**
  String get s_3c58b0d2;

  /// No description provided for @s_4b7e2a19.
  ///
  /// In en, this message translates to:
  /// **'Books worth naming'**
  String get s_4b7e2a19;

  /// No description provided for @s_6e39f7c4.
  ///
  /// In en, this message translates to:
  /// **'Reader profile'**
  String get s_6e39f7c4;

  /// No description provided for @s_1a8d53f6.
  ///
  /// In en, this message translates to:
  /// **'What to read next'**
  String get s_1a8d53f6;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get s_2f9d1a4b;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get s_5c7e3d81;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”?'**
  String s_3e8f5b26({required Object title});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Its reading logs and plans are deleted with it. Notes you wrote are kept — they stay in the Notes tab. This can’t be undone.'**
  String get s_7d4c2e91;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Deleted “{title}”'**
  String s_1f6a8d37({required Object title});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get s_4b2c9e58;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Add, rename or remove categories. Books in a removed category move to “Uncategorized”.'**
  String get s_8d3f6a12;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get s_2c8b5d09;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Category name can’t be empty'**
  String get s_9f4e7a35;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'That category already exists'**
  String get s_7a2d6c81;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Added “{name}”'**
  String s_5e9c1b47({required Object name});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”'**
  String s_3b7f2d64({required Object name});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Delete category “{name}”?'**
  String s_8c4a1e92({required Object name});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'{count} books in it will move to “Uncategorized”.'**
  String s_1d7b3f08({required Object count});

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get s_6a9e4c27;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Restore default categories'**
  String get s_2f5d8b13;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Default categories restored'**
  String get s_4e1c7a69;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get s_9c3f5d21;

  /// shelf: delete book / tag filter / editable categories
  ///
  /// In en, this message translates to:
  /// **'Renamed to “{name}”; {count} books updated'**
  String s_9d2e7f13({required Object name, required Object count});

  /// 皮肤名称：Starlit Sky
  ///
  /// In en, this message translates to:
  /// **'Starlit Sky'**
  String get themeBgStarfield;

  /// 皮肤名称：Mountain Mist
  ///
  /// In en, this message translates to:
  /// **'Mountain Mist'**
  String get themeBgMist;

  /// 皮肤名称：Moss Garden
  ///
  /// In en, this message translates to:
  /// **'Moss Garden'**
  String get themeBgMoss;

  /// 皮肤名称：Dusk Film
  ///
  /// In en, this message translates to:
  /// **'Dusk Film'**
  String get themeBgDusk;

  /// 皮肤名称：Cat Nap
  ///
  /// In en, this message translates to:
  /// **'Cat Nap'**
  String get themeBgCat;

  /// 皮肤名称：Dog Park
  ///
  /// In en, this message translates to:
  /// **'Dog Park'**
  String get themeBgDog;

  /// Skin group label in the theme picker
  ///
  /// In en, this message translates to:
  /// **'Textured'**
  String get s_2f8a1c47;

  /// 设置页「检查更新」按钮文案
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdate;

  /// 「检查更新」区块副标题
  ///
  /// In en, this message translates to:
  /// **'See whether a newer version exists. If it does, it will say what changed.'**
  String get checkUpdateDesc;

  /// 检查进行中的按钮态
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingForUpdate;

  /// 已是最新版的弹窗标题
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version'**
  String get updateUpToDate;

  /// 已是最新版的弹窗正文，含当前版本号占位符
  ///
  /// In en, this message translates to:
  /// **'You are on {version}. No newer version is available yet.'**
  String updateUpToDateDesc({required String version});

  /// 发现新版的弹窗标题，含新版本号占位符
  ///
  /// In en, this message translates to:
  /// **'{version} is available'**
  String updateAvailable({required String version});

  /// 发现新版的弹窗正文，含当前版与新版本号占位符
  ///
  /// In en, this message translates to:
  /// **'You are on {current}. Update to {latest} when you like — nothing is downloaded automatically.'**
  String updateAvailableDesc({required String current, required String latest});

  /// 更新说明列表的标题
  ///
  /// In en, this message translates to:
  /// **'What changed'**
  String get updateNotesTitle;

  /// 发布者未写更新说明时的占位说明
  ///
  /// In en, this message translates to:
  /// **'The publisher didn’t write release notes this time.'**
  String get updateNoNotes;

  /// 弹窗里的下载按钮，含版本号占位符
  ///
  /// In en, this message translates to:
  /// **'Download {version}'**
  String updateDownload({required String version});

  /// 拿不到 APK 直链时改为打开发布页的按钮
  ///
  /// In en, this message translates to:
  /// **'Open the release page'**
  String get updateOpenRelease;

  /// 检查失败弹窗标题
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check for updates'**
  String get updateCheckFailed;

  /// 网络不可达时的错误说明
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the server. Check your connection and try again.'**
  String get updateCheckFailedNetwork;

  /// 返回内容无法解析时的错误说明
  ///
  /// In en, this message translates to:
  /// **'The server sent something unexpected. Please try again later.'**
  String get updateCheckFailedMalformed;

  /// Release 存在但找不到 APK 时的说明
  ///
  /// In en, this message translates to:
  /// **'No installer found: {version} is published, but no APK could be found.'**
  String updateNeverInstalled({required String version});

  /// 弹窗里的发布时间，含日期占位符
  ///
  /// In en, this message translates to:
  /// **'Published {date}'**
  String updateReleasedOn({required String date});
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return SDe();
    case 'en': return SEn();
    case 'es': return SEs();
    case 'fr': return SFr();
    case 'zh': return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

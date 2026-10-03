import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Readnest';

  @override
  String get navShelf => 'Shelf';

  @override
  String get addBookSheetTitle => 'Add a book';

  @override
  String get addBookManualTitle => 'Enter manually';

  @override
  String get addBookManualDesc => 'Type in the title and author yourself — no account or file needed.';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get supportDev => 'Support the Developer';

  @override
  String get supportDevDesc => 'Every feature is free to use, with no ads and no in-app purchases. If the app helps with your reading, you can buy me a coffee — entirely optional, and nothing changes either way.';

  @override
  String get openTipPage => 'Buy me a coffee · Ko-fi';

  @override
  String get about => 'About';

  @override
  String get aboutDesc => 'Developer details and related links.';

  @override
  String get appIntroPage => 'About this app';

  @override
  String get developerHomepage => 'Developer website';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String appVersionLabel({required String version}) {
    return 'Version $version';
  }

  @override
  String get goodreadsImport => 'Goodreads / Library CSV import';

  @override
  String get goodreadsImportDesc => 'Import a library CSV exported from Goodreads and similar services (title, author, rating, shelf status).';

  @override
  String get goodreadsImportEmpty => 'No \"Title\" column found in the CSV';

  @override
  String get openLibraryImport => 'Open Library / Google Books search import';

  @override
  String get openLibraryImportDesc => 'Search public catalogs by title or ISBN and import with enriched metadata (author, publisher, cover).';

  @override
  String get catalogSearchTitle => 'Catalog search';

  @override
  String get catalogSearchHint => 'Enter a title or ISBN';

  @override
  String get catalogSearchAction => 'Search';

  @override
  String get catalogSearchInitial => 'Search public catalogs on Google Books and Open Library. Selected books are added with author, publisher, cover and page count.';

  @override
  String get catalogNoResult => 'No matching books found — try a different keyword.';

  @override
  String catalogSearchFailed({required Object e}) {
    return 'Search failed: $e';
  }

  @override
  String get imageUploadConsentTitle => 'Send bookshelf screenshot to AI service?';

  @override
  String get imageUploadConsentBody => 'To let the AI read your entire shelf screenshot, this image is sent to the AI service you configured in Settings (a third party). It contains no note text, but does include book titles and covers. Allow this upload?';

  @override
  String get allow => 'Allow';

  @override
  String get cancel => 'Cancel';

  @override
  String get s_178329ba => 'WeRead API key not configured';

  @override
  String get s_dd204792 => '[\\s·・\\-—_:：,，。.·（）()\\[\\]【】]';

  @override
  String get s_ad86a5ca => 'LLM API key not configured';

  @override
  String get s_8a853cbe => 'Fill it in under Settings → LLM';

  @override
  String get s_7d704c88 => 'No model selected';

  @override
  String get s_4508cedd => 'Tap \"Fetch models\" to pick one from your account\'s available list';

  @override
  String get s_1b5140db => 'Output valid JSON only — no explanatory text, no markdown code blocks.';

  @override
  String s_c94c96fc({required Object apiError}) {
    return 'The model service returned an error: $apiError';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return 'Raw response: $head\nFirst check the address and model name under Settings → LLM using \"Fetch models\". An unpaid balance or a model that isn\'t enabled will also land here.';
  }

  @override
  String get s_231cf54a => 'The model\'s response couldn\'t be parsed';

  @override
  String s_90747d4c({required Object head}) {
    return 'Raw response: $head\nThe gateway returned a non-standard structure. Try another model or protocol; sending us this raw text also helps us add support for it.';
  }

  @override
  String get s_9d9714af => 'The message is empty and can\'t be sent';

  @override
  String get s_f44ff25c => 'The model refused this request';

  @override
  String get s_cad5bf6e => 'The content was flagged as inappropriate. Rephrase it or try another model.';

  @override
  String get s_0f7b54a1 => 'API key not configured';

  @override
  String get s_345e9547 => 'Enter the key before fetching models';

  @override
  String get s_3a5d4cca => 'The service returned an empty model list';

  @override
  String s_cea80527({required Object apiError}) {
    return 'Failed to fetch models: $apiError';
  }

  @override
  String get s_4674d953 => 'You can enter the model name manually';

  @override
  String s_749fc40e({required Object raw}) {
    return 'Raw response: $raw';
  }

  @override
  String get s_8add575d => 'This service doesn\'t provide a model-list endpoint (404)';

  @override
  String get s_53fb436d => 'Just type the model name in, e.g. deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => 'No model name entered';

  @override
  String get s_1da90e20 => 'Tap \"Fetch models\" first, or type one in';

  @override
  String get s_2abb6b8a => 'Reply with two characters: OK';

  @override
  String get s_ad736a74 => 'You are a book cataloguing assistant. Output JSON only, no explanations.';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return 'Known title \"$title\"$author.\nPlease fill in:\n- categoryPrimary: must be one of: $vocab\n- description: a neutral 80–150 character summary of the book\'s content, stating facts without evaluation\n- tags: 3–5 keyword tags\n- authors: an array if the author can be determined, otherwise an empty array\nOutput format: {\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}';
  }

  @override
  String get s_cbe8aa6b => 'You are a reading-profile analyst. Output JSON only, no explanations.';

  @override
  String s_3864d3b4({required Object summary}) {
    return 'Here is my reading data (JSON):\n$summary\n\nGive me 10 personality tags, each 2–6 words, like the nicknames a book club gives people.\nRequirements:\n1. Every tag must be supported by the data above — don\'t make things up\n2. Style reference: Learning Is My Joy / In Tune with Nature / Beauty Above All / Erudite Across the Ages / The Lonely Sage\n3. Don\'t use empty words like \"reader\", \"enthusiast\" or \"aficionado\"\n4. No explanations, no markdown code blocks\nOutput format: {\"tags\":[\"tag1\",\"tag2\"]}';
  }

  @override
  String get s_735e2d59 => '6. Naming names: pick 3–5 specific books from bookList to discuss (which one you finished, which you started but didn\'t continue, which is rated highest) and give their titles.\nEvery title mentioned in the report must come from bookList — don\'t invent any.\n';

  @override
  String get s_99acf9a4 => 'You are a personal reading advisor. Analyse the data objectively, avoid vague praise, and point out the structural problems that are being overlooked.';

  @override
  String s_414278bd({required Object data, required Object listHint, required Object period}) {
    return 'Here is my reading data for $period (JSON):\n$data\n\nWrite a reading report covering:\n1. Overview: books finished, total time, daily average\n2. Structure: category breakdown, source platform breakdown, format mix\n3. Habits: reading rhythm, consecutive days, abandonment rate\n4. Profile: what kind of reader I might be\n5. Suggestions: 3 concrete, actionable next steps based on the gaps. Suggestions must stay within reading itself (what to read, how to read, how to record reflections): never comment on where or how I acquire books, never push me to write reviews, share, or keep streaks, and pass no judgment beyond reading.\n${listHint}Format rules (follow strictly - the report is rendered as Markdown inside the app):\n- Open each of the six sections with a level-2 heading such as ## Overview. No numbers inside headings.\n- Bold every key figure: finished **12 books**, **37 minutes** a day.\n- Use - bullets for parallel observations, and a numbered list for the suggestions.\n- Put every book title in italics, like *The Road to Serfdom*.\n- No HTML tags, and no headings deeper than level 3.';
  }

  @override
  String s_46e5ebef({required Object host}) {
    return 'Connection timed out: couldn\'t reach $host within 20 seconds';
  }

  @override
  String get s_3c836870 => 'Check the network or the base URL; some overseas services need a proxy from mainland China';

  @override
  String get s_84264711 => 'Send timed out';

  @override
  String get s_225ed2e1 => 'The upstream connection is unstable; try again later';

  @override
  String get s_b265cf86 => 'Response timed out: the model didn\'t respond within 180 seconds';

  @override
  String get s_cc12eea3 => 'Try a faster model, or shorten the report period and retry';

  @override
  String get s_d711b259 => 'HTTPS certificate validation failed';

  @override
  String get s_4722b0f8 => 'For a self-hosted or intranet endpoint, switch to a trusted certificate';

  @override
  String get s_07a2b144 => 'Request cancelled';

  @override
  String s_8ae0b0e4({required Object host}) {
    return 'Network unreachable: can\'t connect to $host';
  }

  @override
  String get s_0a9425b8 => '① Check the phone\'s network; ② make sure the base URL is complete (including /v1); ③ check whether the service needs a proxy; ④ a local service (Ollama) can\'t be reached from the phone via the computer\'s localhost';

  @override
  String get s_554d5235 => 'The connection was interrupted';

  @override
  String get s_020fe21a => 'Usually a blocked network permission, or a proxy or firewall dropping the connection; plaintext HTTP may also be unsupported. Retry later or switch networks.';

  @override
  String get s_dfde23b1 => 'Network request failed';

  @override
  String get s_2ae4f5fe => 'Check the base URL, proxy settings and network';

  @override
  String s_d6ac5952({required Object detail}) {
    return 'Request rejected (400)$detail';
  }

  @override
  String get s_cb980461 => 'Most likely the model name is wrong, or the model doesn\'t support the current parameters';

  @override
  String s_d9775d22({required Object detail}) {
    return 'Authentication failed (401)$detail';
  }

  @override
  String get s_c4198142 => 'The API key is invalid or expired — copy a fresh one';

  @override
  String get s_e06ab1cc => 'Insufficient account balance (402)';

  @override
  String s_05b3ec8b({required Object detail}) {
    return 'No permission (403)$detail';
  }

  @override
  String get s_f00f6ff2 => 'The key has no permission to call this model, or the account isn\'t verified/enabled';

  @override
  String s_016f7576({required Object detail}) {
    return 'Endpoint or model not found (404)$detail';
  }

  @override
  String get s_a8aa2c59 => 'Check whether the base URL is filled in up to /v1; use \"Fetch models\" to get the model name';

  @override
  String s_9688a257({required Object detail}) {
    return 'Invalid parameters (422)$detail';
  }

  @override
  String get s_1b3daaa3 => 'Rate limited (429)';

  @override
  String get s_2a564df1 => 'Try again shortly, or upgrade your plan';

  @override
  String s_6627221e({required int? code}) {
    return 'Server error ($code)';
  }

  @override
  String get s_2fe391dd => 'A problem on the remote side; try again later';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return 'Request failed$code$detail';
  }

  @override
  String get s_0cf0a499 => '(empty response body)';

  @override
  String get s_9ed7e745 => 'Network request failed. Check the phone\'s network and the base URL under Settings → LLM.';

  @override
  String get s_2ad3b6ba => 'OpenAI-compatible';

  @override
  String get s_e2213e87 => 'Enter the base URL up to /v1, e.g. https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'The base URL is usually https://api.anthropic.com (without /v1)';

  @override
  String get s_f1ea3335 => 'SenseNova';

  @override
  String get s_e522fe39 => 'Qwen';

  @override
  String get s_7e12f8b4 => 'Zhipu GLM';

  @override
  String get s_c3d30bc2 => 'Moonshot Kimi';

  @override
  String get s_8e941e27 => 'SiliconFlow';

  @override
  String get s_c800478c => 'Ollama (local)';

  @override
  String get s_0babfa89 => 'Any non-empty string';

  @override
  String get s_e74f752c => 'Reading days are days manually recorded as read';

  @override
  String s_9ea3cbae({required Object year}) {
    return 'Reading time and days come from WeRead\'s $year yearly statistics (full-year basis)';
  }

  @override
  String get s_f676228c => 'WeRead only provides yearly figures, so reading days for this range can\'t be given precisely; time is aggregated at month granularity';

  @override
  String get s_06225788 => 'Unrated';

  @override
  String s_89cfaca8({required Object i}) {
    return '$i stars';
  }

  @override
  String get s_e7a2db51 => 'All time';

  @override
  String s_a87cfcc9({required Object y}) {
    return '$y';
  }

  @override
  String s_62654321({required Object n}) {
    return 'Last $n months';
  }

  @override
  String get s_41f3af95 => 'Reading time and days are aggregated at month/year granularity';

  @override
  String get s_e8a43314 => 'Start your next book and this list gets its first number.';

  @override
  String get s_af03278c => 'The shelf is still empty — every reading history starts here.';

  @override
  String s_f53eead8({required Object streak}) {
    return '$streak days of consecutive reading — the rhythm has taken hold.';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return 'A $streak-day streak — don\'t let it break today.';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '$streak days in a row — a habit worth more than any reading list.';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '$finished books finished — swap speed for rhythm and you\'ll go further.';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '$finished books finished. Look back now and then at which ones really stuck.';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '$finished books finished in this stretch — every one counts.';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '$finished books finished. Pick up one you already started next.';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '$minutes minutes read in this stretch — make half an hour a daily habit and that\'s 180 hours a year.';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return '$minutes minutes logged already. Add a little more today?';
  }

  @override
  String get s_152a88d7 => 'Your shelf is ready — start today\'s ten minutes with a light short story.';

  @override
  String get s_795806c0 => 'Pick a book you\'ve already started — ten minutes counts as a win.';

  @override
  String get s_aa51bf46 => 'You don\'t have to read a lot in one go — opening any book today counts.';

  @override
  String get s_363c6a0c => 'Uncategorized';

  @override
  String get s_420a7ac1 => 'Learning Is My Joy';

  @override
  String get s_bcd278a6 => 'Personal Growth';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '$cat personal-growth books · $pct';
  }

  @override
  String get s_6672b3fa => 'Romantic and Poetic';

  @override
  String get s_d422d33c => 'Literature';

  @override
  String s_40ba4ecb({required Object cat, required Object pct}) {
    return '$cat literature books · $pct';
  }

  @override
  String get s_ea2eaec4 => 'The Lonely Sage';

  @override
  String get s_5da32671 => 'Philosophy';

  @override
  String s_0f80a135({required Object cat, required Object pct}) {
    return '$cat philosophy books · $pct';
  }

  @override
  String get s_111ec0f6 => 'Lessons from History';

  @override
  String get s_07f288e9 => 'History';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '$cat history books · $pct';
  }

  @override
  String get s_5e336507 => 'Looks Inward';

  @override
  String get s_4307c7a8 => 'Psychology';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '$cat psychology books · $pct';
  }

  @override
  String get s_d5e26f37 => 'Tech Elite';

  @override
  String get s_8612fa7f => 'Computing';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '$cat computing books · $pct';
  }

  @override
  String get s_00dcb308 => 'Beauty Above All';

  @override
  String get s_b31e932c => 'Art';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '$cat art books · $pct';
  }

  @override
  String get s_2ddd554c => 'Rational and Practical';

  @override
  String get s_56734d39 => 'Economics';

  @override
  String get s_5974bf24 => 'Business';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '$cat economics & business books · $toStringAsFixed%';
  }

  @override
  String get s_d574ffeb => 'Worldly Wise';

  @override
  String get s_086ac5bf => 'Social Science';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '$cat social-science books · $pct';
  }

  @override
  String get s_d81bab36 => 'Insatiably Curious';

  @override
  String get s_41fa5c70 => 'Popular Science';

  @override
  String get s_fcc3102d => 'Technology';

  @override
  String s_76c118d0({required Object n}) {
    return '$n popular-science and tech books';
  }

  @override
  String get s_2b65326c => 'Learns from Others';

  @override
  String get s_f85fa7d4 => 'Biography';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '$cat biographies · $pct';
  }

  @override
  String get s_9e49409c => 'Healthy Living';

  @override
  String get s_c21b69a8 => 'Medicine';

  @override
  String s_1dd31356({required Object cat}) {
    return '$cat medicine & health books';
  }

  @override
  String get s_77e32253 => 'Pragmatic Borrower';

  @override
  String get s_0323f1bb => 'Law';

  @override
  String s_82364cc8({required Object cat}) {
    return '$cat law books';
  }

  @override
  String get s_ea038731 => 'Self-Entertained';

  @override
  String get s_dbb1c112 => 'Comic';

  @override
  String get s_6398a679 => 'Children\'s Books';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '$cat comics and children\'s books';
  }

  @override
  String get s_94f8d7c2 => 'In Tune with Nature';

  @override
  String get s_30412ad5 => 'Religion';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '$cat religion books';
  }

  @override
  String get s_52c36d65 => 'Knows How to Live';

  @override
  String get s_06e23c48 => 'Other';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '$cat lifestyle books · $pct';
  }

  @override
  String get s_dc2e94c1 => 'Teacher at Heart';

  @override
  String get s_235af603 => 'Education';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '$cat education books · $pct';
  }

  @override
  String get s_7ea6e8a9 => 'Erudite Across the Ages';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return 'Your library spans $categoryKinds categories — a bit of everything';
  }

  @override
  String get s_41a09d04 => 'Deep Focus';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '$total books fall into only $categoryKinds categories';
  }

  @override
  String get s_431dc47d => 'Finisher';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return 'Finish rate $toStringAsFixed% ($finished/$total)';
  }

  @override
  String get s_6b51050c => 'Tsundoku Master';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '$wish want-to-read, but only $finished finished';
  }

  @override
  String get s_e60e931c => 'Cuts Losses Fast';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '$abandoned dropped · $toStringAsFixed% — you put down what doesn\'t grab you';
  }

  @override
  String get s_4be15f8c => 'Serial Starter';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '$stalled books in progress but under 15%';
  }

  @override
  String get s_10b9bddd => 'Gentle Spirit';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Your $ratedCount rated books average $toStringAsFixed';
  }

  @override
  String get s_e67694db => 'Sharp-Tongued Critic';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Your $ratedCount rated books average only $toStringAsFixed';
  }

  @override
  String get s_fe4567e4 => 'Strong Opinions';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return 'Rating standard deviation $toStringAsFixed — your good and bad are far apart';
  }

  @override
  String get s_fbad19d5 => 'Revisits and Renews';

  @override
  String s_8d62979c({required Object reread}) {
    return '$reread books read twice or more';
  }

  @override
  String get s_54302bb2 => 'Immersive Reader';

  @override
  String s_bc9dbced({required Object round}) {
    return '$round minutes per active day on average';
  }

  @override
  String get s_e9eddf51 => 'Digital Native';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '$weread from WeRead · $toStringAsFixed%';
  }

  @override
  String get s_ce6517f9 => 'Paper and Digital';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return 'plus $libraryCount borrowed and $paper paper books';
  }

  @override
  String get s_8cac22b7 => 'Reads with Ears';

  @override
  String s_72b826e9({required Object audio}) {
    return '$audio audiobooks';
  }

  @override
  String get s_7caeab27 => 'Visual Reader';

  @override
  String s_a5a44a39({required Object comic}) {
    return '$comic comics';
  }

  @override
  String s_0e59d960({required Object m, required Object y}) {
    return '$m/$y';
  }

  @override
  String s_1a2e873e({required Object month}) {
    return 'Month $month';
  }

  @override
  String s_5583162a({required Object e}) {
    return 'Image preprocessing failed; using the original image: $e';
  }

  @override
  String s_628c2132({required Object e}) {
    return 'Failed to convert to JPEG: $e';
  }

  @override
  String get s_ebf4bdfb => 'Parsing the layout structure…';

  @override
  String get s_ba1038b1 => 'Cleaning up recognition results with the LLM…';

  @override
  String get s_6292a274 => 'Verifying titles…';

  @override
  String get s_427e1f0d => '[\\s《》「」『』…⋯.\\-—_:：]';

  @override
  String get s_af041a1b => 'Title completed';

  @override
  String s_988dd5cb({required Object reason}) {
    return '$reason, title completed';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '\"$title\": $e';
  }

  @override
  String get s_d2bbf7ce => 'Multimodal recognition';

  @override
  String get s_381ca835 => 'This is a screenshot of a shelf or reading list';

  @override
  String get s_fce28e56 => 'This is a screenshot of a single book\'s cover or detail page';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene.\n\nOutput a JSON array only, each item shaped like:\n{\"title\":\"title\",\"author\":\"author\",\"progress\":a number from 0-100 or null,\"status\":\"one of unread/reading/finished or null\",\"confidence\":a number from 0-1}\n\nRequirements:\n1. Only output books that are **actually visible** in the image; don\'t add books you assume should be there;\n2. Ignore UI text (filters, search, sort, All, Shelf, N books, etc.);\n3. Copy titles exactly as shown, including ones cut off by an ellipsis — don\'t complete them yourself;\n4. Leave author as an empty string if it can\'t be read; don\'t guess;\n5. Only fill in author when it really is written in the image.\n$n';
  }

  @override
  String get s_951042c3 => 'You extract information from bookshelf screenshots. Output a JSON array only, with no explanatory text.';

  @override
  String get s_29dbdb32 => 'LLM cleanup';

  @override
  String get s_9cd6567e => 'A photo of a book cover or spine';

  @override
  String get s_a6db1cf4 => 'A screenshot of an e-book app\'s shelf';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return 'Below are the text lines OCR\'d from $scene, in top-to-bottom order.\n\nExtract the **real book titles** from them, ignoring all UI text (search box, filters, categories, status bar, page numbers, chapter headings, buttons, statistics).\n\nRules:\n1. Only output books that actually appear in the image. Don\'t add books you assume should be there.\n2. If a title is truncated by an ellipsis in the UI (for example \"Deep…\"), complete it into the full title.\n3. progress takes an integer percentage from 0–100; leave it an empty string if it can\'t be read. Note that \"0.8%\" is 0.8, not 80.\n4. status must be one of \"unread / reading / finished / dropped\"; leave it an empty string if it can\'t be read.\n5. Only fill in author when it clearly appears in the image; otherwise leave it blank. Don\'t guess.\n6. Skip lines you\'re unsure about. Better to miss one book than to add a fake one.\n\nOutput a JSON array only, with elements shaped like:\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nOCR text lines:\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => '[\\s《》「」『』]';

  @override
  String get s_95222176 => 'Unread';

  @override
  String get s_5a833930 => 'Want to read';

  @override
  String get s_b9bf9b53 => 'Reading';

  @override
  String get s_be5492a5 => 'Currently reading';

  @override
  String get s_44c14529 => 'Finished reading';

  @override
  String get s_0872b5b7 => 'Finished';

  @override
  String get s_300a32bd => 'Finished';

  @override
  String get s_0f4d9c68 => 'Dropped (merged into Shelved)';

  @override
  String get s_7675d229 => '\\s*(著|编著|译|著译)\$';

  @override
  String get s_285bb37e => '[，。；、？！：）」』]\$';

  @override
  String get s_8f936d11 => '(著|编著|译|著译)\$';

  @override
  String get s_d0c345ec => '[（《·“]\$';

  @override
  String get s_2d3c83a7 => '[）》」』”]\$';

  @override
  String get s_0686f279 => 'Largest text on cover';

  @override
  String get s_5514105a => 'Secondary cover text';

  @override
  String get s_174faffb => 'Contains Chinese';

  @override
  String get s_b13a1237 => 'Has progress or status';

  @override
  String get s_24745e9d => 'Has author';

  @override
  String get s_0cedc3f4 => 'Reasonable length';

  @override
  String get s_5bdfa6ae => 'Too short';

  @override
  String get s_58171266 => 'Too long';

  @override
  String get s_1e8c236b => 'Columns left-aligned';

  @override
  String get s_89ac54fb => 'Cover lettering';

  @override
  String get s_132a750b => 'Too-short English';

  @override
  String get s_6af25a96 => '[，。；、？！]\$';

  @override
  String get s_a335b25f => 'Sentence-ending punctuation';

  @override
  String get s_885dd894 => '％';

  @override
  String get s_620b459e => '《';

  @override
  String get s_150c7508 => '》';

  @override
  String get s_67df3afd => 'Has title marks';

  @override
  String get s_5a09ed37 => 'Chinese';

  @override
  String get s_6b631636 => 'Looks like an English UI word';

  @override
  String get s_1dd3f274 => 'Adjacent line';

  @override
  String get s_f547232b => ', merged line break';

  @override
  String get s_fc39b00e => 'Borrowed';

  @override
  String get s_eba88d83 => 'Shelved';

  @override
  String get s_b6fe7962 => 'Ebook';

  @override
  String get s_c7673d27 => 'Paper';

  @override
  String get s_02a1a8ed => 'Audiobook';

  @override
  String get s_fe152225 => 'WeRead';

  @override
  String get s_2032cbd7 => 'iReader Select';

  @override
  String get s_12ed007e => 'JD Read';

  @override
  String get s_570bb7c8 => 'BOOX';

  @override
  String get s_36bfef2d => 'Library';

  @override
  String get s_4139f3b5 => 'Manual';

  @override
  String get s_88cdd7e4 => 'Highlight';

  @override
  String get s_6abc44a8 => 'Thought';

  @override
  String get s_67585b8a => 'Review';

  @override
  String get s_96009a7e => 'Reading report';

  @override
  String s_4343b7b3({required Object join}) {
    return 'Generating in the background: $join';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return 'Automatically generated $ok reports';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return 'Generated $ok, failed $failed (you can retry manually)';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return 'Connected · $model · $latencyMs ms';
  }

  @override
  String get s_d2a3748e => 'The model returned empty content';

  @override
  String get s_3abdc334 => 'The model may not support the current parameters, or content filtering was triggered. Try another model.';

  @override
  String get s_cc72f973 => 'No LLM key configured. Fill one in under Settings → LLM and test the connection first';

  @override
  String get s_9e51ce93 => 'No model selected. Go to Settings → LLM and use \"Fetch models\" to pick one';

  @override
  String get s_c6e18e89 => 'No books match in this period; try a different one';

  @override
  String get s_8bb45b34 => 'Report period';

  @override
  String get s_8bd59fb2 => 'Choose a yearly or monthly report';

  @override
  String get s_53bea04d => 'Filed by calendar year / month; once generated you can revisit it anytime. The current month\'s report is only generated next month.';

  @override
  String get s_1f048ed9 => 'Testing…';

  @override
  String get s_38fb1115 => 'Test connection';

  @override
  String get s_a14e36dc => 'Generating… (long text takes about a minute)';

  @override
  String get s_b36c173d => 'Generate report';

  @override
  String get s_c94ade95 => 'Sends this period\'s book list (title / author / category / rating) and aggregate statistics so the report can name specific books; note text and highlights are not uploaded.';

  @override
  String get s_5e05e92a => 'Included';

  @override
  String s_be9a1551({required Object total}) {
    return '$total books';
  }

  @override
  String s_ce115766({required Object finished}) {
    return '$finished books';
  }

  @override
  String s_8b46a11f({required Object reading}) {
    return '$reading books';
  }

  @override
  String s_81e94993({required Object wish}) {
    return '$wish books';
  }

  @override
  String get s_09b589b4 => 'Average rating';

  @override
  String s_0825e123({required Object label}) {
    return 'Report content · $label';
  }

  @override
  String get s_049eca89 => 'Copy all';

  @override
  String get s_50bf9961 => 'Report copied to clipboard';

  @override
  String get s_772cbfcf => 'Auto-generate';

  @override
  String get s_01955ddf => 'When this is on, opening this page automatically generates any missing yearly report and last month\'s monthly report.';

  @override
  String get s_b2a52a3d => 'Auto-generate missing';

  @override
  String get s_b233138e => 'Yearly';

  @override
  String get s_877b864d => 'Monthly';

  @override
  String get s_a3dfa2a6 => 'Past reports';

  @override
  String get s_66772db6 => 'Export reading data';

  @override
  String get s_6b198f0b => 'Export cancelled';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return 'Exported to: $saved\n\n$counts';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return 'Export failed: $e';
  }

  @override
  String get s_c699263b => 'Choose a backup file';

  @override
  String s_e34bdbcb({required Object e}) {
    return 'Couldn\'t read this file: $e';
  }

  @override
  String get s_1dedeaa2 => 'This isn\'t a backup file exported by this app (missing format marker, or newer than the current app)';

  @override
  String get s_103c5811 => 'This file contains no restorable data';

  @override
  String get s_674a7957 => 'Restore now?';

  @override
  String s_94094e0d({required Object length}) {
    return 'This will overwrite this device\'s data with the backup:\n\n$length\n\nRecords with the same name are overwritten whole — restoring means \"go back to the moment of the backup\", with no field-level merging. Books added after the backup will not be deleted.';
  }

  @override
  String get s_a0451c97 => 'Cancel';

  @override
  String get s_ec7085ab => 'Restore';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return 'Restore complete$first\n\n$counts';
  }

  @override
  String s_e669bac1({required Object e}) {
    return 'Restore failed: $e';
  }

  @override
  String s_7c0be1cd({required int? books}) {
    return '$books books';
  }

  @override
  String s_dd2321ce({required int? notes}) {
    return '$notes notes';
  }

  @override
  String s_d48aa751({required int? reading_logs}) {
    return '$reading_logs reading logs';
  }

  @override
  String s_d044717e({required int? llm_reports}) {
    return '$llm_reports AI reports';
  }

  @override
  String s_f4d248a7({required int? settings}) {
    return '$settings settings entries';
  }

  @override
  String get s_8719bf89 => 'Data export & restore';

  @override
  String get s_8fe27f12 => 'What\'s exported';

  @override
  String get s_5d9af0a7 => 'A full JSON snapshot: books, notes, reading logs, AI reports and settings. It saves as a single file — use it to restore on another device.';

  @override
  String get s_582f4cb6 => 'Export as a JSON file';

  @override
  String get s_091ad5f4 => 'Restore from backup';

  @override
  String get s_3a36f742 => 'Choose a previously exported .json file. Records with the same name are overwritten whole, not merged field by field — this means \"go back to the moment of the backup\", not \"take the union\".';

  @override
  String get s_6f9ab88c => 'Choose a backup file and restore';

  @override
  String get s_f24f63da => 'Delete this note?';

  @override
  String get s_ecbd7449 => 'Delete';

  @override
  String get s_f98a79dc => 'Add note';

  @override
  String get s_05712ea1 => 'Edit note';

  @override
  String get s_e3fdcb7e => 'A quote, a thought, or a review…';

  @override
  String get s_c8d8fada => 'Chapter / page';

  @override
  String get s_f80f4749 => 'Optional';

  @override
  String get s_abfe9512 => 'Save';

  @override
  String get s_a647c2e0 => 'This book doesn\'t exist or has been deleted';

  @override
  String s_154ada37({required Object join}) {
    return 'Author: $join';
  }

  @override
  String s_904feb6c({required Object join}) {
    return 'Translator: $join';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return 'Publisher: $publisher';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return 'Published: $first';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return 'Category: $categoryPrimary';
  }

  @override
  String get s_d9bdf56b => 'Status';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return 'Progress $toStringAsFixed%';
  }

  @override
  String get s_8331377a => 'Rating';

  @override
  String get s_205eb716 => 'Summary';

  @override
  String get s_b5e2aa8a => 'Record what this book is about';

  @override
  String get s_3ec1ca86 => 'Review';

  @override
  String get s_aa5a5d3e => 'Your thoughts and reviews';

  @override
  String s_fb47d52b({required Object length}) {
    return 'Notes · $length';
  }

  @override
  String get s_18dd30c5 => 'No notes yet. Jot one down when something strikes you — it\'ll be material for your year in review.';

  @override
  String get s_4b7d48f2 => 'Description';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return 'Due: $dueAt';
  }

  @override
  String get s_ad207008 => 'Edit';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => 'Title can\'t be empty';

  @override
  String get s_1f0939bc => '[,，、;；]';

  @override
  String get s_6c7a6cc5 => 'Edit book';

  @override
  String get s_31e2aa97 => 'Add a book manually';

  @override
  String get s_eda73905 => 'Save changes';

  @override
  String get s_71b10e99 => 'Add to shelf';

  @override
  String get s_2dae8ba5 => 'Choose a local cover';

  @override
  String get s_5be7901d => 'Set cover';

  @override
  String get s_a59912dd => 'Remove cover';

  @override
  String get s_e2b6c0de => 'Title *';

  @override
  String get s_22760472 => 'Author';

  @override
  String get s_5f70e9dd => 'Separate multiple authors with commas';

  @override
  String get s_759fb403 => 'Status';

  @override
  String get s_da1c08d9 => 'Format';

  @override
  String get s_5ce4e16d => 'Clear';

  @override
  String get s_b0d7b0de => 'Description / summary';

  @override
  String get s_d0dd45ac => 'Categories are normalized to a controlled vocabulary — typing \"Business & Motivation\" also merges into \"Business\", so statistics won\'t split into two separate buckets.';

  @override
  String get s_b32f0afe => 'Category';

  @override
  String get s_87635298 => 'Optional';

  @override
  String get s_5aa23087 => 'None';

  @override
  String s_573b6694({required Object e}) {
    return 'Something went wrong: $e';
  }

  @override
  String get s_28690759 => 'Enhancing image…';

  @override
  String get s_d5155b2d => 'No title recognized; try another image';

  @override
  String get s_e20dac78 => 'Reading the image with a multimodal model…';

  @override
  String get s_5fea0487 => 'The multimodal model couldn\'t read a title from this image. Check that the selected model accepts image input (text-only models reject it outright), or set Settings → Screenshot recognition → Recognition mode back to \"Auto\" to fall back to on-device OCR.';

  @override
  String get s_cdda9381 => 'Multimodal returned nothing; falling back to on-device OCR…';

  @override
  String get s_b85e4cbc => 'Image upload not allowed; falling back to on-device OCR…';

  @override
  String get s_a9698571 => 'Recognizing text…';

  @override
  String get s_7ef6b42d => 'No text was found in this image. Try a different angle, get the text sharper, or just take a screenshot (screenshots are cleaner than photos).';

  @override
  String get s_319b9488 => 'No title-like text found. If this is an inside page the title usually isn\'t on it — try \"Import shelf screenshot\" or photograph the cover instead.';

  @override
  String get s_37588c9c => 'No title could be read from this image. Try cropping out the surrounding UI and retry.';

  @override
  String get s_04a1b347 => 'Title';

  @override
  String get s_a9fe3793 => 'No \"Title\" column found in the CSV';

  @override
  String get s_3db59388 => 'Progress';

  @override
  String get s_9e160a69 => 'Publisher';

  @override
  String s_d4b7c3c7({required Object length}) {
    return 'Parsed $length books. Import them?';
  }

  @override
  String get s_649320a3 => 'Reading your WeRead shelf…';

  @override
  String get s_e53774ba => 'The shelf is empty, or the API returned no data';

  @override
  String s_8151aa42({required Object length}) {
    return 'Your WeRead shelf has $length books. Import them?';
  }

  @override
  String get s_9b37038a => 'Completing metadata and saving…';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return 'Import complete: $added added, $duplicated updated$failed';
  }

  @override
  String get s_28ab46d9 => 'No WeRead books on this device yet — sync the shelf first';

  @override
  String get s_6d61442b => 'Syncing reading progress…';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return 'Updated reading progress for $updated of $length books';
  }

  @override
  String get s_3a0cf870 => 'The connection was interrupted. Check your network and retry.';

  @override
  String get s_1cbe2507 => 'Confirm';

  @override
  String get s_1df9fbd5 => 'Import';

  @override
  String get s_874053cb => 'WeRead API key';

  @override
  String get s_58652b51 => 'Scan the QR code in WeChat to open weread.qq.com/r/weread-skills,\nthen copy the key shown on the page (it starts with \"wrk-\"). The key is stored on this device only.';

  @override
  String get s_cb2558f7 => 'Import shelf screenshot';

  @override
  String get s_24b715f3 => 'Pick a screenshot of your shelf and read each cell\'s title and progress. Results can be off — check before saving.';

  @override
  String get s_4f062f79 => 'Import shelf photo';

  @override
  String get s_6e464c0e => 'Photograph a cover, spine or page; the title is detected and the rest of the metadata filled in. Results can be off — check before saving.';

  @override
  String get s_a5452d46 => 'Sync shelf from channels';

  @override
  String get s_d40e2a14 => 'Reads your shelf and reading status through the official API of your configured channels — no screenshots needed. WeRead is supported today; more channels are on the way.';

  @override
  String get s_af94a367 => 'Sync reading progress';

  @override
  String get s_59d2efab => 'Fetches each book\'s reading percentage and accumulated time. Some channel shelf endpoints omit progress, so it needs a separate request per book.';

  @override
  String get s_fa52186c => 'CSV / Notion import';

  @override
  String get s_2c78f2b8 => 'One-click migration from a Notion CSV export: column names are detected automatically and custom fields are preserved.';

  @override
  String get s_238b14fc => 'Processing…';

  @override
  String s_ed4b0551({required Object length}) {
    return '$length books couldn\'t be imported';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '…and $length more';
  }

  @override
  String get s_18307d56 => 'Add manually';

  @override
  String s_cc0eef03({required Object length}) {
    return '$length books recognized';
  }

  @override
  String get s_0f466d7a => 'Select all';

  @override
  String get s_42b2fafa => 'Deselect all';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return 'Read $totalLines lines of text, kept $keptLines books$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => 'Items marked \"completed\" or \"inferred\" are not verbatim from the image — please check them before importing. You can tap any title or author to edit it.';

  @override
  String get s_0f40975c => 'Add one manually (missed by OCR)';

  @override
  String s_fdc0acd1({required Object length}) {
    return 'Import the $length selected';
  }

  @override
  String get s_4443bd2c => 'The original image was truncated';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return 'Progress $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return 'Confidence $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return 'Original image: $rawText';
  }

  @override
  String get s_7bbe0f10 => 'Author (optional)';

  @override
  String get s_bd13cf0b => 'Delete this one';

  @override
  String get s_c048f107 => 'Statistics range';

  @override
  String get s_89c61e4a => 'Total books';

  @override
  String get s_9da15a74 => 'Status breakdown';

  @override
  String get s_130a42ae => 'Category breakdown';

  @override
  String get s_98f42577 => 'Source breakdown';

  @override
  String get s_5e8ebbe6 => 'Format breakdown';

  @override
  String get s_5182e58a => 'Average rating';

  @override
  String get s_50bcc778 => 'Books rated';

  @override
  String get s_59c5e73a => 'Reading time (minutes)';

  @override
  String get s_48529b9f => 'Days with reading activity';

  @override
  String get s_7be1388c => 'No LLM key configured. Fill one in under Settings → LLM to generate.';

  @override
  String get s_992d7786 => 'The model returned no usable tags; try another model';

  @override
  String get s_eead3bcd => 'Replace with this set?';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return 'Your current $length tags will be replaced with these $length_1. You can still edit or delete them one by one afterwards.';
  }

  @override
  String get s_89829921 => 'Replace';

  @override
  String get s_0f8acec9 => 'Replaced with the main tags';

  @override
  String get s_93aebfd1 => 'That tag is already listed above';

  @override
  String get s_bca518fd => 'Added to the main tags';

  @override
  String s_284dfaab({required Object text}) {
    return 'Removed \"$text\"';
  }

  @override
  String get s_8eb8d18d => 'Edit tag';

  @override
  String get s_35c48d07 => 'This is a tag you wrote yourself; there\'s no automatic basis for it.';

  @override
  String get s_724386f0 => 'Add tag';

  @override
  String get s_fdd8c684 => 'Tags you write yourself aren\'t validated and won\'t be overwritten by recomputation.';

  @override
  String get s_7b328e58 => 'Reset tags to default?';

  @override
  String get s_b9a4d4ef => 'Your manual edits will be cleared and the tags will be inferred again from your current library.';

  @override
  String get s_0fcef2c8 => 'Restored to tags inferred from your library';

  @override
  String get s_e97565e5 => 'My reading profile';

  @override
  String s_783e43af({required Object e}) {
    return 'Couldn\'t generate the share image: $e';
  }

  @override
  String get s_14f92b04 => 'Generate share image';

  @override
  String get s_a17c4e02 => 'Saved to your photos';

  @override
  String s_3f81d5b6({required Object e}) {
    return 'Couldn\'t save: $e';
  }

  @override
  String get s_c6d1e7a3 => 'Image ready';

  @override
  String get s_b8e4c9a1 => 'Save image to this device';

  @override
  String get s_51ebc0d1 => 'Recompute';

  @override
  String get s_6c64acc5 => 'My reading personality tags';

  @override
  String s_03bf36af({required Object length}) {
    return 'Inferred from $length books';
  }

  @override
  String get s_a789d74f => 'All the tags have been deleted. Tap \"Add\" below to write your own, or reset to default and let the app infer them again.';

  @override
  String get s_a1d885c1 => 'Add';

  @override
  String get s_64bff158 => 'Tap a tag to rename or delete it. For rule-inferred tags, the numbers behind them are visible in the edit dialog.';

  @override
  String get s_84bf2c49 => 'Generating…';

  @override
  String get s_5a251fee => 'Generate another set with AI';

  @override
  String get s_18be3bbe => 'Reset to default';

  @override
  String get s_7ae84af3 => 'Reading preferences';

  @override
  String s_aeed65e7({required Object length}) {
    return '$length categories';
  }

  @override
  String get s_f2a9e2a4 => 'The circle\'s area is proportional to the number of books (so the radius is the square root of the count — using the count directly as the radius would exaggerate differences and mislead).';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'AI generated · $stamp';
  }

  @override
  String get s_7ea8e671 => 'Replace main tags';

  @override
  String get s_d1a58b2f => 'Tap a single tag to add it to the main tags, or replace the whole set. This set is generated by the model from aggregate statistics, so its basis is less explicit than the rule-based one.';

  @override
  String get s_a38881a0 => 'No books in this range yet';

  @override
  String get s_20fde694 => 'Try another time range, or import some books first';

  @override
  String get s_9fe34cff => 'No category data yet';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount books';
  }

  @override
  String get s_bfc50de8 => 'Personality tags';

  @override
  String get s_ab5cc063 => 'Reading preferences';

  @override
  String get s_9de44e0f => 'Reading tracker · My shelf';

  @override
  String get s_20a63774 => 'Choose statistics range';

  @override
  String get s_d507abff => 'OK';

  @override
  String get s_ff31410d => 'Custom…';

  @override
  String get s_72cca1f6 => 'Configuration saved locally';

  @override
  String s_b6477017({required Object name}) {
    return 'Filled in $name; the API key is still needed';
  }

  @override
  String get s_533f5118 => 'Fetching model list…';

  @override
  String s_648219b9({required Object id}) {
    return 'Selected model: $id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '$length models available (none selected)';
  }

  @override
  String get s_e37cab47 => 'Testing the connection…';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return 'Connected · $model\nTook $latencyMs ms; the model replied \"$reply\"';
  }

  @override
  String get s_5df0d12b => 'Verifying WeRead key…';

  @override
  String s_bd245b07({required Object n}) {
    return 'Key is valid; the shelf currently has $n books';
  }

  @override
  String s_73f89115({required Object host}) {
    return 'Can\'t reach $host\nCheck your network, whether the base URL is complete (including /v1), and whether the service needs a proxy';
  }

  @override
  String get s_9038e16e => 'The endpoint timed out (180 seconds)';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return 'Service returned $statusCode: $e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return 'Request failed: $name';
  }

  @override
  String get s_4d3eb2b3 => 'Search models';

  @override
  String s_17d94005({required Object length}) {
    return '$length in total';
  }

  @override
  String get s_a48ae43a => 'Clicking a suggestion writes the model name in';

  @override
  String get s_b5c7b82d => 'Settings';

  @override
  String get s_bc90fa59 => 'Used to sync your shelf and reading progress. Scan the QR code to open weread.qq.com/r/weread-skills to get one.';

  @override
  String get s_e44e9f26 => 'Verify key';

  @override
  String get s_75bf6943 => 'LLM';

  @override
  String get s_9e8f6691 => 'Used for metadata fallback, screenshot recognition cleanup and reading reports.';

  @override
  String get s_cc3c9556 => 'Provider presets';

  @override
  String get s_9021b9f9 => 'Selecting one fills in the address and model';

  @override
  String get s_1fd51aaa => 'Model name';

  @override
  String get s_209e1f28 => 'Use \"Fetch models\" to pick from the list your account actually has';

  @override
  String get s_ab135d7c => 'Fetch models';

  @override
  String get s_a46a5664 => 'Test connection';

  @override
  String get s_e4f7e107 => 'Show key';

  @override
  String get s_b13be56e => 'Hide key';

  @override
  String get s_9ac01f6b => 'Both Test and Fetch save what you\'ve entered first; whatever is tested is what gets stored.';

  @override
  String get s_0001747c => 'Screenshot recognition';

  @override
  String get s_3f5cbdbf => 'Determines how well photo and screenshot imports are recognized.';

  @override
  String get s_9130a4ed => 'Image enhancement preprocessing';

  @override
  String get s_b79fc99c => 'Before recognition, the image is upscaled to 1200px wide, converted to grayscale and given more contrast. Small titles are recognized noticeably better.';

  @override
  String get s_9695a603 => 'Use the LLM to clean up recognition results';

  @override
  String get s_267118b5 => 'Hand the OCR text to the LLM to pick out the real titles and complete truncated ones. Needs an LLM key and consumes tokens.';

  @override
  String get s_6d7e1f9f => 'Recognition mode';

  @override
  String get s_ed144a76 => 'Auto (multimodal first, falls back to on-device)';

  @override
  String get s_c7bab837 => 'Multimodal LLM reads the image directly';

  @override
  String get s_d8f3da2a => 'On-device OCR (offline, free)';

  @override
  String get s_f22e4cd2 => 'On-device OCR returns coordinates, so in a multi-column shelf it can attribute \"0.8%\" to the right book — but it can\'t read vertical titles, cover lettering or truncated titles. A multimodal model understands the layout, at the cost of needing a network and sometimes inventing titles. The two fail in different ways, so the \"Auto\" default (using both) is the most reliable.';

  @override
  String get s_67677b3d => 'Data';

  @override
  String get s_d596ba9b => 'Export the whole database as JSON to move to another device. A fresh install starts with an empty shelf; add books from the Import tab to get going.';

  @override
  String get s_39239742 => 'One-tap export / restore';

  @override
  String get s_3c21597a => 'All changes are saved to this device\'s database automatically — no manual save needed.';

  @override
  String get s_68885a92 => 'Keys are stored only in this device\'s database; they are never bundled with the app or uploaded.';

  @override
  String get s_9b3c95d4 => 'Recently updated';

  @override
  String get s_97428491 => 'Recently finished';

  @override
  String get s_8f38c041 => 'Highest rated';

  @override
  String get s_50a7317f => 'Most progress';

  @override
  String get s_b5538557 => 'Title A–Z';

  @override
  String s_e3cd14ba({required Object title}) {
    return 'Added \"$title\"';
  }

  @override
  String get s_296fc9b4 => 'Shelf';

  @override
  String get s_a444b428 => 'Sort';

  @override
  String get s_fa0a5cdd => 'Switch to list';

  @override
  String get s_cb4a4231 => 'Switch to cover grid';

  @override
  String get s_78966c42 => 'Search title / author / publisher';

  @override
  String get s_8ed41c6c => 'No books match these filters';

  @override
  String get s_bd33274a => 'No books yet — add some from the Import tab';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '$length books';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '$reading reading · $finished read';
  }

  @override
  String get s_68022ee7 => 'All';

  @override
  String get s_542b67cc => 'More filters';

  @override
  String get s_ec977df0 => 'Source';

  @override
  String get s_50d471b2 => 'Reset';

  @override
  String get s_37361909 => 'Chart visibility';

  @override
  String get s_b1288e4a => 'Show all';

  @override
  String get s_6b2b7015 => 'Hide all';

  @override
  String get s_e91a9228 => 'Show only the charts you care about; hide the rest.';

  @override
  String get s_fe93ef35 => 'Apply';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return 'Due in $daysUntilDue days';
  }

  @override
  String get s_0e13c16f => 'Statistics';

  @override
  String get s_3ad4c4c8 => 'Reading profile';

  @override
  String s_7c6c253b({required Object label}) {
    return 'This period · $label';
  }

  @override
  String get s_88c0b751 => 'Attributed by each book\'s completion or activity date';

  @override
  String get s_50ba5fd5 => 'books';

  @override
  String get s_cc4556af => 'Books added';

  @override
  String get s_3509a9f8 => 'days';

  @override
  String get s_a7e9ff0f => 'pts';

  @override
  String get s_58d90b89 => 'Current shelf';

  @override
  String get s_c3bb899b => 'Snapshot figures, unaffected by the time filter above';

  @override
  String get s_563edd9d => 'Total books';

  @override
  String get s_0d8d3eb3 => 'Reading streak';

  @override
  String get s_4ab30c5b => 'Started but stalled';

  @override
  String s_b563f985({required Object label}) {
    return 'Structure · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '$length books included';
  }

  @override
  String get s_c6cc650b => 'Status breakdown';

  @override
  String get s_8137585d => 'Top 8 categories';

  @override
  String s_f92480e2({required Object length}) {
    return '$length categories';
  }

  @override
  String get s_50feb68a => 'Reading per month';

  @override
  String get s_750a3b1c => 'No reading activity in this range yet';

  @override
  String get s_4d7dd157 => 'Monthly reading time';

  @override
  String get s_5a78dc03 => 'Shown after importing WeRead yearly statistics';

  @override
  String get s_5b37ad6b => 'Rating distribution';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return 'Average $toStringAsFixed · $unratedCount unrated';
  }

  @override
  String get s_3c1cb8ee => 'No ratings yet';

  @override
  String get s_01d886c7 => 'In-progress distribution';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '$readingInRange in progress';
  }

  @override
  String get s_faf98ba4 => 'No books in progress in this range';

  @override
  String s_77030fdc({required Object length}) {
    return '$length platforms';
  }

  @override
  String s_cea9cf70({required Object first}) {
    return '$first';
  }

  @override
  String s_c4e530bb({required Object first, required Object last}) {
    return '$first–$last';
  }

  @override
  String s_00fbaae1({required Object scope, required Object toStringAsFixed}) {
    return '$scope · $toStringAsFixed h total';
  }

  @override
  String s_e7b115df({required Object join}) {
    return 'WeRead yearly statistics only cover $join, so this chart is drawn by calendar year; the finished-books chart above uses the most recent 12 months.';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name\n$toInt books';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt books';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed h';
  }

  @override
  String get s_1597bc27 => 'AI reading report';

  @override
  String s_5024726e({required Object reportCount}) {
    return '$reportCount archived · filed by year / month, revisit anytime';
  }

  @override
  String get s_73f01b82 => 'Generate a yearly / monthly reading summary; open one to create it';

  @override
  String get s_530f5951 => 'View';

  @override
  String get s_d51cd7ae => 'Generate';

  @override
  String get s_f8525cf2 => 'No data yet';

  @override
  String s_854a34ca({required Object author}) {
    return ', by $author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return ': $detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\nAdditional context: $hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '(backed up on $first)';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return ', $failed failed';
  }

  @override
  String get s_da4d4d27 => ' · cleaned up with the LLM';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return ' · completed $repairedTitles truncated titles';
  }

  @override
  String get navNotes => 'Records';

  @override
  String get notesViewByTime => 'By time';

  @override
  String get notesViewByBook => 'By book';

  @override
  String get notesFilterByBook => 'Filter by book';

  @override
  String get notesAllBooks => 'All books';

  @override
  String get notesBookMissing => 'Book removed';

  @override
  String notesOverview({required int count, required int books}) {
    return '$count notes · across $books books';
  }

  @override
  String notesMoreCount({required int count}) {
    return '$count more';
  }

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyDesc => 'Open any book and add a highlight or thought at the bottom of its detail page — they will collect here.';

  @override
  String get notesEmptyFilteredTitle => 'No notes for this book yet';

  @override
  String get notesEmptyFilteredDesc => 'Pick another book, or clear the filter to see the rest.';

  @override
  String get notesClearFilter => 'Clear filter';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDesc => 'Choose the language used by the app. Defaults to your system setting.';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get langEs => 'Español';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceDesc => 'Pick a theme and a light or dark mode.';

  @override
  String get statusWishHint => 'Not started yet.';

  @override
  String get statusReadingHint => 'Currently reading. Reaches 100% progress it becomes Finished automatically.';

  @override
  String get statusFinishedHint => 'Finished. Slide progress to 100% and it is marked automatically.';

  @override
  String get statusShelvedHint => 'Started but not planning to continue for now. Switch back to Reading to pick it up again.';

  @override
  String get borrowTitle => 'Borrowed';

  @override
  String get borrowDesc => 'Mark the book as borrowed, with a lender and a due date.';

  @override
  String get borrowFlag => 'This book is borrowed';

  @override
  String get borrowFrom => 'Borrowed from';

  @override
  String get borrowFromHint => 'e.g. City Library, a colleague';

  @override
  String get borrowDue => 'Due date';

  @override
  String get borrowDueUnset => 'Not set';

  @override
  String borrowDueIn({required int days}) {
    return '$days days until due';
  }

  @override
  String borrowOverdue({required int days}) {
    return 'Overdue by $days days';
  }

  @override
  String get borrowClearDue => 'Clear date';

  @override
  String get borrowReturn => 'Mark as returned';

  @override
  String get borrowReturnDesc => 'This clears the loan flag, the lender and the due date, and cancels the return reminder.';

  @override
  String get borrowReturned => 'Marked as returned';

  @override
  String get statusSectionTitle => 'Reading status';

  @override
  String get planSectionTitle => 'Reading plans';

  @override
  String get planSectionDesc => 'Set a goal you can actually keep. Plans stay on this device.';

  @override
  String get planEmpty => 'No plans yet. Start small — 20 minutes a day.';

  @override
  String get planAdd => 'New plan';

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planKindDaily => 'Read every day';

  @override
  String get planKindFinishBook => 'Finish a book';

  @override
  String get planKindDailyDesc => 'Set a daily reading time; judged on your daily average.';

  @override
  String get planKindFinishBookDesc => 'Pick a book and a deadline. Reaching 100% completes it.';

  @override
  String get planDailyTarget => 'Daily target';

  @override
  String planMinutesUnit({required int n}) {
    return '$n min';
  }

  @override
  String get planPickBook => 'Pick a book';

  @override
  String get planDueLabel => 'Deadline';

  @override
  String get planDueUnset => 'Not set';

  @override
  String get planRemind => 'Remind me before the deadline';

  @override
  String get planRemindOff => 'Turning this on asks for notification permission. The reminder cancels itself once the plan is done.';

  @override
  String get planTitleLabel => 'Plan name (optional)';

  @override
  String get planTitleHint => 'Leave empty to use the default name';

  @override
  String get planSave => 'Save';

  @override
  String get planDelete => 'Delete plan';

  @override
  String get planDeleteConfirm => 'Delete this plan? Your reading records are not affected.';

  @override
  String get planMarkDone => 'Mark as done';

  @override
  String get planAchieved => 'Achieved';

  @override
  String get planMarkToday => 'Read today';

  @override
  String get planDoneToday => 'Done for today';

  @override
  String get planDailyCycleHint => 'Every day is a fresh start — ticking it only counts for today, and the reminder comes back tomorrow.';

  @override
  String get planReminderUnavailable => 'The system couldn\'t schedule the reminder (power-saving may have blocked it). Your plan was still saved.';

  @override
  String planProgressDaily({required String current, required String target}) {
    return 'Daily average $current / $target min';
  }

  @override
  String planProgressBook({required int current}) {
    return 'Progress $current% · target 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return '$days days left';
  }

  @override
  String planOverdue({required int days}) {
    return 'Overdue by $days days';
  }

  @override
  String get planDueToday => 'Due today';

  @override
  String get planBookGone => 'The target book is no longer on your shelf';

  @override
  String get planDoneSection => 'Finished';

  @override
  String get planReminderDenied => 'Notification permission was denied, so reminders cannot be delivered. Enable it in system settings.';

  @override
  String get planReminderDailyTitle => 'Today\'s reading goal is not done yet';

  @override
  String planReminderDailyBody({required int minutes}) {
    return 'Your goal is $minutes minutes — there is still time.';
  }

  @override
  String get planReminderBookTitle => 'A reading deadline is coming up';

  @override
  String planReminderBookBody({required int days}) {
    return 'Your plan is due in $days days. A good time to finish it.';
  }

  @override
  String get settingsPlanReminder => 'Reading reminders';

  @override
  String get reportSettings => 'Report settings';

  @override
  String get reportBackfill => 'Generate missing reports';

  @override
  String get reportNothingToBackfill => 'Every report that should exist is already here.';

  @override
  String get reportHistoryEmpty => 'No reports yet. Pick a period and generate your first one below.';

  @override
  String get reportNoKey => 'No model configured, so reports cannot be generated. Add a key in Settings first.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsBrightness => 'Light or dark';

  @override
  String get brightnessSystem => 'Follow system';

  @override
  String get brightnessLight => 'Light';

  @override
  String get brightnessDark => 'Dark';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeInk => 'Ink';

  @override
  String get themeAmber => 'Amber';

  @override
  String get themeBlue => 'Blue';

  @override
  String get themeRose => 'Rose';

  @override
  String get settingsChannels => 'Connected services';

  @override
  String get settingsChannelsDesc => 'Sync your shelf and progress from other reading platforms. WeRead is supported today; more platforms will be added as they open their APIs.';

  @override
  String get settingsChannelsHint => 'Keys are stored only in this device\'s system keychain and are never uploaded.';

  @override
  String get settingsChannelAddHint => 'More services are on the way.';

  @override
  String get importAccuracyTitle => 'Results may be inaccurate';

  @override
  String get importAccuracyDesc => 'Titles and authors are inferred by OCR and AI models, so they can misread a word or pick the wrong book. Please review before saving.';

  @override
  String get importFromImageTitle => 'Import from screenshot';

  @override
  String get importFromImageDesc => 'Pick a screenshot of your shelf and detect the books on it.';

  @override
  String get importFromCameraTitle => 'Import by camera';

  @override
  String get importFromCameraDesc => 'Take a photo of your shelf and detect the books on it.';

  @override
  String get insights => 'Insights';

  @override
  String get insightsDesc => 'Your long-term reading profile, plus reports by month and year.';

  @override
  String get chronology => 'Timeline';

  @override
  String get chronologyDesc => 'Your reading month by month. Tap a card to open the book.';

  @override
  String get chronologyEmpty => 'Nothing finished or in progress this year yet.';

  @override
  String get chronologyFinished => 'Finished';

  @override
  String get chronologyReading => 'Reading';

  @override
  String get chronologyShelved => 'Shelved';

  @override
  String get chronologyWish => 'Want to read';

  @override
  String chronologyMore({required int n}) {
    return '$n more — see the whole month';
  }

  @override
  String get reportStyle => 'Report style';

  @override
  String get reportStyleDesc => 'Choose the tone and structure of generated reports, or write your own prompt.';

  @override
  String get reportStyleRational => 'Plain facts';

  @override
  String get reportStyleRationalDesc => 'States the data objectively: no praise, no prodding, clearly itemised.';

  @override
  String get reportStyleWarm => 'Warm encouragement';

  @override
  String get reportStyleWarmDesc => 'Acknowledges your consistency and offers advice gently.';

  @override
  String get reportStyleDirect => 'Straight talk';

  @override
  String get reportStyleDirectDesc => 'Names the problems without softening, for readers who want it plain.';

  @override
  String get reportStyleConcise => 'Brief';

  @override
  String get reportStyleConciseDesc => 'Conclusions only, as short as possible.';

  @override
  String get reportStyleCustom => 'Custom';

  @override
  String get reportStyleCustomDesc => 'Write the prompt yourself and control exactly how reports read.';

  @override
  String get reportStyleCustomHint => 'e.g. Talk to me in second person, like a friend commenting on my reading.';

  @override
  String get reportReadMore => 'Read full report';

  @override
  String get reportNoContent => '(this report has no body text)';
}

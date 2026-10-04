import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Readnest';

  @override
  String get navShelf => 'Étagère';

  @override
  String get addBookSheetTitle => 'Ajouter un livre';

  @override
  String get addBookManualTitle => 'Saisir manuellement';

  @override
  String get addBookManualDesc => 'Saisissez le titre et créez vous-même — aucun compte ou fichier n\'est nécessaire.';

  @override
  String get navStats => 'Statistiques';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get supportDev => 'Soutenir le développeur';

  @override
  String get supportDevDesc => 'Chaque fonctionnalité est gratuite, sans publicité ni achat dans l\'application. Si l\'application vous aide à lire, vous pouvez m\'acheter un café — entièrement facultatif, et rien ne change dans les deux cas.';

  @override
  String get openTipPage => 'Achetez-moi un café · Ko-fi';

  @override
  String get openTipDomestic => 'Soutien · Afdian (Chine)';

  @override
  String get openTipForeign => 'Soutien · Ko-fi (International)';

  @override
  String get about => 'À propos';

  @override
  String get aboutDesc => 'Détails du développeur et liens connexes.';

  @override
  String get appIntroPage => 'A propos de cette application';

  @override
  String get developerHomepage => 'Site web du développeur';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get reportDeleteConfirm => 'Supprimer ce rapport ? Cela ne peut pas être annulé.';

  @override
  String get reportDelete => 'Effacer';

  @override
  String appVersionLabel({required String version}) {
    return 'Version $version';
  }

  @override
  String get goodreadsImport => 'Importation Goodreads / Library CSV';

  @override
  String get goodreadsImportDesc => 'Importer un fichier CSV de bibliothèque exporté à partir de Goodreads et de services similaires (titre, auteur, classement, statut de l\'étagère).';

  @override
  String get goodreadsImportEmpty => 'Aucune colonne « Titre » trouvée dans le CSV';

  @override
  String get openLibraryImport => 'Ouvrir l\'importation de la recherche Bibliothèque / Google Books';

  @override
  String get openLibraryImportDesc => 'Rechercher dans les catalogues publics par titre ou ISBN et importer avec des métadonnées enrichies (auteur, éditeur, couverture).';

  @override
  String get catalogSearchTitle => 'Catalogue/recherche';

  @override
  String get catalogSearchHint => 'Saisissez un titre ou un ISBN';

  @override
  String get catalogSearchAction => 'Rechercher';

  @override
  String get catalogSearchInitial => 'Rechercher des catalogues publics sur Google Books et Open Library. Les livres sélectionnés sont ajoutés avec l\'auteur, l\'éditeur, la couverture et le nombre de pages.';

  @override
  String get catalogNoResult => 'Aucun livre correspondant trouvé — essayez un mot-clé différent.';

  @override
  String catalogSearchFailed({required Object e}) {
    return 'Échec de la recherche : $e';
  }

  @override
  String get imageUploadConsentTitle => 'Envoyer une capture d\'écran de l\'étagère au service d\'IA ?';

  @override
  String get imageUploadConsentBody => 'Pour permettre à l\'IA de lire l\'intégralité de votre capture d\'écran d\'étagère, cette image est envoyée au service d\'IA que vous avez configuré dans Paramètres (un tiers). Il ne contient aucun texte de note, mais inclut les titres et les couvertures de livres. Autoriser ce téléchargement ?';

  @override
  String get allow => 'Autoriser';

  @override
  String get cancel => 'Annuler';

  @override
  String get s_178329ba => 'Clé API WeRead non configurée';

  @override
  String get s_dd204792 => 's';

  @override
  String get s_ad86a5ca => 'Clé API LLM non configurée';

  @override
  String get s_8a853cbe => 'Remplissez-le sous Paramètres → LLM';

  @override
  String get s_7d704c88 => 'Aucun modèle sélectionné';

  @override
  String get s_4508cedd => 'Appuyez sur « Récupérer les modèles » pour en choisir un dans la liste disponible de votre compte.';

  @override
  String get s_1b5140db => 'Sortie JSON valide uniquement — pas de texte explicatif, pas de blocs de code de démarque.';

  @override
  String s_c94c96fc({required Object apiError}) {
    return 'Le service modèle a renvoyé une erreur : $apiError';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return 'Raw response: $head\nFirst check the address and model name under Settings → LLM using \"Fetch models\". An unpaid balance or a model that isn\'t enabled will also land here.';
  }

  @override
  String get s_231cf54a => 'La réponse du modèle n\'a pas pu être analysée';

  @override
  String s_90747d4c({required Object head}) {
    return 'Raw response: $head\nThe gateway returned a non-standard structure. Try another model or protocol; sending us this raw text also helps us add support for it.';
  }

  @override
  String get s_9d9714af => 'Le message est vide et ne peut pas être envoyé';

  @override
  String get s_f44ff25c => 'Le mannequin a refusé cette demande';

  @override
  String get s_cad5bf6e => 'Le contenu a été signalé comme inapproprié. Reformulez-le ou essayez un autre modèle.';

  @override
  String get s_0f7b54a1 => 'La clé API n’est pas configurée.';

  @override
  String get s_345e9547 => 'Saisissez la clé avant de récupérer les modèles';

  @override
  String get s_3a5d4cca => 'Le service a renvoyé une liste de modèles vide';

  @override
  String s_cea80527({required Object apiError}) {
    return 'Impossible de récupérer les modèles : $apiError';
  }

  @override
  String get s_4674d953 => 'Vous pouvez saisir le nom du modèle manuellement';

  @override
  String s_749fc40e({required Object raw}) {
    return 'Réponse brute : $raw';
  }

  @override
  String get s_8add575d => 'Ce service ne fournit pas de point de terminaison de liste de modèles (404)';

  @override
  String get s_53fb436d => 'Il suffit de taper le nom du modèle, par exemple deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => 'Aucun nom de modèle saisi';

  @override
  String get s_1da90e20 => 'Appuyez d\'abord sur « Récupérer les modèles » ou saisissez-en un dans';

  @override
  String get s_2abb6b8a => 'Répondre avec deux caractères : OK';

  @override
  String get s_ad736a74 => 'Vous êtes un (e) assistant (e) de catalogage de livres. Sortie JSON uniquement, pas d\'explications.';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return 'Known title \"$title\"$author.\nPlease fill in:\n- categoryPrimary: must be one of: $vocab\n- description: a neutral 80–150 character summary of the book\'s content, stating facts without evaluation\n- tags: 3–5 keyword tags\n- authors: an array if the author can be determined, otherwise an empty array\nOutput format: {\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}';
  }

  @override
  String get s_cbe8aa6b => 'Vous êtes un analyste de profil de lecture. Sortie JSON uniquement, pas d\'explications.';

  @override
  String s_3864d3b4({required Object summary}) {
    return 'Here is my reading data (JSON):\n$summary\n\nGive me 10 personality tags, each 2–6 words, like the nicknames a book club gives people.\nRequirements:\n1. Every tag must be supported by the data above — don\'t make things up\n2. Style reference: Learning Is My Joy / In Tune with Nature / Beauty Above All / Erudite Across the Ages / The Lonely Sage\n3. Don\'t use empty words like \"reader\", \"enthusiast\" or \"aficionado\"\n4. No explanations, no markdown code blocks\nOutput format: {\"tags\":[\"tag1\",\"tag2\"]}';
  }

  @override
  String get s_735e2d59 => '6. Noms de noms : choisissez 3 à 5 livres spécifiques dans bookList pour en discuter (celui que vous avez terminé, que vous avez commencé mais que vous n\'avez pas continué, qui est le mieux noté) et donnez leurs titres.\nChaque titre mentionné dans le rapport doit provenir de bookList — n\'en inventez aucun.\n';

  @override
  String get s_99acf9a4 => 'Vous êtes un conseiller en lecture personnel. Analysez les données objectivement, évitez les éloges vagues et soulignez les problèmes structurels qui sont négligés.';

  @override
  String s_414278bd({required Object data, required Object listHint, required Object period}) {
    return 'Here is my reading data for $period (JSON):\n$data\n\nWrite a reading report covering:\n1. Overview: books finished, total time, daily average\n2. Structure: category breakdown, source platform breakdown, format mix\n3. Habits: reading rhythm, consecutive days, abandonment rate\n4. Profile: what kind of reader I might be\n5. Suggestions: 3 concrete, actionable next steps based on the gaps. Suggestions must stay within reading itself (what to read, how to read, how to record reflections): never comment on where or how I acquire books, never push me to write reviews, share, or keep streaks, and pass no judgment beyond reading.\n${listHint}Format rules (follow strictly - the report is rendered as Markdown inside the app):\n- Open each of the six sections with a level-2 heading such as ## Overview. No numbers inside headings.\n- Bold every key figure: finished **12 books**, **37 minutes** a day.\n- Use - bullets for parallel observations, and a numbered list for the suggestions.\n- Put every book title in italics, like *The Road to Serfdom*.\n- No HTML tags, and no headings deeper than level 3.';
  }

  @override
  String s_46e5ebef({required Object host}) {
    return 'Délai de connexion expiré : impossible d\'atteindre $host dans les 20 secondes';
  }

  @override
  String get s_3c836870 => 'Vérifiez le réseau ou l\'URL de base ; certains services à l\'étranger ont besoin d\'un proxy de Chine continentale';

  @override
  String get s_84264711 => 'Délai expiré';

  @override
  String get s_225ed2e1 => 'La connexion en amont est instable ; réessayez plus tard';

  @override
  String get s_b265cf86 => 'Réponse expirée : le modèle n\'a pas répondu dans les 180 secondes';

  @override
  String get s_cc12eea3 => 'Essayez un modèle plus rapide ou raccourcissez la période du rapport et réessayez';

  @override
  String get s_d711b259 => 'Échec de la validation du certificat HTTPS';

  @override
  String get s_4722b0f8 => 'Pour un point de terminaison auto-hébergé ou intranet, passez à un certificat de confiance';

  @override
  String get s_07a2b144 => 'Demande annulée';

  @override
  String s_8ae0b0e4({required Object host}) {
    return 'Réseau inaccessible : impossible de se connecter à $host';
  }

  @override
  String get s_0a9425b8 => '① Vérifier le réseau du téléphone ; ② s\'assurer que l\'URL de base est complète (y compris /v1) ; ‹ vérifier si le service a besoin d\'un proxy ; ‹ un service local (Ollama) ne peut pas être joint à partir du téléphone via l\'hôte local de l\'ordinateur';

  @override
  String get s_554d5235 => 'La connexion a été interrompue';

  @override
  String get s_020fe21a => 'Habituellement, une autorisation réseau bloquée, ou un proxy ou un pare-feu abandonnant la connexion ; HTTP en texte clair peut également ne pas être pris en charge. Réessayez plus tard ou changez de réseau.';

  @override
  String get s_dfde23b1 => 'La requête réseau a échoué';

  @override
  String get s_2ae4f5fe => 'Vérifiez l\'URL de base, les paramètres du proxy et le réseau';

  @override
  String s_d6ac5952({required Object detail}) {
    return 'Demande rejetée (400)$detail';
  }

  @override
  String get s_cb980461 => 'Très probablement, le nom du modèle est incorrect, ou le modèle ne prend pas en charge les paramètres actuels';

  @override
  String s_d9775d22({required Object detail}) {
    return 'Échec de l\'authentification (401)$detail';
  }

  @override
  String get s_c4198142 => 'La clé API n\'est pas valide ou a expiré — copiez-en une nouvelle';

  @override
  String get s_e06ab1cc => 'Crédit de compte insuffisant';

  @override
  String s_05b3ec8b({required Object detail}) {
    return 'Aucune autorisation (403)$detail';
  }

  @override
  String get s_f00f6ff2 => 'La clé n\'a pas la permission d\'appeler ce modèle, ou le compte n\'est pas vérifié/activé';

  @override
  String s_016f7576({required Object detail}) {
    return 'Point de terminaison ou modèle introuvable (404)$detail';
  }

  @override
  String get s_a8aa2c59 => 'Vérifiez si l\'URL de base est renseignée jusqu\'à /v1 ; utilisez « Récupérer les modèles » pour obtenir le nom du modèle';

  @override
  String s_9688a257({required Object detail}) {
    return 'Paramètres non valides (422)$detail';
  }

  @override
  String get s_1b3daaa3 => 'Tarif limité (429)';

  @override
  String get s_2a564df1 => 'Réessayez sous peu ou mettez à niveau votre forfait';

  @override
  String s_6627221e({required int? code}) {
    return 'Erreur de serveur ($code)';
  }

  @override
  String get s_2fe391dd => 'Un problème du côté distant ; réessayez plus tard';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return 'Request failed$code$detail';
  }

  @override
  String get s_0cf0a499 => 'Réponse vide';

  @override
  String get s_9ed7e745 => 'Échec de la demande réseau. Vérifiez le réseau du téléphone et l\'URL de base sous Paramètres → LLM.';

  @override
  String get s_2ad3b6ba => 'Compatible OpenAI';

  @override
  String get s_e2213e87 => 'Entrez l\'URL de base jusqu\'à /v1, par exemple https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'L\'URL de base est généralement https://api.anthropic.com (sans /v1)';

  @override
  String get s_f1ea3335 => 'SenseNova';

  @override
  String get s_e522fe39 => 'Qwen';

  @override
  String get s_7e12f8b4 => 'Zhipu GLM';

  @override
  String get s_c3d30bc2 => 'Kimi Moonshot';

  @override
  String get s_8e941e27 => 'SiliconFlow';

  @override
  String get s_c800478c => 'Ollama (local)';

  @override
  String get s_0babfa89 => 'Toute chaîne non vide';

  @override
  String get s_e74f752c => 'Les jours de lecture sont des jours enregistrés manuellement comme lus';

  @override
  String s_9ea3cbae({required Object year}) {
    return 'Reading time and days come from WeRead\'s $year yearly statistics (full-year basis)';
  }

  @override
  String get s_f676228c => 'WeRead ne fournit que des chiffres annuels, de sorte que les jours de lecture pour cette plage ne peuvent pas être donnés avec précision ; le temps est agrégé à la granularité du mois';

  @override
  String get s_06225788 => 'Non classé ';

  @override
  String s_89cfaca8({required Object i}) {
    return '$i étoiles';
  }

  @override
  String get s_e7a2db51 => 'Tout le temps';

  @override
  String s_a87cfcc9({required Object y}) {
    return '$y';
  }

  @override
  String s_62654321({required Object n}) {
    return 'Last $n months';
  }

  @override
  String get s_41f3af95 => 'Le temps et les jours de lecture sont agrégés selon la granularité mois/année';

  @override
  String get s_e8a43314 => 'Commencez votre prochain livre et cette liste obtient son premier numéro.';

  @override
  String get s_af03278c => 'L\'étagère est toujours vide — chaque historique de lecture commence ici.';

  @override
  String s_f53eead8({required Object streak}) {
    return '$streak jours de lecture consécutifs — le rythme s\'est imposé.';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return 'A $streak-day streak — don\'t let it break today.';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '$streak jours d\'affilée — une habitude qui vaut plus que n\'importe quelle liste de lecture.';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '$finished livres terminés — échangez la vitesse pour le rythme et vous irez plus loin.';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '$finished livres terminés. Revenez de temps en temps sur ceux qui ont vraiment collé.';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '$finished livres terminés dans cette section — chacun compte.';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '$finished livres terminés. Choisissez-en un que vous avez déjà commencé.';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '$minutes minutes lues dans cette section — faites d\'une demi-heure une habitude quotidienne et c\'est 180 heures par an.';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return '$minutes minutes déjà enregistrées. Ajouter un peu plus aujourd\'hui ?';
  }

  @override
  String get s_152a88d7 => 'Votre étagère est prête — commencez les dix minutes d\'aujourd\' hui avec une courte histoire légère.';

  @override
  String get s_795806c0 => 'Choisissez un livre que vous avez déjà commencé — dix minutes comptent comme une victoire.';

  @override
  String get s_aa51bf46 => 'Vous n\'avez pas besoin de lire beaucoup en une seule fois : ouvrir un livre aujourd\'hui compte.';

  @override
  String get s_363c6a0c => 'Sans catégorie';

  @override
  String get s_420a7ac1 => 'Apprendre est ma joie';

  @override
  String get s_bcd278a6 => 'Développement personnel';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '$cat livres de croissance personnelle · $pct';
  }

  @override
  String get s_6672b3fa => 'Romantique et poétique';

  @override
  String get s_d422d33c => 'Littérature';

  @override
  String s_40ba4ecb({required Object cat, required Object pct}) {
    return '$cat livres de littérature · $pct';
  }

  @override
  String get s_ea2eaec4 => 'Le sage solitaire';

  @override
  String get s_5da32671 => 'Philosophie';

  @override
  String s_0f80a135({required Object cat, required Object pct}) {
    return '$cat livres de philosophie · $pct';
  }

  @override
  String get s_111ec0f6 => 'Les leçons de l’Histoire';

  @override
  String get s_07f288e9 => 'Historique';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '$cat livres d\'histoire · $pct';
  }

  @override
  String get s_5e336507 => 'Regarde vers l\'intérieur';

  @override
  String get s_4307c7a8 => 'Psychologie';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '$cat livres de psychologie · $pct';
  }

  @override
  String get s_d5e26f37 => 'Tech Elite';

  @override
  String get s_8612fa7f => 'Informatique';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '$cat livres informatiques · $pct';
  }

  @override
  String get s_00dcb308 => 'La beauté avant tout';

  @override
  String get s_b31e932c => 'l’art ;';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '$cat livres D\'ART · $pct';
  }

  @override
  String get s_2ddd554c => 'Rationnel et pratique';

  @override
  String get s_56734d39 => 'Economie';

  @override
  String get s_5974bf24 => 'Entreprise';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '$cat économie ET livres D\'AFFAIRES · $toStringAsFixed%';
  }

  @override
  String get s_d574ffeb => 'Worldly Wise';

  @override
  String get s_086ac5bf => 'Sciences sociales';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '$cat livres de sciences sociales · $pct';
  }

  @override
  String get s_d81bab36 => 'Insatiablement curieux';

  @override
  String get s_41fa5c70 => 'Vulgarisation';

  @override
  String get s_fcc3102d => 'Technologie';

  @override
  String s_76c118d0({required Object n}) {
    return '$n livres de vulgarisation scientifique et technologique';
  }

  @override
  String get s_2b65326c => 'Apprend des autres.';

  @override
  String get s_f85fa7d4 => 'Biographie';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '$cat biographies · $pct';
  }

  @override
  String get s_9e49409c => 'Vie saine ';

  @override
  String get s_c21b69a8 => 'Médecine';

  @override
  String s_1dd31356({required Object cat}) {
    return '$cat livres de médecine et de santé';
  }

  @override
  String get s_77e32253 => 'Emprunteur pragmatique';

  @override
  String get s_0323f1bb => 'Droit';

  @override
  String s_82364cc8({required Object cat}) {
    return '$cat livres de droit';
  }

  @override
  String get s_ea038731 => 'Auto-entretenu';

  @override
  String get s_dbb1c112 => 'Bande Dessinée';

  @override
  String get s_6398a679 => 'Les livres pour les enfants';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '$cat bandes dessinées et livres pour enfants';
  }

  @override
  String get s_94f8d7c2 => 'En harmonie avec la nature';

  @override
  String get s_30412ad5 => 'La religion';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '$cat livres de religion';
  }

  @override
  String get s_52c36d65 => 'Savoir vivre';

  @override
  String get s_06e23c48 => 'Autre';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '$cat Livres lifestyle · $pct';
  }

  @override
  String get s_dc2e94c1 => 'Enseignant dans l\'âme';

  @override
  String get s_235af603 => 'éducation';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '$cat livres éducatifs · $pct';
  }

  @override
  String get s_7ea6e8a9 => 'Erudite à travers les âges';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return 'Your library spans $categoryKinds categories — a bit of everything';
  }

  @override
  String get s_41a09d04 => 'Concentration absolue,';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '$total books fall into only $categoryKinds categories';
  }

  @override
  String get s_431dc47d => 'En finition';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return 'Taux de finition $toStringAsFixed% ($finished/$total)';
  }

  @override
  String get s_6b51050c => 'Tsundoku Master';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '$wish veut lire, mais seulement $finished a terminé';
  }

  @override
  String get s_e60e931c => 'Réduit rapidement les pertes';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '$abandoned a chuté · $toStringAsFixed% — vous déposez ce qui ne vous attrape pas';
  }

  @override
  String get s_4be15f8c => 'Démarreur série';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '$stalled livres en cours mais moins de 15 %';
  }

  @override
  String get s_10b9bddd => 'Esprit doux';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Your $ratedCount rated books average $toStringAsFixed';
  }

  @override
  String get s_e67694db => 'Critique à la langue vive';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Your $ratedCount rated books average only $toStringAsFixed';
  }

  @override
  String get s_fe4567e4 => 'Opinions fortes';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return 'Rating standard deviation $toStringAsFixed — your good and bad are far apart';
  }

  @override
  String get s_fbad19d5 => 'Revisites et renouvellements';

  @override
  String s_8d62979c({required Object reread}) {
    return '$reread livres lus deux fois ou plus';
  }

  @override
  String get s_54302bb2 => 'Lecteur immersif';

  @override
  String s_bc9dbced({required Object round}) {
    return '$round minutes par jour actif en moyenne';
  }

  @override
  String get s_e9eddf51 => 'digital native';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '$weread de WeRead · $toStringAsFixed%';
  }

  @override
  String get s_ce6517f9 => 'Papier et numérique';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return 'plus $libraryCount livres empruntés et $paper livres papier';
  }

  @override
  String get s_8cac22b7 => 'Lecture avec les oreilles';

  @override
  String s_72b826e9({required Object audio}) {
    return '$audio audiobooks';
  }

  @override
  String get s_7caeab27 => 'Lecteur visuel';

  @override
  String s_a5a44a39({required Object comic}) {
    return '$comic BD';
  }

  @override
  String s_0e59d960({required Object m, required Object y}) {
    return '$m/$y';
  }

  @override
  String s_1a2e873e({required Object month}) {
    return 'Mois $month';
  }

  @override
  String s_5583162a({required Object e}) {
    return 'Échec du prétraitement de l\'image ; utilisation de l\'image d\'origine : $e';
  }

  @override
  String s_628c2132({required Object e}) {
    return 'Échec de la conversion en JPEG : $e';
  }

  @override
  String get s_ebf4bdfb => 'Analyse de la structure de mise en page…';

  @override
  String get s_ba1038b1 => 'Nettoyage des résultats de reconnaissance avec le LLM…';

  @override
  String get s_6292a274 => 'Vérification des titres…';

  @override
  String get s_427e1f0d => 'C';

  @override
  String get s_af041a1b => 'Titre terminé';

  @override
  String s_988dd5cb({required Object reason}) {
    return '$reason, titre terminé';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '\"$title\" : $e';
  }

  @override
  String get s_d2bbf7ce => 'Reconnaissance multimodale';

  @override
  String get s_381ca835 => 'Ceci est une capture d\'écran d\'une étagère ou d\'une liste de lecture';

  @override
  String get s_fce28e56 => 'Ceci est une capture d\'écran de la couverture ou de la page de détail d\'un seul livre';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene.\n\nOutput a JSON array only, each item shaped like:\n{\"title\":\"title\",\"author\":\"author\",\"progress\":a number from 0-100 or null,\"status\":\"one of unread/reading/finished or null\",\"confidence\":a number from 0-1}\n\nRequirements:\n1. Only output books that are **actually visible** in the image; don\'t add books you assume should be there;\n2. Ignore UI text (filters, search, sort, All, Shelf, N books, etc.);\n3. Copy titles exactly as shown, including ones cut off by an ellipsis — don\'t complete them yourself;\n4. Leave author as an empty string if it can\'t be read; don\'t guess;\n5. Only fill in author when it really is written in the image.\n$n';
  }

  @override
  String get s_951042c3 => 'Vous extrayez des informations à partir de captures d\'écran d\'étagère. Sortie d\'un tableau JSON uniquement, sans texte explicatif.';

  @override
  String get s_29dbdb32 => 'Nettoyage LLM';

  @override
  String get s_9cd6567e => 'Une photo d\'une couverture de livre ou d\'une colonne vertébrale';

  @override
  String get s_a6db1cf4 => 'Une capture d\'écran de l\'étagère d\'une application e-book';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return 'Below are the text lines OCR\'d from $scene, in top-to-bottom order.\n\nExtract the **real book titles** from them, ignoring all UI text (search box, filters, categories, status bar, page numbers, chapter headings, buttons, statistics).\n\nRules:\n1. Only output books that actually appear in the image. Don\'t add books you assume should be there.\n2. If a title is truncated by an ellipsis in the UI (for example \"Deep…\"), complete it into the full title.\n3. progress takes an integer percentage from 0–100; leave it an empty string if it can\'t be read. Note that \"0.8%\" is 0.8, not 80.\n4. status must be one of \"unread / reading / finished / dropped\"; leave it an empty string if it can\'t be read.\n5. Only fill in author when it clearly appears in the image; otherwise leave it blank. Don\'t guess.\n6. Skip lines you\'re unsure about. Better to miss one book than to add a fake one.\n\nOutput a JSON array only, with elements shaped like:\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nOCR text lines:\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => 's';

  @override
  String get s_95222176 => 'Non lu';

  @override
  String get s_5a833930 => 'À lire';

  @override
  String get s_b9bf9b53 => 'Lecture';

  @override
  String get s_be5492a5 => 'Lecture en cours';

  @override
  String get s_44c14529 => 'Lecture terminée';

  @override
  String get s_0872b5b7 => 'Clôturée';

  @override
  String get s_300a32bd => 'Clôturée';

  @override
  String get s_0f4d9c68 => 'Abandonné (fusionné dans Shelved)';

  @override
  String get s_7675d229 => '\\s*(著|编著|译|著译)\$';

  @override
  String get s_285bb37e => '[，。 ；、 ？！：）」』]\$';

  @override
  String get s_8f936d11 => '(著|编著 |译 |著译)\$';

  @override
  String get s_d0c345ec => '[（《 ·“]\$';

  @override
  String get s_2d3c83a7 => '[）》」』 ”]\$';

  @override
  String get s_0686f279 => 'Plus grand texte sur la couverture';

  @override
  String get s_5514105a => 'Texte de couverture secondaire';

  @override
  String get s_174faffb => 'Contient du chinois';

  @override
  String get s_b13a1237 => 'A une progression ou un statut';

  @override
  String get s_24745e9d => 'A l\'auteur';

  @override
  String get s_0cedc3f4 => 'Longueur raisonnable';

  @override
  String get s_5bdfa6ae => 'Trop court';

  @override
  String get s_58171266 => 'Trop longs';

  @override
  String get s_1e8c236b => 'Colonnes alignées à gauche';

  @override
  String get s_89ac54fb => 'Lettrage de couverture';

  @override
  String get s_132a750b => 'Anglais trop court';

  @override
  String get s_6af25a96 => '[，。 ；、 ？！]\$';

  @override
  String get s_a335b25f => 'Ponctuation de fin de phrase';

  @override
  String get s_885dd894 => '％';

  @override
  String get s_620b459e => '《';

  @override
  String get s_150c7508 => '》';

  @override
  String get s_67df3afd => 'A des marques de titre';

  @override
  String get s_5a09ed37 => 'Chinois';

  @override
  String get s_6b631636 => 'On dirait un mot anglais de l\'interface utilisateur';

  @override
  String get s_1dd3f274 => 'Ligne adjacente';

  @override
  String get s_f547232b => ', saut de ligne fusionné';

  @override
  String get s_fc39b00e => 'emprunt';

  @override
  String get s_eba88d83 => '^Classement';

  @override
  String get s_b6fe7962 => 'Ebook';

  @override
  String get s_c7673d27 => 'Papier';

  @override
  String get s_02a1a8ed => 'Livre audio';

  @override
  String get s_fe152225 => 'WeRead';

  @override
  String get s_2032cbd7 => 'sélection iReader';

  @override
  String get s_12ed007e => 'JD Read';

  @override
  String get s_570bb7c8 => 'BOOX';

  @override
  String get s_36bfef2d => 'Bibliothèque';

  @override
  String get s_4139f3b5 => 'Manuel';

  @override
  String get s_88cdd7e4 => 'Surligner';

  @override
  String get s_6abc44a8 => 'Pensée';

  @override
  String get s_67585b8a => 'Évaluation';

  @override
  String get s_96009a7e => 'Lecture du rapport';

  @override
  String s_4343b7b3({required Object join}) {
    return 'Génération en arrière-plan : $join';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return 'Automatically generated $ok reports';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return 'Généré $ok, échec $failed (vous pouvez réessayer manuellement)';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return 'Connecté · $model · $latencyMs ms';
  }

  @override
  String get s_d2a3748e => 'Le modèle a renvoyé du contenu vide';

  @override
  String get s_3abdc334 => 'Le modèle peut ne pas prendre en charge les paramètres actuels, ou le filtrage de contenu a été déclenché. Essayez un autre modèle.';

  @override
  String get s_cc72f973 => 'Aucune clé LLM configurée. Remplissez-en un dans Paramètres → LLM et testez d\'abord la connexion';

  @override
  String get s_9e51ce93 => 'Aucun modèle sélectionné. Accédez à Paramètres → LLM et utilisez « Récupérer les modèles » pour en choisir un';

  @override
  String get s_c6e18e89 => 'Aucun livre ne correspond pour cette période ; essayez-en un autre';

  @override
  String get s_8bb45b34 => 'Période du rapport';

  @override
  String get s_8bd59fb2 => 'Choisissez un rapport annuel ou mensuel';

  @override
  String get s_53bea04d => 'Classé par année civile/ mois ; une fois généré, vous pouvez le consulter à tout moment. Le rapport du mois en cours n\'est généré que le mois prochain.';

  @override
  String get s_1f048ed9 => 'Test';

  @override
  String get s_38fb1115 => 'Tester la connexion';

  @override
  String get s_a14e36dc => 'Génération… (le texte long prend environ une minute)';

  @override
  String get s_b36c173d => 'Générer un rapport';

  @override
  String get s_c94ade95 => 'Envoie la liste des livres de cette période (titre / auteur / catégorie / note) et des statistiques agrégées afin que le rapport puisse nommer des livres spécifiques ; le texte des notes et les faits saillants ne sont pas téléchargés.';

  @override
  String get s_5e05e92a => 'Inclus';

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
  String get s_09b589b4 => 'Note moyenne';

  @override
  String s_0825e123({required Object label}) {
    return 'Contenu du rapport · $label';
  }

  @override
  String get s_049eca89 => 'Copier tout';

  @override
  String get s_50bf9961 => 'Rapport copié dans le presse-papiers';

  @override
  String get s_772cbfcf => 'Auto-générer';

  @override
  String get s_01955ddf => 'Lorsque cette option est activée, l\'ouverture de cette page génère automatiquement tout rapport annuel manquant et le rapport mensuel du mois dernier.';

  @override
  String get s_b2a52a3d => 'Génération automatique manquante';

  @override
  String get s_b233138e => 'Annuel';

  @override
  String get s_877b864d => 'Mensuellement';

  @override
  String get s_a3dfa2a6 => 'Rapports des années précédentes';

  @override
  String get s_66772db6 => 'Exporter les données de lecture';

  @override
  String get s_6b198f0b => 'Exportation annulée';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return 'Exporté vers : $saved@ @NL @@@NL@$counts';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return 'Échec de l\'exportation : $e';
  }

  @override
  String get s_c699263b => 'Choisir un fichier de sauvegarde';

  @override
  String s_e34bdbcb({required Object e}) {
    return 'Impossible de lire ce fichier : $e';
  }

  @override
  String get s_1dedeaa2 => 'Il ne s\'agit pas d\'un fichier de sauvegarde exporté par cette application (marqueur de format manquant ou plus récent que l\'application actuelle)';

  @override
  String get s_103c5811 => 'Ce fichier ne contient aucune donnée restaurable';

  @override
  String get s_674a7957 => 'Restaurer maintenant';

  @override
  String s_94094e0d({required Object length}) {
    return 'This will overwrite this device\'s data with the backup:\n\n$length\n\nRecords with the same name are overwritten whole — restoring means \"go back to the moment of the backup\", with no field-level merging. Books added after the backup will not be deleted.';
  }

  @override
  String get s_a0451c97 => 'Annuler';

  @override
  String get s_ec7085ab => 'Restaurer';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return 'Restauration terminée$first\n@NL@@$counts';
  }

  @override
  String s_e669bac1({required Object e}) {
    return 'Échec de la restauration : $e';
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
    return '$reading_logs lisant les journaux';
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
  String get s_8719bf89 => 'Exportation et restauration de données';

  @override
  String get s_8fe27f12 => 'Ce qui est exporté';

  @override
  String get s_5d9af0a7 => 'Un instantané JSON complet : livres, notes, journaux de lecture, rapports et paramètres d\'IA. Il s\'enregistre en tant que fichier unique — utilisez-le pour restaurer sur un autre appareil.';

  @override
  String get s_582f4cb6 => 'Exporter en tant que fichier JSON';

  @override
  String get s_091ad5f4 => 'Restaurer à partir d\'une sauvegarde';

  @override
  String get s_3a36f742 => 'Choisissez un fichier .json précédemment exporté. Les enregistrements portant le même nom sont écrasés entiers, pas fusionnés champ par champ — cela signifie « revenir au moment de la sauvegarde », pas « prendre l\'union ».';

  @override
  String get s_6f9ab88c => 'Choisissez un fichier archive à restaurer';

  @override
  String get s_f24f63da => 'Enlever cet article?';

  @override
  String get s_ecbd7449 => 'Effacer';

  @override
  String get s_f98a79dc => 'Ajouter une note';

  @override
  String get s_05712ea1 => 'Modifier la note';

  @override
  String get s_e3fdcb7e => 'Une citation, une pensée ou un commentaire…';

  @override
  String get s_c8d8fada => 'Page du chapitre';

  @override
  String get s_f80f4749 => '<g id=\"1\">Facultatif</g>';

  @override
  String get s_abfe9512 => 'Sauvegarder';

  @override
  String get s_a647c2e0 => 'Cet utilisateur n\'existe pas ou a été supprimé.';

  @override
  String s_154ada37({required Object join}) {
    return 'Auteur : $join';
  }

  @override
  String s_904feb6c({required Object join}) {
    return 'Traducteur : $join';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return 'Éditeur : $publisher';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return 'Publié : $first';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return 'Catégorie : $categoryPrimary';
  }

  @override
  String get s_d9bdf56b => 'Statut';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return 'Progression $toStringAsFixed%';
  }

  @override
  String get s_8331377a => 'Evaluation';

  @override
  String get s_205eb716 => 'Résumé';

  @override
  String get s_b5e2aa8a => 'Sujet de ce manuel';

  @override
  String get s_3ec1ca86 => 'Évaluation';

  @override
  String get s_aa5a5d3e => 'Vos réflexions et commentaires';

  @override
  String s_fb47d52b({required Object length}) {
    return 'Notes · $length';
  }

  @override
  String get s_18dd30c5 => 'Pas encore de notes. Notez-en une lorsque quelque chose vous frappe — ce sera important pour votre année en cours.';

  @override
  String get s_4b7d48f2 => 'Description';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return 'Échéance : $dueAt';
  }

  @override
  String get s_ad207008 => 'editer';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => 'Le titre ne peut pas être vide';

  @override
  String get s_1f0939bc => '[,，、 ;；]';

  @override
  String get s_6c7a6cc5 => 'Modifier le livre';

  @override
  String get s_31e2aa97 => 'Ajouter un livre manuellement';

  @override
  String get s_eda73905 => 'Enregistrer les modifications';

  @override
  String get s_71b10e99 => 'Ajouter à l\'étagère';

  @override
  String get s_2dae8ba5 => 'Choisissez une couverture locale';

  @override
  String get s_5be7901d => 'Définir le couvercle';

  @override
  String get s_a59912dd => 'Supprimer la couverture';

  @override
  String get s_e2b6c0de => 'Titre*';

  @override
  String get s_22760472 => 'Auteur';

  @override
  String get s_5f70e9dd => 'Séparer les auteurs avec des virgules';

  @override
  String get s_759fb403 => 'Statut';

  @override
  String get s_da1c08d9 => 'Format';

  @override
  String get s_5ce4e16d => 'Réinitialiser&#10;';

  @override
  String get s_b0d7b0de => 'Description sommaire:';

  @override
  String get s_d0dd45ac => 'Les catégories sont normalisées en un vocabulaire contrôlé — taper « Business & Motivation » fusionne également avec « Business », de sorte que les statistiques ne seront pas divisées en deux catégories distinctes.';

  @override
  String get s_b32f0afe => 'Catégorie';

  @override
  String get s_87635298 => '<g id=\"1\">Facultatif</g>';

  @override
  String get s_5aa23087 => 'Aucune';

  @override
  String s_573b6694({required Object e}) {
    return 'Something went wrong: $e';
  }

  @override
  String get s_28690759 => 'amélioration de données d\'images';

  @override
  String get s_d5155b2d => 'Aucun titre reconnu ; essayez une autre image';

  @override
  String get s_e20dac78 => 'Lecture de l\'image avec un modèle multimodal…';

  @override
  String get s_5fea0487 => 'Le modèle multimodal n\'a pas pu lire un titre de cette image. Vérifiez que le modèle sélectionné accepte la saisie d\'image (les modèles de texte uniquement la rejettent purement et simplement), ou réglez le mode de → reconnaissance de → capture d\'écran Paramètres sur « Auto » pour revenir à l\'OCR sur l\'appareil.';

  @override
  String get s_cdda9381 => 'Multimodal n\'a rien retourné ; revenir à l\'OCR sur l\'appareil…';

  @override
  String get s_b85e4cbc => 'Téléchargement d\'image non autorisé ; retour à l\'OCR sur l\'appareil…';

  @override
  String get s_a9698571 => '\"Reconnaître le texte...\"';

  @override
  String get s_7ef6b42d => 'Aucun texte n\'a été trouvé dans cette image. Essayez un angle différent, rendez le texte plus net ou prenez simplement une capture d\'écran (les captures d\'écran sont plus nettes que les photos).';

  @override
  String get s_319b9488 => 'Aucun texte de type titre trouvé. S\'il s\'agit d\'une page intérieure, le titre n\'y figure généralement pas — essayez « Importer une capture d\'écran d\'étagère » ou photographiez la couverture à la place.';

  @override
  String get s_37588c9c => 'Aucun titre n\'a pu être lu à partir de cette image. Essayez de recadrer l\'interface utilisateur environnante et réessayez.';

  @override
  String get s_04a1b347 => 'Titre';

  @override
  String get s_a9fe3793 => 'Aucune colonne « Titre » trouvée dans le CSV';

  @override
  String get s_3db59388 => 'Progrès&#10;';

  @override
  String get s_9e160a69 => 'Éditeur';

  @override
  String s_d4b7c3c7({required Object length}) {
    return 'Livres $length analysés. Les importer ?';
  }

  @override
  String get s_649320a3 => 'Lecture de votre étagère WeRead…';

  @override
  String get s_e53774ba => 'L\'étagère est vide ou l\'API n\'a renvoyé aucune donnée';

  @override
  String s_8151aa42({required Object length}) {
    return 'Your WeRead shelf has $length books. Import them?';
  }

  @override
  String get s_9b37038a => 'Compléter les métadonnées et enregistrer…';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return 'Import complete: $added added, $duplicated updated$failed';
  }

  @override
  String get s_28ab46d9 => 'Aucun livre WeRead sur cet appareil pour le moment — synchronisez d\'abord l\'étagère';

  @override
  String get s_6d61442b => 'Synchronisation de la progression de la lecture…';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return 'Updated reading progress for $updated of $length books';
  }

  @override
  String get s_3a0cf870 => 'La connexion a été interrompue. Vérifiez votre réseau et réessayez.';

  @override
  String get s_1cbe2507 => 'Confirmer';

  @override
  String get s_1df9fbd5 => 'Importer';

  @override
  String get s_874053cb => 'Clé API WeRead';

  @override
  String get s_58652b51 => 'Scannez le code QR dans WeChat pour ouvrir weread.qq.com/r/weread-skills,\npuis copiez la clé affichée sur la page (elle commence par \"wrk-\"). La clé est stockée uniquement sur cet appareil.';

  @override
  String get s_cb2558f7 => 'Importer une capture d\'écran d\'étagère';

  @override
  String get s_24b715f3 => 'Choisissez une capture d\'écran de votre étagère et lisez le titre et la progression de chaque cellule. Les résultats peuvent être désactivés — vérifiez avant d\'enregistrer.';

  @override
  String get s_4f062f79 => 'Importer une photo d\'étagère';

  @override
  String get s_6e464c0e => 'Photographiez une couverture, une colonne vertébrale ou une page ; le titre est détecté et le reste des métadonnées est renseigné. Les résultats peuvent être désactivés — vérifiez avant d\'enregistrer.';

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
  String get s_9ac01f6b => 'Test and Fetch both save your entries first.';

  @override
  String get s_0001747c => 'Screenshot recognition';

  @override
  String get s_3f5cbdbf => 'Determines how well photo and screenshot imports are recognized.';

  @override
  String get s_9130a4ed => 'Image enhancement preprocessing';

  @override
  String get s_b79fc99c => 'Enlarges and sharpens the image first, so small titles are recognized better.';

  @override
  String get s_9695a603 => 'Use the LLM to clean up recognition results';

  @override
  String get s_267118b5 => 'Let the LLM clean up the recognized titles. Needs an LLM key and uses tokens.';

  @override
  String get s_6d7e1f9f => 'Recognition mode';

  @override
  String get s_ed144a76 => 'Auto (multimodal first, falls back to on-device)';

  @override
  String get s_c7bab837 => 'Multimodal LLM reads the image directly';

  @override
  String get s_d8f3da2a => 'On-device OCR (offline, free)';

  @override
  String get s_f22e4cd2 => 'On-device OCR works offline but may miss titles; the multimodal model reads the layout but needs a network and may invent one. \"Auto\" uses both.';

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
  String planStreak({required int n}) {
    return '$n-day check-in streak';
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

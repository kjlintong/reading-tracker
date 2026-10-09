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
  String get addBookManualDesc => 'Saisis toi-même le titre et l\'auteur : aucun compte ni fichier nécessaire.';

  @override
  String get navStats => 'Statistiques';

  @override
  String get navSettings => 'Réglages';

  @override
  String get supportDev => 'Soutenir le développeur';

  @override
  String get supportDevDesc => 'Toutes les fonctionnalités sont gratuites, sans publicité ni achat intégré. Si l\'app t\'aide dans ta lecture, tu peux m\'offrir un café — c\'est entièrement volontaire et cela ne change rien dans un cas comme dans l\'autre.';

  @override
  String get openTipPage => 'M\'inviter un café · Ko-fi';

  @override
  String get openTipDomestic => 'Soutien · Afdian (Chine)';

  @override
  String get openTipForeign => 'Soutien · Ko-fi (International)';

  @override
  String get about => 'À propos';

  @override
  String get aboutDesc => 'Informations sur le développeur et liens associés.';

  @override
  String get appIntroPage => 'À propos de cette app';

  @override
  String get developerHomepage => 'Site du développeur';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get reportDeleteConfirm => 'Supprimer ce rapport ? Action irréversible.';

  @override
  String get reportDelete => 'Supprimer';

  @override
  String appVersionLabel({required String version}) {
    return 'Version $version';
  }

  @override
  String get goodreadsImport => 'Import CSV Goodreads / bibliothèque';

  @override
  String get goodreadsImportDesc => 'Importe un CSV de bibliothèque exporté depuis Goodreads ou des services similaires (titre, auteur, note, statut sur l\'étagère).';

  @override
  String get goodreadsImportEmpty => 'Colonne « Title » introuvable dans le CSV';

  @override
  String get openLibraryImport => 'Recherche Open Library / Google Books';

  @override
  String get openLibraryImportDesc => 'Cherche dans les catalogues publics par titre ou ISBN et importe avec les métadonnées complétées (auteur, éditeur, couverture).';

  @override
  String get catalogSearchTitle => 'Rechercher dans les catalogues';

  @override
  String get catalogSearchHint => 'Saisis un titre ou un ISBN';

  @override
  String get catalogSearchAction => 'Rechercher';

  @override
  String get catalogSearchInitial => 'Cherche dans les catalogues publics de Google Books et Open Library. Les livres sélectionnés sont ajoutés avec l\'auteur, l\'éditeur, la couverture et le nombre de pages.';

  @override
  String get catalogNoResult => 'Aucun livre trouvé — essaie un autre mot-clé.';

  @override
  String catalogSearchFailed({required Object e}) {
    return 'Échec de la recherche : $e';
  }

  @override
  String get imageUploadConsentTitle => 'Envoyer la capture d\'étagère au service IA ?';

  @override
  String get imageUploadConsentBody => 'Pour que l\'IA puisse lire ta capture d\'étagère entière, l\'image est envoyée au service IA que tu as configuré dans Réglages (un tiers). Elle ne contient pas le texte de tes notes, mais bien les titres et les couvertures. Autoriser cet envoi ?';

  @override
  String get allow => 'Autoriser';

  @override
  String get cancel => 'Annuler';

  @override
  String get s_178329ba => 'Clé API WeRead non configurée';

  @override
  String get s_dd204792 => 's';

  @override
  String get s_ad86a5ca => 'Clé API du LLM non configurée';

  @override
  String get s_8a853cbe => 'Renseigne-la dans Réglages → LLM';

  @override
  String get s_7d704c88 => 'Aucun modèle sélectionné';

  @override
  String get s_4508cedd => 'Appuie sur « Obtenir les modèles » pour en choisir un dans la liste disponible sur ton compte';

  @override
  String get s_1b5140db => 'Renvoie uniquement du JSON valide : pas de texte explicatif, pas de bloc de code markdown.';

  @override
  String s_c94c96fc({required Object apiError}) {
    return 'Le service du modèle a renvoyé une erreur : $apiError';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return 'Réponse brute : $head\nVérifie l\'adresse et le nom du modèle dans Réglages → LLM avec « Obtenir les modèles ». Un solde insuffisant ou un modèle non activé mène aussi ici.';
  }

  @override
  String get s_231cf54a => 'Impossible d\'analyser la réponse du modèle';

  @override
  String s_90747d4c({required Object head}) {
    return 'Réponse brute : $head\nLa passerelle a renvoyé une structure non standard. Essaie un autre modèle ou un autre protocole ; nous envoyer ce texte brut nous aide aussi à le prendre en charge.';
  }

  @override
  String get s_9d9714af => 'Le message est vide et ne peut pas être envoyé';

  @override
  String get s_f44ff25c => 'Le modèle a refusé cette requête';

  @override
  String get s_cad5bf6e => 'Le contenu a été signalé comme inapproprié. Reformule-le ou essaie un autre modèle.';

  @override
  String get s_0f7b54a1 => 'Clé API non configurée';

  @override
  String get s_345e9547 => 'Saisis la clé avant d\'obtenir les modèles';

  @override
  String get s_3a5d4cca => 'Le service a renvoyé une liste de modèles vide';

  @override
  String s_cea80527({required Object apiError}) {
    return 'Échec de la récupération des modèles : $apiError';
  }

  @override
  String get s_4674d953 => 'Tu peux saisir le nom du modèle à la main';

  @override
  String s_749fc40e({required Object raw}) {
    return 'Réponse brute : $raw';
  }

  @override
  String get s_8add575d => 'Ce service ne fournit pas de point d\'accès pour lister les modèles (404)';

  @override
  String get s_53fb436d => 'Tape simplement le nom du modèle, par exemple deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => 'Aucun nom de modèle saisi';

  @override
  String get s_1da90e20 => 'Appuie d\'abord sur « Obtenir les modèles », ou saisis-en un';

  @override
  String get s_2abb6b8a => 'Réponds par deux caractères : OK';

  @override
  String get s_ad736a74 => 'Tu es un assistant de catalogage bibliographique. Renvoie uniquement du JSON, sans explication.';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return 'Titre connu « $title »$author.\nComplète ce qui suit :\n- categoryPrimary : doit être l\'un de : $vocab\n- description : un résumé neutre de 80 à 150 caractères sur le contenu du livre, factuel et sans appréciation\n- tags : de 3 à 5 mots-clés\n- authors : un tableau si l\'auteur peut être déterminé, sinon un tableau vide\nFormat de sortie : {\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}';
  }

  @override
  String get s_cbe8aa6b => 'Tu es un analyste de profil de lecture. Renvoie uniquement du JSON, sans explication.';

  @override
  String s_3864d3b4({required Object summary}) {
    return 'Voici mes données de lecture (JSON) :\n$summary\n\nDonne-moi 10 étiquettes de personnalité, de 2 à 6 mots chacune, comme les surnoms qu\'un club de lecture donne aux gens.\nExigences :\n1. Chaque étiquette doit être justifiée par les données ci-dessus — n\'invente rien\n2. Références de style : L\'apprentissage est mon bonheur / En accord avec la nature / La beauté avant tout / Erudit à travers les âges / Le sage solitaire\n3. N\'emploie pas de mots creux comme « lecteur », « passionné » ou « amateur »\n4. Pas d\'explication, pas de bloc de code markdown\nFormat de sortie : {\"tags\":[\"étiquette1\",\"étiquette2\"]}';
  }

  @override
  String get s_99acf9a4 => 'Tu es un conseiller personnel de lecture. Analyse les données objectivement, évite les compliments vagues et signale les problèmes structurels auxquels on ne fait pas attention.';

  @override
  String s_46e5ebef({required Object host}) {
    return 'Délai de connexion dépassé : impossible de joindre $host en 20 secondes';
  }

  @override
  String get s_3c836870 => 'Vérifie le réseau ou l\'URL de base ; certains services étrangers exigent un proxy depuis la Chine continentale';

  @override
  String get s_84264711 => 'Délai d\'envoi dépassé';

  @override
  String get s_225ed2e1 => 'La connexion amont est instable ; réessaie plus tard';

  @override
  String get s_b265cf86 => 'Délai de réponse dépassé : le modèle n\'a pas répondu en 180 secondes';

  @override
  String get s_cc12eea3 => 'Essaie un modèle plus rapide, ou raccourcis la période du rapport et réessaie';

  @override
  String get s_d711b259 => 'Échec de la validation du certificat HTTPS';

  @override
  String get s_4722b0f8 => 'Pour un service auto-hébergé ou d\'intranet, passe à un certificat de confiance';

  @override
  String get s_07a2b144 => 'Requête annulée';

  @override
  String s_8ae0b0e4({required Object host}) {
    return 'Réseau injoignable : impossible de se connecter à $host';
  }

  @override
  String get s_0a9425b8 => '① Vérifie le réseau du téléphone ; ② assure-toi que l\'URL de base est complète (y compris /v1) ; ③ vérifie si le service exige un proxy ; ④ un service local (Ollama) n\'est pas accessible depuis le téléphone via le localhost de l\'ordinateur';

  @override
  String get s_554d5235 => 'La connexion a été interrompue';

  @override
  String get s_020fe21a => 'Cela arrive quand une permission réseau est bloquée, qu\'un proxy ou un pare-feu coupe la connexion, ou que le HTTP en clair n\'est pas pris en charge. Réessaie plus tard ou change de réseau.';

  @override
  String get s_dfde23b1 => 'La requête réseau a échoué';

  @override
  String get s_2ae4f5fe => 'Vérifie l\'URL de base, la configuration du proxy et le réseau';

  @override
  String s_d6ac5952({required Object detail}) {
    return 'Requête rejetée (400)$detail';
  }

  @override
  String get s_cb980461 => 'Le plus souvent, le nom du modèle est incorrect, ou ce modèle ne prend pas en charge les paramètres actuels';

  @override
  String s_d9775d22({required Object detail}) {
    return 'Échec de l\'authentification (401)$detail';
  }

  @override
  String get s_c4198142 => 'La clé API est invalide ou a expiré — copie-en une neuve';

  @override
  String get s_e06ab1cc => 'Solde du compte insuffisant (402)';

  @override
  String s_05b3ec8b({required Object detail}) {
    return 'Pas d\'autorisation (403)$detail';
  }

  @override
  String get s_f00f6ff2 => 'La clé n\'a pas l\'autorisation d\'appeler ce modèle, ou le compte n\'est pas vérifié ou activé';

  @override
  String s_016f7576({required Object detail}) {
    return 'Point d\'accès ou modèle introuvable (404)$detail';
  }

  @override
  String get s_a8aa2c59 => 'Vérifie que l\'URL de base va bien jusqu\'à /v1 ; utilise « Obtenir les modèles » pour connaître le nom du modèle';

  @override
  String s_9688a257({required Object detail}) {
    return 'Paramètres invalides (422)$detail';
  }

  @override
  String get s_1b3daaa3 => 'Limite de requêtes atteinte (429)';

  @override
  String get s_2a564df1 => 'Réessaie sous peu, ou passe à un forfait supérieur';

  @override
  String s_6627221e({required int? code}) {
    return 'Erreur du serveur ($code)';
  }

  @override
  String get s_2fe391dd => 'Un problème côté distant ; réessaie plus tard';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return 'La requête a échoué$code$detail';
  }

  @override
  String get s_0cf0a499 => '(corps de réponse vide)';

  @override
  String get s_9ed7e745 => 'La requête réseau a échoué. Vérifie le réseau du téléphone et l\'URL de base dans Réglages → LLM.';

  @override
  String get s_2ad3b6ba => 'Compatible OpenAI';

  @override
  String get s_e2213e87 => 'Saisis l\'URL de base jusqu\'à /v1, par exemple https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'L\'URL de base est généralement https://api.anthropic.com (sans /v1)';

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
  String get s_0babfa89 => 'Toute chaîne non vide';

  @override
  String get s_e74f752c => 'Les jours de lecture sont les jours que tu as enregistrés manuellement comme lus';

  @override
  String s_9ea3cbae({required Object year}) {
    return 'Le temps et les jours de lecture proviennent des statistiques annuelles de WeRead pour $year (base année complète)';
  }

  @override
  String get s_f676228c => 'WeRead ne fournit que des chiffres annuels : les jours de lecture de cette période ne peuvent pas être donnés précisément ; le temps est agrégé au mois';

  @override
  String get s_06225788 => 'Non noté';

  @override
  String s_89cfaca8({required Object i}) {
    return '$i étoiles';
  }

  @override
  String get s_e7a2db51 => 'Depuis toujours';

  @override
  String s_a87cfcc9({required Object y}) {
    return '$y';
  }

  @override
  String s_62654321({required Object n}) {
    return '$n derniers mois';
  }

  @override
  String get s_41f3af95 => 'Le temps et les jours de lecture sont agrégés au mois et à l\'année';

  @override
  String get s_e8a43314 => 'Commence le livre suivant et cette liste tiendra son premier chiffre.';

  @override
  String get s_af03278c => 'L\'étagère est encore vide — toute histoire de lecture commence ici.';

  @override
  String s_f53eead8({required Object streak}) {
    return '$streak jours de lecture d\'affilée — le rythme s\'est installé.';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return 'Une série de $streak jours — ne la casse pas aujourd\'hui.';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '$streak jours d\'affilée — une habitude qui vaut plus que n\'importe quelle liste de lecture.';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '$finished livres terminés — échange la vitesse contre le rythme et tu iras plus loin.';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '$finished livres terminés. Regarde de temps en arrière lesquels t\'ont vraiment marqué.';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '$finished livres terminés sur cette période — chacun compte.';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '$finished livres terminés. Pour le suivant, choisis-en un que tu as déjà commencé.';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '$minutes minutes de lecture sur cette période — si tu fais d\'une demi-heure une habitude quotidienne, cela fait 180 heures par an.';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return 'Tu as déjà $minutes minutes enregistrées. Tu en ajoutes un peu aujourd\'hui ?';
  }

  @override
  String get s_152a88d7 => 'Ton étagère est prête — commence tes dix minutes d\'aujourd\'hui par une nouvelle légère.';

  @override
  String get s_795806c0 => 'Choisis un livre que tu as déjà commencé : dix minutes, c\'est une victoire.';

  @override
  String get s_aa51bf46 => 'Tu n\'as pas besoin de beaucoup lire d\'un coup — ouvrir un livre aujourd\'hui suffit.';

  @override
  String get s_363c6a0c => 'Sans catégorie';

  @override
  String get s_420a7ac1 => 'Apprendre est mon bonheur';

  @override
  String get s_bcd278a6 => 'Développement personnel';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '$cat livres de développement personnel · $pct';
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
  String get s_111ec0f6 => 'Les leçons de l\'histoire';

  @override
  String get s_07f288e9 => 'Histoire';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '$cat livres d\'histoire · $pct';
  }

  @override
  String get s_5e336507 => 'Se tourner vers l\'intérieur';

  @override
  String get s_4307c7a8 => 'Psychologie';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '$cat livres de psychologie · $pct';
  }

  @override
  String get s_d5e26f37 => 'Élite de la tech';

  @override
  String get s_8612fa7f => 'Informatique';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '$cat livres d\'informatique · $pct';
  }

  @override
  String get s_00dcb308 => 'La beauté avant tout';

  @override
  String get s_b31e932c => 'Art';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '$cat livres d\'art · $pct';
  }

  @override
  String get s_2ddd554c => 'Rationaliste et pragmatique';

  @override
  String get s_56734d39 => 'Économie';

  @override
  String get s_5974bf24 => 'Management';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '$cat livres d\'économie et de management · $toStringAsFixed%';
  }

  @override
  String get s_d574ffeb => 'Sagace dans les choses du monde';

  @override
  String get s_086ac5bf => 'Sciences sociales';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '$cat livres de sciences sociales · $pct';
  }

  @override
  String get s_d81bab36 => 'Curiosité insatiable';

  @override
  String get s_41fa5c70 => 'Vulgarisation scientifique';

  @override
  String get s_fcc3102d => 'Technologie';

  @override
  String s_76c118d0({required Object n}) {
    return '$n livres de vulgarisation et de technologie';
  }

  @override
  String get s_2b65326c => 'Apprend des autres';

  @override
  String get s_f85fa7d4 => 'Biographie';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '$cat biographies · $pct';
  }

  @override
  String get s_9e49409c => 'Vivre en bonne santé';

  @override
  String get s_c21b69a8 => 'Médecine';

  @override
  String s_1dd31356({required Object cat}) {
    return '$cat livres de médecine et de santé';
  }

  @override
  String get s_77e32253 => 'Pragmatique et parvenu';

  @override
  String get s_0323f1bb => 'Droit';

  @override
  String s_82364cc8({required Object cat}) {
    return '$cat livres de droit';
  }

  @override
  String get s_ea038731 => 'S\'amuse tout seul';

  @override
  String get s_dbb1c112 => 'BD';

  @override
  String get s_6398a679 => 'Livres pour enfants';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '$cat BD et livres pour enfants';
  }

  @override
  String get s_94f8d7c2 => 'En accord avec la nature';

  @override
  String get s_30412ad5 => 'Religion';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '$cat livres de religion';
  }

  @override
  String get s_52c36d65 => 'Sait vivre';

  @override
  String get s_06e23c48 => 'Autres';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '$cat livres de mode de vie · $pct';
  }

  @override
  String get s_dc2e94c1 => 'Enseignant dans l\'âme';

  @override
  String get s_235af603 => 'Éducation';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '$cat livres d\'éducation · $pct';
  }

  @override
  String get s_7ea6e8a9 => 'Erudit à travers les âges';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return 'Ta bibliothèque couvre $categoryKinds catégories — un peu de tout';
  }

  @override
  String get s_41a09d04 => 'Concentré à fond';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '$total livres se répartissent entre $categoryKinds catégories seulement';
  }

  @override
  String get s_431dc47d => 'Va au bout des choses';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return 'Taux de livres terminés $toStringAsFixed% ($finished/$total)';
  }

  @override
  String get s_6b51050c => 'Accumule les livres';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '$wish à lire, mais seulement $finished terminés';
  }

  @override
  String get s_e60e931c => 'Coupe vite les pertes';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '$abandoned abandonnés · $toStringAsFixed% — tu lâches ce qui ne te prend pas';
  }

  @override
  String get s_4be15f8c => 'Lanceur de projets';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '$stalled livres en cours mais sous les 15%';
  }

  @override
  String get s_10b9bddd => 'Bienveillance';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Tes $ratedCount livres notés atteignent $toStringAsFixed de moyenne';
  }

  @override
  String get s_e67694db => 'Critique sans langue de bois';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return 'Tes $ratedCount livres notés plafonnent à $toStringAsFixed de moyenne';
  }

  @override
  String get s_fe4567e4 => 'Opinions tranchées';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return 'Écart-type des notes $toStringAsFixed — le bien et le mal sont très éloignés';
  }

  @override
  String get s_fbad19d5 => 'Relit et se renouvelle';

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
  String get s_e9eddf51 => 'Numérique assumé';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '$weread sur WeRead · $toStringAsFixed%';
  }

  @override
  String get s_ce6517f9 => 'Papier et numérique';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return 'plus $libraryCount empruntés et $paper en papier';
  }

  @override
  String get s_8cac22b7 => 'Lit avec ses oreilles';

  @override
  String s_72b826e9({required Object audio}) {
    return '$audio livres audio';
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
    return 'Mois de $month';
  }

  @override
  String s_5583162a({required Object e}) {
    return 'Échec du prétraitement de l\'image ; utilisation de l\'original : $e';
  }

  @override
  String s_628c2132({required Object e}) {
    return 'Échec de la conversion en JPEG : $e';
  }

  @override
  String get s_ebf4bdfb => 'Analyse de la structure de la mise en page…';

  @override
  String get s_ba1038b1 => 'Nettoyage des résultats de reconnaissance avec le LLM…';

  @override
  String get s_6292a274 => 'Vérification des titres…';

  @override
  String get s_427e1f0d => 'C';

  @override
  String get s_af041a1b => 'Titre complété';

  @override
  String s_988dd5cb({required Object reason}) {
    return '$reason, titre complété';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '« $title » : $e';
  }

  @override
  String get s_d2bbf7ce => 'Reconnaissance multimodale';

  @override
  String get s_381ca835 => 'Voici une capture d\'une étagère ou d\'une liste de lecture';

  @override
  String get s_fce28e56 => 'Voici une capture de la couverture ou de la page de détail d\'un seul livre';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene.\n\nRenvoie uniquement un tableau JSON, chaque élément de la forme :\n{\"title\":\"titre\",\"author\":\"auteur\",\"progress\":un nombre de 0 à 100 ou null,\"status\":\"un parmi unread/reading/finished ou null\",\"confidence\":un nombre de 0 à 1}\n\nExigences :\n1. Ne renvoie que les livres **réellement visibles** sur l\'image ; n\'ajoute pas de livres que tu supposes devoir y être ;\n2. Ignore le texte de l\'interface (filtres, recherche, tri, Tous, Étagère, N livres, etc.) ;\n3. Recopie les titres tels qu\'ils apparaissent, y compris tronqués par des points de suspension — ne les complète pas toi-même ;\n4. Laisse l\'auteur vide si tu ne peux pas le lire ; ne devine pas ;\n5. Ne renseigne l\'auteur que s\'il est réellement écrit sur l\'image.\n$n';
  }

  @override
  String get s_951042c3 => 'Tu extrais des informations de captures d\'étagères. Renvoie uniquement un tableau JSON, sans texte explicatif.';

  @override
  String get s_29dbdb32 => 'Nettoyage par le LLM';

  @override
  String get s_9cd6567e => 'Une photo de couverture ou de dos d\'un livre';

  @override
  String get s_a6db1cf4 => 'Une capture d\'écran de l\'étagère d\'une app de lecture numérique';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return 'Voici les lignes de texte extraites par l\'OCR de $scene, dans l\'ordre haut-bas de la page.\n\nExtrais les **vrais titres de livres**, en ignorant tout le texte d\'interface (barre de recherche, filtres, catégories, barre d\'état, numéros de page, titres de chapitre, boutons, statistiques).\n\nRègles :\n1. Ne renvoie que les livres qui apparaissent réellement sur l\'image. N\'ajoute pas de livres que tu supposes devoir y être.\n2. Si l\'interface tronque un titre avec des points de suspension (par exemple « Profon… »), complète-le en titre entier.\n3. progress prend un pourcentage entier de 0 à 100 ; laisse une chaîne vide si tu ne peux pas le lire. Attention : « 0.8% » vaut 0.8, pas 80.\n4. status doit valoir « unread / reading / finished / dropped » ; laisse une chaîne vide si tu ne peux pas le lire.\n5. Ne renseigne l\'auteur que s\'il apparaît clairement sur l\'image ; sinon laisse le champ vide. Ne devine pas.\n6. Passe les lignes dont tu n\'es pas sûr. Mieux vaut manquer un livre qu\'en ajouter un faux.\n\nRenvoie uniquement un tableau JSON, avec des éléments de la forme :\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nLignes de texte de l\'OCR :\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => 's';

  @override
  String get s_95222176 => 'Non lu';

  @override
  String get s_5a833930 => 'À lire';

  @override
  String get s_b9bf9b53 => 'En cours';

  @override
  String get s_be5492a5 => 'En cours de lecture';

  @override
  String get s_44c14529 => 'Lecture terminée';

  @override
  String get s_0872b5b7 => 'Terminé';

  @override
  String get s_300a32bd => 'Terminé';

  @override
  String get s_0f4d9c68 => 'Abandonné (fusionné avec « Mis de côté »)';

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
  String get s_0686f279 => 'Plus gros texte de la couverture';

  @override
  String get s_5514105a => 'Texte secondaire de la couverture';

  @override
  String get s_174faffb => 'Contient du chinois';

  @override
  String get s_b13a1237 => 'A une progression ou un statut';

  @override
  String get s_24745e9d => 'A un auteur';

  @override
  String get s_0cedc3f4 => 'Longueur raisonnable';

  @override
  String get s_5bdfa6ae => 'Trop court';

  @override
  String get s_58171266 => 'Trop long';

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
  String get s_67df3afd => 'Comporte des guillemets de titre';

  @override
  String get s_5a09ed37 => 'Chinois';

  @override
  String get s_6b631636 => 'Ressemble à un mot d\'interface en anglais';

  @override
  String get s_1dd3f274 => 'Ligne voisine';

  @override
  String get s_f547232b => ', ligne fusionnée';

  @override
  String get s_fc39b00e => 'Emprunté';

  @override
  String get s_eba88d83 => 'Mis de côté';

  @override
  String get s_b6fe7962 => 'Livre numérique';

  @override
  String get s_c7673d27 => 'Papier';

  @override
  String get s_02a1a8ed => 'Livre audio';

  @override
  String get s_fe152225 => 'WeRead';

  @override
  String get s_2032cbd7 => 'iReader Select';

  @override
  String get s_12ed007e => 'JD Read';

  @override
  String get s_570bb7c8 => 'BOOX';

  @override
  String get s_36bfef2d => 'Bibliothèque';

  @override
  String get s_4139f3b5 => 'Manuel';

  @override
  String get s_88cdd7e4 => 'Surlignage';

  @override
  String get s_6abc44a8 => 'Idée';

  @override
  String get s_67585b8a => 'Critique';

  @override
  String get s_96009a7e => 'Rapport de lecture';

  @override
  String s_4343b7b3({required Object join}) {
    return 'Génération en arrière-plan : $join';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return '$ok rapports générés automatiquement';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return '$ok générés, $failed en échec (tu peux réessayer à la main)';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return 'Connecté · $model · $latencyMs ms';
  }

  @override
  String get s_d2a3748e => 'Le modèle a renvoyé un contenu vide';

  @override
  String get s_3abdc334 => 'Le modèle ne prend peut-être pas en charge les paramètres actuels, ou un filtre de contenu s\'est déclenché. Essaie un autre modèle.';

  @override
  String get s_cc72f973 => 'Aucune clé LLM configurée. Renseigne-la dans Réglages → LLM et teste d\'abord la connexion';

  @override
  String get s_9e51ce93 => 'Aucun modèle sélectionné. Va dans Réglages → LLM et utilise « Obtenir les modèles » pour en choisir un';

  @override
  String get s_c6e18e89 => 'Aucun livre ne correspond sur cette période ; essaie-en une autre';

  @override
  String get s_8bb45b34 => 'Période du rapport';

  @override
  String get s_8bd59fb2 => 'Choisis un rapport annuel ou mensuel';

  @override
  String get s_53bea04d => 'Classés par année ou mois civil ; une fois généré, tu peux le consulter à tout moment. Le rapport du mois en cours n\'est généré que le mois suivant.';

  @override
  String get s_1f048ed9 => 'Test en cours…';

  @override
  String get s_38fb1115 => 'Tester la connexion';

  @override
  String get s_a14e36dc => 'Génération… (les textes longs prennent environ une minute)';

  @override
  String get s_b36c173d => 'Générer le rapport';

  @override
  String get s_c94ade95 => 'Envoie la liste des livres de la période (titre / auteur / catégorie / note) et des statistiques agrégées, pour que le rapport puisse nommer des livres précis ; le texte des notes et les surlignages ne sont pas envoyés.';

  @override
  String get s_5e05e92a => 'Inclus';

  @override
  String s_be9a1551({required Object total}) {
    return '$total livres';
  }

  @override
  String s_ce115766({required Object finished}) {
    return '$finished livres';
  }

  @override
  String s_8b46a11f({required Object reading}) {
    return '$reading livres';
  }

  @override
  String s_81e94993({required Object wish}) {
    return '$wish livres';
  }

  @override
  String get s_09b589b4 => 'Note moyenne';

  @override
  String s_0825e123({required Object label}) {
    return 'Contenu du rapport · $label';
  }

  @override
  String get s_049eca89 => 'Tout copier';

  @override
  String get s_50bf9961 => 'Rapport copié dans le presse-papiers';

  @override
  String get s_772cbfcf => 'Génération automatique';

  @override
  String get s_01955ddf => 'Quand c\'est activé, ouvrir cette page génère automatiquement les rapports annuels manquants et le rapport mensuel du mois dernier.';

  @override
  String get s_b2a52a3d => 'Générer les manquants';

  @override
  String get s_b233138e => 'Annuel';

  @override
  String get s_877b864d => 'Mensuel';

  @override
  String get s_a3dfa2a6 => 'Rapports précédents';

  @override
  String get s_66772db6 => 'Exporter les données de lecture';

  @override
  String get s_6b198f0b => 'Export annulé';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return 'Exporté vers : $saved\n\n$counts';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return 'Échec de l\'export : $e';
  }

  @override
  String get s_c699263b => 'Choisis un fichier de sauvegarde';

  @override
  String s_e34bdbcb({required Object e}) {
    return 'Impossible de lire ce fichier : $e';
  }

  @override
  String get s_1dedeaa2 => 'Ce n\'est pas une sauvegarde exportée par cette app (marqueur de format manquant, ou version plus récente que l\'app actuelle)';

  @override
  String get s_103c5811 => 'Ce fichier ne contient aucune donnée restaurable';

  @override
  String get s_674a7957 => 'Restaurer maintenant ?';

  @override
  String s_94094e0d({required Object length}) {
    return 'Ceci va écraser les données de cet appareil avec la sauvegarde :\n\n$length\n\nLes enregistrements de même nom sont entièrement écrasés — restaurer signifie « revenir au moment de la sauvegarde », sans fusion champ par champ. Les livres ajoutés après la sauvegarde ne seront pas supprimés.';
  }

  @override
  String get s_a0451c97 => 'Annuler';

  @override
  String get s_ec7085ab => 'Restaurer';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return 'Restauration terminée$first\n\n$counts';
  }

  @override
  String s_e669bac1({required Object e}) {
    return 'Échec de la restauration : $e';
  }

  @override
  String s_7c0be1cd({required int? books}) {
    return '$books livres';
  }

  @override
  String s_dd2321ce({required int? notes}) {
    return '$notes notes';
  }

  @override
  String s_d48aa751({required int? reading_logs}) {
    return '$reading_logs entrées de lecture';
  }

  @override
  String s_d044717e({required int? llm_reports}) {
    return '$llm_reports rapports IA';
  }

  @override
  String s_f4d248a7({required int? settings}) {
    return '$settings réglages';
  }

  @override
  String get s_8719bf89 => 'Export et restauration des données';

  @override
  String get s_8fe27f12 => 'Ce qui est exporté';

  @override
  String get s_5d9af0a7 => 'Un instantané JSON complet : livres, notes, entrées de lecture, rapports IA et réglages. Tout est dans un seul fichier — sers-t\'en pour restaurer sur un autre appareil.';

  @override
  String get s_582f4cb6 => 'Exporter en fichier JSON';

  @override
  String get s_091ad5f4 => 'Restaurer depuis une sauvegarde';

  @override
  String get s_3a36f742 => 'Choisis un fichier .json exporté précédemment. Les enregistrements de même nom sont entièrement écrasés, pas fusionnés champ par champ : cela signifie « revenir au moment de la sauvegarde », pas « faire l\'union ».';

  @override
  String get s_6f9ab88c => 'Choisis une sauvegarde et restaure-la';

  @override
  String get s_f24f63da => 'Supprimer cette note ?';

  @override
  String get s_ecbd7449 => 'Supprimer';

  @override
  String get s_f98a79dc => 'Ajouter une note';

  @override
  String get s_05712ea1 => 'Modifier la note';

  @override
  String get s_e3fdcb7e => 'Une citation, une idée, une critique…';

  @override
  String get s_c8d8fada => 'Chapitre / page';

  @override
  String get s_f80f4749 => 'Facultatif';

  @override
  String get s_abfe9512 => 'Enregistrer';

  @override
  String get s_a647c2e0 => 'Ce livre n\'existe pas ou a été supprimé';

  @override
  String s_154ada37({required Object join}) {
    return 'Auteur : $join';
  }

  @override
  String s_904feb6c({required Object join}) {
    return 'Traducteur : $join';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return 'Éditeur : $publisher';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return 'Publié : $first';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return 'Catégorie : $categoryPrimary';
  }

  @override
  String get s_d9bdf56b => 'Statut de lecture';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return 'Progression $toStringAsFixed%';
  }

  @override
  String get s_8331377a => 'Note';

  @override
  String get s_205eb716 => 'Résumé';

  @override
  String get s_b5e2aa8a => 'Note ce dont ce livre parle';

  @override
  String get s_3ec1ca86 => 'Critique';

  @override
  String get s_aa5a5d3e => 'Tes avis et réflexions';

  @override
  String s_fb47d52b({required Object length}) {
    return 'Notes · $length';
  }

  @override
  String get s_18dd30c5 => 'Pas encore de notes. Note quelque chose quand une idée te frappe — ce sera de la matière pour ta revue annuelle.';

  @override
  String get s_4b7d48f2 => 'Description';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return 'À rendre le : $dueAt';
  }

  @override
  String get s_ad207008 => 'Modifier';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => 'Le titre ne peut pas être vide';

  @override
  String get s_1f0939bc => '[,，、 ;；]';

  @override
  String get s_6c7a6cc5 => 'Modifier le livre';

  @override
  String get s_31e2aa97 => 'Ajouter un livre à la main';

  @override
  String get s_eda73905 => 'Enregistrer les modifications';

  @override
  String get s_71b10e99 => 'Ajouter à l\'étagère';

  @override
  String get s_2dae8ba5 => 'Choisis une couverture locale';

  @override
  String get s_5be7901d => 'Définir la couverture';

  @override
  String get s_a59912dd => 'Retirer la couverture';

  @override
  String get s_e2b6c0de => 'Titre *';

  @override
  String get s_22760472 => 'Auteur';

  @override
  String get s_5f70e9dd => 'Sépare plusieurs auteurs par des virgules';

  @override
  String get s_759fb403 => 'Statut';

  @override
  String get s_da1c08d9 => 'Format';

  @override
  String get s_5ce4e16d => 'Effacer';

  @override
  String get s_b0d7b0de => 'Description / résumé';

  @override
  String get s_d0dd45ac => 'Les catégories sont normalisées dans un vocabulaire contrôlé : écrire « Business et motivation » fusionne aussi dans « Management », les statistiques ne se scindent donc pas en deux.';

  @override
  String get s_b32f0afe => 'Catégorie';

  @override
  String get s_87635298 => 'Facultatif';

  @override
  String get s_5aa23087 => 'Aucun';

  @override
  String s_573b6694({required Object e}) {
    return 'Une erreur est survenue : $e';
  }

  @override
  String get s_28690759 => 'Amélioration de l\'image…';

  @override
  String get s_d5155b2d => 'Aucun titre reconnu ; essaie une autre image';

  @override
  String get s_e20dac78 => 'Lecture de l\'image par un modèle multimodal…';

  @override
  String get s_5fea0487 => 'Le modèle multimodal n\'a pas pu lire de titre sur cette image. Vérifie que le modèle sélectionné accepte les images (les modèles uniquement texte les refusent d\'emblée), ou remets Réglages → Reconnaissance de captures → Mode de reconnaissance sur « Auto » pour retomber sur l\'OCR de l\'appareil.';

  @override
  String get s_cdda9381 => 'Le multimodal n\'a rien renvoyé ; repli sur l\'OCR de l\'appareil…';

  @override
  String get s_b85e4cbc => 'Envoi d\'image non autorisé ; repli sur l\'OCR de l\'appareil…';

  @override
  String get s_a9698571 => 'Reconnaissance du texte…';

  @override
  String get s_7ef6b42d => 'Aucun texte trouvé sur cette image. Essaie sous un autre angle, avec un texte plus net, ou fais directement une capture d\'écran (les captures sont plus nettes que les photos).';

  @override
  String get s_319b9488 => 'Aucun texte ressemblant à un titre trouvé. S\'il s\'agit d\'une page intérieure, le titre n\'y figure généralement pas : essaie « Importer une capture d\'étagère » ou photographie la couverture.';

  @override
  String get s_37588c9c => 'Aucun titre n\'a pu être lu sur cette image. Essaie de recadrer pour enlever l\'interface superflue et recommence.';

  @override
  String get s_04a1b347 => 'Titre';

  @override
  String get s_a9fe3793 => 'Colonne « Title » introuvable dans le CSV';

  @override
  String get s_3db59388 => 'Progression';

  @override
  String get s_9e160a69 => 'Éditeur';

  @override
  String s_d4b7c3c7({required Object length}) {
    return '$length livres analysés. Les importer ?';
  }

  @override
  String get s_649320a3 => 'Lecture de ton étagère WeRead…';

  @override
  String get s_e53774ba => 'L\'étagère est vide, ou l\'API n\'a renvoyé aucune donnée';

  @override
  String s_8151aa42({required Object length}) {
    return 'Ton étagère WeRead contient $length livres. Les importer ?';
  }

  @override
  String get s_9b37038a => 'Complétion des métadonnées et enregistrement…';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return 'Import terminé : $added ajoutés, $duplicated mis à jour$failed';
  }

  @override
  String get s_28ab46d9 => 'Aucun livre WeRead sur cet appareil pour l\'instant — synchronise d\'abord l\'étagère';

  @override
  String get s_6d61442b => 'Synchronisation de la progression de lecture…';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return 'Progression mise à jour pour $updated livres sur $length';
  }

  @override
  String get s_3a0cf870 => 'La connexion a été interrompue. Vérifie ton réseau et réessaie.';

  @override
  String get s_1cbe2507 => 'Confirmer';

  @override
  String get s_1df9fbd5 => 'Importer';

  @override
  String get s_874053cb => 'Clé API WeRead';

  @override
  String get s_58652b51 => 'Scanne avec WeChat le QR code pour ouvrir weread.qq.com/r/weread-skills,\npuis copie la clé affichée sur la page (elle commence par « wrk- »). La clé reste uniquement sur cet appareil.';

  @override
  String get s_cb2558f7 => 'Importer l\'étagère depuis une capture';

  @override
  String get s_24b715f3 => 'Choisis une capture de ton étagère et lis le titre et la progression de chaque case. Le résultat peut être imprécis : vérifie avant d\'enregistrer.';

  @override
  String get s_4f062f79 => 'Importer l\'étagère avec une photo';

  @override
  String get s_6e464c0e => 'Photographie une couverture, un dos ou une page : le titre est détecté et le reste des métadonnées complété. Le résultat peut être imprécis : vérifie avant d\'enregistrer.';

  @override
  String get s_a5452d46 => 'Synchroniser l\'étagère depuis les canaux';

  @override
  String get s_d40e2a14 => 'Lit ton étagère et ton statut de lecture via l\'API officielle des canaux configurés — aucune capture nécessaire. WeRead est pris en charge aujourd\'hui ; d\'autres canaux arrivent.';

  @override
  String get s_af94a367 => 'Synchroniser la progression de lecture';

  @override
  String get s_59d2efab => 'Récupère le pourcentage lu et le temps cumulé de chaque livre. Certains canaux n\'exposent pas la progression dans leur étagère : il faut une requête par livre.';

  @override
  String get s_fa52186c => 'Import CSV / Notion';

  @override
  String get s_2c78f2b8 => 'Migration en un clic depuis un CSV exporté de Notion : les noms de colonnes sont détectés automatiquement et les champs personnalisés sont conservés.';

  @override
  String get s_238b14fc => 'Traitement…';

  @override
  String s_ed4b0551({required Object length}) {
    return '$length livres n\'ont pas pu être importés';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '… et $length de plus';
  }

  @override
  String get s_18307d56 => 'Ajouter à la main';

  @override
  String s_cc0eef03({required Object length}) {
    return '$length livres reconnus';
  }

  @override
  String get s_0f466d7a => 'Tout sélectionner';

  @override
  String get s_42b2fafa => 'Tout désélectionner';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return '$totalLines lignes de texte lues, $keptLines livres conservés$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => 'Les éléments marqués « complété » ou « inféré » ne sont pas littéraux de l\'image : vérifie-les avant d\'importer. Tu peux toucher un titre ou un auteur pour le modifier.';

  @override
  String get s_0f40975c => 'Ajouter un livre à la main (non détecté par l\'OCR)';

  @override
  String s_fdc0acd1({required Object length}) {
    return 'Importer les $length sélectionnés';
  }

  @override
  String get s_4443bd2c => 'L\'image d\'origine était tronquée';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return 'Progression $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return 'Confiance $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return 'Image d\'origine : $rawText';
  }

  @override
  String get s_7bbe0f10 => 'Auteur (facultatif)';

  @override
  String get s_bd13cf0b => 'Supprimer celui-ci';

  @override
  String get s_c048f107 => 'Intervalle des statistiques';

  @override
  String get s_89c61e4a => 'Total des livres';

  @override
  String get s_9da15a74 => 'Répartition par statut';

  @override
  String get s_130a42ae => 'Répartition par catégorie';

  @override
  String get s_98f42577 => 'Répartition par source';

  @override
  String get s_5e8ebbe6 => 'Répartition par format';

  @override
  String get s_5182e58a => 'Note moyenne';

  @override
  String get s_50bcc778 => 'Livres notés';

  @override
  String get s_59c5e73a => 'Temps de lecture (minutes)';

  @override
  String get s_48529b9f => 'Jours d\'activité de lecture';

  @override
  String get s_7be1388c => 'Aucune clé LLM configurée. Renseigne-la dans Réglages → LLM pour pouvoir générer.';

  @override
  String get s_992d7786 => 'Le modèle n\'a renvoyé aucune étiquette exploitable ; essaie un autre modèle';

  @override
  String get s_eead3bcd => 'Remplacer par cet ensemble ?';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return 'Tes $length étiquettes actuelles seront remplacées par ces $length_1. Tu pourras encore les modifier ou les supprimer une à une ensuite.';
  }

  @override
  String get s_89829921 => 'Remplacer';

  @override
  String get s_0f8acec9 => 'Remplacées par les étiquettes principales';

  @override
  String get s_93aebfd1 => 'Cette étiquette figure déjà plus haut';

  @override
  String get s_bca518fd => 'Ajoutée aux étiquettes principales';

  @override
  String s_284dfaab({required Object text}) {
    return '« $text » supprimée';
  }

  @override
  String get s_8eb8d18d => 'Modifier l\'étiquette';

  @override
  String get s_35c48d07 => 'Cette étiquette, c\'est toi qui l\'as écrite ; elle n\'a aucune base automatique.';

  @override
  String get s_724386f0 => 'Ajouter une étiquette';

  @override
  String get s_fdd8c684 => 'Les étiquettes que tu écris toi-même ne sont pas validées et ne seront pas écrasées au recalcul.';

  @override
  String get s_7b328e58 => 'Réinitialiser les étiquettes par défaut ?';

  @override
  String get s_b9a4d4ef => 'Tes modifications manuelles seront effacées et les étiquettes déduites à nouveau à partir de ta bibliothèque actuelle.';

  @override
  String get s_0fcef2c8 => 'Rétablies d\'après les étiquettes déduites de ta bibliothèque';

  @override
  String get s_e97565e5 => 'Mon profil de lecture';

  @override
  String s_783e43af({required Object e}) {
    return 'Impossible de générer l\'image à partager : $e';
  }

  @override
  String get s_14f92b04 => 'Générer l\'image à partager';

  @override
  String get s_a17c4e02 => 'Enregistrée dans tes photos';

  @override
  String s_3f81d5b6({required Object e}) {
    return 'Enregistrement impossible : $e';
  }

  @override
  String get s_c6d1e7a3 => 'Image prête';

  @override
  String get s_b8e4c9a1 => 'Enregistrer l\'image sur cet appareil';

  @override
  String get s_51ebc0d1 => 'Recalculer';

  @override
  String get s_6c64acc5 => 'Mes étiquettes de personnalité de lecteur';

  @override
  String s_03bf36af({required Object length}) {
    return 'Déduites de $length livres';
  }

  @override
  String get s_a789d74f => 'Toutes les étiquettes ont été supprimées. Touche « Ajouter » ci-dessous pour en écrire une, ou réinitialise et laisse l\'app les déduire à nouveau.';

  @override
  String get s_a1d885c1 => 'Ajouter';

  @override
  String get s_64bff158 => 'Touche une étiquette pour la renommer ou la supprimer. Pour les étiquettes déduites par des règles, les chiffres qui les sous-tendent sont visibles dans la boîte de dialogue d\'édition.';

  @override
  String get s_84bf2c49 => 'Génération…';

  @override
  String get s_5a251fee => 'Générer un autre ensemble avec l\'IA';

  @override
  String get s_18be3bbe => 'Réinitialiser par défaut';

  @override
  String get s_7ae84af3 => 'Préférences de lecture';

  @override
  String s_aeed65e7({required Object length}) {
    return '$length catégories';
  }

  @override
  String get s_f2a9e2a4 => 'L\'aire du cercle est proportionnelle au nombre de livres (le rayon est donc la racine carrée du nombre : utiliser le nombre directement comme rayon exagérerait les écarts et induirait en erreur).';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'Généré par l\'IA · $stamp';
  }

  @override
  String get s_7ea8e671 => 'Remplacer les étiquettes principales';

  @override
  String get s_d1a58b2f => 'Touche une étiquette pour l\'ajouter aux principales, ou remplace tout l\'ensemble. Celui-ci est généré par le modèle à partir de statistiques agrégées : sa base est donc moins explicite que celle de la version par règles.';

  @override
  String get s_a38881a0 => 'Pas encore de livres sur cet intervalle';

  @override
  String get s_20fde694 => 'Essaie un autre intervalle, ou importe d\'abord quelques livres';

  @override
  String get s_9fe34cff => 'Pas encore de données de catégories';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount livres';
  }

  @override
  String get s_bfc50de8 => 'Étiquettes de personnalité';

  @override
  String get s_ab5cc063 => 'Préférences de lecture';

  @override
  String get s_9de44e0f => 'Gestionnaire de lecture · Mon étagère';

  @override
  String get s_20a63774 => 'Choisir l\'intervalle des statistiques';

  @override
  String get s_d507abff => 'OK';

  @override
  String get s_ff31410d => 'Personnalisé…';

  @override
  String get s_72cca1f6 => 'Configuration enregistrée localement';

  @override
  String s_b6477017({required Object name}) {
    return '$name renseigné ; la clé API est encore nécessaire';
  }

  @override
  String get s_533f5118 => 'Récupération de la liste des modèles…';

  @override
  String s_648219b9({required Object id}) {
    return 'Modèle sélectionné : $id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '$length modèles disponibles (aucun sélectionné)';
  }

  @override
  String get s_e37cab47 => 'Test de la connexion…';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return 'Connecté · $model\nCela a pris $latencyMs ms ; le modèle a répondu « $reply »';
  }

  @override
  String get s_5df0d12b => 'Vérification de la clé WeRead…';

  @override
  String s_bd245b07({required Object n}) {
    return 'La clé est valide ; l\'étagère compte actuellement $n livres';
  }

  @override
  String s_73f89115({required Object host}) {
    return 'Impossible de joindre $host\nVérifie le réseau, que l\'URL de base est complète (y compris /v1) et si le service exige un proxy';
  }

  @override
  String get s_9038e16e => 'Le point d\'accès a expiré (180 secondes)';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return 'Le service a renvoyé $statusCode : $e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return 'Échec de la requête : $name';
  }

  @override
  String get s_4d3eb2b3 => 'Rechercher des modèles';

  @override
  String s_17d94005({required Object length}) {
    return '$length au total';
  }

  @override
  String get s_a48ae43a => 'Toucher une suggestion écrit le nom du modèle';

  @override
  String get s_b5c7b82d => 'Réglages';

  @override
  String get s_bc90fa59 => 'Sert à synchroniser ton étagère et ta progression de lecture. Scanne le QR code pour ouvrir weread.qq.com/r/weread-skills et en obtenir une.';

  @override
  String get s_e44e9f26 => 'Vérifier la clé';

  @override
  String get s_75bf6943 => 'LLM';

  @override
  String get s_9e8f6691 => 'Sert à compléter les métadonnées manquantes, à nettoyer la reconnaissance de captures et à générer les rapports de lecture.';

  @override
  String get s_cc3c9556 => 'Fournisseurs prédéfinis';

  @override
  String get s_9021b9f9 => 'En choisir un remplit l\'adresse et le modèle';

  @override
  String get s_1fd51aaa => 'Nom du modèle';

  @override
  String get s_209e1f28 => 'Nous teconseillons de toucher « Obtenir les modèles » et de choisir parmi la liste réellement disponible pour ton compte';

  @override
  String get s_ab135d7c => 'Obtenir les modèles';

  @override
  String get s_a46a5664 => 'Tester la connexion';

  @override
  String get s_e4f7e107 => 'Afficher la clé';

  @override
  String get s_b13be56e => 'Masquer la clé';

  @override
  String get s_9ac01f6b => 'Tester et Obtenir les modèles enregistrent d\'abord ce que tu as saisi.';

  @override
  String get s_0001747c => 'Reconnaissance de captures';

  @override
  String get s_3f5cbdbf => 'Détermine la qualité de la reconnaissance des imports par photo et par capture.';

  @override
  String get s_9130a4ed => 'Prétraitement d\'amélioration de l\'image';

  @override
  String get s_b79fc99c => 'Agrandit et nette l\'image d\'abord, ce qui améliore la reconnaissance des petits titres.';

  @override
  String get s_9695a603 => 'Utiliser le LLM pour nettoyer les résultats';

  @override
  String get s_267118b5 => 'Laisse le LLM nettoyer les titres reconnus. Nécessite une clé LLM et consomme des tokens.';

  @override
  String get s_6d7e1f9f => 'Mode de reconnaissance';

  @override
  String get s_ed144a76 => 'Auto (multimodal d\'abord, repli sur l\'appareil)';

  @override
  String get s_c7bab837 => 'Un LLM multimodal lit l\'image directement';

  @override
  String get s_d8f3da2a => 'OCR sur l\'appareil (hors ligne, gratuit)';

  @override
  String get s_f22e4cd2 => 'L\'OCR de l\'appareil fonctionne hors ligne mais peut manquer des titres ; le modèle multimodal comprend la mise en page mais a besoin du réseau et peut inventer un titre. « Auto » combine les deux.';

  @override
  String get s_67677b3d => 'Données';

  @override
  String get s_d596ba9b => 'Exporte toute la base de données en JSON pour déménager sur un autre appareil. Une installation neuve démarre avec une étagère vide ; ajoute des livres depuis l\'onglet Import pour commencer.';

  @override
  String get s_39239742 => 'Export / restauration en un geste';

  @override
  String get s_3c21597a => 'Toutes les modifications sont enregistrées automatiquement dans la base de données de cet appareil — rien à sauvegarder à la main.';

  @override
  String get s_68885a92 => 'Les clés ne sont stockées que dans la base de données de cet appareil ; elles ne sont jamais incluses dans l\'app ni envoyées en ligne.';

  @override
  String get s_9b3c95d4 => 'Mis à jour récemment';

  @override
  String get s_97428491 => 'Terminés récemment';

  @override
  String get s_8f38c041 => 'Mieux notés';

  @override
  String get s_50a7317f => 'Les plus avancés';

  @override
  String get s_b5538557 => 'Titre A–Z';

  @override
  String s_e3cd14ba({required Object title}) {
    return '« $title » ajouté';
  }

  @override
  String get s_296fc9b4 => 'Étagère';

  @override
  String get s_a444b428 => 'Trier';

  @override
  String get s_fa0a5cdd => 'Passer en liste';

  @override
  String get s_cb4a4231 => 'Passer en grille de couvertures';

  @override
  String get s_78966c42 => 'Rechercher titre / auteur / éditeur';

  @override
  String get s_8ed41c6c => 'Aucun livre ne correspond à ces filtres';

  @override
  String get s_bd33274a => 'Pas encore de livres — ajoute-en depuis l\'onglet Import';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '$length livres';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '$reading en cours · $finished lus';
  }

  @override
  String get s_68022ee7 => 'Tous';

  @override
  String get s_542b67cc => 'Plus de filtres';

  @override
  String get s_ec977df0 => 'Source';

  @override
  String get s_50d471b2 => 'Réinitialiser';

  @override
  String get s_37361909 => 'Visibilité des graphiques';

  @override
  String get s_b1288e4a => 'Tout afficher';

  @override
  String get s_6b2b7015 => 'Tout masquer';

  @override
  String get s_e91a9228 => 'N\'affiche que les graphiques qui t\'intéressent et masque les autres.';

  @override
  String get s_fe93ef35 => 'Appliquer';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return 'À rendre dans $daysUntilDue jours';
  }

  @override
  String get s_0e13c16f => 'Statistiques';

  @override
  String get s_3ad4c4c8 => 'Profil de lecture';

  @override
  String s_7c6c253b({required Object label}) {
    return 'Cette période · $label';
  }

  @override
  String get s_88c0b751 => 'Attribués selon la date de fin ou d\'activité de chaque livre';

  @override
  String get s_50ba5fd5 => 'livres';

  @override
  String get s_cc4556af => 'Livres ajoutés';

  @override
  String get s_3509a9f8 => 'jours';

  @override
  String get s_a7e9ff0f => 'pts';

  @override
  String get s_58d90b89 => 'Étagère actuelle';

  @override
  String get s_c3bb899b => 'Chiffres instantanés, non affectés par le filtre de temps ci-dessus';

  @override
  String get s_563edd9d => 'Total des livres';

  @override
  String get s_0d8d3eb3 => 'Série de lecture';

  @override
  String get s_4ab30c5b => 'Commencés mais bloqués';

  @override
  String s_b563f985({required Object label}) {
    return 'Structure · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '$length livres inclus';
  }

  @override
  String get s_c6cc650b => 'Répartition par statut de lecture';

  @override
  String get s_8137585d => '8 principales catégories';

  @override
  String s_f92480e2({required Object length}) {
    return '$length catégories';
  }

  @override
  String get s_50feb68a => 'Lecture par mois';

  @override
  String get s_750a3b1c => 'Pas encore d\'activité de lecture sur cet intervalle';

  @override
  String get s_4d7dd157 => 'Temps de lecture mensuel';

  @override
  String get s_5a78dc03 => 'Affiché après import des statistiques annuelles WeRead';

  @override
  String get s_5b37ad6b => 'Répartition des notes';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return 'Moyenne $toStringAsFixed · $unratedCount non notés';
  }

  @override
  String get s_3c1cb8ee => 'Pas encore de note';

  @override
  String get s_01d886c7 => 'Répartition des progressions';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '$readingInRange en cours';
  }

  @override
  String get s_faf98ba4 => 'Aucun livre en cours sur cet intervalle';

  @override
  String s_77030fdc({required Object length}) {
    return '$length plateformes';
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
    return '$scope · $toStringAsFixed h au total';
  }

  @override
  String s_e7b115df({required Object join}) {
    return 'Les statistiques annuelles de WeRead ne couvrent que $join, ce graphique est donc tracé par année civile ; le graphique des livres terminés ci-dessus utilise les 12 derniers mois.';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name\n$toInt livres';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt livres';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed h';
  }

  @override
  String get s_1597bc27 => 'Rapport de lecture IA';

  @override
  String s_5024726e({required Object reportCount}) {
    return '$reportCount archivés · classés par année / mois, consultables à tout moment';
  }

  @override
  String get s_73f01b82 => 'Génère un récapitulatif de lecture annuel ou mensuel ; ouvre-le pour le créer';

  @override
  String get s_530f5951 => 'Voir';

  @override
  String get s_d51cd7ae => 'Générer';

  @override
  String get s_f8525cf2 => 'Pas encore de données';

  @override
  String s_854a34ca({required Object author}) {
    return ', de $author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return ' : $detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\nContexte supplémentaire : $hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '(sauvegardé le $first)';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return ', $failed en échec';
  }

  @override
  String get s_da4d4d27 => ' · nettoyé par le LLM';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return ' · $repairedTitles titres tronqués complétés';
  }

  @override
  String get navNotes => 'Journal';

  @override
  String get notesViewByTime => 'Par date';

  @override
  String get notesViewByBook => 'Par livre';

  @override
  String get notesFilterByBook => 'Filtrer par livre';

  @override
  String get notesAllBooks => 'Tous les livres';

  @override
  String get notesBookMissing => 'Livre supprimé';

  @override
  String notesOverview({required int count, required int books}) {
    return '$count notes · sur $books livres';
  }

  @override
  String notesMoreCount({required int count}) {
    return '$count de plus';
  }

  @override
  String get notesEmptyTitle => 'Pas encore de notes';

  @override
  String get notesEmptyDesc => 'Ouvre un livre et ajoute un surlignage ou une idée en bas de sa page de détail : ils se rassembleront ici.';

  @override
  String get notesEmptyFilteredTitle => 'Ce livre n\'a pas encore de notes';

  @override
  String get notesEmptyFilteredDesc => 'Choisis un autre livre, ou enlève le filtre pour voir les autres.';

  @override
  String get notesClearFilter => 'Retirer le filtre';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageDesc => 'Choisis la langue utilisée par l\'app. Par défaut, elle suit celle du système.';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsCategoryPick => 'Choisir une catégorie';

  @override
  String get settingsCategoryEmpty => 'Plus aucune catégorie — ajoutez-en une ou restaurez les valeurs par défaut.';

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
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsAppearanceDesc => 'Choisis un thème et le mode clair ou sombre.';

  @override
  String get statusWishHint => 'Pas encore commencé.';

  @override
  String get statusReadingHint => 'En cours de lecture. À 100% de progression, il passe automatiquement à Terminé.';

  @override
  String get statusFinishedHint => 'Terminé. Fais glisser la progression à 100% et il sera marqué automatiquement.';

  @override
  String get statusShelvedHint => 'Commencé mais sans intention de continuer pour l\'instant. Reviens à « En cours » pour le reprendre.';

  @override
  String get borrowTitle => 'Emprunté';

  @override
  String get borrowDesc => 'Marque le livre comme emprunté, avec un prêteur et une date de retour.';

  @override
  String get borrowFlag => 'Ce livre est emprunté';

  @override
  String get borrowFrom => 'Emprunté à';

  @override
  String get borrowFromHint => 'p. ex. la bibliothèque municipale, un collègue';

  @override
  String get borrowDue => 'Date de retour';

  @override
  String get borrowDueUnset => 'Non fixée';

  @override
  String borrowDueIn({required int days}) {
    return 'À rendre dans $days jours';
  }

  @override
  String borrowOverdue({required int days}) {
    return 'En retard de $days jours';
  }

  @override
  String get borrowClearDue => 'Effacer la date';

  @override
  String get borrowReturn => 'Marquer comme rendu';

  @override
  String get borrowReturnDesc => 'Cela efface la marque d\'emprunt, le prêteur et la date de retour, et annule le rappel.';

  @override
  String get borrowReturned => 'Marqué comme rendu';

  @override
  String get statusSectionTitle => 'Statut de lecture';

  @override
  String get planSectionTitle => 'Plans de lecture';

  @override
  String get planSectionDesc => 'Fixe-toi un objectif que tu puisses vraiment tenir. Les plans restent sur cet appareil.';

  @override
  String get planEmpty => 'Pas encore de plans. Commence petit : 20 minutes par jour.';

  @override
  String get planAdd => 'Nouveau plan';

  @override
  String get planEdit => 'Modifier le plan';

  @override
  String get planKindDaily => 'Lire tous les jours';

  @override
  String get planKindFinishBook => 'Terminer un livre';

  @override
  String get planKindDailyDesc => 'Fixe un temps de lecture quotidien ; l\'évaluation se fait sur ta moyenne journalière.';

  @override
  String get planKindFinishBookDesc => 'Choisis un livre et une date limite ; atteindre 100% le valide.';

  @override
  String get planDailyTarget => 'Objectif quotidien';

  @override
  String planMinutesUnit({required int n}) {
    return '$n min';
  }

  @override
  String get planPickBook => 'Choisis un livre';

  @override
  String get planDueLabel => 'Date limite';

  @override
  String get planDueUnset => 'Non fixée';

  @override
  String get planRemind => 'Me rappeler avant la date limite';

  @override
  String get planRemindOff => 'Activer ceci demandera l\'autorisation des notifications. Le rappel s\'annule de lui-même une fois le plan terminé.';

  @override
  String get planTitleLabel => 'Nom du plan (facultatif)';

  @override
  String get planTitleHint => 'Laisse vide pour utiliser le nom par défaut';

  @override
  String get planSave => 'Enregistrer';

  @override
  String get planDelete => 'Supprimer le plan';

  @override
  String get planDeleteConfirm => 'Supprimer ce plan ? Tes enregistrements de lecture ne sont pas affectés.';

  @override
  String get planMarkDone => 'Marquer comme fait';

  @override
  String get planAchieved => 'Atteint';

  @override
  String get planMarkToday => 'J\'ai lu aujourd\'hui';

  @override
  String get planDoneToday => 'Fait pour aujourd\'hui';

  @override
  String get planDailyCycleHint => 'Chaque jour est un nouveau départ : cocher ne compte que pour aujourd\'hui, et le rappel revient demain.';

  @override
  String get planReminderUnavailable => 'Le système n\'a pas pu programmer le rappel (l\'économie d\'énergie a pu le bloquer). Ton plan a bien été enregistré.';

  @override
  String planProgressDaily({required String current, required String target}) {
    return 'Moyenne quotidienne $current / $target min';
  }

  @override
  String planProgressBook({required int current}) {
    return 'Progression $current% · objectif 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return '$days jours restants';
  }

  @override
  String planOverdue({required int days}) {
    return 'En retard de $days jours';
  }

  @override
  String planStreak({required int n}) {
    return 'Série de $n jours de validation';
  }

  @override
  String get planDueToday => 'Échéance aujourd\'hui';

  @override
  String get planBookGone => 'Le livre visé n\'est plus sur ton étagère';

  @override
  String get planDoneSection => 'Terminés';

  @override
  String get planReminderDenied => 'L\'autorisation des notifications a été refusée, les rappels ne peuvent donc pas être délivrés. Active-la dans les réglages du système.';

  @override
  String get planReminderDailyTitle => 'L\'objectif de lecture du jour n\'est pas encore atteint';

  @override
  String planReminderDailyBody({required int minutes}) {
    return 'Ton objectif est de $minutes minutes — il est encore temps.';
  }

  @override
  String get planReminderBookTitle => 'Une date limite de lecture approche';

  @override
  String planReminderBookBody({required int days}) {
    return 'Ton plan expire dans $days jours. C\'est le bon moment pour le terminer.';
  }

  @override
  String get settingsPlanReminder => 'Rappels de lecture';

  @override
  String get reportSettings => 'Réglages du rapport';

  @override
  String get reportBackfill => 'Générer les rapports manquants';

  @override
  String get reportNothingToBackfill => 'Tous les rapports qui devraient exister sont déjà là.';

  @override
  String get reportHistoryEmpty => 'Pas encore de rapports. Choisis une période et génère le premier ci-dessous.';

  @override
  String get reportNoKey => 'Aucun modèle configuré, les rapports ne peuvent donc pas être générés. Ajoute d\'abord une clé dans les Réglages.';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsBrightness => 'Clair ou sombre';

  @override
  String get brightnessSystem => 'Suivre le système';

  @override
  String get brightnessLight => 'Clair';

  @override
  String get brightnessDark => 'Sombre';

  @override
  String get themeGreen => 'Vert';

  @override
  String get themeInk => 'Encre';

  @override
  String get themeBlue => 'Montagne';

  @override
  String get themePlum => 'Prune';

  @override
  String get themeLagoon => 'Lagon';

  @override
  String get themeBerry => 'Baie';

  @override
  String get settingsChannels => 'Services connectés';

  @override
  String get settingsChannelsDesc => 'Synchronise ton étagère et ta progression depuis d\'autres plateformes de lecture. WeRead est pris en charge aujourd\'hui ; d\'autres plateformes seront ajoutées à l\'ouverture de leurs API.';

  @override
  String get settingsChannelsHint => 'Les clés ne sont stockées que dans le trousseau système de cet appareil et ne sont jamais envoyées en ligne.';

  @override
  String get settingsChannelAddHint => 'D\'autres services arrivent.';

  @override
  String get importAccuracyTitle => 'Le résultat peut être imprécis';

  @override
  String get importAccuracyDesc => 'Les titres et les auteurs sont déduits par l\'OCR et les modèles d\'IA : ils peuvent mal lire un mot ou choisir le mauvais livre. Vérifie avant d\'enregistrer.';

  @override
  String get importFromImageTitle => 'Importer depuis une capture';

  @override
  String get importFromImageDesc => 'Choisis une capture de ton étagère et détecte les livres qui s\'y trouvent.';

  @override
  String get importFromCameraTitle => 'Importer avec l\'appareil photo';

  @override
  String get importFromCameraDesc => 'Photographie ton étagère et détecte les livres qui s\'y trouvent.';

  @override
  String get insights => 'Carnet de lecture';

  @override
  String get insightsDesc => 'Ton profil de lecture de long terme, plus les rapports par mois et par année.';

  @override
  String get chronology => 'Chronologie';

  @override
  String get chronologyDesc => 'Ta lecture mois par mois. Touche une carte pour ouvrir le livre.';

  @override
  String get chronologyEmpty => 'Rien de terminé ni d\'en cours cette année pour l\'instant.';

  @override
  String get chronologyFinished => 'Terminés';

  @override
  String get chronologyReading => 'En cours';

  @override
  String get chronologyShelved => 'Mis de côté';

  @override
  String get chronologyWish => 'À lire';

  @override
  String chronologyMore({required int n}) {
    return '$n de plus — voir tout le mois';
  }

  @override
  String get reportStyle => 'Style du rapport';

  @override
  String get reportStyleDesc => 'Choisis le ton et la structure des rapports générés, ou écris ton propre prompt.';

  @override
  String get reportStyleRational => 'Faits et données';

  @override
  String get reportStyleRationalDesc => 'Expose les données objectivement : sans éloge, sans incitation à partager ou à cocher des jours, avec des points clairement listés.';

  @override
  String get reportStyleWarm => 'Encouragement chaleureux';

  @override
  String get reportStyleWarmDesc => 'Reconnaît ta constance et donne des conseils avec douceur.';

  @override
  String get reportStyleDirect => 'Franc et direct';

  @override
  String get reportStyleDirectDesc => 'Nomme les problèmes sans les adoucir, pour qui préfère les choses claires.';

  @override
  String get reportStyleConcise => 'Bref';

  @override
  String get reportStyleConciseDesc => 'Uniquement des conclusions, aussi brèves que possible.';

  @override
  String get reportStyleCustom => 'Personnalisé';

  @override
  String get reportStyleCustomDesc => 'Écris le prompt toi-même et contrôle exactement la façon dont les rapports se lisent.';

  @override
  String get reportStyleCustomHint => 'p. ex. Parle-moi à la deuxième personne, comme un ami qui commente ma lecture.';

  @override
  String get reportReadMore => 'Lire le rapport complet';

  @override
  String get reportNoContent => '(ce rapport n\'a pas de corps de texte)';

  @override
  String get s_9f2c1d4e => 'Vue d\'ensemble';

  @override
  String get s_0f2b6c1a => 'Lecture de cette période';

  @override
  String get s_7d1a4e35 => 'Structure de l\'étagère';

  @override
  String get s_3c58b0d2 => 'Habitudes de lecture';

  @override
  String get s_4b7e2a19 => 'Livres qui méritent d\'être nommés';

  @override
  String get s_6e39f7c4 => 'Profil du lecteur';

  @override
  String get s_1a8d53f6 => 'Que lire ensuite';

  @override
  String get s_2f9d1a4b => 'Étiquettes';

  @override
  String get s_5c7e3d81 => 'Aucune étiquette pour l’instant';

  @override
  String s_3e8f5b26({required Object title}) {
    return 'Supprimer « $title » ?';
  }

  @override
  String get s_7d4c2e91 => 'Ses journaux de lecture et ses plans sont supprimés avec lui. Vos notes sont conservées : elles restent dans l’onglet Notes. Cette action est irréversible.';

  @override
  String s_1f6a8d37({required Object title}) {
    return '« $title » supprimé';
  }

  @override
  String get s_4b2c9e58 => 'Catégories';

  @override
  String get s_8d3f6a12 => 'Ajoutez, renommez ou supprimez des catégories. Les livres d’une catégorie supprimée vont dans « Non classé ».';

  @override
  String get s_2c8b5d09 => 'Nom de la catégorie';

  @override
  String get s_9f4e7a35 => 'Le nom de la catégorie ne peut pas être vide';

  @override
  String get s_7a2d6c81 => 'Cette catégorie existe déjà';

  @override
  String s_5e9c1b47({required Object name}) {
    return '« $name » ajoutée';
  }

  @override
  String s_3b7f2d64({required Object name}) {
    return '« $name » supprimée';
  }

  @override
  String s_8c4a1e92({required Object name}) {
    return 'Supprimer la catégorie « $name » ?';
  }

  @override
  String s_1d7b3f08({required Object count}) {
    return '$count livres qu’elle contient iront dans « Non classé ».';
  }

  @override
  String get s_6a9e4c27 => 'Renommer';

  @override
  String get s_2f5d8b13 => 'Rétablir les catégories par défaut';

  @override
  String get s_4e1c7a69 => 'Catégories par défaut rétablies';

  @override
  String get s_9c3f5d21 => 'Personnalisée';

  @override
  String s_9d2e7f13({required Object name, required Object count}) {
    return 'Renommée en « $name » ; $count livres mis à jour';
  }

  @override
  String get themeBgStarfield => 'Ciel étoilé';

  @override
  String get themeBgMist => 'Brume de montagne';

  @override
  String get themeBgMoss => 'Jardin de mousse';

  @override
  String get themeBgDusk => 'Lumière du soir';

  @override
  String get themeBgCat => 'Sieste du chat';

  @override
  String get themeBgDog => 'Parc du chien';

  @override
  String get s_2f8a1c47 => 'Texturé';

  @override
  String get checkUpdate => 'Vérifier les mises à jour';

  @override
  String get checkUpdateDesc => 'Voir si une version plus récente existe. Si oui, elle indiquera ce qui a changé.';

  @override
  String get checkingForUpdate => 'Vérification…';

  @override
  String get updateUpToDate => 'Vous utilisez déjà la dernière version';

  @override
  String updateUpToDateDesc({required String version}) {
    return 'Vous utilisez la version $version. Aucune version plus récente n’est disponible.';
  }

  @override
  String updateAvailable({required String version}) {
    return 'La version $version est disponible';
  }

  @override
  String updateAvailableDesc({required String current, required String latest}) {
    return 'Vous utilisez $current. Mettez à jour vers $latest quand vous voulez — rien n’est téléchargé automatiquement.';
  }

  @override
  String get updateNotesTitle => 'Ce qui a changé';

  @override
  String get updateNoNotes => 'L’éditeur n’a pas fourni de notes de version cette fois-ci.';

  @override
  String updateDownload({required String version}) {
    return 'Télécharger $version';
  }

  @override
  String get updateOpenRelease => 'Ouvrir la page de publication';

  @override
  String get updateCheckFailed => 'Échec de la vérification des mises à jour';

  @override
  String get updateCheckFailedNetwork => 'Serveur injoignable. Vérifiez la connexion et réessayez.';

  @override
  String get updateCheckFailedMalformed => 'Le serveur a renvoyé une réponse illisible. Réessayez plus tard.';

  @override
  String updateNeverInstalled({required String version}) {
    return 'Aucun installateur trouvé : $version est publié, mais aucun APK n’a été trouvé.';
  }

  @override
  String updateReleasedOn({required String date}) {
    return 'Publié le $date';
  }
}

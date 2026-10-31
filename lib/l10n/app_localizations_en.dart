// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gustaro';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navWines => 'Wines';

  @override
  String get navMore => 'More';

  @override
  String get navScan => 'Scan a bottle';

  @override
  String get homeLanguage => 'Language';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String get homeSearchHint => 'Search “Fetească Neagră”';

  @override
  String get homeSommelier => 'Ask the sommelier';

  @override
  String get hero1Tag => 'Guided tasting';

  @override
  String get hero1Title => 'Learn to taste like a sommelier';

  @override
  String get hero1Body =>
      'Short tastings you can follow anywhere. Grab a glass and follow the steps.';

  @override
  String get hero2Tag => 'Tasting of the week';

  @override
  String get hero2Title => 'Fetească Neagră, step by step';

  @override
  String get hero2Body => '5 steps, about 4 minutes. Pour a glass of red.';

  @override
  String get hero3Tag => 'For beginners';

  @override
  String get hero3Title => 'Your first sparkling';

  @override
  String get hero3Body =>
      '5 steps, about 4 minutes. Bubbles show best in a tall glass.';

  @override
  String get heroStart => 'Start';

  @override
  String get heroHide => 'Hide';

  @override
  String heroSlide(int number) {
    return 'Tasting $number';
  }

  @override
  String get recentOverline => 'Build your taste profile';

  @override
  String get recentTitle => 'Your recent scans';

  @override
  String recentCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get recentEmptyTitle => 'Scan your first bottle';

  @override
  String get recentEmptyBody =>
      'Point the camera at a barcode and see what\'s in the bottle.';

  @override
  String get recentEmptyAction => 'Scan a bottle';

  @override
  String get recentScannedToday => 'Scanned today';

  @override
  String get recentScannedYesterday => 'Scanned yesterday';

  @override
  String recentScannedDays(int days) {
    return 'Scanned $days days ago';
  }

  @override
  String get recentScannedLastWeek => 'Scanned last week';

  @override
  String get recentScannedEarlier => 'Scanned earlier';

  @override
  String get recentHide => 'Remove from recent scans';

  @override
  String get feedbackQuestion => 'Did you like it?';

  @override
  String get feedbackNo => 'Not really';

  @override
  String get feedbackYes => 'I liked it';

  @override
  String get feedbackNotTasted => 'Haven\'t tasted it yet';

  @override
  String get feedbackTasteNow => '· Taste it now';

  @override
  String get feedbackLiked => 'You liked this wine';

  @override
  String get feedbackDisliked => 'Not really your wine';

  @override
  String get feedbackChange => 'Change';

  @override
  String get sommelierTitle => 'Ask the sommelier';

  @override
  String get sommelierPrompt1 => 'A good wine at a good price';

  @override
  String get sommelierPrompt2 => 'Match a wine to dinner';

  @override
  String get sommelierPrompt3 => 'Find a gift';

  @override
  String get sommelierInput => 'Ask anything about wine…';

  @override
  String get sommelierSoonTitle => 'The sommelier is on its way';

  @override
  String get sommelierSoonBody =>
      'We\'re training our sommelier on verified winemaker data. It isn\'t ready yet, but it\'s coming to Gustaro soon.';

  @override
  String get moreWinesTitle => 'More wines to discover';

  @override
  String get moreWinesBody => 'From the Gustaro catalogue.';

  @override
  String get wineriesTitle => 'Wineries';

  @override
  String get wineriesBody => 'The wineries in Gustaro so far.';

  @override
  String get footerMade => 'Made with love in Moldova';

  @override
  String get notificationsTitle => 'No notifications yet';

  @override
  String get notificationsBody =>
      'When there\'s news from Gustaro, you\'ll find it here.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRomanian => 'Română';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageSoonTitle => 'We\'re working on it';

  @override
  String languageSoonBody(String language) {
    return '$language is on its way. For now, Gustaro is available in English.';
  }

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSoonTag => 'In the works';

  @override
  String get exploreSoonTitle => 'Something good is in the barrel';

  @override
  String get exploreSoonBody =>
      'Wine regions, wineries and grapes of Moldova will live here. We\'re still working on this page.';

  @override
  String get exploreSoonAction => 'Browse the wines';

  @override
  String get winesTitle => 'Wines';

  @override
  String get winesSearchHint => 'Search wines and wineries';

  @override
  String get winesFilterAll => 'All';

  @override
  String get winesEmptyTitle => 'The catalogue is growing';

  @override
  String get winesEmptyBody =>
      'New wines are added directly from the winemakers.';

  @override
  String get winesNoResults => 'No wines match your search';

  @override
  String get winesMineBadge => 'Added by you';

  @override
  String winesYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vintages',
      one: '1 vintage',
    );
    return '$_temp0';
  }

  @override
  String get typeRed => 'Red';

  @override
  String get typeWhite => 'White';

  @override
  String get typeRose => 'Rosé';

  @override
  String get typeOrange => 'Orange';

  @override
  String get typeSparkling => 'Sparkling';

  @override
  String get typeDessert => 'Dessert';

  @override
  String wineOrigin(String type, String region) {
    return '$type · $region, Moldova';
  }

  @override
  String get moreTitle => 'More';

  @override
  String get moreGuest => 'Guest';

  @override
  String get moreGuestBody =>
      'No account needed. Your scans and bottles stay on this phone.';

  @override
  String get moreAddBottle => 'Add a wine bottle';

  @override
  String get moreAddBottleBody =>
      'Barcode, grapes, specs, tasting notes and pairings';

  @override
  String get moreMyBottles => 'My bottles';

  @override
  String get moreLanguage => 'Language';

  @override
  String get moreTastingGuide => 'Tasting guide';

  @override
  String get moreTerms => 'Terms & Conditions';

  @override
  String get morePrivacy => 'Privacy Policy';

  @override
  String get moreAbout => 'About Gustaro';

  @override
  String get moreClearData => 'Delete my data';

  @override
  String get moreClearTitle => 'Delete all your data?';

  @override
  String get moreClearBody =>
      'This removes your recent scans, the bottles you added and your preferences from this phone. It can\'t be undone.';

  @override
  String get moreClearDone => 'Your data was deleted';

  @override
  String get moreResponsible =>
      'Enjoy wine responsibly. For people of legal drinking age only.';

  @override
  String moreVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutBody =>
      'Gustaro identifies Moldovan wines. Scan a bottle and see technical specifications, sensory notes and food pairings supplied directly by winemakers. No reviews and no scores.';

  @override
  String get aboutLicenses => 'Open-source licences';

  @override
  String get myBottlesTitle => 'My bottles';

  @override
  String get myBottlesEmptyTitle => 'No bottles yet';

  @override
  String get myBottlesEmptyBody =>
      'Add a bottle and it can be scanned right away on this phone.';

  @override
  String get addTitle => 'Add a wine bottle';

  @override
  String get addIntro =>
      'Bottles you add stay on this phone and work with the scanner right away. They\'re marked “Added by you”, because they don\'t come from a winemaker.';

  @override
  String get addSectionPhoto => 'Photo';

  @override
  String get addPhotoHelp =>
      'Optional. A picture of the bottle. It stays on this phone.';

  @override
  String get addPhotoTake => 'Take a photo';

  @override
  String get addPhotoChoose => 'Choose a photo';

  @override
  String get addPhotoRemove => 'Remove photo';

  @override
  String get addSectionBarcode => 'Barcode';

  @override
  String get addSectionWine => 'The wine';

  @override
  String get addSectionSpecs => 'Technical specifications';

  @override
  String get addSectionTasting => 'Tasting';

  @override
  String get addBarcode => 'Barcode digits';

  @override
  String get addBarcodeHelp =>
      'The digits under the bars. Tap the icon to scan them.';

  @override
  String get addBarcodeScan => 'Scan the barcode';

  @override
  String get addBarcodeTypo =>
      'This barcode doesn\'t look right. Check the digits.';

  @override
  String get addBottleSize => 'Bottle size (ml)';

  @override
  String get addWinery => 'Winery';

  @override
  String get addWineName => 'Wine name';

  @override
  String get addType => 'Type';

  @override
  String get addYear => 'Year';

  @override
  String get addRegion => 'Region';

  @override
  String get addRegionHint => 'Codru, Ștefan Vodă, Valul lui Traian…';

  @override
  String get addGrapes => 'Grape varieties';

  @override
  String get addGrapesHint => 'Separate with commas';

  @override
  String get addAbv => 'Alcohol (%)';

  @override
  String get addAcidity => 'Acidity (g/L)';

  @override
  String get addTannins => 'Tannins (g/L)';

  @override
  String get addSugar => 'Residual sugar (g/L)';

  @override
  String get addSensory => 'Sensory notes';

  @override
  String get addSensoryHint => 'Colour, aroma, taste';

  @override
  String get addPairings => 'Food pairings';

  @override
  String get addPairingsHint => 'Separate with commas';

  @override
  String get addDescription => 'Description';

  @override
  String get addSave => 'Save bottle';

  @override
  String get addRequired => 'Required';

  @override
  String get addInvalidNumber => 'Enter a number';

  @override
  String addInvalidYear(int max) {
    return 'Enter a year between 1900 and $max';
  }

  @override
  String get addInvalidAbv => 'Enter a value between 0 and 100';

  @override
  String get addTypeRequired => 'Choose a type';

  @override
  String get addFixErrors => 'Please check the highlighted fields';

  @override
  String get addSaved => 'Bottle saved. Try scanning it!';

  @override
  String get addDuplicate => 'You already added this wine and year.';

  @override
  String get addDuplicateOpen => 'Open it';

  @override
  String get scanHint => 'Point the camera at the barcode';

  @override
  String get scanHintLabel => 'Can\'t find a barcode? Read the label instead.';

  @override
  String get scanCaptureHint => 'Scan the barcode on the bottle';

  @override
  String get scanReadLabel => 'Read the label';

  @override
  String get scanEnterCode => 'Type the code';

  @override
  String get scanTorch => 'Flashlight';

  @override
  String get scanLooking => 'Looking it up…';

  @override
  String get scanReading => 'Reading the label…';

  @override
  String get scanManualTitle => 'Type the barcode';

  @override
  String get scanManualBody => 'Enter the digits printed under the bars.';

  @override
  String get scanManualAction => 'Look it up';

  @override
  String get scanNoCameraTitle => 'Camera not available';

  @override
  String get scanNoCameraBody =>
      'You can still type the barcode or choose a photo of the label.';

  @override
  String get scanNoPermissionTitle => 'Gustaro needs the camera';

  @override
  String get scanNoPermissionBody =>
      'Allow camera access in Settings to scan bottles. Images stay on your phone.';

  @override
  String get scanOpenSettings => 'Open Settings';

  @override
  String get scanChoosePhoto => 'Choose a photo';

  @override
  String get pickVintageTitle => 'Which year is your bottle?';

  @override
  String get pickVintageLabelRead => 'Read on the label';

  @override
  String get pickWineBarcodeTitle => 'Several wines share this barcode';

  @override
  String get pickWineLabelTitle => 'Is it one of these?';

  @override
  String get pickWineNone => 'None of these';

  @override
  String get missTitle => 'Not in our catalogue yet';

  @override
  String get missBodyBarcode =>
      'We don\'t have this bottle yet. Reading the label might still find it.';

  @override
  String get missBodyLabel =>
      'We couldn\'t match this label to a wine in the catalogue.';

  @override
  String missCode(String code) {
    return 'Barcode $code';
  }

  @override
  String get missTryLabel => 'Read the label';

  @override
  String get missAddBottle => 'Add this bottle';

  @override
  String get missScanAgain => 'Scan another bottle';

  @override
  String get wineVerified => 'Verified by the winemaker';

  @override
  String get wineUnverified => 'Added by you · not verified';

  @override
  String get wineSpecs => 'Technical specifications';

  @override
  String get wineAlcohol => 'Alcohol';

  @override
  String get wineAcidity => 'Acidity';

  @override
  String get wineTannins => 'Tannins';

  @override
  String get wineSugar => 'Residual sugar';

  @override
  String get wineGrapes => 'Grape varieties';

  @override
  String get wineSensory => 'Sensory notes';

  @override
  String get winePairings => 'Food pairings';

  @override
  String get wineAbout => 'About this wine';

  @override
  String get wineLanguageNote =>
      'Wine texts are shown in Romanian for now. English is on its way.';

  @override
  String get wineSourceVerified =>
      'All information comes directly from the winemaker.';

  @override
  String get wineSourceMine =>
      'You entered this information. It only exists on this phone.';

  @override
  String get wineDelete => 'Delete this bottle';

  @override
  String get wineDeleteTitle => 'Delete this bottle?';

  @override
  String get wineDeleteBody => 'It will be removed from this phone.';

  @override
  String get wineNotFound => 'This wine is no longer available.';

  @override
  String get tastingTitle => 'Tasting guide';

  @override
  String tastingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tastingNext => 'Next';

  @override
  String get tastingDone => 'Done';

  @override
  String get tastingResponsible =>
      'Enjoy responsibly. For people of legal drinking age only.';

  @override
  String get tastingLook => 'Look';

  @override
  String get tastingSwirl => 'Swirl';

  @override
  String get tastingSmell => 'Smell';

  @override
  String get tastingSip => 'Sip';

  @override
  String get tastingFinish => 'Finish';

  @override
  String get tasting1Look =>
      'Hold the glass against something white. Notice the colour: deep or pale, bright or cloudy.';

  @override
  String get tasting1Swirl =>
      'Move the glass in small circles. This wakes up the aromas and shows how the wine clings to the glass.';

  @override
  String get tasting1Smell =>
      'Bring the glass to your nose and breathe in gently. Look for fruit first, then flowers, spice or oak.';

  @override
  String get tasting1Sip =>
      'Take a small sip and let it cover your whole mouth. Is it sweet or dry, fresh or soft, light or full?';

  @override
  String get tasting1Finish =>
      'Swallow and wait. How long does the taste stay? A long finish usually means a well-made wine.';

  @override
  String get tasting2Look =>
      'Fetească Neagră is usually a deep ruby. Tilt the glass and look at the colour near the rim.';

  @override
  String get tasting2Swirl =>
      'Swirl gently for a few seconds. Reds open up with a little air, so take your time.';

  @override
  String get tasting2Smell =>
      'Look for dark fruit such as plum and black cherry. Older wines may add spice and dried fruit.';

  @override
  String get tasting2Sip =>
      'Notice the tannins: that gentle grip on your gums. They give red wine its structure.';

  @override
  String get tasting2Finish =>
      'Think about what you\'d eat with it. Rich reds like this one love grilled meat and aged cheese.';

  @override
  String get tasting3Look =>
      'Pour into a tall glass and watch the bubbles. Fine, steady bubbles are a good sign.';

  @override
  String get tasting3Swirl =>
      'Skip the swirl here. Hold the glass still so you keep the bubbles.';

  @override
  String get tasting3Smell =>
      'Look for green apple and citrus. Bottle-aged sparkling can also smell of toast or brioche.';

  @override
  String get tasting3Sip =>
      'Take a small sip and feel the bubbles on your tongue. Is it dry and fresh, or a little sweet?';

  @override
  String get tasting3Finish =>
      'Notice how clean your mouth feels afterwards. That freshness makes sparkling great with food.';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onb1Title => 'Know what\'s in the bottle';

  @override
  String get onb1Body =>
      'Scan any Moldovan wine in the store and see what it is in seconds.';

  @override
  String get onb2Title => 'Straight from the winemaker';

  @override
  String get onb2Body =>
      'Specs, sensory notes and food pairings supplied by winemakers. No reviews, no scores.';

  @override
  String get onb3Title => 'Works everywhere';

  @override
  String get onb3Body =>
      'The catalogue lives on your phone, so scanning works even with no signal. No account needed.';

  @override
  String get onbLegalTitle => 'One last thing';

  @override
  String get onbLegalBody => 'Gustaro is about wine, so it\'s for adults only.';

  @override
  String get onbAge =>
      'I am 18 or older and of legal drinking age in my country.';

  @override
  String get onbTermsPrefix => 'I agree to the ';

  @override
  String get onbTerms => 'Terms & Conditions';

  @override
  String get onbTermsAnd => ' and ';

  @override
  String get onbPrivacy => 'Privacy Policy';

  @override
  String get onbStart => 'Start exploring';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorBody =>
      'Gustaro couldn\'t open its catalogue. Please restart the app.';
}

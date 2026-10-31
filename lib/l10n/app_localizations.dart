import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gustaro'**
  String get appName;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navWines.
  ///
  /// In en, this message translates to:
  /// **'Wines'**
  String get navWines;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a bottle'**
  String get navScan;

  /// No description provided for @homeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get homeLanguage;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search “Fetească Neagră”'**
  String get homeSearchHint;

  /// No description provided for @homeSommelier.
  ///
  /// In en, this message translates to:
  /// **'Ask the sommelier'**
  String get homeSommelier;

  /// No description provided for @hero1Tag.
  ///
  /// In en, this message translates to:
  /// **'Guided tasting'**
  String get hero1Tag;

  /// No description provided for @hero1Title.
  ///
  /// In en, this message translates to:
  /// **'Learn to taste like a sommelier'**
  String get hero1Title;

  /// No description provided for @hero1Body.
  ///
  /// In en, this message translates to:
  /// **'Short tastings you can follow anywhere. Grab a glass and follow the steps.'**
  String get hero1Body;

  /// No description provided for @hero2Tag.
  ///
  /// In en, this message translates to:
  /// **'Tasting of the week'**
  String get hero2Tag;

  /// No description provided for @hero2Title.
  ///
  /// In en, this message translates to:
  /// **'Fetească Neagră, step by step'**
  String get hero2Title;

  /// No description provided for @hero2Body.
  ///
  /// In en, this message translates to:
  /// **'5 steps, about 4 minutes. Pour a glass of red.'**
  String get hero2Body;

  /// No description provided for @hero3Tag.
  ///
  /// In en, this message translates to:
  /// **'For beginners'**
  String get hero3Tag;

  /// No description provided for @hero3Title.
  ///
  /// In en, this message translates to:
  /// **'Your first sparkling'**
  String get hero3Title;

  /// No description provided for @hero3Body.
  ///
  /// In en, this message translates to:
  /// **'5 steps, about 4 minutes. Bubbles show best in a tall glass.'**
  String get hero3Body;

  /// No description provided for @heroStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get heroStart;

  /// No description provided for @heroHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get heroHide;

  /// No description provided for @heroSlide.
  ///
  /// In en, this message translates to:
  /// **'Tasting {number}'**
  String heroSlide(int number);

  /// No description provided for @recentOverline.
  ///
  /// In en, this message translates to:
  /// **'Build your taste profile'**
  String get recentOverline;

  /// No description provided for @recentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recent scans'**
  String get recentTitle;

  /// No description provided for @recentCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String recentCount(int current, int total);

  /// No description provided for @recentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan your first bottle'**
  String get recentEmptyTitle;

  /// No description provided for @recentEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a barcode and see what\'s in the bottle.'**
  String get recentEmptyBody;

  /// No description provided for @recentEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Scan a bottle'**
  String get recentEmptyAction;

  /// No description provided for @recentScannedToday.
  ///
  /// In en, this message translates to:
  /// **'Scanned today'**
  String get recentScannedToday;

  /// No description provided for @recentScannedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Scanned yesterday'**
  String get recentScannedYesterday;

  /// No description provided for @recentScannedDays.
  ///
  /// In en, this message translates to:
  /// **'Scanned {days} days ago'**
  String recentScannedDays(int days);

  /// No description provided for @recentScannedLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Scanned last week'**
  String get recentScannedLastWeek;

  /// No description provided for @recentScannedEarlier.
  ///
  /// In en, this message translates to:
  /// **'Scanned earlier'**
  String get recentScannedEarlier;

  /// No description provided for @recentHide.
  ///
  /// In en, this message translates to:
  /// **'Remove from recent scans'**
  String get recentHide;

  /// No description provided for @feedbackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did you like it?'**
  String get feedbackQuestion;

  /// No description provided for @feedbackNo.
  ///
  /// In en, this message translates to:
  /// **'Not really'**
  String get feedbackNo;

  /// No description provided for @feedbackYes.
  ///
  /// In en, this message translates to:
  /// **'I liked it'**
  String get feedbackYes;

  /// No description provided for @feedbackNotTasted.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t tasted it yet'**
  String get feedbackNotTasted;

  /// No description provided for @feedbackTasteNow.
  ///
  /// In en, this message translates to:
  /// **'· Taste it now'**
  String get feedbackTasteNow;

  /// No description provided for @feedbackLiked.
  ///
  /// In en, this message translates to:
  /// **'You liked this wine'**
  String get feedbackLiked;

  /// No description provided for @feedbackDisliked.
  ///
  /// In en, this message translates to:
  /// **'Not really your wine'**
  String get feedbackDisliked;

  /// No description provided for @feedbackChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get feedbackChange;

  /// No description provided for @sommelierTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the sommelier'**
  String get sommelierTitle;

  /// No description provided for @sommelierPrompt1.
  ///
  /// In en, this message translates to:
  /// **'A good wine at a good price'**
  String get sommelierPrompt1;

  /// No description provided for @sommelierPrompt2.
  ///
  /// In en, this message translates to:
  /// **'Match a wine to dinner'**
  String get sommelierPrompt2;

  /// No description provided for @sommelierPrompt3.
  ///
  /// In en, this message translates to:
  /// **'Find a gift'**
  String get sommelierPrompt3;

  /// No description provided for @sommelierInput.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about wine…'**
  String get sommelierInput;

  /// No description provided for @sommelierSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'The sommelier is on its way'**
  String get sommelierSoonTitle;

  /// No description provided for @sommelierSoonBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re training our sommelier on verified winemaker data. It isn\'t ready yet, but it\'s coming to Gustaro soon.'**
  String get sommelierSoonBody;

  /// No description provided for @moreWinesTitle.
  ///
  /// In en, this message translates to:
  /// **'More wines to discover'**
  String get moreWinesTitle;

  /// No description provided for @moreWinesBody.
  ///
  /// In en, this message translates to:
  /// **'From the Gustaro catalogue.'**
  String get moreWinesBody;

  /// No description provided for @wineriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Wineries'**
  String get wineriesTitle;

  /// No description provided for @wineriesBody.
  ///
  /// In en, this message translates to:
  /// **'The wineries in Gustaro so far.'**
  String get wineriesBody;

  /// No description provided for @footerMade.
  ///
  /// In en, this message translates to:
  /// **'Made with love in Moldova'**
  String get footerMade;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsTitle;

  /// No description provided for @notificationsBody.
  ///
  /// In en, this message translates to:
  /// **'When there\'s news from Gustaro, you\'ll find it here.'**
  String get notificationsBody;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRomanian.
  ///
  /// In en, this message translates to:
  /// **'Română'**
  String get languageRomanian;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re working on it'**
  String get languageSoonTitle;

  /// No description provided for @languageSoonBody.
  ///
  /// In en, this message translates to:
  /// **'{language} is on its way. For now, Gustaro is available in English.'**
  String languageSoonBody(String language);

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreSoonTag.
  ///
  /// In en, this message translates to:
  /// **'In the works'**
  String get exploreSoonTag;

  /// No description provided for @exploreSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Something good is in the barrel'**
  String get exploreSoonTitle;

  /// No description provided for @exploreSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Wine regions, wineries and grapes of Moldova will live here. We\'re still working on this page.'**
  String get exploreSoonBody;

  /// No description provided for @exploreSoonAction.
  ///
  /// In en, this message translates to:
  /// **'Browse the wines'**
  String get exploreSoonAction;

  /// No description provided for @winesTitle.
  ///
  /// In en, this message translates to:
  /// **'Wines'**
  String get winesTitle;

  /// No description provided for @winesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search wines and wineries'**
  String get winesSearchHint;

  /// No description provided for @winesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get winesFilterAll;

  /// No description provided for @winesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The catalogue is growing'**
  String get winesEmptyTitle;

  /// No description provided for @winesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New wines are added directly from the winemakers.'**
  String get winesEmptyBody;

  /// No description provided for @winesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No wines match your search'**
  String get winesNoResults;

  /// No description provided for @winesMineBadge.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get winesMineBadge;

  /// No description provided for @winesYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vintage} other{{count} vintages}}'**
  String winesYears(int count);

  /// No description provided for @typeRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get typeRed;

  /// No description provided for @typeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get typeWhite;

  /// No description provided for @typeRose.
  ///
  /// In en, this message translates to:
  /// **'Rosé'**
  String get typeRose;

  /// No description provided for @typeOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get typeOrange;

  /// No description provided for @typeSparkling.
  ///
  /// In en, this message translates to:
  /// **'Sparkling'**
  String get typeSparkling;

  /// No description provided for @typeDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get typeDessert;

  /// No description provided for @wineOrigin.
  ///
  /// In en, this message translates to:
  /// **'{type} · {region}, Moldova'**
  String wineOrigin(String type, String region);

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get moreGuest;

  /// No description provided for @moreGuestBody.
  ///
  /// In en, this message translates to:
  /// **'No account needed. Your scans and bottles stay on this phone.'**
  String get moreGuestBody;

  /// No description provided for @moreAddBottle.
  ///
  /// In en, this message translates to:
  /// **'Add a wine bottle'**
  String get moreAddBottle;

  /// No description provided for @moreAddBottleBody.
  ///
  /// In en, this message translates to:
  /// **'Barcode, grapes, specs, tasting notes and pairings'**
  String get moreAddBottleBody;

  /// No description provided for @moreMyBottles.
  ///
  /// In en, this message translates to:
  /// **'My bottles'**
  String get moreMyBottles;

  /// No description provided for @moreLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get moreLanguage;

  /// No description provided for @moreTastingGuide.
  ///
  /// In en, this message translates to:
  /// **'Tasting guide'**
  String get moreTastingGuide;

  /// No description provided for @moreTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get moreTerms;

  /// No description provided for @morePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get morePrivacy;

  /// No description provided for @moreAbout.
  ///
  /// In en, this message translates to:
  /// **'About Gustaro'**
  String get moreAbout;

  /// No description provided for @moreClearData.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get moreClearData;

  /// No description provided for @moreClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all your data?'**
  String get moreClearTitle;

  /// No description provided for @moreClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your recent scans, the bottles you added and your preferences from this phone. It can\'t be undone.'**
  String get moreClearBody;

  /// No description provided for @moreClearDone.
  ///
  /// In en, this message translates to:
  /// **'Your data was deleted'**
  String get moreClearDone;

  /// No description provided for @moreResponsible.
  ///
  /// In en, this message translates to:
  /// **'Enjoy wine responsibly. For people of legal drinking age only.'**
  String get moreResponsible;

  /// No description provided for @moreVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String moreVersion(String version);

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Gustaro identifies Moldovan wines. Scan a bottle and see technical specifications, sensory notes and food pairings supplied directly by winemakers. No reviews and no scores.'**
  String get aboutBody;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicenses;

  /// No description provided for @myBottlesTitle.
  ///
  /// In en, this message translates to:
  /// **'My bottles'**
  String get myBottlesTitle;

  /// No description provided for @myBottlesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bottles yet'**
  String get myBottlesEmptyTitle;

  /// No description provided for @myBottlesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a bottle and it can be scanned right away on this phone.'**
  String get myBottlesEmptyBody;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a wine bottle'**
  String get addTitle;

  /// No description provided for @addIntro.
  ///
  /// In en, this message translates to:
  /// **'Bottles you add stay on this phone and work with the scanner right away. They\'re marked “Added by you”, because they don\'t come from a winemaker.'**
  String get addIntro;

  /// No description provided for @addSectionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get addSectionPhoto;

  /// No description provided for @addPhotoHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. A picture of the bottle. It stays on this phone.'**
  String get addPhotoHelp;

  /// No description provided for @addPhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get addPhotoTake;

  /// No description provided for @addPhotoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get addPhotoChoose;

  /// No description provided for @addPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get addPhotoRemove;

  /// No description provided for @addSectionBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get addSectionBarcode;

  /// No description provided for @addSectionWine.
  ///
  /// In en, this message translates to:
  /// **'The wine'**
  String get addSectionWine;

  /// No description provided for @addSectionSpecs.
  ///
  /// In en, this message translates to:
  /// **'Technical specifications'**
  String get addSectionSpecs;

  /// No description provided for @addSectionTasting.
  ///
  /// In en, this message translates to:
  /// **'Tasting'**
  String get addSectionTasting;

  /// No description provided for @addBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode digits'**
  String get addBarcode;

  /// No description provided for @addBarcodeHelp.
  ///
  /// In en, this message translates to:
  /// **'The digits under the bars. Tap the icon to scan them.'**
  String get addBarcodeHelp;

  /// No description provided for @addBarcodeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the barcode'**
  String get addBarcodeScan;

  /// No description provided for @addBarcodeTypo.
  ///
  /// In en, this message translates to:
  /// **'This barcode doesn\'t look right. Check the digits.'**
  String get addBarcodeTypo;

  /// No description provided for @addBottleSize.
  ///
  /// In en, this message translates to:
  /// **'Bottle size (ml)'**
  String get addBottleSize;

  /// No description provided for @addWinery.
  ///
  /// In en, this message translates to:
  /// **'Winery'**
  String get addWinery;

  /// No description provided for @addWineName.
  ///
  /// In en, this message translates to:
  /// **'Wine name'**
  String get addWineName;

  /// No description provided for @addType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get addType;

  /// No description provided for @addYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get addYear;

  /// No description provided for @addRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get addRegion;

  /// No description provided for @addRegionHint.
  ///
  /// In en, this message translates to:
  /// **'Codru, Ștefan Vodă, Valul lui Traian…'**
  String get addRegionHint;

  /// No description provided for @addGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grape varieties'**
  String get addGrapes;

  /// No description provided for @addGrapesHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get addGrapesHint;

  /// No description provided for @addAbv.
  ///
  /// In en, this message translates to:
  /// **'Alcohol (%)'**
  String get addAbv;

  /// No description provided for @addAcidity.
  ///
  /// In en, this message translates to:
  /// **'Acidity (g/L)'**
  String get addAcidity;

  /// No description provided for @addTannins.
  ///
  /// In en, this message translates to:
  /// **'Tannins (g/L)'**
  String get addTannins;

  /// No description provided for @addSugar.
  ///
  /// In en, this message translates to:
  /// **'Residual sugar (g/L)'**
  String get addSugar;

  /// No description provided for @addSensory.
  ///
  /// In en, this message translates to:
  /// **'Sensory notes'**
  String get addSensory;

  /// No description provided for @addSensoryHint.
  ///
  /// In en, this message translates to:
  /// **'Colour, aroma, taste'**
  String get addSensoryHint;

  /// No description provided for @addPairings.
  ///
  /// In en, this message translates to:
  /// **'Food pairings'**
  String get addPairings;

  /// No description provided for @addPairingsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get addPairingsHint;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get addDescription;

  /// No description provided for @addSave.
  ///
  /// In en, this message translates to:
  /// **'Save bottle'**
  String get addSave;

  /// No description provided for @addRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get addRequired;

  /// No description provided for @addInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get addInvalidNumber;

  /// No description provided for @addInvalidYear.
  ///
  /// In en, this message translates to:
  /// **'Enter a year between 1900 and {max}'**
  String addInvalidYear(int max);

  /// No description provided for @addInvalidAbv.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 0 and 100'**
  String get addInvalidAbv;

  /// No description provided for @addTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a type'**
  String get addTypeRequired;

  /// No description provided for @addFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields'**
  String get addFixErrors;

  /// No description provided for @addSaved.
  ///
  /// In en, this message translates to:
  /// **'Bottle saved. Try scanning it!'**
  String get addSaved;

  /// No description provided for @addDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already added this wine and year.'**
  String get addDuplicate;

  /// No description provided for @addDuplicateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get addDuplicateOpen;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the barcode'**
  String get scanHint;

  /// No description provided for @scanHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find a barcode? Read the label instead.'**
  String get scanHintLabel;

  /// No description provided for @scanCaptureHint.
  ///
  /// In en, this message translates to:
  /// **'Scan the barcode on the bottle'**
  String get scanCaptureHint;

  /// No description provided for @scanReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Read the label'**
  String get scanReadLabel;

  /// No description provided for @scanEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Type the code'**
  String get scanEnterCode;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get scanTorch;

  /// No description provided for @scanLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking it up…'**
  String get scanLooking;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the label…'**
  String get scanReading;

  /// No description provided for @scanManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Type the barcode'**
  String get scanManualTitle;

  /// No description provided for @scanManualBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the digits printed under the bars.'**
  String get scanManualBody;

  /// No description provided for @scanManualAction.
  ///
  /// In en, this message translates to:
  /// **'Look it up'**
  String get scanManualAction;

  /// No description provided for @scanNoCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get scanNoCameraTitle;

  /// No description provided for @scanNoCameraBody.
  ///
  /// In en, this message translates to:
  /// **'You can still type the barcode or choose a photo of the label.'**
  String get scanNoCameraBody;

  /// No description provided for @scanNoPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gustaro needs the camera'**
  String get scanNoPermissionTitle;

  /// No description provided for @scanNoPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings to scan bottles. Images stay on your phone.'**
  String get scanNoPermissionBody;

  /// No description provided for @scanOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get scanOpenSettings;

  /// No description provided for @scanChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get scanChoosePhoto;

  /// No description provided for @pickVintageTitle.
  ///
  /// In en, this message translates to:
  /// **'Which year is your bottle?'**
  String get pickVintageTitle;

  /// No description provided for @pickVintageLabelRead.
  ///
  /// In en, this message translates to:
  /// **'Read on the label'**
  String get pickVintageLabelRead;

  /// No description provided for @pickWineBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Several wines share this barcode'**
  String get pickWineBarcodeTitle;

  /// No description provided for @pickWineLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Is it one of these?'**
  String get pickWineLabelTitle;

  /// No description provided for @pickWineNone.
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get pickWineNone;

  /// No description provided for @missTitle.
  ///
  /// In en, this message translates to:
  /// **'Not in our catalogue yet'**
  String get missTitle;

  /// No description provided for @missBodyBarcode.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have this bottle yet. Reading the label might still find it.'**
  String get missBodyBarcode;

  /// No description provided for @missBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t match this label to a wine in the catalogue.'**
  String get missBodyLabel;

  /// No description provided for @missCode.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code}'**
  String missCode(String code);

  /// No description provided for @missTryLabel.
  ///
  /// In en, this message translates to:
  /// **'Read the label'**
  String get missTryLabel;

  /// No description provided for @missAddBottle.
  ///
  /// In en, this message translates to:
  /// **'Add this bottle'**
  String get missAddBottle;

  /// No description provided for @missScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan another bottle'**
  String get missScanAgain;

  /// No description provided for @wineVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified by the winemaker'**
  String get wineVerified;

  /// No description provided for @wineUnverified.
  ///
  /// In en, this message translates to:
  /// **'Added by you · not verified'**
  String get wineUnverified;

  /// No description provided for @wineSpecs.
  ///
  /// In en, this message translates to:
  /// **'Technical specifications'**
  String get wineSpecs;

  /// No description provided for @wineAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get wineAlcohol;

  /// No description provided for @wineAcidity.
  ///
  /// In en, this message translates to:
  /// **'Acidity'**
  String get wineAcidity;

  /// No description provided for @wineTannins.
  ///
  /// In en, this message translates to:
  /// **'Tannins'**
  String get wineTannins;

  /// No description provided for @wineSugar.
  ///
  /// In en, this message translates to:
  /// **'Residual sugar'**
  String get wineSugar;

  /// No description provided for @wineGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grape varieties'**
  String get wineGrapes;

  /// No description provided for @wineSensory.
  ///
  /// In en, this message translates to:
  /// **'Sensory notes'**
  String get wineSensory;

  /// No description provided for @winePairings.
  ///
  /// In en, this message translates to:
  /// **'Food pairings'**
  String get winePairings;

  /// No description provided for @wineAbout.
  ///
  /// In en, this message translates to:
  /// **'About this wine'**
  String get wineAbout;

  /// No description provided for @wineLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Wine texts are shown in Romanian for now. English is on its way.'**
  String get wineLanguageNote;

  /// No description provided for @wineSourceVerified.
  ///
  /// In en, this message translates to:
  /// **'All information comes directly from the winemaker.'**
  String get wineSourceVerified;

  /// No description provided for @wineSourceMine.
  ///
  /// In en, this message translates to:
  /// **'You entered this information. It only exists on this phone.'**
  String get wineSourceMine;

  /// No description provided for @wineDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this bottle'**
  String get wineDelete;

  /// No description provided for @wineDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this bottle?'**
  String get wineDeleteTitle;

  /// No description provided for @wineDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from this phone.'**
  String get wineDeleteBody;

  /// No description provided for @wineNotFound.
  ///
  /// In en, this message translates to:
  /// **'This wine is no longer available.'**
  String get wineNotFound;

  /// No description provided for @tastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasting guide'**
  String get tastingTitle;

  /// No description provided for @tastingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tastingStep(int current, int total);

  /// No description provided for @tastingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tastingNext;

  /// No description provided for @tastingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tastingDone;

  /// No description provided for @tastingResponsible.
  ///
  /// In en, this message translates to:
  /// **'Enjoy responsibly. For people of legal drinking age only.'**
  String get tastingResponsible;

  /// No description provided for @tastingLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get tastingLook;

  /// No description provided for @tastingSwirl.
  ///
  /// In en, this message translates to:
  /// **'Swirl'**
  String get tastingSwirl;

  /// No description provided for @tastingSmell.
  ///
  /// In en, this message translates to:
  /// **'Smell'**
  String get tastingSmell;

  /// No description provided for @tastingSip.
  ///
  /// In en, this message translates to:
  /// **'Sip'**
  String get tastingSip;

  /// No description provided for @tastingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tastingFinish;

  /// No description provided for @tasting1Look.
  ///
  /// In en, this message translates to:
  /// **'Hold the glass against something white. Notice the colour: deep or pale, bright or cloudy.'**
  String get tasting1Look;

  /// No description provided for @tasting1Swirl.
  ///
  /// In en, this message translates to:
  /// **'Move the glass in small circles. This wakes up the aromas and shows how the wine clings to the glass.'**
  String get tasting1Swirl;

  /// No description provided for @tasting1Smell.
  ///
  /// In en, this message translates to:
  /// **'Bring the glass to your nose and breathe in gently. Look for fruit first, then flowers, spice or oak.'**
  String get tasting1Smell;

  /// No description provided for @tasting1Sip.
  ///
  /// In en, this message translates to:
  /// **'Take a small sip and let it cover your whole mouth. Is it sweet or dry, fresh or soft, light or full?'**
  String get tasting1Sip;

  /// No description provided for @tasting1Finish.
  ///
  /// In en, this message translates to:
  /// **'Swallow and wait. How long does the taste stay? A long finish usually means a well-made wine.'**
  String get tasting1Finish;

  /// No description provided for @tasting2Look.
  ///
  /// In en, this message translates to:
  /// **'Fetească Neagră is usually a deep ruby. Tilt the glass and look at the colour near the rim.'**
  String get tasting2Look;

  /// No description provided for @tasting2Swirl.
  ///
  /// In en, this message translates to:
  /// **'Swirl gently for a few seconds. Reds open up with a little air, so take your time.'**
  String get tasting2Swirl;

  /// No description provided for @tasting2Smell.
  ///
  /// In en, this message translates to:
  /// **'Look for dark fruit such as plum and black cherry. Older wines may add spice and dried fruit.'**
  String get tasting2Smell;

  /// No description provided for @tasting2Sip.
  ///
  /// In en, this message translates to:
  /// **'Notice the tannins: that gentle grip on your gums. They give red wine its structure.'**
  String get tasting2Sip;

  /// No description provided for @tasting2Finish.
  ///
  /// In en, this message translates to:
  /// **'Think about what you\'d eat with it. Rich reds like this one love grilled meat and aged cheese.'**
  String get tasting2Finish;

  /// No description provided for @tasting3Look.
  ///
  /// In en, this message translates to:
  /// **'Pour into a tall glass and watch the bubbles. Fine, steady bubbles are a good sign.'**
  String get tasting3Look;

  /// No description provided for @tasting3Swirl.
  ///
  /// In en, this message translates to:
  /// **'Skip the swirl here. Hold the glass still so you keep the bubbles.'**
  String get tasting3Swirl;

  /// No description provided for @tasting3Smell.
  ///
  /// In en, this message translates to:
  /// **'Look for green apple and citrus. Bottle-aged sparkling can also smell of toast or brioche.'**
  String get tasting3Smell;

  /// No description provided for @tasting3Sip.
  ///
  /// In en, this message translates to:
  /// **'Take a small sip and feel the bubbles on your tongue. Is it dry and fresh, or a little sweet?'**
  String get tasting3Sip;

  /// No description provided for @tasting3Finish.
  ///
  /// In en, this message translates to:
  /// **'Notice how clean your mouth feels afterwards. That freshness makes sparkling great with food.'**
  String get tasting3Finish;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onb1Title.
  ///
  /// In en, this message translates to:
  /// **'Know what\'s in the bottle'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In en, this message translates to:
  /// **'Scan any Moldovan wine in the store and see what it is in seconds.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In en, this message translates to:
  /// **'Straight from the winemaker'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In en, this message translates to:
  /// **'Specs, sensory notes and food pairings supplied by winemakers. No reviews, no scores.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In en, this message translates to:
  /// **'Works everywhere'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In en, this message translates to:
  /// **'The catalogue lives on your phone, so scanning works even with no signal. No account needed.'**
  String get onb3Body;

  /// No description provided for @onbLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'One last thing'**
  String get onbLegalTitle;

  /// No description provided for @onbLegalBody.
  ///
  /// In en, this message translates to:
  /// **'Gustaro is about wine, so it\'s for adults only.'**
  String get onbLegalBody;

  /// No description provided for @onbAge.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older and of legal drinking age in my country.'**
  String get onbAge;

  /// No description provided for @onbTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get onbTermsPrefix;

  /// No description provided for @onbTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get onbTerms;

  /// No description provided for @onbTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get onbTermsAnd;

  /// No description provided for @onbPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onbPrivacy;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get onbStart;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In en, this message translates to:
  /// **'Gustaro couldn\'t open its catalogue. Please restart the app.'**
  String get errorBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

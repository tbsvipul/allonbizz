import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'routent'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Navigate smarter. Discover deals along every route.'**
  String get tagline;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Smart Navigation'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Get the best routes with real-time traffic and AI-powered suggestions.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Discover Exclusive Deals'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Find the best offers and discounts right around you.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Save Big Every Day'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Track your savings and watch your points grow.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Augmented Discovery'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'See offers floating in the real world around you.'**
  String get onboardingDesc4;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @welcomeBackShort.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your journey'**
  String get welcomeBackShort;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @emailValidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailValidError;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordValidError.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get passwordValidError;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get fullNameHint;

  /// No description provided for @fullNameValidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name (min 3 characters)'**
  String get fullNameValidError;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @dontHaveAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccountPrefix;

  /// No description provided for @alreadyHaveAccountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountPrefix;

  /// No description provided for @joinAppPrefix.
  ///
  /// In en, this message translates to:
  /// **'Join '**
  String get joinAppPrefix;

  /// No description provided for @joinAppSuffix.
  ///
  /// In en, this message translates to:
  /// **' to discover the best deals!'**
  String get joinAppSuffix;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginLink;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get noInternet;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your credentials.'**
  String get authFailed;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found for that email.'**
  String get authUserNotFound;

  /// No description provided for @authInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'The password or email is incorrect.'**
  String get authInvalidCredential;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'The account already exists for that email.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey'**
  String get startJourney;

  /// No description provided for @whereToGo.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get whereToGo;

  /// No description provided for @bestDealsNearby.
  ///
  /// In en, this message translates to:
  /// **'Best Deals Near You'**
  String get bestDealsNearby;

  /// No description provided for @trendingOnRoute.
  ///
  /// In en, this message translates to:
  /// **'Trending On Route'**
  String get trendingOnRoute;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @discoverDealsDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover deals along your route'**
  String get discoverDealsDesc;

  /// No description provided for @routePreview.
  ///
  /// In en, this message translates to:
  /// **'Route Preview'**
  String get routePreview;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @setDestination.
  ///
  /// In en, this message translates to:
  /// **'Set your destination'**
  String get setDestination;

  /// No description provided for @detectingOffers.
  ///
  /// In en, this message translates to:
  /// **'Detecting offers on route'**
  String get detectingOffers;

  /// No description provided for @tapSearchRoute.
  ///
  /// In en, this message translates to:
  /// **'Tap search to choose a route'**
  String get tapSearchRoute;

  /// No description provided for @offersOnRoute.
  ///
  /// In en, this message translates to:
  /// **'Offers On This Route'**
  String get offersOnRoute;

  /// No description provided for @noOffersDetected.
  ///
  /// In en, this message translates to:
  /// **'No offers detected yet'**
  String get noOffersDetected;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @dealsCount.
  ///
  /// In en, this message translates to:
  /// **'deals'**
  String get dealsCount;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search deals, shops, cuisines...'**
  String get searchHint;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search Destination'**
  String get searchDestination;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @routeOptions.
  ///
  /// In en, this message translates to:
  /// **'Route Options'**
  String get routeOptions;

  /// No description provided for @fastestRoute.
  ///
  /// In en, this message translates to:
  /// **'Fastest Route'**
  String get fastestRoute;

  /// No description provided for @mostDeals.
  ///
  /// In en, this message translates to:
  /// **'Most Deals'**
  String get mostDeals;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @arScanSurroundings.
  ///
  /// In en, this message translates to:
  /// **'Scan your surroundings for deals'**
  String get arScanSurroundings;

  /// No description provided for @arActiveDealsCount.
  ///
  /// In en, this message translates to:
  /// **'{area} • {count} Active Deals'**
  String arActiveDealsCount(Object area, Object count);

  /// No description provided for @cameraFeedPerspective.
  ///
  /// In en, this message translates to:
  /// **'Camera Feed Perspective'**
  String get cameraFeedPerspective;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catSight.
  ///
  /// In en, this message translates to:
  /// **'Sight'**
  String get catSight;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catCafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get catCafes;

  /// No description provided for @catWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get catWellness;

  /// No description provided for @catFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get catFun;

  /// No description provided for @catHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get catHotels;

  /// No description provided for @catMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get catMore;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @pastJourneys.
  ///
  /// In en, this message translates to:
  /// **'Past Journeys'**
  String get pastJourneys;

  /// No description provided for @availablePoints.
  ///
  /// In en, this message translates to:
  /// **'Available Points'**
  String get availablePoints;

  /// No description provided for @readyToUse.
  ///
  /// In en, this message translates to:
  /// **'Ready to Use'**
  String get readyToUse;

  /// No description provided for @viewExpiredDeals.
  ///
  /// In en, this message translates to:
  /// **'View Expired Deals'**
  String get viewExpiredDeals;

  /// No description provided for @tripTo.
  ///
  /// In en, this message translates to:
  /// **'Trip to'**
  String get tripTo;

  /// No description provided for @groupActive.
  ///
  /// In en, this message translates to:
  /// **'Group: {count} Active'**
  String groupActive(Object count);

  /// No description provided for @participant.
  ///
  /// In en, this message translates to:
  /// **'Participant'**
  String get participant;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @useNow.
  ///
  /// In en, this message translates to:
  /// **'Use Now'**
  String get useNow;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get noNotifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @totalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total Saved'**
  String get totalSaved;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @showQrAtCounter.
  ///
  /// In en, this message translates to:
  /// **'Show this QR at the counter'**
  String get showQrAtCounter;

  /// No description provided for @redeemNow.
  ///
  /// In en, this message translates to:
  /// **'Redeem Now'**
  String get redeemNow;

  /// No description provided for @offerRedeemedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer Redeemed Successfully!'**
  String get offerRedeemedSuccess;

  /// No description provided for @offerRedeemedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to redeem offer'**
  String get offerRedeemedFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navNavigate;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @startingLocation.
  ///
  /// In en, this message translates to:
  /// **'Starting Location'**
  String get startingLocation;

  /// No description provided for @startLocation.
  ///
  /// In en, this message translates to:
  /// **'Starting Location'**
  String get startLocation;

  /// No description provided for @destinationLocation.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get fetchingLocation;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @enterDestination.
  ///
  /// In en, this message translates to:
  /// **'Enter destination'**
  String get enterDestination;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @endJourney.
  ///
  /// In en, this message translates to:
  /// **'End Journey'**
  String get endJourney;

  /// No description provided for @locationSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Location Suggestions'**
  String get locationSuggestions;

  /// No description provided for @noPastJourneys.
  ///
  /// In en, this message translates to:
  /// **'No past journeys detected yet'**
  String get noPastJourneys;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

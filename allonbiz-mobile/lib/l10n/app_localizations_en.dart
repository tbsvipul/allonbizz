// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'routent';

  @override
  String get tagline => 'Navigate smarter. Discover deals along every route.';

  @override
  String get onboardingTitle1 => 'Smart Navigation';

  @override
  String get onboardingDesc1 =>
      'Get the best routes with real-time traffic and AI-powered suggestions.';

  @override
  String get onboardingTitle2 => 'Discover Exclusive Deals';

  @override
  String get onboardingDesc2 =>
      'Find the best offers and discounts right around you.';

  @override
  String get onboardingTitle3 => 'Save Big Every Day';

  @override
  String get onboardingDesc3 =>
      'Track your savings and watch your points grow.';

  @override
  String get onboardingTitle4 => 'Augmented Discovery';

  @override
  String get onboardingDesc4 =>
      'See offers floating in the real world around you.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get welcomeBackShort => 'Welcome back to your journey';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get registerButton => 'Register';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailValidError => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordValidError => 'Must be at least 6 characters';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get fullNameValidError => 'Enter a valid name (min 3 characters)';

  @override
  String get createAccount => 'Create Account';

  @override
  String get orDivider => 'OR';

  @override
  String get dontHaveAccountPrefix => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccountPrefix => 'Already have an account? ';

  @override
  String get joinAppPrefix => 'Join ';

  @override
  String get joinAppSuffix => ' to discover the best deals!';

  @override
  String get loginLink => 'Log In';

  @override
  String get registerLink => 'Register';

  @override
  String get noInternet => 'No internet connection. Please check your network.';

  @override
  String get authFailed =>
      'Authentication failed. Please check your credentials.';

  @override
  String get authUserNotFound => 'No user found for that email.';

  @override
  String get authInvalidCredential => 'The password or email is incorrect.';

  @override
  String get authEmailAlreadyInUse =>
      'The account already exists for that email.';

  @override
  String get startJourney => 'Start Your Journey';

  @override
  String get whereToGo => 'Where do you want to go?';

  @override
  String get bestDealsNearby => 'Best Deals Near You';

  @override
  String get trendingOnRoute => 'Trending On Route';

  @override
  String get seeAll => 'See All';

  @override
  String get discoverDealsDesc => 'Discover deals along your route';

  @override
  String get routePreview => 'Route Preview';

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String get setDestination => 'Set your destination';

  @override
  String get detectingOffers => 'Detecting offers on route';

  @override
  String get tapSearchRoute => 'Tap search to choose a route';

  @override
  String get offersOnRoute => 'Offers On This Route';

  @override
  String get noOffersDetected => 'No offers detected yet';

  @override
  String get nearby => 'Nearby';

  @override
  String get dealsCount => 'deals';

  @override
  String get searchHint => 'Search deals, shops, cuisines...';

  @override
  String get searchDestination => 'Search Destination';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get routeOptions => 'Route Options';

  @override
  String get fastestRoute => 'Fastest Route';

  @override
  String get mostDeals => 'Most Deals';

  @override
  String get best => 'BEST';

  @override
  String get arScanSurroundings => 'Scan your surroundings for deals';

  @override
  String arActiveDealsCount(Object area, Object count) {
    return '$area • $count Active Deals';
  }

  @override
  String get cameraFeedPerspective => 'Camera Feed Perspective';

  @override
  String get categories => 'Categories';

  @override
  String get trending => 'Trending';

  @override
  String get recommendedForYou => 'Recommended For You';

  @override
  String get catFood => 'Food';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catSight => 'Sight';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catCafes => 'Cafes';

  @override
  String get catWellness => 'Wellness';

  @override
  String get catFun => 'Fun';

  @override
  String get catHotels => 'Hotels';

  @override
  String get catMore => 'More';

  @override
  String get trips => 'Trips';

  @override
  String get myWallet => 'My Wallet';

  @override
  String get pastJourneys => 'Past Journeys';

  @override
  String get availablePoints => 'Available Points';

  @override
  String get readyToUse => 'Ready to Use';

  @override
  String get viewExpiredDeals => 'View Expired Deals';

  @override
  String get tripTo => 'Trip to';

  @override
  String groupActive(Object count) {
    return 'Group: $count Active';
  }

  @override
  String get participant => 'Participant';

  @override
  String get distance => 'Distance';

  @override
  String get saved => 'Saved';

  @override
  String get points => 'Points';

  @override
  String get useNow => 'Use Now';

  @override
  String get profile => 'Profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'You have no new notifications.';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get signOut => 'Sign Out';

  @override
  String get totalSaved => 'Total Saved';

  @override
  String get settings => 'Settings';

  @override
  String get details => 'Details';

  @override
  String get showQrAtCounter => 'Show this QR at the counter';

  @override
  String get redeemNow => 'Redeem Now';

  @override
  String get offerRedeemedSuccess => 'Offer Redeemed Successfully!';

  @override
  String get offerRedeemedFailed => 'Failed to redeem offer';

  @override
  String get navHome => 'Home';

  @override
  String get navNavigate => 'Navigate';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navTrips => 'Trips';

  @override
  String get navMe => 'Me';

  @override
  String get startingLocation => 'Starting Location';

  @override
  String get startLocation => 'Starting Location';

  @override
  String get destinationLocation => 'Destination';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get fetchingLocation => 'Fetching location...';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get enterDestination => 'Enter destination';

  @override
  String get locationPermissionRequired => 'Location permission required';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get endJourney => 'End Journey';

  @override
  String get locationSuggestions => 'Location Suggestions';

  @override
  String get noPastJourneys => 'No past journeys detected yet';
}

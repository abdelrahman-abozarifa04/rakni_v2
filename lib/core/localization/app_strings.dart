import 'package:rakni_v2/core/localization/locale_service.dart';

/// Single source of truth for every user-facing string in the app.
///
/// HOW TO EXTEND (read before adding any new screen):
///   1. Add ONE static getter per string.
///   2. Return Egyptian colloquial Arabic when `_ar` is true, English
///      otherwise. NEVER write Modern Standard Arabic / textbook Arabic —
///      use everyday spoken Egyptian Arabic, borrow common Egyptian tech
///      slang where natural (باسورد، إيميل، بوكينج) instead of forcing a
///      formal translation.
///   3. Reference it as `AppStrings.yourKey` in the widget instead of a
///      raw string literal. That is the ENTIRE integration — no extra
///      registration anywhere.
class AppStrings {
  AppStrings._();

  static bool get _ar => LocaleService.instance.isArabic;

  // ── Onboarding ──────────────────────────────────────────────
  static String get onboardingTitle => _ar
      ? 'هتلاقي مكان الباركينج اللي يناسبك'
      : 'Find Your Perfect Parking Spot';
  static String get onboardingSubtitle => _ar
      ? 'حل شاطر للباركينج في القاهرة، مصر'
      : 'Smart parking solution for Cairo, Egypt';
  static String get getStarted => _ar ? 'يلا بينا' : 'Get Started';
  static String get alreadyHaveAccount =>
      _ar ? 'عندك حساب؟ ' : 'Already have an account? ';
  static String get signInAction => _ar ? 'سجل دخولك' : 'Sign In';
  static String get byContiuning =>
      _ar ? 'بالمتابعة، أنت موافق على ' : 'By continuing, you agree to our ';
  static String get terms => _ar ? 'الشروط' : 'Terms';
  static String get and => _ar ? ' و ' : ' & ';
  static String get privacyPolicy => _ar ? 'سياسة الخصوصية' : 'Privacy Policy';

  // ── Auth ────────────────────────────────────────────────────
  static String get welcomeBack => _ar ? 'أهلاً بيك تاني' : 'Welcome Back';
  static String get signInSubtitle =>
      _ar ? 'سجل دخولك وابدأ تلاقي باركينج' : 'Sign in to find parking';
  static String get email => _ar ? 'الإيميل' : 'Email';
  static String get forgotPassword => _ar ? 'ناسي الباسورد؟' : 'Forgot password?';
  static String get signIn => _ar ? 'دخول' : 'Sign In';
  static String get or => _ar ? 'أو' : 'or';
  static String get continueWithGoogle =>
      _ar ? 'كمّل بحساب جوجل' : 'Continue with Google';
  static String get noAccount =>
      _ar ? 'لسه معملتش حساب؟ ' : "Don't have an account? ";
  static String get signUp => _ar ? 'اعمل حساب' : 'Sign up';

  // ── Create Account ──────────────────────────────────────────
  static String get createAccount => _ar ? 'اعمل حساب' : 'Create Account';
  static String get createAccountSubtitle =>
      _ar ? 'سجل وابدأ تحجز باركينج بسهولة' : 'Register and start booking parking easily';
  static String get fullName => _ar ? 'الاسم الكامل' : 'Full Name';
  static String get phoneNumber => _ar ? 'رقم الموبايل' : 'Phone Number';
  static String get confirmPassword => _ar ? 'تأكيد الباسورد' : 'Confirm Password';
  static String get next => _ar ? 'التالي' : 'Next';
  static String get back => _ar ? 'رجوع' : 'Back';
  static String get alreadyHaveAccountQ =>
      _ar ? 'عندك حساب؟ ' : 'Already have an account? ';

  // ── Reset / New Password ────────────────────────────────────
  static String get resetPassword => _ar ? 'استعادة الباسورد' : 'Reset Password';
  static String get resetPasswordSubtitle =>
      _ar ? 'هنبعتلك لينك على إيميلك' : "We'll send a reset link to your email";
  static String get sendResetLink => _ar ? 'ابعت اللينك' : 'Send Reset Link';
  static String get newPassword => _ar ? 'الباسورد الجديد' : 'New Password';
  static String get setNewPassword => _ar ? 'حدّد باسورد جديد' : 'Set New Password';
  static String get setNewPasswordSubtitle =>
      _ar ? 'الباسورد الجديد لازم يكون مختلف عن القديم' : 'Your new password must differ from the old one';

  // ── Verification ────────────────────────────────────────────
  static String get verifyPhone => _ar ? 'تأكيد الموبايل' : 'Verify Phone';
  static String get verifyPhoneSubtitle =>
      _ar ? 'اكتب الكود اللي وصلك' : 'Enter the code we sent you';
  static String get verify => _ar ? 'تأكيد' : 'Verify';
  static String get resendCode => _ar ? 'ابعت الكود تاني' : 'Resend Code';
  static String get didntReceiveCode =>
      _ar ? 'ماجاكش الكود؟ ' : "Didn't receive code? ";

  // ── Add Car ─────────────────────────────────────────────────
  static String get addCar => _ar ? 'ضيف عربية' : 'Add Car';
  static String get addCarSubtitle =>
      _ar ? 'ضيف عربيتك عشان تحجز باركينج' : 'Add your car to book parking';
  static String get carBrand => _ar ? 'الماركة' : 'Brand';
  static String get carModel => _ar ? 'الموديل' : 'Model';
  static String get carColor => _ar ? 'اللون' : 'Color';
  static String get plateNumber => _ar ? 'رقم اللوحة' : 'Plate Number';

  // ── Bottom Nav ──────────────────────────────────────────────
  static String get navHome => _ar ? 'الرئيسية' : 'Home';
  static String get navMap => _ar ? 'الخريطة' : 'Map';
  static String get navBookings => _ar ? 'الحجوزات' : 'Bookings';
  static String get navVehicles => _ar ? 'عربيتي' : 'Vehicles';
  static String get navProfile => _ar ? 'حسابي' : 'Profile';

  // ── Home ────────────────────────────────────────────────────
  static String get nearbyParking => _ar ? 'باركينج قريب منك' : 'Nearby Parking';
  static String get seeAll => _ar ? 'شوف الكل' : 'See all';
  static String get quickActions => _ar ? 'خدمات سريعة' : 'Quick Actions';
  static String get findParking => _ar ? 'دور على\nباركينج' : 'Find\nParking';
  static String get reserveSpot => _ar ? 'احجز\nمكان' : 'Reserve\nSpot';
  static String get favourites => _ar ? 'المفضلة' : 'Favourites';
  static String get history => _ar ? 'السجل' : 'History';
  static String get featuredMalls => _ar ? 'مولات مميزة' : 'Featured Malls';
  static String get searchParkingHint =>
      _ar ? 'دور على مكان باركينج...' : 'Search for a parking spot...';
  static String get activeSession => _ar ? 'الجلسة الشغالة' : 'Active Session';
  static String get endSession => _ar ? 'خلاص' : 'End';
  static String get gettingLocation => _ar ? 'بنجيب موقعك...' : 'Getting location...';
  static String get locationDisabled =>
      _ar ? 'الموقع مش شغال' : 'Location disabled';
  static String get locationPermissionNeeded =>
      _ar ? 'محتاجين إذن الموقع' : 'Location permission needed';
  static String get enableLocationInSettings =>
      _ar ? 'فعّل الموقع من الإعدادات' : 'Enable location in settings';
  static String get cairoEgypt => _ar ? 'القاهرة، مصر' : 'Cairo, Egypt';
  static String get noParking =>
      _ar ? 'مفيش باركينج متاح' : 'No parking lots available';

  // ── Map ─────────────────────────────────────────────────────
  static String get locatingYou => _ar ? 'بنجيب موقعك…' : 'Locating you…';
  static String get routingTo => _ar ? 'بنوجهك لـ: ' : 'Routing to: ';
  static String get getDirections => _ar ? 'اعملي خريطة' : 'Get Directions';
  static String get spotsAvailable => _ar ? 'مكان متاح' : 'spots available';
  static String get open24 => _ar ? 'مفتوح 24/7' : 'Open 24/7';

  // ── Bookings ────────────────────────────────────────────────
  static String get bookings => _ar ? 'الحجوزات' : 'Bookings';
  static String get noBookings => _ar ? 'مفيش حجوزات لسه' : 'No bookings yet';
  static String get active => _ar ? 'شغّالة' : 'Active';
  static String get upcoming => _ar ? 'قادمة' : 'Upcoming';
  static String get completed => _ar ? 'خلصت' : 'Completed';
  static String get cancelled => _ar ? 'اتلغت' : 'Cancelled';
  static String get bookNow => _ar ? 'احجز دلوقتي' : 'Book Now';

  // ── Profile ─────────────────────────────────────────────────
  static String get profile => _ar ? 'حسابي' : 'Profile';
  static String get editProfile => _ar ? 'عدّل الحساب' : 'Edit Profile';
  static String get myVehicles => _ar ? 'عربياتي' : 'My Vehicles';
  static String get paymentMethods => _ar ? 'طرق الدفع' : 'Payment Methods';
  static String get helpSupport => _ar ? 'مساعدة ودعم' : 'Help & Support';
  static String get logout => _ar ? 'خروج' : 'Log Out';
  static String get wallet => _ar ? 'المحفظة' : 'Wallet';
  static String get transactions => _ar ? 'المعاملات' : 'Transactions';

  // ── Settings ────────────────────────────────────────────────
  static String get settings => _ar ? 'الإعدادات' : 'Settings';
  static String get notifications => _ar ? 'الإشعارات' : 'Notifications';
  static String get pushNotifications => _ar ? 'إشعارات فورية' : 'Push Notifications';
  static String get pushNotificationsSubtitle =>
      _ar ? 'استقبل التنبيهات على موبايلك' : 'Receive push alerts on your device';
  static String get emailNotifications => _ar ? 'إشعارات الإيميل' : 'Email Notifications';
  static String get emailNotificationsSubtitle =>
      _ar ? 'وصلك تحديثات الحجز على الإيميل' : 'Get booking updates via email';
  static String get parkingReminders => _ar ? 'تذكير الباركينج' : 'Parking Reminders';
  static String get parkingRemindersSubtitle =>
      _ar ? 'تنبيه قبل ما الجلسة تخلص' : 'Alert before parking session ends';
  static String get promotions => _ar ? 'العروض والخصومات' : 'Promotions & Offers';
  static String get promotionsSubtitle =>
      _ar ? 'استقبل أحدث الصفقات والخصومات' : 'Receive special deals and discounts';
  static String get privacySecurity => _ar ? 'الخصوصية والأمان' : 'Privacy & Security';
  static String get locationServices => _ar ? 'خدمات الموقع' : 'Location Services';
  static String get locationServicesSubtitle =>
      _ar ? 'سمح للتطبيق يوصل لموقعك' : 'Allow app to access your location';
  static String get changePassword => _ar ? 'غيّر الباسورد' : 'Change Password';
  static String get twoFactorAuth =>
      _ar ? 'التحقق بخطوتين' : 'Two-Factor Authentication';
  static String get loginActivity => _ar ? 'سجل الدخول' : 'Login Activity';
  static String get appearance => _ar ? 'المظهر' : 'Appearance';
  static String get darkMode => _ar ? 'الوضع الليلي' : 'Dark Mode';
  static String get darkModeSubtitle =>
      _ar ? 'استخدم المظهر الداكن في التطبيق كله' : 'Use dark theme throughout the app';
  static String get regional => _ar ? 'إعدادات المنطقة' : 'Regional';
  static String get language => _ar ? 'اللغة' : 'Language';
  static String get currency => _ar ? 'العملة' : 'Currency';
  static String get legal => _ar ? 'قانوني' : 'Legal';
  static String get termsOfService => _ar ? 'شروط الاستخدام' : 'Terms of Service';
  static String get account => _ar ? 'الحساب' : 'Account';
  static String get deleteAccount => _ar ? 'حذف الحساب' : 'Delete Account';
  static String get deleteAccountContent => _ar
      ? 'الإجراء ده نهائي ومش هيتراجع فيه. كل بياناتك هتتمسح.'
      : 'This action is permanent and cannot be undone. All your data will be deleted.';
  static String get cancel => _ar ? 'إلغاء' : 'Cancel';
  static String get delete => _ar ? 'حذف' : 'Delete';
  static String get update => _ar ? 'تحديث' : 'Update';
  static String get currentPassword => _ar ? 'الباسورد الحالي' : 'Current Password';
  static String get newPasswordLabel => _ar ? 'الباسورد الجديد' : 'New Password';
  static String get confirmNewPassword =>
      _ar ? 'تأكيد الباسورد الجديد' : 'Confirm New Password';
  static String get passwordChanged =>
      _ar ? 'اتغير الباسورد!' : 'Password changed!';

  // ── Notifications ───────────────────────────────────────────
  static String get notificationsTitle => _ar ? 'الإشعارات' : 'Notifications';
  static String get noNotifications =>
      _ar ? 'مفيش إشعارات لسه' : 'No notifications yet';
  static String get markAllRead => _ar ? 'علّم الكل كمقروء' : 'Mark all as read';

  // ⬆ Keep adding new keys here as new screens/features ship. Do not
  // hardcode raw strings in any widget from this point forward.
}

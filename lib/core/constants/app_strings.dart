// ─────────────────────────────────────────────
// App-wide string constants
// ─────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  // App
  static const appName        = 'Festivo';
  static const appTagline     = 'Premium Event Venues';
  static const appCopyright   = '© 2026 Festivo. Premium Event Venue Platform';
  static const appVersion     = 'v2.0.0';

  // Auth – Login
  static const welcomeBack        = 'Welcome Back';
  static const signInToContinue   = 'Sign in to continue to Festivo';
  static const secureAuth         = 'Secure Authentication';
  static const selectYourRole     = 'Select Your Role';
  static const emailAddress       = 'Email Address';
  static const emailHint          = 'your@email.com';
  static const password           = 'Password';
  static const passwordHint       = '••••••••';
  static const signIn             = 'Sign In';
  static const forgotPassword     = 'Forgot Password?';
  static const dontHaveAccount    = "Don't have an account?";
  static const createAccount      = 'Create Account';

  // Auth – Roles
  static const roleCustomer      = 'Customer';
  static const roleVenueOwner    = 'Venue Owner';
  static const roleAdministrator = 'Administrator';

  // Auth – Create Account
  static const joinFestivo       = 'Join Festivo to discover premium venues';
  static const fullName          = 'Full Name';
  static const fullNameHint      = 'Your full name';
  static const phoneNumber       = 'Phone Number';
  static const phoneHint         = '+20 1XX XXX XXXX';
  static const passwordMinHint   = 'Min 8 characters';
  static const confirmPassword   = 'Confirm Password';
  static const confirmPassHint   = 'Re-enter password';
  static const accountType       = 'Account Type';
  static const alreadyHaveAcc    = 'Already have an account? ';
  static const accountCreated    = 'Account created successfully! Please sign in.';

  // Auth – Forgot Password
  static const forgotPasswordQ   = 'Forgot Password?';
  static const resetLinkSent     = "We'll send a reset link to your email";
  static const enterYourEmail    = 'Enter your email';
  static const resetLinkDesc     = "We'll send a password reset link to your email address.";
  static const sendResetLink     = 'Send Reset Link';
  static const checkYourInbox    = 'Check your inbox';
  static const backToSignIn      = 'Back to Sign In';
  static const didntReceive      = "Didn't receive it? ";
  static const resend            = 'Resend';

  // Admin Dashboard
  static const adminDashboard    = 'Admin Dashboard';
  static const platformMgmt      = 'Platform management';
  static const logOut            = 'Log Out';
  static const overview          = 'Overview';
  static const users             = 'Users';
  static const venues            = 'Venues';
  static const recentActivity    = 'Recent Activity';
  static const platformRevenue   = 'Platform Revenue';
  static const noActionRequired  = 'No action required';
  static const venueRejected     = 'Venue rejected';

  // Profile
  static const editProfile       = 'Edit Profile';
  static const updateInfo        = 'Update your information';
  static const changePhoto       = 'Change Photo';
  static const photoHint         = 'JPG or PNG · Max 5 MB';
  static const saveChanges       = '✓  Save Changes';
  static const customerAccount   = 'Customer Account';

  // Navigation labels
  static const navHome      = 'Home';
  static const navFavorites = 'Favorites';
  static const navBookings  = 'Bookings';
  static const navProfile   = 'Profile';

  // Home
  static const featuredVenues    = 'Featured Venues';
  static const searchHint        = 'Search venues...';
  static const noVenuesFound     = 'No venues match your search.';
  static const tryDifferent      = 'Try different filters.';

  // Favorites
  static const favoritesTitle    = 'Favorites';
  static const savedVenues       = 'Your saved venues';
  static const noFavoritesYet    = 'No favorites yet';
  static const tapHeartHint      = 'Tap the heart icon on any venue to save it here.';

  // Bookings
  static const myBookings        = 'My Bookings';
  static const manageReserv      = 'Manage your reservations';
  static const viewDetails       = 'View Details';
  static const contactVenue      = 'Contact Venue';
  static const viewVenueDetails  = 'View Venue Details';
  static const viewOwnerInfo     = 'View Owner Information';
  static const ownerInformation  = 'Owner Information';
  static const ownerContactSub   = 'Venue owner contact details';
  static const ownerNotFound     = 'Owner information is not available.';
  static const couldNotLoadOwner = 'Could not load owner information.';
  static const venueNotFound     = 'This venue is no longer available.';
  static const couldNotLoadVenue = 'Could not load venue details.';
  static const notAvailable      = 'Not available';

  // Owner bookings
  static const viewBookingDetails  = 'View Booking Details';
  static const viewCustomerInfo    = 'View Customer Information';
  static const bookingDetails      = 'Booking Details';
  static const bookingDetailsSub   = 'Full reservation information';
  static const customerInformation = 'Customer Information';
  static const customerContactSub  = 'Customer contact details';
  static const bookingNotFound     = 'This booking is no longer available.';
  static const couldNotLoadBooking = 'Could not load booking details.';
  static const customerNotFound    = 'Customer information is not available.';
  static const couldNotLoadCustomer = 'Could not load customer information.';

  // Filter
  static const filterVenues      = 'Filter Venues';
  static const category          = 'Category';
  static const priceRange        = 'Price Range (EGP)';
  static const reset             = 'Reset';
  static const applyFilters      = 'Apply Filters';

  // Egyptian phone
  static const egyptPhoneHint    = '01X XXXX XXXX';
  static const egyptPhoneHelper  = 'Start with 010, 011, 012, or 015 · 11 digits total';
  static const gpsHint           = 'Tap 📍 to auto-fill your current GPS location';
  static const locationHint      = 'Lat, Lng  or  City, Country';
}

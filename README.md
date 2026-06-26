# Festivo

Flutter event venue booking app (customer, owner, admin).

## Customer booking setup

### Cloudinary (payment receipts)

1. Open [Cloudinary Console](https://cloudinary.com/console).
2. Create an **unsigned** upload preset (e.g. `festivo_receipts`).
3. Edit `lib/core/constants/cloudinary_config.dart`:

```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'festivo_receipts';
```

### Firestore

- Bookings are stored in the `bookings` collection.
- Deploy rules from `firestore.rules` in the Firebase console (Firestore → Rules), or via Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

### Booking fields

Each document includes: `userId`, `userName`, `phone`, `email`, `venueId`, `venueName`, `guestCount`, `packageType`, `bookingDate`, `bookingTime`, `paymentMethod`, `receiptUrl`, `paymentStatus`, `bookingStatus`, `createdAt`.

## Run the app

```bash
flutter pub get
flutter run
```

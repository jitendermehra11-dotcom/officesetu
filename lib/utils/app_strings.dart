class AppStrings {
  static bool isEnglish = false;

  // ऐप टाइटल्स और टेक्स्ट
  static String get appTitle => isEnglish ? 'OfficeSetu - Master Dashboard' : 'OfficeSetu - मास्टर डैशबोर्ड';
  static String get room1Title => isEnglish ? 'Room 01: Attendance & OCR' : 'Room 01: अटेंडेंस और ओसीआर मिलान';
  static String get cameraBtn => isEnglish ? 'Camera (Live)' : 'कैमरा (Live)';
  static String get galleryBtn => isEnglish ? 'Gallery / Screenshot' : 'गैलरी / स्क्रीनशॉट';
  static String get pdfBtn => isEnglish ? 'Download Verified PDF Report' : 'सत्यापित रिपोर्ट PDF में डाउनलोड/प्रिंट करें';
  static String get langToast => isEnglish ? 'Switched to English' : 'हिंदी भाषा चुनी गई';
}

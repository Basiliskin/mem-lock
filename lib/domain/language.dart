enum AppLanguage { ru, en }

/// The Helper's choice wins. Otherwise follow the phone, using English for any
/// language the app doesn't have.
AppLanguage resolveLanguage(AppLanguage? saved, String phoneLanguageCode) =>
    saved ?? (phoneLanguageCode == 'ru' ? AppLanguage.ru : AppLanguage.en);

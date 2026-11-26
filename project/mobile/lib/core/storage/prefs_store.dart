import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive client UI preferences store (never stores JWTs or refresh tokens).
class PrefsStore {
  PrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _localeKey = 'afab_locale';
  static const String _appearanceKey = 'afab_appearance_settings';
  static const String _activeBusinessKey = 'afab_active_business_id';
  static const String _numberFormatKey = 'afab_number_format';
  static const String _dateFormatKey = 'afab_date_format';
  static const String _exportBrandingPrefix = 'afab_export_branding_';
  static const String _signatureRegistryPrefix = 'afab_wet_signature_registry_';

  String? getLocaleCode() => _prefs.getString(_localeKey);
  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  String? getExportBrandingJson(String businessId) =>
      _prefs.getString('$_exportBrandingPrefix$businessId');
  Future<void> setExportBrandingJson(String businessId, String json) =>
      _prefs.setString('$_exportBrandingPrefix$businessId', json);

  String? getSignatureRegistryJson(String businessId) =>
      _prefs.getString('$_signatureRegistryPrefix$businessId');
  Future<void> setSignatureRegistryJson(String businessId, String json) =>
      _prefs.setString('$_signatureRegistryPrefix$businessId', json);

  String? getAppearanceJson() => _prefs.getString(_appearanceKey);
  Future<void> setAppearanceJson(String json) =>
      _prefs.setString(_appearanceKey, json);

  String? getActiveBusinessId() => _prefs.getString(_activeBusinessKey);
  Future<void> setActiveBusinessId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(_activeBusinessKey);
    } else {
      await _prefs.setString(_activeBusinessKey, id);
    }
  }

  String getNumberFormat() => _prefs.getString(_numberFormatKey) ?? 'US';
  Future<void> setNumberFormat(String format) =>
      _prefs.setString(_numberFormatKey, format);

  String getDateFormat() => _prefs.getString(_dateFormatKey) ?? 'YYYY-MM-DD';
  Future<void> setDateFormat(String format) =>
      _prefs.setString(_dateFormatKey, format);
}

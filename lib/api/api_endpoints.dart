class ApiEndpoints {
  const ApiEndpoints._();

  static const signup = '/api/v1/auth/signup';
  static const login = '/api/v1/auth/login';
  static const refresh = '/api/v1/auth/refresh';
  static const logout = '/api/v1/auth/logout';
  static const passwordFind = '/api/v1/auth/password/find';
  static const passwordVerifyCode = '/api/v1/auth/password/verify-code';
  static const passwordReset = '/api/v1/auth/password/reset';

  static const nickname = '/api/v1/users/me/nickname';
  static const password = '/api/v1/users/me/password';
  static const termsConsent = '/api/v1/users/me/terms';
  static const me = '/api/v1/users/me';

  static const keywords = '/api/v1/keywords';
  static const taggedKeywords = '/api/v1/keywords/tagged';
  static const topKeywords = '/api/v1/keywords/top';
  static String keyword(String id) => '/api/v1/keywords/$id';
  static String keywordStatus(String id) => '/api/v1/keywords/$id/status';

  static const myTasteKeywords = '/api/v1/taste/me/keywords';
  static const myTastePrograms = '/api/v1/taste/me';

  static const programs = '/api/v1/programs';
  static const programsHot = '/api/v1/programs/hot';
  static const programsHotKeywords = '/api/v1/programs/hot-keywords';
  static const programsClosingSoon = '/api/v1/programs/closing-soon';
  static const programsMap = '/api/v1/programs/map';
  static const programsNearby = '/api/v1/programs/nearby';
  static const programThumbnails = '/api/v1/programs/thumbnails';
  static String program(String id) => '/api/v1/programs/$id';

  static String scrap(String programId) => '/api/v1/scraps/$programId';
  static const myScraps = '/api/v1/scraps/me';

  static const suggestions = '/api/v1/suggestions';
  static const mySuggestions = '/api/v1/suggestions/me';
  static const managerSuggestions = '/api/v1/suggestions/manager';
  static String suggestion(String id) => '/api/v1/suggestions/$id';
  static String suggestionStatus(String id) => '/api/v1/suggestions/$id/status';

  static const announcements = '/api/v1/announcements';
  static const managerAnnouncements = '/api/v1/announcements/manager';
  static String announcement(String id) => '/api/v1/announcements/$id';

  static const recentSearch = '/api/v1/search/recent';
  static const recentSearchAll = '/api/v1/search/recent/all';
}

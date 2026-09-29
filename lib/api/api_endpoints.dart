class ApiEndpoints {
  const ApiEndpoints._();

  static const signup = '/api/v1/auth/signup';
  static const signupEmailSendCode = '/api/v1/auth/email/send-code';
  static const signupEmailVerifyCode = '/api/v1/auth/email/verify-code';
  static const login = '/api/v1/auth/login';
  static const socialLogin = '/api/v1/auth/social/login';
  static const refresh = '/api/v1/auth/refresh';
  static const logout = '/api/v1/auth/logout';
  static const passwordFind = '/api/v1/auth/password/find';
  static const passwordVerifyCode = '/api/v1/auth/password/verify-code';
  static const passwordReset = '/api/v1/auth/password/reset';

  static const nickname = '/api/v1/users/me/nickname';
  static const password = '/api/v1/users/me/password';
  static const termsConsent = '/api/v1/users/me/terms';
  static const me = '/api/v1/users/me';
  static const profileImage = '/api/v1/users/me/profile-image';
  static const adminUsers = '/api/v1/admin/users';

  static const curatorApplications = '/api/v1/curator-applications';
  static const myCuratorApplications = '/api/v1/curator-applications/me';
  static const latestCuratorApplication =
      '/api/v1/curator-applications/me/latest';
  static const managerCuratorApplications =
      '/api/v1/curator-applications/manager';
  static String curatorApplication(String id) =>
      '/api/v1/curator-applications/$id';

  static const myCuratorProfile = '/api/v1/curators/me';
  static const curations = '/api/v1/curations';
  static const myCurations = '/api/v1/curations/me';
  static String myCuration(String id) => '/api/v1/curations/me/$id';
  static String curation(String id) => '/api/v1/curations/$id';
  static String resubmitCuration(String id) => '/api/v1/curations/$id/resubmit';
  static const managerCurations = '/api/v1/manager/curations';
  static String managerCuration(String id) => '$managerCurations/$id';
  static String approveExistingCuration(String id) =>
      '${managerCuration(id)}/approve-existing';
  static String approveNewCuration(String id) =>
      '${managerCuration(id)}/approve-new';
  static String requestCurationChanges(String id) =>
      '${managerCuration(id)}/request-changes';

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
  static String programCurations(String id) => '/api/v1/programs/$id/curations';
  static String relatedPrograms(String id) => '/api/v1/programs/$id/related';
  static String programCuration(String programId, String curationId) =>
      '${programCurations(programId)}/$curationId';
  static String programReaction(String programId) =>
      '/api/v1/program-reactions/$programId';
  static const myProgramReactions = '/api/v1/program-reactions/me';

  static String scrap(String programId) => '/api/v1/scraps/$programId';
  static const myScraps = '/api/v1/scraps/me';

  static const suggestions = '/api/v1/suggestions';
  static const mySuggestions = '/api/v1/suggestions/me';
  static const managerSuggestions = '/api/v1/suggestions/manager';
  static const managerDeletedSuggestions =
      '/api/v1/suggestions/manager/del-suggestion';
  static String suggestion(String id) => '/api/v1/suggestions/$id';
  static String suggestionStatus(String id) => '/api/v1/suggestions/$id/status';

  static const announcements = '/api/v1/announcements';
  static const managerAnnouncements = '/api/v1/announcements/manager';
  static String announcement(String id) => '/api/v1/announcements/$id';

  static const recentSearch = '/api/v1/search/recent';
  static const recentSearchAll = '/api/v1/search/recent/all';
}

abstract class AppStrings {
  // ── General & Common ──────────────────────────────────────
  String get appTitle;
  String get cancel;
  String get confirm;
  String get save;
  String get delete;
  String get done;
  String get close;
  String get retry;
  String get edit;
  String get share;
  String get loading;
  String get errorOccurred;
  String get success;
  String get failure;
  String get tryAgain;

  // ── Language & Regional ──────────────────────────────────
  String get language;
  String get languageAuto;
  String get languageVi;
  String get languageEn;
  String get languageJa;
  String get selectLanguage;

  // ── Navigation ───────────────────────────────────────────
  String get navHome;
  String get navSearch;
  String get navNewThread;
  String get navActivity;
  String get navProfile;

  // ── Profile Menu & Settings ──────────────────────────────
  String get menuSettings;
  String get menuChangePassword;
  String get menuSaved;
  String get menuYourQr;
  String get menuLogout;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;

  // ── Home & Feed ──────────────────────────────────────────
  String get tabForYou;
  String get tabFollowing;
  String get whatsNewPlaceholder;
  String get postChip;
  String get emptyFeedTitle;
  String get emptyFeedSub;
  String get anonymousAuthor;

  // ── Time & Formatting ────────────────────────────────────
  String get timeJustNow;
  String timeMinutes(int minutes);
  String timeHours(int hours);
  String timeDays(int days);
  String timeWeeks(int weeks);

  // ── Post Card & Interactions ─────────────────────────────
  String get likeTooltip;
  String get commentTooltip;
  String get repostTooltip;
  String get shareTooltip;
  String get copyLink;
  String get copyLinkSuccess;
  String get deletePost;
  String get deleteComment;
  String get deletePostConfirm;
  String get deleteCommentConfirm;
  String get postDeletedSuccess;

  // ── Post Detail ──────────────────────────────────────────
  String get postDetailTitle;
  String replyTo(String author);
  String get authorBadge;
  String get writeReplyPlaceholder;
  String get postReply;
  String get noRepliesYet;
  String get noRepliesSub;

  // ── Hashtags & Trends ────────────────────────────────────
  String get tabTop;
  String get tabLatest;
  String postsCount(String count);

  // ── Search & Discovery ───────────────────────────────────
  String get searchPlaceholder;
  String get tabAll;
  String get tabAccounts;
  String get tabPosts;
  String get tabHashtags;
  String get trendingToday;
  String get past7Days;
  String get noTrendingHashtags;
  String get viewAll;
  String get noSearchResultsTitle;
  String get noSearchResultsSub;
  String get noAccountsFound;
  String get noPostsFound;
  String get noHashtagsFound;

  // ── Activity & Notifications ─────────────────────────────
  String get activityTitle;
  String get filterAll;
  String get filterLikes;
  String get filterReplies;
  String get filterFollows;
  String get notiLikedPost;
  String get notiRepliedPost;
  String get notiFollowedYou;
  String get notiRepostedPost;
  String get noActivityTitle;
  String get noActivitySub;

  // ── Profile Screen ───────────────────────────────────────
  String get btnEditProfile;
  String get btnShareProfile;
  String get btnFollow;
  String get btnFollowing;
  String get btnMessage;
  String followersText(String count);
  String followingText(String count);
  String get followersLabel;
  String get followingLabel;
  String get tabThreads;
  String get tabReposts;
  String get editProfileTitle;
  String get editNameLabel;
  String get editBioLabel;
  String get editBioPlaceholder;
  String get updateProfileSuccess;
  String get noPostsYet;
  String get noRepostsYet;
  String get noFollowersYet;

  // ── Direct Messaging ─────────────────────────────────────
  String get messagesTitle;
  String get messageRequests;
  String get newChat;
  String get noConversationsTitle;
  String get noConversationsSub;
  String get typeMessagePlaceholder;
  String get statusSending;
  String get statusSent;
  String get statusDelivered;
  String get statusRead;
  String get actionRecall;
  String get actionCopy;
  String get messageRecalled;
  String get cannotChatSelf;

  // ── Auth: Login ──────────────────────────────────────────
  String get loginWelcome;
  String get loginSubtitle;
  String get emailOrUsername;
  String get passwordLabel;
  String get forgotPasswordQuestion;
  String get loginButton;
  String get orDivider;
  String get continueWithGoogle;
  String get dontHaveAccount;
  String get signUpNow;

  // ── Auth: Register ───────────────────────────────────────
  String get registerTitle;
  String get registerSubtitle;
  String get firstNameLabel;
  String get lastNameLabel;
  String get emailLabel;
  String get confirmPasswordLabel;
  String get registerButton;
  String get alreadyHaveAccount;
  String get signInNow;
  String get loginFailure;
  String get googleLoginFailure;
  String get registerSuccess;
  String get registerFailure;
  String get passwordsDoNotMatch;
  String get enterPassword;
  String get enterConfirmPassword;
  String get usernameLabel;
  String get nicknameLabel;
  String get nicknameHint;
  String get usernameOrEmailHint;

  // ── Password Rules & Checklist ───────────────────────────
  String get ruleLength;
  String get ruleUppercase;
  String get ruleLowercase;
  String get ruleDigit;
  String get ruleSpecial;
  String get ruleNoWhitespace;
  String get ruleNotCommon;
  String get ruleMatch;
  String get ruleMatchFail;

  // ── Change & Reset Password ──────────────────────────────
  String get changePasswordTitle;
  String get changePasswordSubtitle;
  String get currentPasswordLabel;
  String get newPasswordLabel;
  String get confirmNewPasswordLabel;
  String get saveNewPasswordButton;
  String get changePasswordSuccess;
  String get changePasswordSuccessSub;
  String get passwordCannotMatchOld;
  String get changePasswordFailure;
  String get currentPasswordIncorrect;
  String get sessionExpiredReLogin;
  String get googleAccountNoPassword;
  String get forgotPasswordTitle;
  String get forgotPasswordEmailSub;
  String get sendOtpButton;
  String get otpTitle;
  String otpSentToEmail(String email);
  String get resendOtp;
  String resendCountdown(int seconds);
  String get verifyOtpButton;
  String get noOtpReceived;
  String get changeEmailAddress;
  String get resetPasswordButton;
  String get resetPasswordSuccessTitle;
  String get resetPasswordSuccessSub;
  String get loginNowButton;

  // ── Composer & Share Sheets ──────────────────────────────
  String get createThreadTitle;
  String get writePlaceholder;
  String get pickImageGallery;
  String get pickVideoGallery;
  String get postSuccess;
  String get postFailure;
  String get sharePostTitle;
  String get shareProfileTitle;
  String get sendViaDM;
  String get sendDirectMessage;
  String get shareViaSystem;
  String get noFollowingYet;
  String sharedCountSuccess(int count);
  String get notInterested;
  String get report;

  // ── Auth Validation & Error Messages ─────────────────────
  String get pleaseEnterCurrentPassword;
  String get pleaseEnterEmail;
  String get invalidEmailAddress;
  String get failedToSendOtp;
  String get enterFullOtpCode;
  String get incorrectOtpCode;
  String get failedToResetPassword;
  String get pleaseLoginFirst;
  String get authErrorRelogin;

  // ── Feed, Posts & Comments ───────────────────────────────
  String followUserConfirmTitle(String username);
  String followUserConfirmMessage(String username);
  String get postNotFoundOrDeleted;
  String get failedToLoadPost;
  String get loginToComment;
  String get failedToSendComment;
  String viewMoreReplies(int count);
  String firstPostWithTag(String tag);

  // ── Options & Share ──────────────────────────────────────
  String get failedToDeletePost;
  String get postHiddenFromFeed;
  String get reportReceivedThanks;
  String get sharedPostMessage;
  String viewPostShareText(String authorName, String url);
  String viewPostShareGenericText(String url);
  String get cannotOpenSystemShare;
  String viewProfileShareText(String nickname, String username, String url);

  // ── Profile & Search Feedback ────────────────────────────
  String get failedToLoadProfile;
  String get failedToSaveProfile;
  String get failedToUpdateProfile;
  String get actionFailedTryAgain;
  String get userNotFound;
  String get cannotOpenChatNow;
  String get failedToLoadTrending;
  String get failedToLoadFeed;
  String get failedToLoadFollowingFeed;
  String get failedToUploadImage;
  String get storagePermissionDenied;
  String get failedToSearch;
  String get failedToLoadHashtagPosts;

  // ── Chat & Messaging ─────────────────────────────────────
  String get chatStatusActive;
  String get chatStatusOffline;
  String get chatSingleMessageLimit;
  String get chatRequestPending;
  String get failedToSendMessage;
  String get sendPhoto;
  String get sendVideo;
  String get failedToUploadFile;
  String get startConversationPrompt;
  String get postNoLongerExists;
  String get btnDecline;
  String get btnAccept;
  String get waitingForResponse;
  String get viewProfileMenu;
  String get tapToViewPost;
  String get deleteForMe;
  String get blockUser;
  String get deleteConversation;
  String get tagPending;
  String get tagRequest;
  String get messagePhotoTag;
  String get messageVideoTag;
  String get chatSingleMessagePendingSender;
  String get chatPendingSenderNotice;
  String get replyToAcceptPrompt;
  String get userFallback;
  String youPrefix(String content);

  // ── Activity & Video & Notification ───────────────────────
  String get interactedWithYou;
  String newNotificationsCount(int count);
  String get cannotPlayVideo;
  String get justNow;
  String get sentPhotoNotification;
  String get sentVideoNotification;

  // ── Auth & Account Detailed Errors ───────────────────────
  String get emailAlreadyInUse;
  String get weakPassword;
  String get invalidEmailFormat;
  String get invalidCredentials;
  String get accountNotFound;
  String get accountNotFoundForEmail;
  String get googleAccountSignInPrompt;
  String get tooManyRequests;
  String get pleaseEnterFullName;
  String get cannotConnectServerCompleteRegistration;
}

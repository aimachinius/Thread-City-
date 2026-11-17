import 'app_strings.dart';

class TranslationsEn implements AppStrings {
  const TranslationsEn();

  // ── General & Common ──────────────────────────────────────
  @override String get appTitle => 'Thread City';
  @override String get cancel => 'Cancel';
  @override String get confirm => 'Confirm';
  @override String get save => 'Save';
  @override String get delete => 'Delete';
  @override String get done => 'Done';
  @override String get close => 'Close';
  @override String get retry => 'Retry';
  @override String get edit => 'Edit';
  @override String get share => 'Share';
  @override String get loading => 'Loading...';
  @override String get errorOccurred => 'An error occurred';
  @override String get success => 'Success';
  @override String get failure => 'Failed';
  @override String get tryAgain => 'Try again';

  // ── Language & Regional ──────────────────────────────────
  @override String get language => 'Language';
  @override String get languageAuto => 'Automatic (System Region)';
  @override String get languageVi => 'Tiếng Việt';
  @override String get languageEn => 'English';
  @override String get languageJa => '日本語';
  @override String get selectLanguage => 'Select display language';

  // ── Navigation ───────────────────────────────────────────
  @override String get navHome => 'Home';
  @override String get navSearch => 'Search';
  @override String get navNewThread => 'New Thread';
  @override String get navActivity => 'Activity';
  @override String get navProfile => 'Profile';

  // ── Profile Menu & Settings ──────────────────────────────
  @override String get menuSettings => 'Settings';
  @override String get menuChangePassword => 'Change Password';
  @override String get menuSaved => 'Saved';
  @override String get menuYourQr => 'Your QR Code';
  @override String get menuLogout => 'Log out';
  @override String get logoutConfirmTitle => 'Log out?';
  @override String get logoutConfirmMessage => 'Are you sure you want to log out of your account?';

  // ── Home & Feed ──────────────────────────────────────────
  @override String get tabForYou => 'For you';
  @override String get tabFollowing => 'Following';
  @override String get whatsNewPlaceholder => "What's new?";
  @override String get postChip => 'Post';
  @override String get emptyFeedTitle => 'No posts yet';
  @override String get emptyFeedSub => 'Follow creators or write your very first thread!';
  @override String get anonymousAuthor => 'Anonymous';

  // ── Time & Formatting ────────────────────────────────────
  @override String get timeJustNow => 'Just now';
  @override String timeMinutes(int minutes) => '${minutes}m';
  @override String timeHours(int hours) => '${hours}h';
  @override String timeDays(int days) => '${days}d';
  @override String timeWeeks(int weeks) => '${weeks}w';

  // ── Post Card & Interactions ─────────────────────────────
  @override String get likeTooltip => 'Like';
  @override String get commentTooltip => 'Reply';
  @override String get repostTooltip => 'Repost';
  @override String get shareTooltip => 'Share';
  @override String get copyLink => 'Copy link';
  @override String get copyLinkSuccess => 'Link copied to clipboard';
  @override String get deletePost => 'Delete post';
  @override String get deleteComment => 'Delete reply';
  @override String get deletePostConfirm => 'Are you sure you want to delete this post? This action cannot be undone.';
  @override String get deleteCommentConfirm => 'Are you sure you want to delete this reply?';
  @override String get postDeletedSuccess => 'Post deleted successfully';

  // ── Post Detail ──────────────────────────────────────────
  @override String get postDetailTitle => 'Thread';
  @override String replyTo(String author) => 'Replying to $author';
  @override String get authorBadge => 'Author';
  @override String get writeReplyPlaceholder => 'Reply to thread...';
  @override String get postReply => 'Reply';
  @override String get noRepliesYet => 'No replies yet';
  @override String get noRepliesSub => 'Be the first to share your thoughts 🌿';

  // ── Hashtags & Trends ────────────────────────────────────
  @override String get tabTop => 'Top';
  @override String get tabLatest => 'Latest';
  @override String postsCount(String count) => '$count posts';

  // ── Search & Discovery ───────────────────────────────────
  @override String get searchPlaceholder => 'Search posts, creators, #hashtags...';
  @override String get tabAll => 'All';
  @override String get tabAccounts => 'Profiles';
  @override String get tabPosts => 'Posts';
  @override String get tabHashtags => 'Hashtags';
  @override String get trendingToday => 'Trending today';
  @override String get past7Days => 'Past 7 days';
  @override String get noTrendingHashtags => 'No trending hashtags';
  @override String get viewAll => 'See all';
  @override String get noSearchResultsTitle => 'No matching results found';
  @override String get noSearchResultsSub => 'Try searching with different keywords or terms!';
  @override String get noAccountsFound => 'No accounts found';
  @override String get noPostsFound => 'No posts found';
  @override String get noHashtagsFound => 'No hashtags found';

  // ── Activity & Notifications ─────────────────────────────
  @override String get activityTitle => 'Activity';
  @override String get filterAll => 'All';
  @override String get filterLikes => 'Likes';
  @override String get filterReplies => 'Replies';
  @override String get filterFollows => 'Follows';
  @override String get notiLikedPost => 'liked your post';
  @override String get notiRepliedPost => 'replied to your post';
  @override String get notiFollowedYou => 'started following you';
  @override String get notiRepostedPost => 'reposted your thread';
  @override String get noActivityTitle => 'No activity yet';
  @override String get noActivitySub => 'Likes, replies, and new followers will show up here 🌿';

  // ── Profile Screen ───────────────────────────────────────
  @override String get btnEditProfile => 'Edit profile';
  @override String get btnShareProfile => 'Share profile';
  @override String get btnFollow => 'Follow';
  @override String get btnFollowing => 'Following';
  @override String get btnMessage => 'Message';
  @override String followersText(String count) => '$count followers';
  @override String followingText(String count) => '$count following';
  @override String get followersLabel => 'Followers';
  @override String get followingLabel => 'Following';
  @override String get tabThreads => 'Threads';
  @override String get tabReposts => 'Reposts';
  @override String get editProfileTitle => 'Edit profile';
  @override String get editNameLabel => 'Display name';
  @override String get editBioLabel => 'Bio';
  @override String get editBioPlaceholder => 'Write a short bio about yourself...';
  @override String get updateProfileSuccess => 'Profile updated successfully!';
  @override String get noPostsYet => 'No posts shared yet';
  @override String get noRepostsYet => 'No reposts yet';
  @override String get noFollowersYet => 'No followers yet';

  // ── Direct Messaging ─────────────────────────────────────
  @override String get messagesTitle => 'Messages';
  @override String get messageRequests => 'Requests';
  @override String get newChat => 'New message';
  @override String get noConversationsTitle => 'No conversations yet';
  @override String get noConversationsSub => 'Send a message to people you are following!';
  @override String get typeMessagePlaceholder => 'Type a message...';
  @override String get statusSending => 'Sending...';
  @override String get statusSent => 'Sent';
  @override String get statusDelivered => 'Delivered';
  @override String get statusRead => 'Read';
  @override String get actionRecall => 'Unsend';
  @override String get actionCopy => 'Copy';
  @override String get messageRecalled => 'Message unsent';
  @override String get cannotChatSelf => 'You cannot chat with yourself';

  // ── Auth: Login ──────────────────────────────────────────
  @override String get loginWelcome => 'Welcome back';
  @override String get loginSubtitle => 'Sign in to continue your journey';
  @override String get emailOrUsername => 'Email or username';
  @override String get passwordLabel => 'Password';
  @override String get forgotPasswordQuestion => 'Forgot password?';
  @override String get loginButton => 'Sign In';
  @override String get orDivider => 'or';
  @override String get continueWithGoogle => 'Continue with Google';
  @override String get dontHaveAccount => "Don't have an account? ";
  @override String get signUpNow => 'Sign Up';

  // ── Auth: Register ───────────────────────────────────────
  @override String get registerTitle => 'Create Account';
  @override String get registerSubtitle => 'Join the Thread City community today';
  @override String get firstNameLabel => 'First name';
  @override String get lastNameLabel => 'Last name';
  @override String get emailLabel => 'Email';
  @override String get confirmPasswordLabel => 'Confirm password';
  @override String get registerButton => 'Sign Up';
  @override String get alreadyHaveAccount => 'Already have an account? ';
  @override String get signInNow => 'Sign In';
  @override String get loginFailure => 'Login failed';
  @override String get googleLoginFailure => 'Google sign-in failed';
  @override String get registerSuccess => 'Registration successful!';
  @override String get registerFailure => 'An error occurred during registration';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get enterPassword => 'Enter password';
  @override String get enterConfirmPassword => 'Confirm password';
  @override String get usernameLabel => 'Username';
  @override String get nicknameLabel => 'Nickname';
  @override String get nicknameHint => 'Your display name';
  @override String get usernameOrEmailHint => 'username or email@example.com';

  // ── Password Rules & Checklist ───────────────────────────
  @override String get ruleLength => 'Between 8 and 64 characters';
  @override String get ruleUppercase => 'At least one uppercase letter (A-Z)';
  @override String get ruleLowercase => 'At least one lowercase letter (a-z)';
  @override String get ruleDigit => 'At least one number (0-9)';
  @override String get ruleSpecial => 'At least one special character (!@#\$%...)';
  @override String get ruleNoWhitespace => 'Must not contain whitespace';
  @override String get ruleNotCommon => 'Not an easily guessable password';
  @override String get ruleMatch => 'Passwords match';
  @override String get ruleMatchFail => 'Passwords do not match';

  // ── Change & Reset Password ──────────────────────────────
  @override String get changePasswordTitle => 'Change Password';
  @override String get changePasswordSubtitle => 'To protect your account, your new password must fulfill all 7 security rules.';
  @override String get currentPasswordLabel => 'Current password';
  @override String get newPasswordLabel => 'New password';
  @override String get confirmNewPasswordLabel => 'Confirm new password';
  @override String get saveNewPasswordButton => 'Save New Password';
  @override String get changePasswordSuccess => 'Password changed successfully!';
  @override String get changePasswordSuccessSub => 'Your password has been securely updated. You can use your new password for future logins.';
  @override String get passwordCannotMatchOld => 'New password cannot be the same as old password';
  @override String get changePasswordFailure => 'Failed to change password';
  @override String get currentPasswordIncorrect => 'Current password is incorrect';
  @override String get sessionExpiredReLogin => 'Session expired. Please sign in again to change password.';
  @override String get googleAccountNoPassword => 'This account is linked to Google and does not use a separate password.';
  @override String get forgotPasswordTitle => 'Forgot Password';
  @override String get forgotPasswordEmailSub => 'Enter the email linked to your account to receive a 6-digit OTP';
  @override String get sendOtpButton => 'Send OTP Code';
  @override String get otpTitle => 'OTP Verification';
  @override String otpSentToEmail(String email) => 'A 6-digit code has been sent to:\n$email';
  @override String get resendOtp => 'Resend code';
  @override String resendCountdown(int seconds) => 'Resend in (${seconds}s)';
  @override String get verifyOtpButton => 'Verify Code';
  @override String get noOtpReceived => "Didn't receive code? ";
  @override String get changeEmailAddress => 'Change email address';
  @override String get resetPasswordButton => 'Reset Password';
  @override String get resetPasswordSuccessTitle => 'Password Reset!';
  @override String get resetPasswordSuccessSub => 'Your password has been securely updated. Please log in with your new password.';
  @override String get loginNowButton => 'Sign In Now';

  // ── Composer & Share Sheets ──────────────────────────────
  @override String get createThreadTitle => 'New Thread';
  @override String get writePlaceholder => "What's on your mind?";
  @override String get pickImageGallery => 'Choose photos from gallery';
  @override String get pickVideoGallery => 'Choose video from gallery';
  @override String get postSuccess => 'Posted successfully!';
  @override String get postFailure => 'Failed to publish post';
  @override String get sharePostTitle => 'Share post';
  @override String get shareProfileTitle => 'Share profile';
  @override String get sendViaDM => 'Send via message';
  @override String get sendDirectMessage => 'Send direct message';
  @override String get shareViaSystem => 'Share via...';
  @override String get noFollowingYet => 'You are not following anyone yet.';
  @override String sharedCountSuccess(int count) => 'Successfully shared to $count people.';
  @override String get notInterested => 'Not interested in this post';
  @override String get report => 'Report';

  // ── Auth Validation & Error Messages ─────────────────────
  @override String get pleaseEnterCurrentPassword => 'Please enter your current password';
  @override String get pleaseEnterEmail => 'Please enter your email address';
  @override String get invalidEmailAddress => 'Invalid email address format';
  @override String get failedToSendOtp => 'Failed to send OTP code';
  @override String get enterFullOtpCode => 'Please enter all 6 digits of the OTP code';
  @override String get incorrectOtpCode => 'Incorrect OTP code';
  @override String get failedToResetPassword => 'Failed to reset password';
  @override String get pleaseLoginFirst => 'Please sign in';
  @override String get authErrorRelogin => 'Authentication error. Please sign in again.';

  // ── Feed, Posts & Comments ───────────────────────────────
  @override String followUserConfirmTitle(String username) => 'Follow @$username?';
  @override String followUserConfirmMessage(String username) => 'You will see posts from @$username in your feed.';
  @override String get postNotFoundOrDeleted => 'Post does not exist or has been deleted';
  @override String get failedToLoadPost => 'Failed to load post. Please try again later.';
  @override String get loginToComment => 'Please sign in to reply';
  @override String get failedToSendComment => 'Failed to post reply';
  @override String viewMoreReplies(int count) => 'View $count more replies...';
  @override String firstPostWithTag(String tag) => 'Be the first to post with #$tag';

  // ── Options & Share ──────────────────────────────────────
  @override String get failedToDeletePost => 'Failed to delete post. Please try again.';
  @override String get postHiddenFromFeed => 'Post hidden from your feed';
  @override String get reportReceivedThanks => 'Thank you for reporting. We will review this content.';
  @override String get sharedPostMessage => '[Shared a post]';
  @override String viewPostShareText(String authorName, String url) => 'View $authorName\'s post on Thread-City:\n$url';
  @override String viewPostShareGenericText(String url) => 'View post on Thread-City:\n$url';
  @override String get cannotOpenSystemShare => 'Could not open system share dialog';
  @override String viewProfileShareText(String nickname, String username, String url) => 'View $nickname\'s profile (@$username) on Thread-City:\n$url';

  // ── Profile & Search Feedback ────────────────────────────
  @override String get failedToLoadProfile => 'Failed to load profile. Pull down to retry.';
  @override String get failedToSaveProfile => 'Failed to save changes';
  @override String get failedToUpdateProfile => 'Failed to update profile. Please try again.';
  @override String get actionFailedTryAgain => 'Action failed. Please try again.';
  @override String get userNotFound => 'User information not found';
  @override String get cannotOpenChatNow => 'Cannot open conversation right now';
  @override String get failedToLoadTrending => 'Failed to load trending';
  @override String get failedToLoadFeed => 'Failed to load feed. Please try again.';
  @override String get failedToLoadFollowingFeed => 'Failed to load following feed.';
  @override String get failedToUploadImage => 'Failed to upload image. Please try again.';
  @override String get storagePermissionDenied => 'Storage denied permission. Please check rules.';
  @override String get failedToSearch => 'Search failed. Please try again.';
  @override String get failedToLoadHashtagPosts => 'Failed to load posts for this hashtag.';

  // ── Chat & Messaging ─────────────────────────────────────
  @override String get chatStatusActive => 'Active now';
  @override String get chatStatusOffline => 'Offline';
  @override String get chatSingleMessageLimit => 'You can only send 1 message before they respond';
  @override String get chatRequestPending => 'Message request is pending approval. You cannot send more messages yet.';
  @override String get failedToSendMessage => 'Failed to send message';
  @override String get sendPhoto => 'Send photo';
  @override String get sendVideo => 'Send video';
  @override String get failedToUploadFile => 'Failed to upload file';
  @override String get startConversationPrompt => 'Start the conversation';
  @override String get postNoLongerExists => 'Post no longer exists';
  @override String get btnDecline => 'Decline';
  @override String get btnAccept => 'Accept';
  @override String get waitingForResponse => 'Waiting for response...';
  @override String get viewProfileMenu => 'View profile';
  @override String get tapToViewPost => 'Tap to view post';
  @override String get deleteForMe => 'Delete for me';
  @override String get blockUser => 'Block';
  @override String get deleteConversation => 'Delete conversation';
  @override String get tagPending => 'Pending';
  @override String get tagRequest => 'Request';
  @override String get messagePhotoTag => '[Photo]';
  @override String get messageVideoTag => '[Video]';
  @override String get chatSingleMessagePendingSender => 'Request sent. You can only send 1 message until they accept.';
  @override String get chatPendingSenderNotice => 'You sent 1 message. The chat will open once they reply.';
  @override String get replyToAcceptPrompt => 'Reply to open conversation...';
  @override String get userFallback => 'User';
  @override String youPrefix(String content) => 'You: $content';

  // ── Activity & Video & Notification ───────────────────────
  @override String get interactedWithYou => 'interacted with you';
  @override String newNotificationsCount(int count) => '$count new notifications';
  @override String get cannotPlayVideo => 'Cannot play this video';
  @override String get justNow => 'Just now';
  @override String get sentPhotoNotification => 'Sent a photo';
  @override String get sentVideoNotification => 'Sent a video';

  // ── Auth & Account Detailed Errors ───────────────────────
  @override String get emailAlreadyInUse => 'This email is already in use!';
  @override String get weakPassword => 'Password is too weak according to security policy!';
  @override String get invalidEmailFormat => 'Invalid email address!';
  @override String get invalidCredentials => 'Incorrect email or password';
  @override String get accountNotFound => 'Account does not exist';
  @override String get accountNotFoundForEmail => 'No account found with this email';
  @override String get googleAccountSignInPrompt => 'This account uses Google Sign-In. Please sign in with Google instead.';
  @override String get tooManyRequests => 'Too many requests. Please try again later';
  @override String get pleaseEnterFullName => 'Please enter your full name';
  @override String get cannotConnectServerCompleteRegistration => 'Cannot connect to server to complete registration. Please try signing in again.';
}

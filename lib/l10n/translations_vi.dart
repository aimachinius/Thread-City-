import 'app_strings.dart';

class TranslationsVi implements AppStrings {
  const TranslationsVi();

  // ── General & Common ──────────────────────────────────────
  @override String get appTitle => 'Thread City';
  @override String get cancel => 'Huỷ';
  @override String get confirm => 'Xác nhận';
  @override String get save => 'Lưu';
  @override String get delete => 'Xoá';
  @override String get done => 'Xong';
  @override String get close => 'Đóng';
  @override String get retry => 'Thử lại';
  @override String get edit => 'Chỉnh sửa';
  @override String get share => 'Chia sẻ';
  @override String get loading => 'Đang tải...';
  @override String get errorOccurred => 'Đã có lỗi xảy ra';
  @override String get success => 'Thành công';
  @override String get failure => 'Thất bại';
  @override String get tryAgain => 'Thử lại';

  // ── Language & Regional ──────────────────────────────────
  @override String get language => 'Ngôn ngữ';
  @override String get languageAuto => 'Tự động (Theo vùng hệ thống)';
  @override String get languageVi => 'Tiếng Việt';
  @override String get languageEn => 'English';
  @override String get languageJa => '日本語';
  @override String get selectLanguage => 'Chọn ngôn ngữ hiển thị';

  // ── Navigation ───────────────────────────────────────────
  @override String get navHome => 'Trang chủ';
  @override String get navSearch => 'Tìm kiếm';
  @override String get navNewThread => 'Thread mới';
  @override String get navActivity => 'Hoạt động';
  @override String get navProfile => 'Cá nhân';

  // ── Profile Menu & Settings ──────────────────────────────
  @override String get menuSettings => 'Cài đặt';
  @override String get menuChangePassword => 'Đổi mật khẩu';
  @override String get menuSaved => 'Đã lưu';
  @override String get menuYourQr => 'Mã QR của bạn';
  @override String get menuLogout => 'Đăng xuất';
  @override String get logoutConfirmTitle => 'Đăng xuất?';
  @override String get logoutConfirmMessage => 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?';

  // ── Home & Feed ──────────────────────────────────────────
  @override String get tabForYou => 'Dành cho bạn';
  @override String get tabFollowing => 'Đang theo dõi';
  @override String get whatsNewPlaceholder => 'Có gì mới?';
  @override String get postChip => 'Đăng';
  @override String get emptyFeedTitle => 'Chưa có bài viết nào';
  @override String get emptyFeedSub => 'Hãy theo dõi mọi người hoặc đăng thread đầu tiên của bạn nhé!';
  @override String get anonymousAuthor => 'Ẩn danh';

  // ── Time & Formatting ────────────────────────────────────
  @override String get timeJustNow => 'Vừa xong';
  @override String timeMinutes(int minutes) => '${minutes}m';
  @override String timeHours(int hours) => '${hours}h';
  @override String timeDays(int days) => '${days}d';
  @override String timeWeeks(int weeks) => '${weeks}w';

  // ── Post Card & Interactions ─────────────────────────────
  @override String get likeTooltip => 'Thích';
  @override String get commentTooltip => 'Bình luận';
  @override String get repostTooltip => 'Đăng lại';
  @override String get shareTooltip => 'Chia sẻ';
  @override String get copyLink => 'Sao chép liên kết';
  @override String get copyLinkSuccess => 'Đã sao chép liên kết vào bộ nhớ tạm';
  @override String get deletePost => 'Xóa bài viết';
  @override String get deleteComment => 'Xóa bình luận';
  @override String get deletePostConfirm => 'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.';
  @override String get deleteCommentConfirm => 'Bạn có chắc chắn muốn xóa bình luận này không?';
  @override String get postDeletedSuccess => 'Đã xóa bài viết thành công';

  // ── Post Detail ──────────────────────────────────────────
  @override String get postDetailTitle => 'Bài viết';
  @override String replyTo(String author) => 'Trả lời $author';
  @override String get authorBadge => 'Tác giả';
  @override String get writeReplyPlaceholder => 'Bình luận...';
  @override String get postReply => 'Trả lời';
  @override String get noRepliesYet => 'Chưa có bình luận nào';
  @override String get noRepliesSub => 'Hãy là người đầu tiên để lại suy nghĩ của bạn 🌿';

  // ── Hashtags & Trends ────────────────────────────────────
  @override String get tabTop => 'Hàng đầu';
  @override String get tabLatest => 'Mới nhất';
  @override String postsCount(String count) => '$count bài viết';

  // ── Search & Discovery ───────────────────────────────────
  @override String get searchPlaceholder => 'Tìm kiếm bài viết, người dùng, #hashtag...';
  @override String get tabAll => 'Tất cả';
  @override String get tabAccounts => 'Tài khoản';
  @override String get tabPosts => 'Bài viết';
  @override String get tabHashtags => 'Hashtags';
  @override String get trendingToday => 'Xu hướng hôm nay';
  @override String get past7Days => '7 ngày qua';
  @override String get noTrendingHashtags => 'Chưa có hashtag xu hướng';
  @override String get viewAll => 'Xem tất cả';
  @override String get noSearchResultsTitle => 'Không tìm thấy kết quả phù hợp';
  @override String get noSearchResultsSub => 'Hãy thử tìm kiếm với từ khóa khác xem sao nhé!';
  @override String get noAccountsFound => 'Không tìm thấy tài khoản nào';
  @override String get noPostsFound => 'Không tìm thấy bài viết nào';
  @override String get noHashtagsFound => 'Không tìm thấy hashtag nào';

  // ── Activity & Notifications ─────────────────────────────
  @override String get activityTitle => 'Hoạt động';
  @override String get filterAll => 'Tất cả';
  @override String get filterLikes => 'Lượt thích';
  @override String get filterReplies => 'Bình luận';
  @override String get filterFollows => 'Theo dõi';
  @override String get notiLikedPost => 'đã thích bài viết của bạn';
  @override String get notiRepliedPost => 'đã trả lời bài viết của bạn';
  @override String get notiFollowedYou => 'đã bắt đầu theo dõi bạn';
  @override String get notiRepostedPost => 'đã chia sẻ lại bài của bạn';
  @override String get noActivityTitle => 'Chưa có hoạt động nào';
  @override String get noActivitySub => 'Lượt thích, bình luận và người theo dõi mới sẽ xuất hiện ở đây 🌿';

  // ── Profile Screen ───────────────────────────────────────
  @override String get btnEditProfile => 'Chỉnh sửa';
  @override String get btnShareProfile => 'Chia sẻ';
  @override String get btnFollow => 'Theo dõi';
  @override String get btnFollowing => 'Đang theo dõi';
  @override String get btnMessage => 'Nhắn tin';
  @override String followersText(String count) => '$count người theo dõi';
  @override String followingText(String count) => '$count đang theo dõi';
  @override String get followersLabel => 'Người theo dõi';
  @override String get followingLabel => 'Đang theo dõi';
  @override String get tabThreads => 'Threads';
  @override String get tabReposts => 'Đăng lại';
  @override String get editProfileTitle => 'Chỉnh sửa trang cá nhân';
  @override String get editNameLabel => 'Tên hiển thị';
  @override String get editBioLabel => 'Tiểu sử';
  @override String get editBioPlaceholder => 'Viết vài dòng giới thiệu về bản thân...';
  @override String get updateProfileSuccess => 'Cập nhật trang cá nhân thành công!';
  @override String get noPostsYet => 'Chưa có bài viết nào được đăng';
  @override String get noRepostsYet => 'Chưa đăng lại bài viết nào';
  @override String get noFollowersYet => 'Chưa có người theo dõi nào';

  // ── Direct Messaging ─────────────────────────────────────
  @override String get messagesTitle => 'Nhắn tin';
  @override String get messageRequests => 'Tin nhắn chờ';
  @override String get newChat => 'Tin nhắn mới';
  @override String get noConversationsTitle => 'Chưa có cuộc trò chuyện nào';
  @override String get noConversationsSub => 'Bắt đầu gửi tin nhắn đến những người bạn đang theo dõi!';
  @override String get typeMessagePlaceholder => 'Nhập tin nhắn...';
  @override String get statusSending => 'Đang gửi...';
  @override String get statusSent => 'Đã gửi';
  @override String get statusDelivered => 'Đã nhận';
  @override String get statusRead => 'Đã xem';
  @override String get actionRecall => 'Thu hồi';
  @override String get actionCopy => 'Sao chép';
  @override String get messageRecalled => 'Tin nhắn đã được thu hồi';
  @override String get cannotChatSelf => 'Không thể trò chuyện với chính mình';

  // ── Auth: Login ──────────────────────────────────────────
  @override String get loginWelcome => 'Chào mừng trở lại';
  @override String get loginSubtitle => 'Đăng nhập để tiếp tục hành trình của bạn';
  @override String get emailOrUsername => 'Email hoặc tên đăng nhập';
  @override String get passwordLabel => 'Mật khẩu';
  @override String get forgotPasswordQuestion => 'Quên mật khẩu?';
  @override String get loginButton => 'Đăng nhập';
  @override String get orDivider => 'hoặc';
  @override String get continueWithGoogle => 'Tiếp tục với Google';
  @override String get dontHaveAccount => 'Chưa có tài khoản? ';
  @override String get signUpNow => 'Đăng ký';

  // ── Auth: Register ───────────────────────────────────────
  @override String get registerTitle => 'Tạo tài khoản';
  @override String get registerSubtitle => 'Tham gia cộng đồng Thread City ngay hôm nay';
  @override String get firstNameLabel => 'Họ';
  @override String get lastNameLabel => 'Tên';
  @override String get emailLabel => 'Email';
  @override String get confirmPasswordLabel => 'Nhập lại mật khẩu';
  @override String get registerButton => 'Đăng ký';
  @override String get alreadyHaveAccount => 'Đã có tài khoản? ';
  @override String get signInNow => 'Đăng nhập';
  @override String get loginFailure => 'Đăng nhập thất bại';
  @override String get googleLoginFailure => 'Đăng nhập Google thất bại';
  @override String get registerSuccess => 'Đăng ký thành công!';
  @override String get registerFailure => 'Có lỗi xảy ra khi đăng ký';
  @override String get passwordsDoNotMatch => 'Mật khẩu không khớp';
  @override String get enterPassword => 'Nhập mật khẩu';
  @override String get enterConfirmPassword => 'Nhập lại mật khẩu';
  @override String get usernameLabel => 'Tên người dùng';
  @override String get nicknameLabel => 'Biệt danh';
  @override String get nicknameHint => 'Tên hiển thị của bạn';
  @override String get usernameOrEmailHint => 'username hoặc email@example.com';

  // ── Password Rules & Checklist ───────────────────────────
  @override String get ruleLength => 'Độ dài từ 8 - 64 ký tự';
  @override String get ruleUppercase => 'Có ít nhất 1 chữ in hoa (A-Z)';
  @override String get ruleLowercase => 'Có ít nhất 1 chữ thường (a-z)';
  @override String get ruleDigit => 'Có ít nhất 1 chữ số (0-9)';
  @override String get ruleSpecial => 'Có ít nhất 1 ký tự đặc biệt (!@#\$%...)';
  @override String get ruleNoWhitespace => 'Không chứa khoảng trắng';
  @override String get ruleNotCommon => 'Không phải mật khẩu dễ đoán';
  @override String get ruleMatch => 'Mật khẩu xác nhận trùng khớp';
  @override String get ruleMatchFail => 'Mật khẩu xác nhận không khớp';

  // ── Change & Reset Password ──────────────────────────────
  @override String get changePasswordTitle => 'Đổi mật khẩu';
  @override String get changePasswordSubtitle => 'Để bảo vệ tài khoản, mật khẩu mới cần tuân thủ đầy đủ 7 quy tắc bảo mật.';
  @override String get currentPasswordLabel => 'Mật khẩu hiện tại';
  @override String get newPasswordLabel => 'Mật khẩu mới';
  @override String get confirmNewPasswordLabel => 'Nhập lại mật khẩu mới';
  @override String get saveNewPasswordButton => 'Lưu mật khẩu mới';
  @override String get changePasswordSuccess => 'Đổi mật khẩu thành công!';
  @override String get changePasswordSuccessSub => 'Mật khẩu của bạn đã được cập nhật an toàn. Bạn có thể sử dụng mật khẩu mới cho các lần đăng nhập sau.';
  @override String get passwordCannotMatchOld => 'Mật khẩu mới phải khác mật khẩu hiện tại';
  @override String get changePasswordFailure => 'Đổi mật khẩu thất bại';
  @override String get currentPasswordIncorrect => 'Mật khẩu hiện tại không chính xác';
  @override String get sessionExpiredReLogin => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để đổi mật khẩu.';
  @override String get googleAccountNoPassword => 'Tài khoản này liên kết với Google, không sử dụng mật khẩu riêng.';
  @override String get forgotPasswordTitle => 'Quên mật khẩu';
  @override String get forgotPasswordEmailSub => 'Nhập email liên kết với tài khoản của bạn để nhận mã OTP xác thực';
  @override String get sendOtpButton => 'Gửi mã xác thực';
  @override String get otpTitle => 'Xác thực OTP';
  @override String otpSentToEmail(String email) => 'Mã 6 chữ số đã được gửi đến email:\n$email';
  @override String get resendOtp => 'Gửi lại mã';
  @override String resendCountdown(int seconds) => 'Gửi lại sau (${seconds}s)';
  @override String get verifyOtpButton => 'Xác thực mã';
  @override String get noOtpReceived => 'Không nhận được mã? ';
  @override String get changeEmailAddress => 'Đổi địa chỉ email khác';
  @override String get resetPasswordButton => 'Đặt lại mật khẩu';
  @override String get resetPasswordSuccessTitle => 'Đổi mật khẩu thành công!';
  @override String get resetPasswordSuccessSub => 'Mật khẩu của bạn đã được cập nhật an toàn. Vui lòng đăng nhập bằng mật khẩu mới.';
  @override String get loginNowButton => 'Đăng nhập ngay';

  // ── Composer & Share Sheets ──────────────────────────────
  @override String get createThreadTitle => 'Tạo thread mới';
  @override String get writePlaceholder => 'Có gì mới?';
  @override String get pickImageGallery => 'Chọn ảnh từ thư viện';
  @override String get pickVideoGallery => 'Chọn video từ thư viện';
  @override String get postSuccess => 'Đã đăng thành công!';
  @override String get postFailure => 'Đăng bài thất bại';
  @override String get sharePostTitle => 'Chia sẻ bài viết';
  @override String get shareProfileTitle => 'Chia sẻ trang cá nhân';
  @override String get sendViaDM => 'Gửi qua tin nhắn';
  @override String get sendDirectMessage => 'Gửi tin nhắn riêng';
  @override String get shareViaSystem => 'Chia sẻ qua...';
  @override String get noFollowingYet => 'Bạn chưa theo dõi ai.';
  @override String sharedCountSuccess(int count) => 'Đã chia sẻ thành công đến $count người.';
  @override String get notInterested => 'Không quan tâm bài viết này';
  @override String get report => 'Báo cáo';

  // ── Auth Validation & Error Messages ─────────────────────
  @override String get pleaseEnterCurrentPassword => 'Vui lòng nhập mật khẩu hiện tại';
  @override String get pleaseEnterEmail => 'Vui lòng nhập địa chỉ email';
  @override String get invalidEmailAddress => 'Địa chỉ email không đúng định dạng';
  @override String get failedToSendOtp => 'Không thể gửi mã OTP';
  @override String get enterFullOtpCode => 'Vui lòng nhập đầy đủ 6 chữ số mã OTP';
  @override String get incorrectOtpCode => 'Mã OTP không chính xác';
  @override String get failedToResetPassword => 'Không thể đặt lại mật khẩu';
  @override String get pleaseLoginFirst => 'Vui lòng đăng nhập';
  @override String get authErrorRelogin => 'Lỗi xác thực. Vui lòng đăng nhập lại.';

  // ── Feed, Posts & Comments ───────────────────────────────
  @override String followUserConfirmTitle(String username) => 'Theo dõi @$username?';
  @override String followUserConfirmMessage(String username) => 'Bạn sẽ thấy các bài viết của @$username xuất hiện trên bảng tin của mình.';
  @override String get postNotFoundOrDeleted => 'Bài viết không tồn tại hoặc đã bị xóa';
  @override String get failedToLoadPost => 'Không thể tải bài viết. Vui lòng thử lại sau.';
  @override String get loginToComment => 'Vui lòng đăng nhập để bình luận';
  @override String get failedToSendComment => 'Không thể gửi bình luận';
  @override String viewMoreReplies(int count) => 'Xem thêm $count phản hồi...';
  @override String firstPostWithTag(String tag) => 'Hãy là người đầu tiên đăng bài với #$tag';

  // ── Options & Share ──────────────────────────────────────
  @override String get failedToDeletePost => 'Không thể xóa bài viết. Vui lòng thử lại.';
  @override String get postHiddenFromFeed => 'Đã ẩn bài viết khỏi bảng tin của bạn';
  @override String get reportReceivedThanks => 'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét nội dung này.';
  @override String get sharedPostMessage => '[Đã chia sẻ bài viết]';
  @override String viewPostShareText(String authorName, String url) => 'Xem bài viết của $authorName trên Thread-City:\n$url';
  @override String viewPostShareGenericText(String url) => 'Xem bài viết trên Thread-City:\n$url';
  @override String get cannotOpenSystemShare => 'Không thể mở trình chia sẻ của hệ thống';
  @override String viewProfileShareText(String nickname, String username, String url) => 'Xem trang cá nhân của $nickname (@$username) trên Thread-City:\n$url';

  // ── Profile & Search Feedback ────────────────────────────
  @override String get failedToLoadProfile => 'Không thể tải trang cá nhân. Hãy kéo xuống để thử lại.';
  @override String get failedToSaveProfile => 'Không thể lưu thay đổi';
  @override String get failedToUpdateProfile => 'Không thể cập nhật thông tin. Vui lòng thử lại.';
  @override String get actionFailedTryAgain => 'Thao tác thất bại. Vui lòng thử lại.';
  @override String get userNotFound => 'Không tìm thấy thông tin người dùng';
  @override String get cannotOpenChatNow => 'Không thể mở cuộc trò chuyện lúc này';
  @override String get failedToLoadTrending => 'Không thể tải xu hướng';
  @override String get failedToLoadFeed => 'Không thể tải bảng tin. Vui lòng thử lại.';
  @override String get failedToLoadFollowingFeed => 'Không thể tải bảng tin đang theo dõi.';
  @override String get failedToUploadImage => 'Lỗi tải ảnh lên. Vui lòng thử lại.';
  @override String get storagePermissionDenied => 'Firebase Storage từ chối lưu file. Hãy kiểm tra lại Rules.';
  @override String get failedToSearch => 'Không thể tìm kiếm. Vui lòng thử lại.';
  @override String get failedToLoadHashtagPosts => 'Không thể tải bài viết cho hashtag này.';

  // ── Chat & Messaging ─────────────────────────────────────
  @override String get chatStatusActive => 'Đang hoạt động';
  @override String get chatStatusOffline => 'Không hoạt động';
  @override String get chatSingleMessageLimit => 'Bạn chỉ có thể gửi 1 tin nhắn khi đối phương chưa phản hồi';
  @override String get chatRequestPending => 'Yêu cầu nhắn tin đang chờ chấp nhận. Bạn chưa thể gửi thêm tin nhắn.';
  @override String get failedToSendMessage => 'Không thể gửi tin nhắn';
  @override String get sendPhoto => 'Gửi ảnh';
  @override String get sendVideo => 'Gửi video';
  @override String get failedToUploadFile => 'Không thể tải file lên';
  @override String get startConversationPrompt => 'Hãy bắt đầu cuộc trò chuyện';
  @override String get postNoLongerExists => 'Bài viết không còn tồn tại';
  @override String get btnDecline => 'Từ chối';
  @override String get btnAccept => 'Chấp nhận';
  @override String get waitingForResponse => 'Chờ đối phương phản hồi...';
  @override String get viewProfileMenu => 'Xem trang cá nhân';
  @override String get tapToViewPost => 'Nhấn để xem bài viết';
  @override String get deleteForMe => 'Xóa phía tôi';
  @override String get blockUser => 'Chặn';
  @override String get deleteConversation => 'Xóa cuộc trò chuyện';
  @override String get tagPending => 'Đang chờ';
  @override String get tagRequest => 'Yêu cầu';
  @override String get messagePhotoTag => '[Hình ảnh]';
  @override String get messageVideoTag => '[Video]';
  @override String get chatSingleMessagePendingSender => 'Bạn đã gửi yêu cầu. Bạn chỉ có thể gửi 1 tin nhắn trước khi đối phương chấp nhận.';
  @override String get chatPendingSenderNotice => 'Bạn đã gửi 1 tin nhắn. Cuộc trò chuyện sẽ được mở khi đối phương phản hồi.';
  @override String get replyToAcceptPrompt => 'Nhắn lại để mở cuộc trò chuyện...';
  @override String get userFallback => 'Người dùng';
  @override String youPrefix(String content) => 'Bạn: $content';

  // ── Activity & Video & Notification ───────────────────────
  @override String get interactedWithYou => 'đã tương tác với bạn';
  @override String newNotificationsCount(int count) => '$count thông báo mới';
  @override String get cannotPlayVideo => 'Không thể phát video này';
  @override String get justNow => 'Vừa xong';
  @override String get sentPhotoNotification => 'Đã gửi một hình ảnh';
  @override String get sentVideoNotification => 'Đã gửi một video';

  // ── Auth & Account Detailed Errors ───────────────────────
  @override String get emailAlreadyInUse => 'Email này đã được sử dụng rồi!';
  @override String get weakPassword => 'Mật khẩu quá yếu theo chính sách bảo mật!';
  @override String get invalidEmailFormat => 'Địa chỉ email không hợp lệ';
  @override String get invalidCredentials => 'Email hoặc mật khẩu không chính xác';
  @override String get accountNotFound => 'Tài khoản không tồn tại';
  @override String get accountNotFoundForEmail => 'Không tìm thấy tài khoản với email này';
  @override String get googleAccountSignInPrompt => 'Tài khoản này đăng nhập bằng Google. Vui lòng dùng "Đăng nhập với Google" thay thế.';
  @override String get tooManyRequests => 'Yêu cầu quá nhiều lần. Vui lòng thử lại sau';
  @override String get pleaseEnterFullName => 'Vui lòng nhập họ và tên';
  @override String get cannotConnectServerCompleteRegistration => 'Không thể kết nối đến máy chủ để hoàn tất đăng ký. Vui lòng thử đăng nhập lại với tài khoản này.';
}

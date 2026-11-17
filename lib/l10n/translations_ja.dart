import 'app_strings.dart';

class TranslationsJa implements AppStrings {
  const TranslationsJa();

  // ── General & Common ──────────────────────────────────────
  @override String get appTitle => 'Thread City';
  @override String get cancel => 'キャンセル';
  @override String get confirm => '確認';
  @override String get save => '保存';
  @override String get delete => '削除';
  @override String get done => '完了';
  @override String get close => '閉じる';
  @override String get retry => '再試行';
  @override String get edit => '編集';
  @override String get share => '共有';
  @override String get loading => '読み込み中...';
  @override String get errorOccurred => 'エラーが発生しました';
  @override String get success => '成功';
  @override String get failure => '失敗';
  @override String get tryAgain => '再試行';

  // ── Language & Regional ──────────────────────────────────
  @override String get language => '言語';
  @override String get languageAuto => '自動（端末の地域設定）';
  @override String get languageVi => 'Tiếng Việt';
  @override String get languageEn => 'English';
  @override String get languageJa => '日本語';
  @override String get selectLanguage => '表示言語を選択';

  // ── Navigation ───────────────────────────────────────────
  @override String get navHome => 'ホーム';
  @override String get navSearch => '検索';
  @override String get navNewThread => '新規スレッド';
  @override String get navActivity => 'アクティビティ';
  @override String get navProfile => 'プロフィール';

  // ── Profile Menu & Settings ──────────────────────────────
  @override String get menuSettings => '設定';
  @override String get menuChangePassword => 'パスワード変更';
  @override String get menuSaved => '保存済み';
  @override String get menuYourQr => 'QRコード';
  @override String get menuLogout => 'ログアウト';
  @override String get logoutConfirmTitle => 'ログアウトしますか？';
  @override String get logoutConfirmMessage => 'アカウントからログアウトしてもよろしいですか？';

  // ── Home & Feed ──────────────────────────────────────────
  @override String get tabForYou => 'おすすめ';
  @override String get tabFollowing => 'フォロー中';
  @override String get whatsNewPlaceholder => '今なにしてる？';
  @override String get postChip => '投稿';
  @override String get emptyFeedTitle => 'まだ投稿がありません';
  @override String get emptyFeedSub => '気になる人をフォローするか、最初のスレッドを投稿してみましょう！';
  @override String get anonymousAuthor => '匿名';

  // ── Time & Formatting ────────────────────────────────────
  @override String get timeJustNow => 'たった今';
  @override String timeMinutes(int minutes) => '$minutes分前';
  @override String timeHours(int hours) => '$hours時間前';
  @override String timeDays(int days) => '$days日前';
  @override String timeWeeks(int weeks) => '$weeks週間前';

  // ── Post Card & Interactions ─────────────────────────────
  @override String get likeTooltip => 'いいね';
  @override String get commentTooltip => '返信';
  @override String get repostTooltip => '再投稿';
  @override String get shareTooltip => '共有';
  @override String get copyLink => 'リンクをコピー';
  @override String get copyLinkSuccess => 'リンクをクリップボードにコピーしました';
  @override String get deletePost => '投稿を削除';
  @override String get deleteComment => '返信を削除';
  @override String get deletePostConfirm => 'この投稿を削除してもよろしいですか？この操作は元に戻せません。';
  @override String get deleteCommentConfirm => 'この返信を削除してもよろしいですか？';
  @override String get postDeletedSuccess => '投稿が正常に削除されました';

  // ── Post Detail ──────────────────────────────────────────
  @override String get postDetailTitle => 'スレッド';
  @override String replyTo(String author) => '$author に返信中';
  @override String get authorBadge => '投稿者';
  @override String get writeReplyPlaceholder => 'スレッドに返信...';
  @override String get postReply => '返信する';
  @override String get noRepliesYet => 'まだ返信がありません';
  @override String get noRepliesSub => '最初のコメントを投稿してみましょう 🌿';

  // ── Hashtags & Trends ────────────────────────────────────
  @override String get tabTop => 'トップ';
  @override String get tabLatest => '最新';
  @override String postsCount(String count) => '$count 件の投稿';

  // ── Search & Discovery ───────────────────────────────────
  @override String get searchPlaceholder => '投稿、ユーザー、#ハッシュタグを検索...';
  @override String get tabAll => 'すべて';
  @override String get tabAccounts => 'アカウント';
  @override String get tabPosts => '投稿';
  @override String get tabHashtags => 'ハッシュタグ';
  @override String get trendingToday => '本日のトレンド';
  @override String get past7Days => '過去7日間';
  @override String get noTrendingHashtags => 'トレンドのハッシュタグはありません';
  @override String get viewAll => 'すべて見る';
  @override String get noSearchResultsTitle => '検索結果が見つかりませんでした';
  @override String get noSearchResultsSub => '別のキーワードで再検索してみてください！';
  @override String get noAccountsFound => 'アカウントが見つかりません';
  @override String get noPostsFound => '投稿が見つかりません';
  @override String get noHashtagsFound => 'ハッシュタグが見つかりません';

  // ── Activity & Notifications ─────────────────────────────
  @override String get activityTitle => 'アクティビティ';
  @override String get filterAll => 'すべて';
  @override String get filterLikes => 'いいね';
  @override String get filterReplies => '返信';
  @override String get filterFollows => 'フォロー';
  @override String get notiLikedPost => 'があなたの投稿にいいねしました';
  @override String get notiRepliedPost => 'があなたのスレッドに返信しました';
  @override String get notiFollowedYou => 'があなたをフォローしました';
  @override String get notiRepostedPost => 'があなたの投稿を再投稿しました';
  @override String get noActivityTitle => 'アクティビティはありません';
  @override String get noActivitySub => 'いいね、返信、新規フォロワーがここに表示されます 🌿';

  // ── Profile Screen ───────────────────────────────────────
  @override String get btnEditProfile => 'プロフィールを編集';
  @override String get btnShareProfile => 'プロフィールを共有';
  @override String get btnFollow => 'フォロー';
  @override String get btnFollowing => 'フォロー中';
  @override String get btnMessage => 'メッセージ';
  @override String followersText(String count) => '$count 人のフォロワー';
  @override String followingText(String count) => '$count 人をフォロー中';
  @override String get followersLabel => 'フォロワー';
  @override String get followingLabel => 'フォロー中';
  @override String get tabThreads => 'スレッド';
  @override String get tabReposts => '再投稿';
  @override String get editProfileTitle => 'プロフィール編集';
  @override String get editNameLabel => '表示名';
  @override String get editBioLabel => '自己紹介';
  @override String get editBioPlaceholder => '自己紹介文を入力してください...';
  @override String get updateProfileSuccess => 'プロフィールを更新しました！';
  @override String get noPostsYet => 'まだ投稿がありません';
  @override String get noRepostsYet => 'まだ再投稿はありません';
  @override String get noFollowersYet => 'まだフォロワーはいません';

  // ── Direct Messaging ─────────────────────────────────────
  @override String get messagesTitle => 'メッセージ';
  @override String get messageRequests => 'メッセージリクエスト';
  @override String get newChat => '新規メッセージ';
  @override String get noConversationsTitle => 'チャットがありません';
  @override String get noConversationsSub => 'フォロー中の友達にメッセージを送ってみましょう！';
  @override String get typeMessagePlaceholder => 'メッセージを入力...';
  @override String get statusSending => '送信中...';
  @override String get statusSent => '送信済み';
  @override String get statusDelivered => '配信済み';
  @override String get statusRead => '既読';
  @override String get actionRecall => '送信取消';
  @override String get actionCopy => 'コピー';
  @override String get messageRecalled => 'メッセージの送信を取り消しました';
  @override String get cannotChatSelf => '自分自身とチャットすることはできません';

  // ── Auth: Login ──────────────────────────────────────────
  @override String get loginWelcome => 'おかえりなさい';
  @override String get loginSubtitle => 'ログインして会話をはじめましょう';
  @override String get emailOrUsername => 'メールアドレスまたはユーザー名';
  @override String get passwordLabel => 'パスワード';
  @override String get forgotPasswordQuestion => 'パスワードをお忘れですか？';
  @override String get loginButton => 'ログイン';
  @override String get orDivider => 'または';
  @override String get continueWithGoogle => 'Googleで続行';
  @override String get dontHaveAccount => 'アカウントをお持ちでないですか？ ';
  @override String get signUpNow => '登録する';

  // ── Auth: Register ───────────────────────────────────────
  @override String get registerTitle => '新規登録';
  @override String get registerSubtitle => '今すぐ Thread City コミュニティに参加しましょう';
  @override String get firstNameLabel => '名';
  @override String get lastNameLabel => '姓';
  @override String get emailLabel => 'メールアドレス';
  @override String get confirmPasswordLabel => 'パスワード（確認）';
  @override String get registerButton => 'アカウントを作成';
  @override String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？ ';
  @override String get signInNow => 'ログイン';
  @override String get loginFailure => 'ログインに失敗しました';
  @override String get googleLoginFailure => 'Googleログインに失敗しました';
  @override String get registerSuccess => '登録が完了しました！';
  @override String get registerFailure => '登録中にエラーが発生しました';
  @override String get passwordsDoNotMatch => 'パスワードが一致しません';
  @override String get enterPassword => 'パスワードを入力';
  @override String get enterConfirmPassword => 'パスワードを再入力';
  @override String get usernameLabel => 'ユーザー名';
  @override String get nicknameLabel => 'ニックネーム';
  @override String get nicknameHint => '表示名';
  @override String get usernameOrEmailHint => 'ユーザー名またはemail@example.com';

  // ── Password Rules & Checklist ───────────────────────────
  @override String get ruleLength => '8〜64文字以内';
  @override String get ruleUppercase => '大文字を1文字以上含む (A-Z)';
  @override String get ruleLowercase => '小文字を1文字以上含む (a-z)';
  @override String get ruleDigit => '数字を1文字以上含む (0-9)';
  @override String get ruleSpecial => '特殊文字を1文字以上含む (!@#\$%...)';
  @override String get ruleNoWhitespace => 'スペース（空白文字）を含まない';
  @override String get ruleNotCommon => '推測されやすい一般的な文字列ではない';
  @override String get ruleMatch => '確認用パスワードと一致している';
  @override String get ruleMatchFail => 'パスワードが一致しません';

  // ── Change & Reset Password ──────────────────────────────
  @override String get changePasswordTitle => 'パスワードの変更';
  @override String get changePasswordSubtitle => 'アカウントを保護するため、新しいパスワードは7つのセキュリティルールをすべて満たす必要があります。';
  @override String get currentPasswordLabel => '現在のパスワード';
  @override String get newPasswordLabel => '新しいパスワード';
  @override String get confirmNewPasswordLabel => '新しいパスワード（確認）';
  @override String get saveNewPasswordButton => '新しいパスワードを保存';
  @override String get changePasswordSuccess => 'パスワードを変更しました！';
  @override String get changePasswordSuccessSub => 'パスワードが正常に更新されました。次回から新しいパスワードでログインできます。';
  @override String get passwordCannotMatchOld => '新しいパスワードは現在のパスワードと同じにできません';
  @override String get changePasswordFailure => 'パスワードの変更に失敗しました';
  @override String get currentPasswordIncorrect => '現在のパスワードが正しくありません';
  @override String get sessionExpiredReLogin => 'セッションの有効期限が切れました。再度ログインしてパスワードを変更してください。';
  @override String get googleAccountNoPassword => 'このアカウントはGoogleと連携しているため、専用のパスワードはありません。';
  @override String get forgotPasswordTitle => 'パスワードの再設定';
  @override String get forgotPasswordEmailSub => 'アカウントに登録されているメールアドレスを入力してください';
  @override String get sendOtpButton => '認証コードを送信';
  @override String get otpTitle => 'OTP認証';
  @override String otpSentToEmail(String email) => '6桁の確認コードを送信しました:\n$email';
  @override String get resendOtp => 'コードを再送信';
  @override String resendCountdown(int seconds) => '再送信可能まで ($seconds秒)';
  @override String get verifyOtpButton => 'コードを確認';
  @override String get noOtpReceived => 'コードが届きませんか？ ';
  @override String get changeEmailAddress => '別のメールアドレスに変更';
  @override String get resetPasswordButton => 'パスワードを再設定';
  @override String get resetPasswordSuccessTitle => 'パスワード変更完了！';
  @override String get resetPasswordSuccessSub => 'パスワードが正常に更新されました。新しいパスワードでログインしてください。';
  @override String get loginNowButton => '今すぐログイン';

  // ── Composer & Share Sheets ──────────────────────────────
  @override String get createThreadTitle => '新規スレッド';
  @override String get writePlaceholder => '今どんな気分？';
  @override String get pickImageGallery => '写真を選択';
  @override String get pickVideoGallery => '動画を選択';
  @override String get postSuccess => '投稿しました！';
  @override String get postFailure => '投稿に失敗しました';
  @override String get sharePostTitle => '投稿を共有';
  @override String get shareProfileTitle => 'プロフィールを共有';
  @override String get sendViaDM => 'ダイレクトメッセージで送信';
  @override String get sendDirectMessage => '個別メッセージで送信';
  @override String get shareViaSystem => '他のアプリで共有...';
  @override String get noFollowingYet => 'まだ誰もフォローしていません。';
  @override String sharedCountSuccess(int count) => '$count 人に共有しました。';
  @override String get notInterested => 'この投稿に興味がない';
  @override String get report => '報告';

  // ── Auth Validation & Error Messages ─────────────────────
  @override String get pleaseEnterCurrentPassword => '現在のパスワードを入力してください';
  @override String get pleaseEnterEmail => 'メールアドレスを入力してください';
  @override String get invalidEmailAddress => 'メールアドレスの形式が正しくありません';
  @override String get failedToSendOtp => 'OTPコードを送信できませんでした';
  @override String get enterFullOtpCode => '6桁のOTPコードをすべて入力してください';
  @override String get incorrectOtpCode => 'OTPコードが正しくありません';
  @override String get failedToResetPassword => 'パスワードを再設定できませんでした';
  @override String get pleaseLoginFirst => 'ログインしてください';
  @override String get authErrorRelogin => '認証エラー。再度ログインしてください。';

  // ── Feed, Posts & Comments ───────────────────────────────
  @override String followUserConfirmTitle(String username) => '@$username をフォローしますか？';
  @override String followUserConfirmMessage(String username) => '@$username の投稿がタイムラインに表示されるようになります。';
  @override String get postNotFoundOrDeleted => '投稿が存在しないか、削除されました';
  @override String get failedToLoadPost => '投稿を読み込めませんでした。後でもう一度お試しください。';
  @override String get loginToComment => '返信するにはログインしてください';
  @override String get failedToSendComment => '返信を送信できませんでした';
  @override String viewMoreReplies(int count) => '他 $count 件の返信を表示...';
  @override String firstPostWithTag(String tag) => '#$tag で最初の投稿をしてみましょう';

  // ── Options & Share ──────────────────────────────────────
  @override String get failedToDeletePost => '投稿を削除できませんでした。もう一度お試しください。';
  @override String get postHiddenFromFeed => '投稿をタイムラインから非表示にしました';
  @override String get reportReceivedThanks => 'ご報告ありがとうございます。内容を確認いたします。';
  @override String get sharedPostMessage => '[投稿を共有しました]';
  @override String viewPostShareText(String authorName, String url) => 'Thread-Cityで $authorName さんの投稿を見る:\n$url';
  @override String viewPostShareGenericText(String url) => 'Thread-Cityで投稿を見る:\n$url';
  @override String get cannotOpenSystemShare => 'システム共有を開けませんでした';
  @override String viewProfileShareText(String nickname, String username, String url) => 'Thread-Cityで $nickname さん (@$username) のプロフィールを見る:\n$url';

  // ── Profile & Search Feedback ────────────────────────────
  @override String get failedToLoadProfile => 'プロフィールを読み込めませんでした。下にスワイプして再試行してください。';
  @override String get failedToSaveProfile => '変更を保存できませんでした';
  @override String get failedToUpdateProfile => 'プロフィールを更新できませんでした。再試行してください。';
  @override String get actionFailedTryAgain => '操作に失敗しました。もう一度お試しください。';
  @override String get userNotFound => 'ユーザー情報が見つかりません';
  @override String get cannotOpenChatNow => '現在チャットを開くことができません';
  @override String get failedToLoadTrending => 'トレンドを読み込めませんでした';
  @override String get failedToLoadFeed => 'フィードを読み込めませんでした。再試行してください。';
  @override String get failedToLoadFollowingFeed => 'フォロー中フィードを読み込めませんでした。';
  @override String get failedToUploadImage => '画像のアップロードに失敗しました。再試行してください。';
  @override String get storagePermissionDenied => 'ストレージへの保存が拒否されました。設定を確認してください。';
  @override String get failedToSearch => '検索に失敗しました。再試行してください。';
  @override String get failedToLoadHashtagPosts => 'このハッシュタグの投稿を読み込めませんでした。';

  // ── Chat & Messaging ─────────────────────────────────────
  @override String get chatStatusActive => 'オンライン';
  @override String get chatStatusOffline => 'オフライン';
  @override String get chatSingleMessageLimit => '相手が返信するまで送信できるメッセージは1通のみです';
  @override String get chatRequestPending => 'メッセージリクエストの承認待ちです。まだメッセージを追加送信できません。';
  @override String get failedToSendMessage => 'メッセージを送信できませんでした';
  @override String get sendPhoto => '写真を送信';
  @override String get sendVideo => '動画を送信';
  @override String get failedToUploadFile => 'ファイルをアップロードできませんでした';
  @override String get startConversationPrompt => '会話をはじめましょう';
  @override String get postNoLongerExists => '投稿は存在しません';
  @override String get btnDecline => '拒否';
  @override String get btnAccept => '承認';
  @override String get waitingForResponse => '相手の返信を待っています...';
  @override String get viewProfileMenu => 'プロフィールを見る';
  @override String get tapToViewPost => 'タップして投稿を見る';
  @override String get deleteForMe => '自分のみ削除';
  @override String get blockUser => 'ブロック';
  @override String get deleteConversation => '会話を削除';
  @override String get tagPending => '保留中';
  @override String get tagRequest => 'リクエスト';
  @override String get messagePhotoTag => '[写真]';
  @override String get messageVideoTag => '[動画]';
  @override String get chatSingleMessagePendingSender => 'リクエストを送信しました。相手が承認するまで1通のみ送信できます。';
  @override String get chatPendingSenderNotice => '1通のメッセージを送信しました。相手が返信するとチャットが開始されます。';
  @override String get replyToAcceptPrompt => '返信してチャットを開始...';
  @override String get userFallback => 'ユーザー';
  @override String youPrefix(String content) => 'あなた: $content';

  // ── Activity & Video & Notification ───────────────────────
  @override String get interactedWithYou => 'があなたにアクションしました';
  @override String newNotificationsCount(int count) => '$count 件の新しい通知';
  @override String get cannotPlayVideo => 'この動画を再生できません';
  @override String get justNow => 'たった今';
  @override String get sentPhotoNotification => '写真を送信しました';
  @override String get sentVideoNotification => '動画を送信しました';

  // ── Auth & Account Detailed Errors ───────────────────────
  @override String get emailAlreadyInUse => 'このメールアドレスは既に使用されています。';
  @override String get weakPassword => 'セキュリティポリシーに対してパスワードが弱すぎます。';
  @override String get invalidEmailFormat => '無効なメールアドレスです。';
  @override String get invalidCredentials => 'メールアドレスまたはパスワードが正しくありません';
  @override String get accountNotFound => 'アカウントが存在しません';
  @override String get accountNotFoundForEmail => 'このメールアドレスのアカウントが見つかりません';
  @override String get googleAccountSignInPrompt => 'このアカウントはGoogleログインを使用しています。Googleでログインしてください。';
  @override String get tooManyRequests => 'リクエストが多すぎます。しばらくしてから再試行してください';
  @override String get pleaseEnterFullName => '氏名を入力してください';
  @override String get cannotConnectServerCompleteRegistration => 'サーバーに接続して登録を完了できませんでした。再度ログインをお試しください。';
}

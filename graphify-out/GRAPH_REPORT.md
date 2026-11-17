# Graph Report - Thread-City-  (2026-11-17)

## Corpus Check
- 189 files · ~92,681 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 35 file(s) not represented in the graph (top: (none) 8, .xml 7, .plist 4)

## Summary
- 2291 nodes · 3411 edges · 112 communities (88 shown, 24 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 41 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 90 edges
2. `UserProvider` - 37 edges
3. `MessageProvider` - 29 edges
4. `HomeProvider` - 26 edges
5. `PostProvider` - 22 edges
6. `dependencies` - 20 edges
7. `express` - 18 edges
8. `@prisma/client` - 14 edges
9. `getIO()` - 14 edges
10. `SearchProvider` - 12 edges

## Surprising Connections (you probably didn't know these)
- `FakePostRepository` --implements--> `IPostRepository`  [EXTRACTED]
  test/post_delete_test.dart → lib/data/repositories/post_repository.dart
- `FakeAuthProvider` --implements--> `AuthProvider`  [EXTRACTED]
  test/notification_navigation_test.dart → lib/providers/auth_provider.dart
- `_handleLogin` --references--> `AuthProvider`  [EXTRACTED]
  lib/auth/login_screen.dart → lib/providers/auth_provider.dart
- `_handleGoogleLogin` --references--> `AuthProvider`  [EXTRACTED]
  lib/auth/login_screen.dart → lib/providers/auth_provider.dart
- `_handleGoogleSignUp` --references--> `AuthProvider`  [EXTRACTED]
  lib/auth/register_screen.dart → lib/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (112 total, 24 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.01
Nodes (286): accountNotFound, accountNotFoundForEmail, actionCopy, actionFailedTryAgain, actionRecall, activityTitle, alreadyHaveAccount, anonymousAuthor (+278 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (69): accentBlue, accentGradient, accentOrange, accentPink, accentPurple, accentTeal, AppColors, avatarBg (+61 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (52): bioController, _buildFallback, _buildPostsList, _buildRepostsList, _buildUserList, controller, createState, currentNickname (+44 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (41): _activeStates, build, _calculateVisibility, child, clearCache, controller, _createAndInitController, createState (+33 more)

### Community 4 - "Community 4"
Cohesion: 0.04
Nodes (41): _buildAuthorReplyBranch, _buildAvatar, _buildBody, _buildMedia, _buildRichContent, color, _commentController, _commentFocusNode (+33 more)

### Community 5 - "Community 5"
Cohesion: 0.10
Nodes (41): AuthProvider, HomeProvider, _setupSocketListeners, PostProvider, UserProvider, _openProfile, build, build (+33 more)

### Community 6 - "Community 6"
Cohesion: 0.08
Nodes (27): generateUniqueUsername(), getUserByUid(), prisma, register(), removeVietnameseTones(), resetPasswordWithOtp(), safeUserDTO(), sendForgotPasswordOtp() (+19 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (40): build, container_name, depends_on, environment, networks, ports, restart, context (+32 more)

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (24): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsHelper, BuildContextLocalizations, _current, delegate, getStringForLocaleExact, getStringsForLocale (+16 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (30): MessageProvider, _buildMessageInput, _buildProfileCard, _buildSharedPost, ChatDetailScreen, _ChatDetailScreenState, conversation, createState (+22 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (35): dependencies, cached_network_image, cupertino_icons, firebase_auth, firebase_core, firebase_messaging, firebase_messaging_web, firebase_storage (+27 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (31): action, _activeTabIndex, build, _buildSkeletonItem, _buildTabbar, createState, didUpdateWidget, dispose (+23 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (32): _activeHashtag, _activeTab, _authProvider, clearSearch, _currentQuery, _debounceTimer, dispose, _doSearch (+24 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (33): build, _buildChecklistItem, _buildOtpBoxes, _buildPasswordChecklist, _buildPasswordField, _canResend, _confirmPasswordController, _confirmPasswordFocus (+25 more)

### Community 14 - "Community 14"
Cohesion: 0.06
Nodes (24): actions, _activityKey, badgeCount, build, _buildNavBar, createState, _currentIndex, dispose (+16 more)

### Community 15 - "Community 15"
Cohesion: 0.06
Nodes (23): currentUser, mockPosts, _buildAvatar, _buildMedia, _buildRichContent, createState, didUpdateWidget, dispose (+15 more)

### Community 16 - "Community 16"
Cohesion: 0.06
Nodes (27): AppConfig, authUrl, baseUrl, _envPublicAppUrl, _envServerUrl, getPostShareUrl, getProfileShareUrl, postsUrl (+19 more)

### Community 17 - "Community 17"
Cohesion: 0.06
Nodes (29): acceptMessageRequest, _activeConversationId, _authProvider, blockConversation, _connectSocketIfPossible, _conversationMessages, _conversations, createOrOpenConversation (+21 more)

### Community 18 - "Community 18"
Cohesion: 0.07
Nodes (27): NotificationProvider, actionText, _ActivityCard, ActivityScreen, ActivityScreenState, _animController, build, _buildEmptyState (+19 more)

### Community 19 - "Community 19"
Cohesion: 0.07
Nodes (23): getNotifications, _headers, INotificationRepository, markAsRead, NotificationRepository, connectSocket, disconnect, emitStopTyping (+15 more)

### Community 20 - "Community 20"
Cohesion: 0.07
Nodes (21): main, defaultHashtagPosts, defaultSearchResult, defaultTrending, getPostsByHashtag, getTrendingHashtags, hashtagCompleter, hashtagError (+13 more)

### Community 21 - "Community 21"
Cohesion: 0.08
Nodes (18): android, DefaultFirebaseOptions, ios, web, clearData, clearProfile, _errorMessage, fetchProfile (+10 more)

### Community 22 - "Community 22"
Cohesion: 0.07
Nodes (27): build, _buildChecklistItem, _buildFieldLabel, _buildGoogleIcon, _buildInputField, _buildPasswordChecklist, _confirmPasswordController, _confirmPasswordFocus (+19 more)

### Community 23 - "Community 23"
Cohesion: 0.19
Nodes (24): acceptRequest(), blockConversation(), createOrOpenConversation(), declineRequest(), findConversationWithGuard(), formatConversationForUser(), getAuthUserId(), getConversations() (+16 more)

### Community 24 - "Community 24"
Cohesion: 0.08
Nodes (14): AppScrollBehavior, authRepository, build, dragDevices, getScrollPhysics, initializeApp, main, messageRepository (+6 more)

### Community 25 - "Community 25"
Cohesion: 0.13
Nodes (22): HomeScreen, HomeScreenState, _LoadingSkeleton, _LoadingSkeletonState, MainScreen, _MainScreenState, _MenuItem, _MenuItemState (+14 more)

### Community 26 - "Community 26"
Cohesion: 0.08
Nodes (22): canonicalBlacklist, _digitRegex, errors, hasDigit, hasLength, hasLowercase, hasNoWhitespace, hasSpecialChar (+14 more)

### Community 27 - "Community 27"
Cohesion: 0.08
Nodes (24): build, _buildChecklistItem, _buildPasswordChecklist, _buildPasswordField, ChangePasswordSheet, _ChangePasswordSheetState, _confirmFocus, _confirmPasswordController (+16 more)

### Community 28 - "Community 28"
Cohesion: 0.08
Nodes (20): _animController, _autoDismissTimer, avatarUrl, build, createState, _currentEntry, dismiss, _dismissWithAnim (+12 more)

### Community 29 - "Community 29"
Cohesion: 0.09
Nodes (17): build, _buildGoogleIcon, _buildInputField, createState, dispose, _emailController, _emailFocus, _handleGoogleLogin (+9 more)

### Community 30 - "Community 30"
Cohesion: 0.09
Nodes (15): build, _buildActionItem, _copyLink, createState, initState, _isLoading, post, _selectedUserIds (+7 more)

### Community 31 - "Community 31"
Cohesion: 0.08
Nodes (21): avatarUrl, build, _charCount, _controller, createState, currentUsername, dispose, _focusNode (+13 more)

### Community 32 - "Community 32"
Cohesion: 0.08
Nodes (23): clearData, clearProfile, decrementCommentCount, _errorMessage, fetchProfile, followUser, getProfileDataOnly, getUserFollowers (+15 more)

### Community 33 - "Community 33"
Cohesion: 0.09
Nodes (17): _authRepository, changePassword, _currentUserData, _errorMessage, _firebaseAuth, forgotPassword, _initAuthListener, isAuthenticated (+9 more)

### Community 34 - "Community 34"
Cohesion: 0.09
Nodes (20): authUrl, BackendPolicyException, changePasswordLoggedIn, deleteCurrentFirebaseUser, EmailConflictException, errors, _firebaseAuth, getUserByFirebaseUid (+12 more)

### Community 35 - "Community 35"
Cohesion: 0.09
Nodes (20): author, commentCount, content, copyWith, createdAt, fromMap, hashtags, id (+12 more)

### Community 36 - "Community 36"
Cohesion: 0.10
Nodes (16): action, build, _buildActionItem, _checkIsAuthor, l10n, post, scaffoldMessenger, showPostOptionsSheet (+8 more)

### Community 37 - "Community 37"
Cohesion: 0.09
Nodes (22): MYSQL_DATABASE, MYSQL_PASSWORD, MYSQL_ROOT_PASSWORD, MYSQL_USER, container_name, environment, image, ports (+14 more)

### Community 38 - "Community 38"
Cohesion: 0.10
Nodes (12): _authHeaders, baseUrl, followUser, getUserFollowers, getUserFollowing, getUserProfile, IUserRepository, unfollowUser (+4 more)

### Community 39 - "Community 39"
Cohesion: 0.09
Nodes (16): _animController, _buildAllSection, _buildAllTab, _buildEmptyState, _buildHashtagsTab, _buildPostsTab, _buildSearchResultsView, _buildTabButton (+8 more)

### Community 40 - "Community 40"
Cohesion: 0.09
Nodes (21): _authProvider, clearData, decrementCommentCount, dispose, _errorMessage, fetchFeed, fetchFollowingFeed, _followingErrorMessage (+13 more)

### Community 41 - "Community 41"
Cohesion: 0.10
Nodes (16): borderRadius, build, _buildContainer, CustomCachedImage, _defaultFallback, _defaultPlaceholder, errorWidget, fit (+8 more)

### Community 42 - "Community 42"
Cohesion: 0.10
Nodes (18): behavior, BouncyTap, _BouncyTapState, build, child, _controller, createState, dispose (+10 more)

### Community 43 - "Community 43"
Cohesion: 0.17
Nodes (17): createPost(), deletePost(), getFeed(), getPostById(), getPostsByUserUid(), getReplies(), getUserReposts(), prisma (+9 more)

### Community 44 - "Community 44"
Cohesion: 0.11
Nodes (16): _buildAppBar, _buildEmptyState, conversation, ConversationsScreen, _ConversationsScreenState, _ConversationTile, _ConversationTileState, createState (+8 more)

### Community 45 - "Community 45"
Cohesion: 0.10
Nodes (18): AuthRepository, changePasswordCalls, changePasswordLoggedIn, errorToThrow, lastEmailSent, lastNewPassword, lastOtpSent, main (+10 more)

### Community 46 - "Community 46"
Cohesion: 0.10
Nodes (18): MyApp, _EmptyState, _PillButton, _TopComposeBar, _AppBarIconButton, _CenterFabButton, _FloatingNavItem, _ProfileMenuSheet (+10 more)

### Community 47 - "Community 47"
Cohesion: 0.18
Nodes (18): getPostsByHashtag(), getTrendingHashtags(), prisma, searchAll(), TrendingCache, computeEngagementRaw(), computeEngagementScore(), computeFreshnessScore() (+10 more)

### Community 48 - "Community 48"
Cohesion: 0.11
Nodes (16): build, _burstOpacity, _burstScale, _burstTranslateY, count, createState, dispose, _handleTap (+8 more)

### Community 49 - "Community 49"
Cohesion: 0.11
Nodes (15): _authProvider, dispose, _errorMessage, fetchNotifications, hasUnread, _initSocket, _isDisposed, _isLoading (+7 more)

### Community 50 - "Community 50"
Cohesion: 0.11
Nodes (15): AppTextField, _AppTextFieldState, build, controller, createState, dispose, _focusNode, hintText (+7 more)

### Community 51 - "Community 51"
Cohesion: 0.11
Nodes (18): content, conversationId, copyWith, createdAt, fromMap, id, isDeleted, mediaUrl (+10 more)

### Community 52 - "Community 52"
Cohesion: 0.11
Nodes (18): avatarUrl, bio, copyWith, firebaseUid, followerCount, fromMap, hashtags, id (+10 more)

### Community 53 - "Community 53"
Cohesion: 0.16
Nodes (13): defaultAllowedOrigins, getCorsOptions(), app, httpServer, authLimiter, createPostLimiter, globalLimiter, searchLimiter (+5 more)

### Community 54 - "Community 54"
Cohesion: 0.12
Nodes (15): acceptRequest, baseUrl, blockConversation, createOrOpenConversation, declineRequest, deleteMessage, getConversations, getMessageRequests (+7 more)

### Community 55 - "Community 55"
Cohesion: 0.12
Nodes (16): avatarUrl, bio, build, _buildActionItem, _contacts, _copyLink, createState, initState (+8 more)

### Community 56 - "Community 56"
Cohesion: 0.12
Nodes (12): _applyLanguageCode, clearLocale, _currentLanguageCode, init, _initFuture, isAuto, _isInitialized, _loadPreference (+4 more)

### Community 57 - "Community 57"
Cohesion: 0.13
Nodes (11): build, _controller, createState, dispose, _dotCount, initState, _phaseStep, _totalDuration (+3 more)

### Community 58 - "Community 58"
Cohesion: 0.13
Nodes (7): AuthGate, build, AppRoutes, home, login, onGenerateRoute, register

### Community 59 - "Community 59"
Cohesion: 0.12
Nodes (13): actor, actorId, copyWith, createdAt, fromMap, id, isRead, NotificationModel (+5 more)

### Community 60 - "Community 60"
Cohesion: 0.12
Nodes (13): ConversationModel, ConversationStatus, copyWith, fromMap, id, isMuted, lastActivityAt, lastMessage (+5 more)

### Community 61 - "Community 61"
Cohesion: 0.16
Nodes (13): SearchProvider, build, _buildSortTab, createState, HashtagFeedScreen, _HashtagFeedScreenState, initState, _onSortChanged (+5 more)

### Community 62 - "Community 62"
Cohesion: 0.14
Nodes (13): build, confirmPasswordController, createState, dispose, emailController, _FieldLabel, nicknameController, onSwitchToSignIn (+5 more)

### Community 63 - "Community 63"
Cohesion: 0.14
Nodes (14): _authHeaders, baseUrl, createPost, deletePost, getFeed, getPostById, getPostsByUserUid, getReplies (+6 more)

### Community 64 - "Community 64"
Cohesion: 0.13
Nodes (14): compilerOptions, esModuleInterop, forceConsistentCasingInFileNames, module, moduleResolution, outDir, rootDir, skipLibCheck (+6 more)

### Community 65 - "Community 65"
Cohesion: 0.15
Nodes (5): Flutter, AppDelegate, RunnerTests, UIKit, XCTest

### Community 66 - "Community 66"
Cohesion: 0.14
Nodes (10): _authProvider, createPost, deletePost, _errorMessage, getPostById, getReplies, _isLoading, _postRepository (+2 more)

### Community 67 - "Community 67"
Cohesion: 0.14
Nodes (12): avatarUrl, bio, createdAt, email, firebaseUid, fromMap, id, isOnline (+4 more)

### Community 68 - "Community 68"
Cohesion: 0.14
Nodes (6): currentUserData, getNotifications, main, markAsRead, markedAsReadIds, notificationsToReturn

### Community 69 - "Community 69"
Cohesion: 0.14
Nodes (12): createPost, deletedPostIds, deletePost, getFeed, getPostById, getPostsByUserUid, getReplies, getUserReposts (+4 more)

### Community 70 - "Community 70"
Cohesion: 0.14
Nodes (14): cors, express-rate-limit, prisma, socket.io, @socket.io/redis-adapter, @types/cors, dependencies, cors@^2.8.6 (+6 more)

### Community 71 - "Community 71"
Cohesion: 0.18
Nodes (9): LocaleProvider, build, code, _LanguageOption, LanguageSelectorSheet, leadingEmoji, showLanguageSelectorSheet, subtitle (+1 more)

### Community 72 - "Community 72"
Cohesion: 0.18
Nodes (7): auth, __dirname, __filename, messaging, rtdb, serviceAccountPath, prisma

### Community 73 - "Community 73"
Cohesion: 0.20
Nodes (7): _client, getPostsByHashtag, getTrendingHashtags, ISearchRepository, search, SearchRepository, MockSearchRepository

### Community 74 - "Community 74"
Cohesion: 0.20
Nodes (8): build, createState, dispose, onSwitchToSignUp, passwordController, SignInScreen, _SignInScreenState, usernameController

### Community 75 - "Community 75"
Cohesion: 0.18
Nodes (10): author, description, keywords, license, main, name, prisma, seed (+2 more)

### Community 76 - "Community 76"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 77 - "Community 77"
Cohesion: 0.20
Nodes (8): createdAt, fromMap, id, MediaType, mediaUrl, orderIndex, postId, PostMediaModel

### Community 78 - "Community 78"
Cohesion: 0.20
Nodes (6): dotenv, ioredis, dotenv@^17.4.2, ioredis@^5.10.1, prisma, redis

### Community 79 - "Community 79"
Cohesion: 0.36
Nodes (8): express, followUser(), getUserFollowers(), getUserFollowing(), getUserProfile(), prisma, unfollowUser(), updateProfile()

### Community 80 - "Community 80"
Cohesion: 0.22
Nodes (9): nodemon, ts-node, tsx, @types/nodemailer, devDependencies, nodemon@^3.1.14, ts-node@^10.9.2, tsx@^4.21.0 (+1 more)

### Community 81 - "Community 81"
Cohesion: 0.25
Nodes (6): _GoogleIconPainter, _GoogleIconPainter, ThreadCurvePainter, paint, shouldRepaint, ThreadVectorLogoPainter

### Community 82 - "Community 82"
Cohesion: 0.25
Nodes (5): AppLogo, build, hasShadow, isTilted, size

### Community 84 - "Community 84"
Cohesion: 0.32
Nodes (6): @prisma/client, @prisma/client@^6.19.3, getNotifications(), markNotificationAsRead(), prisma, router

### Community 85 - "Community 85"
Cohesion: 0.29
Nodes (5): createdAt, fromMap, HashtagModel, id, tagName

### Community 87 - "Community 87"
Cohesion: 0.33
Nodes (3): AppBackground, build, child

### Community 88 - "Community 88"
Cohesion: 0.40
Nodes (5): scripts, build, dev, start, test

### Community 89 - "Community 89"
Cohesion: 0.50
Nodes (3): include, linter, rules

## Knowledge Gaps
- **1380 isolated node(s):** `XCTest`, `build`, `_emailController`, `_passwordController`, `_emailFocus` (+1375 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 1663 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **24 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `Community 5` to `Community 2`, `Community 4`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 17`, `Community 18`, `Community 22`, `Community 24`, `Community 25`, `Community 27`, `Community 29`, `Community 30`, `Community 31`, `Community 33`, `Community 36`, `Community 39`, `Community 40`, `Community 44`, `Community 46`, `Community 49`, `Community 55`, `Community 66`?**
  _High betweenness centrality (0.061) - this node is a cross-community bridge._
- **What connects `XCTest`, `build`, `_emailController` to the rest of the system?**
  _1380 weakly-connected nodes found - possible missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.006968641114982578 - nodes in this community are weakly interconnected._
- **Why does `AppStrings` connect `Community 8` to `Community 0`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Why does `PostModel` connect `Community 59` to `Community 35`, `Community 4`, `Community 36`, `Community 15`, `Community 51`, `Community 30`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03571428571428571 - nodes in this community are weakly interconnected._
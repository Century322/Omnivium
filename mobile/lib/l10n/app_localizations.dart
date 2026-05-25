import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @server_address.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get server_address;

  /// No description provided for @api_server_address.
  ///
  /// In zh, this message translates to:
  /// **'API 服务器地址'**
  String get api_server_address;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @no_match_chat.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的聊天'**
  String get no_match_chat;

  /// No description provided for @camera_msg.
  ///
  /// In zh, this message translates to:
  /// **'📷 相机'**
  String get camera_msg;

  /// No description provided for @archive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get archive;

  /// No description provided for @room_not_found.
  ///
  /// In zh, this message translates to:
  /// **'房间不存在'**
  String get room_not_found;

  /// No description provided for @recall.
  ///
  /// In zh, this message translates to:
  /// **'撤回'**
  String get recall;

  /// No description provided for @personalization.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get personalization;

  /// No description provided for @for_you.
  ///
  /// In zh, this message translates to:
  /// **'为您'**
  String get for_you;

  /// No description provided for @group_chat.
  ///
  /// In zh, this message translates to:
  /// **'群聊'**
  String get group_chat;

  /// No description provided for @permission_auto.
  ///
  /// In zh, this message translates to:
  /// **'自动执行（无需确认）'**
  String get permission_auto;

  /// No description provided for @orch_self_check.
  ///
  /// In zh, this message translates to:
  /// **'自我检查: 评估回答质量...'**
  String get orch_self_check;

  /// No description provided for @fill_all_fields.
  ///
  /// In zh, this message translates to:
  /// **'请填写所有字段'**
  String get fill_all_fields;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @clear_history_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有 AI 对话和聊天缓存吗？此操作不可恢复。'**
  String get clear_history_confirm;

  /// No description provided for @privacy_e2e_title.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密'**
  String get privacy_e2e_title;

  /// No description provided for @search_users.
  ///
  /// In zh, this message translates to:
  /// **'搜索用户'**
  String get search_users;

  /// No description provided for @orch_cancelled.
  ///
  /// In zh, this message translates to:
  /// **'操作已取消'**
  String get orch_cancelled;

  /// No description provided for @typing.
  ///
  /// In zh, this message translates to:
  /// **'正在输入…'**
  String get typing;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @thought_analysis.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get thought_analysis;

  /// No description provided for @go_login.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get go_login;

  /// No description provided for @verify_with_emoji.
  ///
  /// In zh, this message translates to:
  /// **'使用 Emoji 验证'**
  String get verify_with_emoji;

  /// No description provided for @search_chat_history.
  ///
  /// In zh, this message translates to:
  /// **'搜索聊天记录'**
  String get search_chat_history;

  /// No description provided for @input_message.
  ///
  /// In zh, this message translates to:
  /// **'输入消息...'**
  String get input_message;

  /// No description provided for @pin_chat.
  ///
  /// In zh, this message translates to:
  /// **'置顶聊天'**
  String get pin_chat;

  /// No description provided for @art_culture.
  ///
  /// In zh, this message translates to:
  /// **'艺术与文化'**
  String get art_culture;

  /// No description provided for @orch_tool_exec.
  ///
  /// In zh, this message translates to:
  /// **'工具执行'**
  String get orch_tool_exec;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @project.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get project;

  /// No description provided for @web_cache_desc.
  ///
  /// In zh, this message translates to:
  /// **'链接预览等'**
  String get web_cache_desc;

  /// No description provided for @quick_explain.
  ///
  /// In zh, this message translates to:
  /// **'请用简单的话解释一下：'**
  String get quick_explain;

  /// No description provided for @new_group.
  ///
  /// In zh, this message translates to:
  /// **'新建群聊'**
  String get new_group;

  /// No description provided for @provider.
  ///
  /// In zh, this message translates to:
  /// **'提供商'**
  String get provider;

  /// No description provided for @used.
  ///
  /// In zh, this message translates to:
  /// **'已用'**
  String get used;

  /// No description provided for @permission_request.
  ///
  /// In zh, this message translates to:
  /// **'请求权限'**
  String get permission_request;

  /// No description provided for @camera_permission.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限才能拍照'**
  String get camera_permission;

  /// No description provided for @push_to_talk.
  ///
  /// In zh, this message translates to:
  /// **'按键说话'**
  String get push_to_talk;

  /// No description provided for @image.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get image;

  /// No description provided for @new_chat.
  ///
  /// In zh, this message translates to:
  /// **'新聊天'**
  String get new_chat;

  /// No description provided for @copy_id.
  ///
  /// In zh, this message translates to:
  /// **'复制 Matrix ID'**
  String get copy_id;

  /// No description provided for @new_conversation.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get new_conversation;

  /// No description provided for @no_files.
  ///
  /// In zh, this message translates to:
  /// **'暂无文件'**
  String get no_files;

  /// No description provided for @tpl_explain_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位善于解释复杂概念的导师。请用简单易懂的语言解释用户提出的问题或概念，适当使用类比和例子帮助理解。'**
  String get tpl_explain_system;

  /// No description provided for @permission_confirm_title.
  ///
  /// In zh, this message translates to:
  /// **'权限确认'**
  String get permission_confirm_title;

  /// No description provided for @photo_msg.
  ///
  /// In zh, this message translates to:
  /// **'📷 图片'**
  String get photo_msg;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @voice_recognition.
  ///
  /// In zh, this message translates to:
  /// **'语音识别'**
  String get voice_recognition;

  /// No description provided for @tpl_code_user.
  ///
  /// In zh, this message translates to:
  /// **'请帮我编写以下功能的代码：\n\n'**
  String get tpl_code_user;

  /// No description provided for @no_models.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型，点击下方添加'**
  String get no_models;

  /// No description provided for @execution_running.
  ///
  /// In zh, this message translates to:
  /// **'执行中…'**
  String get execution_running;

  /// No description provided for @notifications_desc.
  ///
  /// In zh, this message translates to:
  /// **'来自\"发现\"的每日主题'**
  String get notifications_desc;

  /// No description provided for @orch_error.
  ///
  /// In zh, this message translates to:
  /// **'出错了：'**
  String get orch_error;

  /// No description provided for @clear_cache_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有缓存数据吗？聊天记录不会被删除，但图片和文件需要重新下载。'**
  String get clear_cache_confirm;

  /// No description provided for @message_recalled.
  ///
  /// In zh, this message translates to:
  /// **'消息已撤回'**
  String get message_recalled;

  /// No description provided for @verify_instruction.
  ///
  /// In zh, this message translates to:
  /// **'请与对方比对以上验证码，确认一致则通信安全'**
  String get verify_instruction;

  /// No description provided for @orch_error_recovery.
  ///
  /// In zh, this message translates to:
  /// **'遇到错误，尝试恢复'**
  String get orch_error_recovery;

  /// No description provided for @more_members.
  ///
  /// In zh, this message translates to:
  /// **'位成员...'**
  String get more_members;

  /// No description provided for @quick_email.
  ///
  /// In zh, this message translates to:
  /// **'帮我写一封邮件：'**
  String get quick_email;

  /// No description provided for @ai_conversations.
  ///
  /// In zh, this message translates to:
  /// **'AI 对话记录'**
  String get ai_conversations;

  /// No description provided for @total.
  ///
  /// In zh, this message translates to:
  /// **'总共'**
  String get total;

  /// No description provided for @take_photo.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get take_photo;

  /// No description provided for @tpl_translate_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位专业翻译。请将用户提供的文本翻译成目标语言，保持原文的语气和风格。如果用户没有指定目标语言，默认翻译成英文。'**
  String get tpl_translate_system;

  /// No description provided for @delete_chat.
  ///
  /// In zh, this message translates to:
  /// **'删除聊天'**
  String get delete_chat;

  /// No description provided for @verification_complete.
  ///
  /// In zh, this message translates to:
  /// **'验证完成'**
  String get verification_complete;

  /// No description provided for @privacy_agree_notice.
  ///
  /// In zh, this message translates to:
  /// **'继续使用即表示你同意我们的隐私政策和服务条款。'**
  String get privacy_agree_notice;

  /// No description provided for @assistant_permissions.
  ///
  /// In zh, this message translates to:
  /// **'助手权限'**
  String get assistant_permissions;

  /// No description provided for @search_users_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入用户名或 ID...'**
  String get search_users_hint;

  /// No description provided for @verification_failed.
  ///
  /// In zh, this message translates to:
  /// **'验证失败'**
  String get verification_failed;

  /// No description provided for @hide_advanced.
  ///
  /// In zh, this message translates to:
  /// **'隐藏高级选项'**
  String get hide_advanced;

  /// No description provided for @photos_permission.
  ///
  /// In zh, this message translates to:
  /// **'需要相册权限才能选择图片'**
  String get photos_permission;

  /// No description provided for @orch_tool_needed.
  ///
  /// In zh, this message translates to:
  /// **'需要执行工具'**
  String get orch_tool_needed;

  /// No description provided for @orch_analyze_input.
  ///
  /// In zh, this message translates to:
  /// **'分析用户输入'**
  String get orch_analyze_input;

  /// No description provided for @permission_confirm_desc.
  ///
  /// In zh, this message translates to:
  /// **'执行敏感操作前需要您确认'**
  String get permission_confirm_desc;

  /// No description provided for @me.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get me;

  /// No description provided for @image_load_failed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get image_load_failed;

  /// No description provided for @tpl_brainstorm_user.
  ///
  /// In zh, this message translates to:
  /// **'请针对以下主题进行头脑风暴：\n\n'**
  String get tpl_brainstorm_user;

  /// No description provided for @narration.
  ///
  /// In zh, this message translates to:
  /// **'旁白'**
  String get narration;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'帐户'**
  String get account;

  /// No description provided for @storage_desc.
  ///
  /// In zh, this message translates to:
  /// **'查看和管理存储空间'**
  String get storage_desc;

  /// No description provided for @edit_query.
  ///
  /// In zh, this message translates to:
  /// **'编辑查询'**
  String get edit_query;

  /// No description provided for @security.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get security;

  /// No description provided for @add_contact.
  ///
  /// In zh, this message translates to:
  /// **'添加联系人'**
  String get add_contact;

  /// No description provided for @storage_used.
  ///
  /// In zh, this message translates to:
  /// **'已用存储'**
  String get storage_used;

  /// No description provided for @model_name.
  ///
  /// In zh, this message translates to:
  /// **'模型名称'**
  String get model_name;

  /// No description provided for @app_name.
  ///
  /// In zh, this message translates to:
  /// **'Omnivium'**
  String get app_name;

  /// No description provided for @pick_image.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择图片'**
  String get pick_image;

  /// No description provided for @clear_cache.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存'**
  String get clear_cache;

  /// No description provided for @permission_auto_desc.
  ///
  /// In zh, this message translates to:
  /// **'助手直接执行所有操作，无需确认'**
  String get permission_auto_desc;

  /// No description provided for @you.
  ///
  /// In zh, this message translates to:
  /// **'（你）'**
  String get you;

  /// No description provided for @thought_tool_selection.
  ///
  /// In zh, this message translates to:
  /// **'选择工具'**
  String get thought_tool_selection;

  /// No description provided for @privacy_no_collect_desc.
  ///
  /// In zh, this message translates to:
  /// **'Omnivium 不收集、不分享你的个人数据。'**
  String get privacy_no_collect_desc;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @verification_request.
  ///
  /// In zh, this message translates to:
  /// **'验证请求'**
  String get verification_request;

  /// No description provided for @ask_anything.
  ///
  /// In zh, this message translates to:
  /// **'随意提问...'**
  String get ask_anything;

  /// No description provided for @set_pin_desc.
  ///
  /// In zh, this message translates to:
  /// **'设置4-6位数字PIN码来保护你的应用'**
  String get set_pin_desc;

  /// No description provided for @quick_summarize.
  ///
  /// In zh, this message translates to:
  /// **'请总结一下我们之前的对话'**
  String get quick_summarize;

  /// No description provided for @enter_new_name.
  ///
  /// In zh, this message translates to:
  /// **'输入新名称'**
  String get enter_new_name;

  /// No description provided for @view_terms.
  ///
  /// In zh, this message translates to:
  /// **'查看服务条款'**
  String get view_terms;

  /// No description provided for @faq_title.
  ///
  /// In zh, this message translates to:
  /// **'帮助与常见问题'**
  String get faq_title;

  /// No description provided for @rename_conversation.
  ///
  /// In zh, this message translates to:
  /// **'重命名对话'**
  String get rename_conversation;

  /// No description provided for @not_encrypted.
  ///
  /// In zh, this message translates to:
  /// **'未加密'**
  String get not_encrypted;

  /// No description provided for @group_chats.
  ///
  /// In zh, this message translates to:
  /// **'群聊'**
  String get group_chats;

  /// No description provided for @default_model.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get default_model;

  /// No description provided for @use_this_model.
  ///
  /// In zh, this message translates to:
  /// **'使用此模型'**
  String get use_this_model;

  /// No description provided for @orch_handling.
  ///
  /// In zh, this message translates to:
  /// **'好的，我来帮你处理...'**
  String get orch_handling;

  /// No description provided for @follow_up.
  ///
  /// In zh, this message translates to:
  /// **'提出后续问题...'**
  String get follow_up;

  /// No description provided for @mute_off.
  ///
  /// In zh, this message translates to:
  /// **'已取消免打扰'**
  String get mute_off;

  /// No description provided for @pick_video.
  ///
  /// In zh, this message translates to:
  /// **'选择视频'**
  String get pick_video;

  /// No description provided for @data_retention.
  ///
  /// In zh, this message translates to:
  /// **'AI数据保留'**
  String get data_retention;

  /// No description provided for @verify_device.
  ///
  /// In zh, this message translates to:
  /// **'验证设备'**
  String get verify_device;

  /// No description provided for @about_title.
  ///
  /// In zh, this message translates to:
  /// **'关于 Omnivium'**
  String get about_title;

  /// No description provided for @verification_request_desc.
  ///
  /// In zh, this message translates to:
  /// **'对方正在请求验证您的设备。\n\n请确认这是您本人操作。'**
  String get verification_request_desc;

  /// No description provided for @they_dont_match.
  ///
  /// In zh, this message translates to:
  /// **'不一致'**
  String get they_dont_match;

  /// No description provided for @hands_free.
  ///
  /// In zh, this message translates to:
  /// **'免提'**
  String get hands_free;

  /// No description provided for @encrypt_verify.
  ///
  /// In zh, this message translates to:
  /// **'验证密钥'**
  String get encrypt_verify;

  /// No description provided for @invite.
  ///
  /// In zh, this message translates to:
  /// **'邀请'**
  String get invite;

  /// No description provided for @permanent_delete.
  ///
  /// In zh, this message translates to:
  /// **'永久删除'**
  String get permanent_delete;

  /// No description provided for @search_results.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果'**
  String get search_results;

  /// No description provided for @try_different_search.
  ///
  /// In zh, this message translates to:
  /// **'请尝试不同的搜索词'**
  String get try_different_search;

  /// No description provided for @orch_failed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get orch_failed;

  /// No description provided for @files_desc.
  ///
  /// In zh, this message translates to:
  /// **'聊天中收发的文件'**
  String get files_desc;

  /// No description provided for @search_history_desc.
  ///
  /// In zh, this message translates to:
  /// **'您最近的搜索内容将显示在此处'**
  String get search_history_desc;

  /// No description provided for @just_now.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get just_now;

  /// No description provided for @discover.
  ///
  /// In zh, this message translates to:
  /// **'发现'**
  String get discover;

  /// No description provided for @discover_welcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎来到 Omnivium'**
  String get discover_welcome;

  /// No description provided for @discover_welcome_desc.
  ///
  /// In zh, this message translates to:
  /// **'探索由 AI 策划的精选内容，敬请期待最新动态。'**
  String get discover_welcome_desc;

  /// No description provided for @discover_load_error.
  ///
  /// In zh, this message translates to:
  /// **'加载内容失败'**
  String get discover_load_error;

  /// No description provided for @library_empty_desc.
  ///
  /// In zh, this message translates to:
  /// **'您的历史记录和收藏将显示在此处'**
  String get library_empty_desc;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @unarchive.
  ///
  /// In zh, this message translates to:
  /// **'取消归档'**
  String get unarchive;

  /// No description provided for @privacy_policy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacy_policy;

  /// No description provided for @archived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get archived;

  /// No description provided for @ai_conversations_desc.
  ///
  /// In zh, this message translates to:
  /// **'与 AI 的对话历史'**
  String get ai_conversations_desc;

  /// No description provided for @no_chats.
  ///
  /// In zh, this message translates to:
  /// **'暂无聊天'**
  String get no_chats;

  /// No description provided for @share_via_link.
  ///
  /// In zh, this message translates to:
  /// **'通过链接分享'**
  String get share_via_link;

  /// No description provided for @thought_planning.
  ///
  /// In zh, this message translates to:
  /// **'规划'**
  String get thought_planning;

  /// No description provided for @matrix_cache_desc.
  ///
  /// In zh, this message translates to:
  /// **'房间状态、用户信息等'**
  String get matrix_cache_desc;

  /// No description provided for @not_logged_in.
  ///
  /// In zh, this message translates to:
  /// **'未登录 Matrix'**
  String get not_logged_in;

  /// No description provided for @storage.
  ///
  /// In zh, this message translates to:
  /// **'存储管理'**
  String get storage;

  /// No description provided for @select.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get select;

  /// No description provided for @clear_history.
  ///
  /// In zh, this message translates to:
  /// **'清除历史记录'**
  String get clear_history;

  /// No description provided for @mute_notifications.
  ///
  /// In zh, this message translates to:
  /// **'消息免打扰'**
  String get mute_notifications;

  /// No description provided for @enable_lock.
  ///
  /// In zh, this message translates to:
  /// **'启用应用锁'**
  String get enable_lock;

  /// No description provided for @cache.
  ///
  /// In zh, this message translates to:
  /// **'缓存'**
  String get cache;

  /// No description provided for @exit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exit;

  /// No description provided for @invalid_matrix_id.
  ///
  /// In zh, this message translates to:
  /// **'无效的 Matrix ID，格式应为 @用户名:服务器'**
  String get invalid_matrix_id;

  /// No description provided for @qr_code.
  ///
  /// In zh, this message translates to:
  /// **'二维码'**
  String get qr_code;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @cache_cleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清除'**
  String get cache_cleared;

  /// No description provided for @encryption.
  ///
  /// In zh, this message translates to:
  /// **'加密'**
  String get encryption;

  /// No description provided for @add_model.
  ///
  /// In zh, this message translates to:
  /// **'添加模型'**
  String get add_model;

  /// No description provided for @deny_permission.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get deny_permission;

  /// No description provided for @no_match_contact.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的联系人'**
  String get no_match_contact;

  /// No description provided for @execution_log.
  ///
  /// In zh, this message translates to:
  /// **'执行中…'**
  String get execution_log;

  /// No description provided for @encryption_algo.
  ///
  /// In zh, this message translates to:
  /// **'Olm/Megolm 双 Ratchet'**
  String get encryption_algo;

  /// No description provided for @mark_all_read.
  ///
  /// In zh, this message translates to:
  /// **'全部标为已读'**
  String get mark_all_read;

  /// No description provided for @quick_translate.
  ///
  /// In zh, this message translates to:
  /// **'请将以下内容翻译成英文：'**
  String get quick_translate;

  /// No description provided for @minutes_ago.
  ///
  /// In zh, this message translates to:
  /// **'分钟前'**
  String get minutes_ago;

  /// No description provided for @arch_detail.
  ///
  /// In zh, this message translates to:
  /// **'Agent + Runtime + Module'**
  String get arch_detail;

  /// No description provided for @tpl_summarize_user.
  ///
  /// In zh, this message translates to:
  /// **'请总结以下内容：\n\n'**
  String get tpl_summarize_user;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @search_error.
  ///
  /// In zh, this message translates to:
  /// **'搜索失败，请重试'**
  String get search_error;

  /// No description provided for @not_logged_in_short.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get not_logged_in_short;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get light;

  /// No description provided for @thinking_process.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get thinking_process;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @calling.
  ///
  /// In zh, this message translates to:
  /// **'正在呼叫...'**
  String get calling;

  /// No description provided for @ringing.
  ///
  /// In zh, this message translates to:
  /// **'来电响铃中'**
  String get ringing;

  /// No description provided for @connecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接...'**
  String get connecting;

  /// No description provided for @call_ended.
  ///
  /// In zh, this message translates to:
  /// **'通话已结束'**
  String get call_ended;

  /// No description provided for @mute.
  ///
  /// In zh, this message translates to:
  /// **'静音'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In zh, this message translates to:
  /// **'取消静音'**
  String get unmute;

  /// No description provided for @speaker.
  ///
  /// In zh, this message translates to:
  /// **'扬声器'**
  String get speaker;

  /// No description provided for @earpiece.
  ///
  /// In zh, this message translates to:
  /// **'听筒'**
  String get earpiece;

  /// No description provided for @hang_up.
  ///
  /// In zh, this message translates to:
  /// **'挂断'**
  String get hang_up;

  /// No description provided for @open_camera.
  ///
  /// In zh, this message translates to:
  /// **'开启摄像头'**
  String get open_camera;

  /// No description provided for @close_camera.
  ///
  /// In zh, this message translates to:
  /// **'关闭摄像头'**
  String get close_camera;

  /// No description provided for @flip_camera.
  ///
  /// In zh, this message translates to:
  /// **'翻转'**
  String get flip_camera;

  /// No description provided for @decline.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get decline;

  /// No description provided for @answer.
  ///
  /// In zh, this message translates to:
  /// **'接听'**
  String get answer;

  /// No description provided for @incorrect_pin.
  ///
  /// In zh, this message translates to:
  /// **'PIN码错误'**
  String get incorrect_pin;

  /// No description provided for @enter_pin.
  ///
  /// In zh, this message translates to:
  /// **'输入PIN码'**
  String get enter_pin;

  /// No description provided for @unlock.
  ///
  /// In zh, this message translates to:
  /// **'解锁'**
  String get unlock;

  /// No description provided for @hours_ago.
  ///
  /// In zh, this message translates to:
  /// **'小时前'**
  String get hours_ago;

  /// No description provided for @register.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// No description provided for @search_posts.
  ///
  /// In zh, this message translates to:
  /// **'搜索帖子...'**
  String get search_posts;

  /// No description provided for @thanks_feedback.
  ///
  /// In zh, this message translates to:
  /// **'感谢反馈，我们会持续改进'**
  String get thanks_feedback;

  /// No description provided for @invite_member.
  ///
  /// In zh, this message translates to:
  /// **'邀请成员'**
  String get invite_member;

  /// No description provided for @id_copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get id_copied;

  /// No description provided for @favorite_removed.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get favorite_removed;

  /// No description provided for @privacy_welcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 Omnivium！在使用前，请了解：'**
  String get privacy_welcome;

  /// No description provided for @notification_center.
  ///
  /// In zh, this message translates to:
  /// **'通知中心'**
  String get notification_center;

  /// No description provided for @login_matrix_desc.
  ///
  /// In zh, this message translates to:
  /// **'连接到 Matrix 服务器，开始加密聊天'**
  String get login_matrix_desc;

  /// No description provided for @ai_engine.
  ///
  /// In zh, this message translates to:
  /// **'AI 引擎'**
  String get ai_engine;

  /// No description provided for @direct_chats.
  ///
  /// In zh, this message translates to:
  /// **'私聊'**
  String get direct_chats;

  /// No description provided for @qr_code_desc.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码添加好友（后续支持）'**
  String get qr_code_desc;

  /// No description provided for @science_tech.
  ///
  /// In zh, this message translates to:
  /// **'科学与技术'**
  String get science_tech;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @edit_model.
  ///
  /// In zh, this message translates to:
  /// **'编辑模型'**
  String get edit_model;

  /// No description provided for @online.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get online;

  /// No description provided for @compare_emoji.
  ///
  /// In zh, this message translates to:
  /// **'对比 Emoji'**
  String get compare_emoji;

  /// No description provided for @view_profile.
  ///
  /// In zh, this message translates to:
  /// **'查看资料'**
  String get view_profile;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @got_it.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get got_it;

  /// No description provided for @file.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get file;

  /// No description provided for @waiting_for_accept.
  ///
  /// In zh, this message translates to:
  /// **'等待对方接受...'**
  String get waiting_for_accept;

  /// No description provided for @my_id.
  ///
  /// In zh, this message translates to:
  /// **'我的 ID'**
  String get my_id;

  /// No description provided for @orch_done.
  ///
  /// In zh, this message translates to:
  /// **'操作完成'**
  String get orch_done;

  /// No description provided for @thought_memory.
  ///
  /// In zh, this message translates to:
  /// **'记忆'**
  String get thought_memory;

  /// No description provided for @encrypt_not_verified.
  ///
  /// In zh, this message translates to:
  /// **'未验证'**
  String get encrypt_not_verified;

  /// No description provided for @members.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get members;

  /// No description provided for @no_contacts.
  ///
  /// In zh, this message translates to:
  /// **'暂无联系人'**
  String get no_contacts;

  /// No description provided for @quick_draw.
  ///
  /// In zh, this message translates to:
  /// **'请生成一张图片：'**
  String get quick_draw;

  /// No description provided for @permission_confirm.
  ///
  /// In zh, this message translates to:
  /// **'需要确认'**
  String get permission_confirm;

  /// No description provided for @system.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get system;

  /// No description provided for @add_contact_hint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角添加联系人'**
  String get add_contact_hint;

  /// No description provided for @notifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notifications;

  /// No description provided for @assistant_language.
  ///
  /// In zh, this message translates to:
  /// **'助手语言'**
  String get assistant_language;

  /// No description provided for @verification_error.
  ///
  /// In zh, this message translates to:
  /// **'验证过程中发生错误，请重试。'**
  String get verification_error;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @accent_color.
  ///
  /// In zh, this message translates to:
  /// **'强调色'**
  String get accent_color;

  /// No description provided for @accent_teal.
  ///
  /// In zh, this message translates to:
  /// **'青绿'**
  String get accent_teal;

  /// No description provided for @accent_ocean_blue.
  ///
  /// In zh, this message translates to:
  /// **'海洋蓝'**
  String get accent_ocean_blue;

  /// No description provided for @accent_lavender.
  ///
  /// In zh, this message translates to:
  /// **'薰衣紫'**
  String get accent_lavender;

  /// No description provided for @accent_coral.
  ///
  /// In zh, this message translates to:
  /// **'珊瑚红'**
  String get accent_coral;

  /// No description provided for @accent_amber.
  ///
  /// In zh, this message translates to:
  /// **'琥珀橙'**
  String get accent_amber;

  /// No description provided for @accent_emerald.
  ///
  /// In zh, this message translates to:
  /// **'翡翠绿'**
  String get accent_emerald;

  /// No description provided for @accent_rose.
  ///
  /// In zh, this message translates to:
  /// **'玫瑰粉'**
  String get accent_rose;

  /// No description provided for @accent_slate.
  ///
  /// In zh, this message translates to:
  /// **'石墨蓝'**
  String get accent_slate;

  /// No description provided for @orch_reflection_gap.
  ///
  /// In zh, this message translates to:
  /// **'反思发现不足'**
  String get orch_reflection_gap;

  /// No description provided for @verify_device_desc.
  ///
  /// In zh, this message translates to:
  /// **'为了确保通信安全，请验证对方的设备密钥。\n\n通过对比双方设备上显示的 Emoji 或数字来确认。'**
  String get verify_device_desc;

  /// No description provided for @base_url_customizable.
  ///
  /// In zh, this message translates to:
  /// **'Base URL（可自定义）'**
  String get base_url_customizable;

  /// No description provided for @mute_on.
  ///
  /// In zh, this message translates to:
  /// **'已开启免打扰'**
  String get mute_on;

  /// No description provided for @orch_success.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get orch_success;

  /// No description provided for @profile.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get profile;

  /// No description provided for @chat_messages_desc.
  ///
  /// In zh, this message translates to:
  /// **'包括文字、表情和系统消息'**
  String get chat_messages_desc;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get clear;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @terms_of_service.
  ///
  /// In zh, this message translates to:
  /// **'服务条款'**
  String get terms_of_service;

  /// No description provided for @images_desc.
  ///
  /// In zh, this message translates to:
  /// **'聊天中收发的图片'**
  String get images_desc;

  /// No description provided for @tpl_code_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位资深程序员。请根据用户的需求编写高质量的代码，包含必要的注释和说明。代码应当遵循最佳实践。'**
  String get tpl_code_system;

  /// No description provided for @no_users_found.
  ///
  /// In zh, this message translates to:
  /// **'未找到用户'**
  String get no_users_found;

  /// No description provided for @orch_intent_classified.
  ///
  /// In zh, this message translates to:
  /// **'意图分类'**
  String get orch_intent_classified;

  /// No description provided for @privacy_e2e_desc.
  ///
  /// In zh, this message translates to:
  /// **'你的私聊消息使用 Matrix 协议加密，我们无法读取。'**
  String get privacy_e2e_desc;

  /// No description provided for @lock_screen_desc.
  ///
  /// In zh, this message translates to:
  /// **'锁屏时助手将继续在后台执行任务。'**
  String get lock_screen_desc;

  /// No description provided for @file_msg.
  ///
  /// In zh, this message translates to:
  /// **'📎 文件'**
  String get file_msg;

  /// No description provided for @privacy_no_collect_title.
  ///
  /// In zh, this message translates to:
  /// **'不收集个人数据'**
  String get privacy_no_collect_title;

  /// No description provided for @add_by_id.
  ///
  /// In zh, this message translates to:
  /// **'通过 ID 添加'**
  String get add_by_id;

  /// No description provided for @search_id.
  ///
  /// In zh, this message translates to:
  /// **'搜索 ID 或备注...'**
  String get search_id;

  /// No description provided for @enter_new_group_name.
  ///
  /// In zh, this message translates to:
  /// **'输入新群名'**
  String get enter_new_group_name;

  /// No description provided for @architecture.
  ///
  /// In zh, this message translates to:
  /// **'架构'**
  String get architecture;

  /// No description provided for @add_via_omnivium.
  ///
  /// In zh, this message translates to:
  /// **'通过 Omnivium 添加'**
  String get add_via_omnivium;

  /// No description provided for @multi_model.
  ///
  /// In zh, this message translates to:
  /// **'多模型支持'**
  String get multi_model;

  /// No description provided for @help_faq.
  ///
  /// In zh, this message translates to:
  /// **'帮助和常见问题解答'**
  String get help_faq;

  /// No description provided for @deep_research_desc.
  ///
  /// In zh, this message translates to:
  /// **'深度报道与分析'**
  String get deep_research_desc;

  /// No description provided for @files.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get files;

  /// No description provided for @auto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get auto;

  /// No description provided for @tpl_summarize_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位专业的总结助手。请将用户提供的文本进行精炼总结，提取核心要点，保持简洁明了。'**
  String get tpl_summarize_system;

  /// No description provided for @permission_deny.
  ///
  /// In zh, this message translates to:
  /// **'禁止执行'**
  String get permission_deny;

  /// No description provided for @add_via_omnivium_desc.
  ///
  /// In zh, this message translates to:
  /// **'在 Omnivium 内直接添加好友'**
  String get add_via_omnivium_desc;

  /// No description provided for @tpl_polish_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位专业的文字润色编辑。请优化用户提供的文本，改善措辞、修正语法错误、提升表达质量，但保持原文的核心意思不变。'**
  String get tpl_polish_system;

  /// No description provided for @quick_search.
  ///
  /// In zh, this message translates to:
  /// **'帮我搜索最新的'**
  String get quick_search;

  /// No description provided for @share_method.
  ///
  /// In zh, this message translates to:
  /// **'分享方式'**
  String get share_method;

  /// No description provided for @friends.
  ///
  /// In zh, this message translates to:
  /// **'好友'**
  String get friends;

  /// No description provided for @compare_emoji_desc.
  ///
  /// In zh, this message translates to:
  /// **'请确认双方设备上显示的 Emoji 是否一致。\n\n如果一致，说明通信安全。'**
  String get compare_emoji_desc;

  /// No description provided for @tpl_email_user.
  ///
  /// In zh, this message translates to:
  /// **'请帮我写一封邮件：\n\n'**
  String get tpl_email_user;

  /// No description provided for @video_call.
  ///
  /// In zh, this message translates to:
  /// **'视频通话'**
  String get video_call;

  /// No description provided for @listen.
  ///
  /// In zh, this message translates to:
  /// **'听'**
  String get listen;

  /// No description provided for @privacy_key_desc.
  ///
  /// In zh, this message translates to:
  /// **'你的 AI API Key 加密存储，不会上传到任何服务器。'**
  String get privacy_key_desc;

  /// No description provided for @verifying.
  ///
  /// In zh, this message translates to:
  /// **'验证中...'**
  String get verifying;

  /// No description provided for @chat_messages.
  ///
  /// In zh, this message translates to:
  /// **'聊天消息'**
  String get chat_messages;

  /// No description provided for @options.
  ///
  /// In zh, this message translates to:
  /// **'选项'**
  String get options;

  /// No description provided for @tpl_write_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位专业的写作助手。请根据用户的要求撰写高质量的文章、文案或创意内容。内容应当结构清晰、语言流畅。'**
  String get tpl_write_system;

  /// No description provided for @headline_news.
  ///
  /// In zh, this message translates to:
  /// **'头条新闻'**
  String get headline_news;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @search_messages.
  ///
  /// In zh, this message translates to:
  /// **'搜索消息...'**
  String get search_messages;

  /// No description provided for @lock_screen.
  ///
  /// In zh, this message translates to:
  /// **'锁屏设置'**
  String get lock_screen;

  /// No description provided for @orch_memory_found.
  ///
  /// In zh, this message translates to:
  /// **'检索到相关记忆'**
  String get orch_memory_found;

  /// No description provided for @image_model.
  ///
  /// In zh, this message translates to:
  /// **'图像生成模型'**
  String get image_model;

  /// No description provided for @chat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get chat;

  /// No description provided for @delete_account.
  ///
  /// In zh, this message translates to:
  /// **'删除帐户'**
  String get delete_account;

  /// No description provided for @user.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get user;

  /// No description provided for @library.
  ///
  /// In zh, this message translates to:
  /// **'库'**
  String get library;

  /// No description provided for @web_cache.
  ///
  /// In zh, this message translates to:
  /// **'网页缓存'**
  String get web_cache;

  /// No description provided for @tpl_explain_user.
  ///
  /// In zh, this message translates to:
  /// **'请帮我解释以下概念：\n\n'**
  String get tpl_explain_user;

  /// No description provided for @videos.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get videos;

  /// No description provided for @permission_deny_desc.
  ///
  /// In zh, this message translates to:
  /// **'助手仅提供建议，不执行任何操作'**
  String get permission_deny_desc;

  /// No description provided for @tpl_brainstorm_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位创意顾问。请针对用户提出的主题进行头脑风暴，提供多个创新的想法和方案，每个想法附带简要说明。'**
  String get tpl_brainstorm_system;

  /// No description provided for @view_components.
  ///
  /// In zh, this message translates to:
  /// **'查看开源组件'**
  String get view_components;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @advanced_options.
  ///
  /// In zh, this message translates to:
  /// **'高级选项'**
  String get advanced_options;

  /// No description provided for @encrypt_verified.
  ///
  /// In zh, this message translates to:
  /// **'已验证'**
  String get encrypt_verified;

  /// No description provided for @add_by_id_desc.
  ///
  /// In zh, this message translates to:
  /// **'输入 Matrix ID 直接发起加密聊天'**
  String get add_by_id_desc;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @no_conversations.
  ///
  /// In zh, this message translates to:
  /// **'暂无对话'**
  String get no_conversations;

  /// No description provided for @days_ago.
  ///
  /// In zh, this message translates to:
  /// **'天前'**
  String get days_ago;

  /// No description provided for @regenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get regenerate;

  /// No description provided for @matrix_cache.
  ///
  /// In zh, this message translates to:
  /// **'Matrix 缓存'**
  String get matrix_cache;

  /// No description provided for @actions.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get actions;

  /// No description provided for @group_name.
  ///
  /// In zh, this message translates to:
  /// **'群聊名称'**
  String get group_name;

  /// No description provided for @enable_assistant_desc.
  ///
  /// In zh, this message translates to:
  /// **'AI Agent 自动执行任务'**
  String get enable_assistant_desc;

  /// No description provided for @tpl_email_system.
  ///
  /// In zh, this message translates to:
  /// **'你是一位专业的商务邮件撰写助手。请根据用户的需求撰写得体、专业的邮件内容。'**
  String get tpl_email_system;

  /// No description provided for @images.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get images;

  /// No description provided for @privacy_ai_desc.
  ///
  /// In zh, this message translates to:
  /// **'AI 对话由第三方模型提供商处理，请勿输入敏感信息。'**
  String get privacy_ai_desc;

  /// No description provided for @agree_continue.
  ///
  /// In zh, this message translates to:
  /// **'同意并继续'**
  String get agree_continue;

  /// No description provided for @view_privacy.
  ///
  /// In zh, this message translates to:
  /// **'查看隐私政策'**
  String get view_privacy;

  /// No description provided for @storage_overview.
  ///
  /// In zh, this message translates to:
  /// **'已用存储'**
  String get storage_overview;

  /// No description provided for @friend_invite.
  ///
  /// In zh, this message translates to:
  /// **'好友邀请'**
  String get friend_invite;

  /// No description provided for @tpl_polish_user.
  ///
  /// In zh, this message translates to:
  /// **'请帮我润色以下文本：\n\n'**
  String get tpl_polish_user;

  /// No description provided for @privacy_key_title.
  ///
  /// In zh, this message translates to:
  /// **'API Key 安全存储'**
  String get privacy_key_title;

  /// No description provided for @confirm_delete_account.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除你的 Matrix 帐户吗？此操作不可恢复。'**
  String get confirm_delete_account;

  /// No description provided for @ai_generated_images_desc.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成的图片'**
  String get ai_generated_images_desc;

  /// No description provided for @favorite_added.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get favorite_added;

  /// No description provided for @share_via_link_desc.
  ///
  /// In zh, this message translates to:
  /// **'生成邀请链接'**
  String get share_via_link_desc;

  /// No description provided for @verification_complete_desc.
  ///
  /// In zh, this message translates to:
  /// **'设备验证成功！\n\n现在您可以安全地与对方通信。'**
  String get verification_complete_desc;

  /// No description provided for @no_account_create.
  ///
  /// In zh, this message translates to:
  /// **'没有账号？创建一个'**
  String get no_account_create;

  /// No description provided for @privacy_ai_title.
  ///
  /// In zh, this message translates to:
  /// **'AI 对话处理'**
  String get privacy_ai_title;

  /// No description provided for @about_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 驱动的超级生活平台'**
  String get about_subtitle;

  /// No description provided for @incognito.
  ///
  /// In zh, this message translates to:
  /// **'隐身模式'**
  String get incognito;

  /// No description provided for @incognito_mode.
  ///
  /// In zh, this message translates to:
  /// **'隐身模式'**
  String get incognito_mode;

  /// No description provided for @private_chat.
  ///
  /// In zh, this message translates to:
  /// **'私聊'**
  String get private_chat;

  /// No description provided for @username.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @ai_data.
  ///
  /// In zh, this message translates to:
  /// **'AI 数据'**
  String get ai_data;

  /// No description provided for @voice_mode.
  ///
  /// In zh, this message translates to:
  /// **'语音模式'**
  String get voice_mode;

  /// No description provided for @grant_permission.
  ///
  /// In zh, this message translates to:
  /// **'允许'**
  String get grant_permission;

  /// No description provided for @edit_group_name.
  ///
  /// In zh, this message translates to:
  /// **'修改群名'**
  String get edit_group_name;

  /// No description provided for @protocol.
  ///
  /// In zh, this message translates to:
  /// **'协议'**
  String get protocol;

  /// No description provided for @they_match.
  ///
  /// In zh, this message translates to:
  /// **'一致'**
  String get they_match;

  /// No description provided for @pick_file.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get pick_file;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @read.
  ///
  /// In zh, this message translates to:
  /// **'已读'**
  String get read;

  /// No description provided for @voice_call.
  ///
  /// In zh, this message translates to:
  /// **'语音通话'**
  String get voice_call;

  /// No description provided for @yesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get yesterday;

  /// No description provided for @orch_quality_score.
  ///
  /// In zh, this message translates to:
  /// **'回答质量评分'**
  String get orch_quality_score;

  /// No description provided for @no_match_msg.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的消息'**
  String get no_match_msg;

  /// No description provided for @offline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get offline;

  /// No description provided for @videos_desc.
  ///
  /// In zh, this message translates to:
  /// **'聊天中收发的视频'**
  String get videos_desc;

  /// No description provided for @start_new_chat_hint.
  ///
  /// In zh, this message translates to:
  /// **'点击下方按钮开始新对话'**
  String get start_new_chat_hint;

  /// No description provided for @enter_matrix_id.
  ///
  /// In zh, this message translates to:
  /// **'输入 Matrix ID，如 @user:localhost'**
  String get enter_matrix_id;

  /// No description provided for @tech_stack.
  ///
  /// In zh, this message translates to:
  /// **'技术栈'**
  String get tech_stack;

  /// No description provided for @e2e_encrypted.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密通信'**
  String get e2e_encrypted;

  /// No description provided for @no_notifications.
  ///
  /// In zh, this message translates to:
  /// **'暂无通知'**
  String get no_notifications;

  /// No description provided for @verify_unavailable.
  ///
  /// In zh, this message translates to:
  /// **'验证信息不可用'**
  String get verify_unavailable;

  /// No description provided for @camera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get camera;

  /// No description provided for @data_retention_desc.
  ///
  /// In zh, this message translates to:
  /// **'允许 Omnivium 使用您的搜索数据来改进 AI 模型'**
  String get data_retention_desc;

  /// No description provided for @delete_account_desc.
  ///
  /// In zh, this message translates to:
  /// **'永久删除您的帐户'**
  String get delete_account_desc;

  /// No description provided for @have_account_login.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？登录'**
  String get have_account_login;

  /// No description provided for @thought_reflection.
  ///
  /// In zh, this message translates to:
  /// **'反思'**
  String get thought_reflection;

  /// No description provided for @ai.
  ///
  /// In zh, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @encrypt_info.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密已启用'**
  String get encrypt_info;

  /// No description provided for @no_search_results.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关结果'**
  String get no_search_results;

  /// No description provided for @privacy_title.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacy_title;

  /// No description provided for @deep_research.
  ///
  /// In zh, this message translates to:
  /// **'深入研究'**
  String get deep_research;

  /// No description provided for @tpl_translate_user.
  ///
  /// In zh, this message translates to:
  /// **'请将以下内容翻译：\n\n'**
  String get tpl_translate_user;

  /// No description provided for @help_center.
  ///
  /// In zh, this message translates to:
  /// **'帮助中心'**
  String get help_center;

  /// No description provided for @terms_title.
  ///
  /// In zh, this message translates to:
  /// **'服务条款'**
  String get terms_title;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get dark;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @unknown_action.
  ///
  /// In zh, this message translates to:
  /// **'未知操作'**
  String get unknown_action;

  /// No description provided for @add_contact_failed.
  ///
  /// In zh, this message translates to:
  /// **'添加联系人失败'**
  String get add_contact_failed;

  /// No description provided for @no_search_history.
  ///
  /// In zh, this message translates to:
  /// **'未找到搜索历史记录'**
  String get no_search_history;

  /// No description provided for @model_hint.
  ///
  /// In zh, this message translates to:
  /// **'例如 gpt-4o、deepseek-chat...'**
  String get model_hint;

  /// No description provided for @business.
  ///
  /// In zh, this message translates to:
  /// **'商业'**
  String get business;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @not_helpful.
  ///
  /// In zh, this message translates to:
  /// **'没有帮助'**
  String get not_helpful;

  /// No description provided for @share_conversation.
  ///
  /// In zh, this message translates to:
  /// **'分享对话'**
  String get share_conversation;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @thought_evaluation.
  ///
  /// In zh, this message translates to:
  /// **'评估'**
  String get thought_evaluation;

  /// No description provided for @encrypted.
  ///
  /// In zh, this message translates to:
  /// **'已加密'**
  String get encrypted;

  /// No description provided for @file_manager.
  ///
  /// In zh, this message translates to:
  /// **'文件管理'**
  String get file_manager;

  /// No description provided for @search_history.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史'**
  String get search_history;

  /// No description provided for @orch_confidence.
  ///
  /// In zh, this message translates to:
  /// **'置信度'**
  String get orch_confidence;

  /// No description provided for @chat_data.
  ///
  /// In zh, this message translates to:
  /// **'聊天数据'**
  String get chat_data;

  /// No description provided for @waiting_for_confirm.
  ///
  /// In zh, this message translates to:
  /// **'等待对方确认...'**
  String get waiting_for_confirm;

  /// No description provided for @contacts.
  ///
  /// In zh, this message translates to:
  /// **'联系人'**
  String get contacts;

  /// No description provided for @clear_history_desc.
  ///
  /// In zh, this message translates to:
  /// **'清除所有 AI 对话和聊天缓存'**
  String get clear_history_desc;

  /// No description provided for @source_info.
  ///
  /// In zh, this message translates to:
  /// **'来源信息'**
  String get source_info;

  /// No description provided for @total_used.
  ///
  /// In zh, this message translates to:
  /// **'总共 1 GB · 已用 9.7%'**
  String get total_used;

  /// No description provided for @coming_soon.
  ///
  /// In zh, this message translates to:
  /// **'即将推出'**
  String get coming_soon;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于 Omnivium'**
  String get about;

  /// No description provided for @incognito_notice.
  ///
  /// In zh, this message translates to:
  /// **'在隐身模式下，Omnivium 不会保存你的活动；关闭问题后，它们也不会出现在你的库中。'**
  String get incognito_notice;

  /// No description provided for @orch_sorry_error.
  ///
  /// In zh, this message translates to:
  /// **'抱歉，出了点问题：'**
  String get orch_sorry_error;

  /// No description provided for @invited_you_to_chat.
  ///
  /// In zh, this message translates to:
  /// **'邀请你加入聊天'**
  String get invited_you_to_chat;

  /// No description provided for @verify_with_numbers.
  ///
  /// In zh, this message translates to:
  /// **'使用数字验证'**
  String get verify_with_numbers;

  /// No description provided for @group_settings.
  ///
  /// In zh, this message translates to:
  /// **'群聊设置'**
  String get group_settings;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get thinking;

  /// No description provided for @enable_assistant.
  ///
  /// In zh, this message translates to:
  /// **'启用助手'**
  String get enable_assistant;

  /// No description provided for @create_account.
  ///
  /// In zh, this message translates to:
  /// **'创建账号'**
  String get create_account;

  /// No description provided for @open_source.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get open_source;

  /// No description provided for @tpl_write_user.
  ///
  /// In zh, this message translates to:
  /// **'请帮我写一篇关于以下主题的内容：\n\n'**
  String get tpl_write_user;

  /// No description provided for @voice_send_failed.
  ///
  /// In zh, this message translates to:
  /// **'语音消息发送失败'**
  String get voice_send_failed;

  /// No description provided for @ai_generated_images.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成图片'**
  String get ai_generated_images;

  /// No description provided for @system_default.
  ///
  /// In zh, this message translates to:
  /// **'系统默认'**
  String get system_default;

  /// No description provided for @incognito_desc.
  ///
  /// In zh, this message translates to:
  /// **'在隐身模式下，Omnivium 不会保存你的活动；关闭问题后，它们也不会出现在你的库中。'**
  String get incognito_desc;

  /// No description provided for @assistant.
  ///
  /// In zh, this message translates to:
  /// **'助手'**
  String get assistant;

  /// No description provided for @agent_replay.
  ///
  /// In zh, this message translates to:
  /// **'智能体回放'**
  String get agent_replay;

  /// No description provided for @ai_operation_log.
  ///
  /// In zh, this message translates to:
  /// **'AI 操作日志'**
  String get ai_operation_log;

  /// No description provided for @ai_operation_log_desc.
  ///
  /// In zh, this message translates to:
  /// **'查看 AI 操作记录、权限检查和审计追踪'**
  String get ai_operation_log_desc;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @permissions.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get permissions;

  /// No description provided for @violations.
  ///
  /// In zh, this message translates to:
  /// **'违规'**
  String get violations;

  /// No description provided for @total_ops.
  ///
  /// In zh, this message translates to:
  /// **'总操作'**
  String get total_ops;

  /// No description provided for @allowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get allowed;

  /// No description provided for @denied.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get denied;

  /// No description provided for @no_operation_logs.
  ///
  /// In zh, this message translates to:
  /// **'暂无操作日志'**
  String get no_operation_logs;

  /// No description provided for @type.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get type;

  /// No description provided for @actor.
  ///
  /// In zh, this message translates to:
  /// **'操作者'**
  String get actor;

  /// No description provided for @target.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get target;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get status;

  /// No description provided for @details.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get details;

  /// No description provided for @ai_permission_management.
  ///
  /// In zh, this message translates to:
  /// **'AI 权限管理'**
  String get ai_permission_management;

  /// No description provided for @ai_permission_management_desc.
  ///
  /// In zh, this message translates to:
  /// **'管理 AI 能力与权限'**
  String get ai_permission_management_desc;

  /// No description provided for @global_permission_mode.
  ///
  /// In zh, this message translates to:
  /// **'全局权限模式'**
  String get global_permission_mode;

  /// No description provided for @global_permission_desc.
  ///
  /// In zh, this message translates to:
  /// **'所有 AI 能力的默认权限。可在下方单独覆盖。'**
  String get global_permission_desc;

  /// No description provided for @auto_execute.
  ///
  /// In zh, this message translates to:
  /// **'自动执行'**
  String get auto_execute;

  /// No description provided for @need_confirm.
  ///
  /// In zh, this message translates to:
  /// **'需要确认'**
  String get need_confirm;

  /// No description provided for @always_deny.
  ///
  /// In zh, this message translates to:
  /// **'始终拒绝'**
  String get always_deny;

  /// No description provided for @custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @sovereign_identity.
  ///
  /// In zh, this message translates to:
  /// **'主权身份'**
  String get sovereign_identity;

  /// No description provided for @did.
  ///
  /// In zh, this message translates to:
  /// **'DID'**
  String get did;

  /// No description provided for @node_id.
  ///
  /// In zh, this message translates to:
  /// **'节点 ID'**
  String get node_id;

  /// No description provided for @public_key.
  ///
  /// In zh, this message translates to:
  /// **'公钥'**
  String get public_key;

  /// No description provided for @civilization_epoch.
  ///
  /// In zh, this message translates to:
  /// **'文明纪元'**
  String get civilization_epoch;

  /// No description provided for @federation_id.
  ///
  /// In zh, this message translates to:
  /// **'联邦 ID'**
  String get federation_id;

  /// No description provided for @created_at.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get created_at;

  /// No description provided for @copy_did.
  ///
  /// In zh, this message translates to:
  /// **'复制 DID'**
  String get copy_did;

  /// No description provided for @did_copied.
  ///
  /// In zh, this message translates to:
  /// **'DID 已复制'**
  String get did_copied;

  /// No description provided for @trust_level.
  ///
  /// In zh, this message translates to:
  /// **'信任等级'**
  String get trust_level;

  /// No description provided for @trust_system.
  ///
  /// In zh, this message translates to:
  /// **'系统级'**
  String get trust_system;

  /// No description provided for @trust_signed.
  ///
  /// In zh, this message translates to:
  /// **'已签名'**
  String get trust_signed;

  /// No description provided for @trust_verified.
  ///
  /// In zh, this message translates to:
  /// **'已验证'**
  String get trust_verified;

  /// No description provided for @trust_untrusted.
  ///
  /// In zh, this message translates to:
  /// **'未受信'**
  String get trust_untrusted;

  /// No description provided for @trust_blocked.
  ///
  /// In zh, this message translates to:
  /// **'已封禁'**
  String get trust_blocked;

  /// No description provided for @ancestry.
  ///
  /// In zh, this message translates to:
  /// **'血统'**
  String get ancestry;

  /// No description provided for @credentials.
  ///
  /// In zh, this message translates to:
  /// **'凭证'**
  String get credentials;

  /// No description provided for @no_credentials.
  ///
  /// In zh, this message translates to:
  /// **'暂无凭证'**
  String get no_credentials;

  /// No description provided for @no_sovereign_identity.
  ///
  /// In zh, this message translates to:
  /// **'无主权身份'**
  String get no_sovereign_identity;

  /// No description provided for @no_sovereign_identity_desc.
  ///
  /// In zh, this message translates to:
  /// **'登录后自动生成您的主权数字身份'**
  String get no_sovereign_identity_desc;

  /// No description provided for @capability_confirm_title.
  ///
  /// In zh, this message translates to:
  /// **'能力确认'**
  String get capability_confirm_title;

  /// No description provided for @capability_confirm_msg.
  ///
  /// In zh, this message translates to:
  /// **'AI 请求执行: {capability}。是否允许？'**
  String capability_confirm_msg(Object capability);

  /// No description provided for @report_confirm_msg.
  ///
  /// In zh, this message translates to:
  /// **'确定要举报此用户吗？'**
  String get report_confirm_msg;

  /// No description provided for @report_submitted.
  ///
  /// In zh, this message translates to:
  /// **'举报已提交'**
  String get report_submitted;

  /// No description provided for @block_confirm_msg.
  ///
  /// In zh, this message translates to:
  /// **'确定要屏蔽此用户吗？屏蔽后对方将无法给您发送消息。'**
  String get block_confirm_msg;

  /// No description provided for @user_blocked.
  ///
  /// In zh, this message translates to:
  /// **'用户已屏蔽'**
  String get user_blocked;

  /// No description provided for @delete_chat_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此聊天吗？此操作不可撤销。'**
  String get delete_chat_confirm;

  /// No description provided for @delete_session.
  ///
  /// In zh, this message translates to:
  /// **'删除会话'**
  String get delete_session;

  /// No description provided for @delete_session_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此会话吗？所有消息将丢失。'**
  String get delete_session_confirm;

  /// No description provided for @open_chat.
  ///
  /// In zh, this message translates to:
  /// **'打开聊天'**
  String get open_chat;

  /// No description provided for @remove_friend.
  ///
  /// In zh, this message translates to:
  /// **'删除好友'**
  String get remove_friend;

  /// No description provided for @remove_friend_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此好友吗？聊天将被关闭。'**
  String get remove_friend_confirm;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get remove;

  /// No description provided for @clear_all.
  ///
  /// In zh, this message translates to:
  /// **'清空全部'**
  String get clear_all;

  /// No description provided for @clear_all_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有通知吗？'**
  String get clear_all_confirm;

  /// No description provided for @add_me_omnivium.
  ///
  /// In zh, this message translates to:
  /// **'在 Omnivium 上添加我'**
  String get add_me_omnivium;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @something_went_wrong.
  ///
  /// In zh, this message translates to:
  /// **'出了点问题'**
  String get something_went_wrong;

  /// No description provided for @error_boundary_desc.
  ///
  /// In zh, this message translates to:
  /// **'发生了意外错误，请重试。'**
  String get error_boundary_desc;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @ai_request_confirm.
  ///
  /// In zh, this message translates to:
  /// **'AI 请求确认'**
  String get ai_request_confirm;

  /// No description provided for @clear_chat_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认清空聊天记录？'**
  String get clear_chat_confirm;

  /// No description provided for @clear_chat.
  ///
  /// In zh, this message translates to:
  /// **'清空聊天'**
  String get clear_chat;

  /// No description provided for @close_incognito.
  ///
  /// In zh, this message translates to:
  /// **'关闭隐身模式'**
  String get close_incognito;

  /// No description provided for @conversations.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get conversations;

  /// No description provided for @delete_conversation.
  ///
  /// In zh, this message translates to:
  /// **'删除对话'**
  String get delete_conversation;

  /// No description provided for @e2e_benefits.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密的好处'**
  String get e2e_benefits;

  /// No description provided for @e2e_detail.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密详情'**
  String get e2e_detail;

  /// No description provided for @e2e_encrypted_short.
  ///
  /// In zh, this message translates to:
  /// **'端到端加密'**
  String get e2e_encrypted_short;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @faq_q1.
  ///
  /// In zh, this message translates to:
  /// **'Omnivium 是什么？'**
  String get faq_q1;

  /// No description provided for @faq_q2.
  ///
  /// In zh, this message translates to:
  /// **'我的数据安全吗？'**
  String get faq_q2;

  /// No description provided for @faq_q3.
  ///
  /// In zh, this message translates to:
  /// **'如何更换 AI 模型？'**
  String get faq_q3;

  /// No description provided for @faq_q4.
  ///
  /// In zh, this message translates to:
  /// **'支持哪些语言？'**
  String get faq_q4;

  /// No description provided for @faq_q5.
  ///
  /// In zh, this message translates to:
  /// **'如何删除账户？'**
  String get faq_q5;

  /// No description provided for @faq_q6.
  ///
  /// In zh, this message translates to:
  /// **'隐身模式是什么？'**
  String get faq_q6;

  /// No description provided for @faq_q7.
  ///
  /// In zh, this message translates to:
  /// **'如何添加好友？'**
  String get faq_q7;

  /// No description provided for @faq_q8.
  ///
  /// In zh, this message translates to:
  /// **'消息可以撤回吗？'**
  String get faq_q8;

  /// No description provided for @faq_q9.
  ///
  /// In zh, this message translates to:
  /// **'支持语音通话吗？'**
  String get faq_q9;

  /// No description provided for @faq_q10.
  ///
  /// In zh, this message translates to:
  /// **'如何反馈问题？'**
  String get faq_q10;

  /// No description provided for @favorite_conversation.
  ///
  /// In zh, this message translates to:
  /// **'收藏对话'**
  String get favorite_conversation;

  /// No description provided for @favorited.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get favorited;

  /// No description provided for @fingerprint_key.
  ///
  /// In zh, this message translates to:
  /// **'指纹密钥'**
  String get fingerprint_key;

  /// No description provided for @identity_key.
  ///
  /// In zh, this message translates to:
  /// **'身份密钥'**
  String get identity_key;

  /// No description provided for @incognito_mode_short.
  ///
  /// In zh, this message translates to:
  /// **'隐身模式'**
  String get incognito_mode_short;

  /// No description provided for @input.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get input;

  /// No description provided for @leave_group.
  ///
  /// In zh, this message translates to:
  /// **'退出群聊'**
  String get leave_group;

  /// No description provided for @leave_group_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认退出群聊？'**
  String get leave_group_confirm;

  /// No description provided for @listening.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听'**
  String get listening;

  /// No description provided for @messages.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get messages;

  /// No description provided for @mute_chat.
  ///
  /// In zh, this message translates to:
  /// **'静音聊天'**
  String get mute_chat;

  /// No description provided for @muted_off.
  ///
  /// In zh, this message translates to:
  /// **'已取消静音'**
  String get muted_off;

  /// No description provided for @no_agent_logs.
  ///
  /// In zh, this message translates to:
  /// **'暂无智能体日志'**
  String get no_agent_logs;

  /// No description provided for @no_e2e_detail.
  ///
  /// In zh, this message translates to:
  /// **'未加密详情'**
  String get no_e2e_detail;

  /// No description provided for @output.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get output;

  /// No description provided for @search_conversation.
  ///
  /// In zh, this message translates to:
  /// **'搜索对话'**
  String get search_conversation;

  /// No description provided for @security_warning.
  ///
  /// In zh, this message translates to:
  /// **'安全警告'**
  String get security_warning;

  /// No description provided for @security_warning_desc.
  ///
  /// In zh, this message translates to:
  /// **'检测到您的账户存在安全风险，建议立即修改密码。'**
  String get security_warning_desc;

  /// No description provided for @understand.
  ///
  /// In zh, this message translates to:
  /// **'我了解了'**
  String get understand;

  /// No description provided for @unmuted.
  ///
  /// In zh, this message translates to:
  /// **'已取消静音'**
  String get unmuted;

  /// No description provided for @voice_not_available.
  ///
  /// In zh, this message translates to:
  /// **'语音功能不可用'**
  String get voice_not_available;

  /// No description provided for @voice_start_failed.
  ///
  /// In zh, this message translates to:
  /// **'语音启动失败'**
  String get voice_start_failed;

  /// No description provided for @voice_tap_to_start.
  ///
  /// In zh, this message translates to:
  /// **'点击开始语音'**
  String get voice_tap_to_start;

  /// No description provided for @voice_thinking.
  ///
  /// In zh, this message translates to:
  /// **'正在思考'**
  String get voice_thinking;

  /// No description provided for @update_available.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get update_available;

  /// No description provided for @new_version.
  ///
  /// In zh, this message translates to:
  /// **'最新版本'**
  String get new_version;

  /// No description provided for @min_version_required.
  ///
  /// In zh, this message translates to:
  /// **'最低支持版本'**
  String get min_version_required;

  /// No description provided for @update_now.
  ///
  /// In zh, this message translates to:
  /// **'立即更新'**
  String get update_now;

  /// No description provided for @later.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get later;

  /// No description provided for @error_occurred.
  ///
  /// In zh, this message translates to:
  /// **'出了点问题'**
  String get error_occurred;

  /// No description provided for @executing_tool.
  ///
  /// In zh, this message translates to:
  /// **'执行补充工具'**
  String get executing_tool;

  /// No description provided for @ai_not_configured.
  ///
  /// In zh, this message translates to:
  /// **'AI 服务未配置，请在设置中配置代理。'**
  String get ai_not_configured;

  /// No description provided for @message_too_long.
  ///
  /// In zh, this message translates to:
  /// **'消息过长（最多32000字符）'**
  String get message_too_long;

  /// No description provided for @password_min_length.
  ///
  /// In zh, this message translates to:
  /// **'密码至少8个字符'**
  String get password_min_length;

  /// No description provided for @input_too_long.
  ///
  /// In zh, this message translates to:
  /// **'输入过长'**
  String get input_too_long;

  /// No description provided for @no_model_configured.
  ///
  /// In zh, this message translates to:
  /// **'未配置模型'**
  String get no_model_configured;

  /// No description provided for @generation_error.
  ///
  /// In zh, this message translates to:
  /// **'生成出错'**
  String get generation_error;

  /// No description provided for @workbench_empty.
  ///
  /// In zh, this message translates to:
  /// **'AI 工作台'**
  String get workbench_empty;

  /// No description provided for @workbench_empty_hint.
  ///
  /// In zh, this message translates to:
  /// **'选择模板，开始创作'**
  String get workbench_empty_hint;

  /// No description provided for @generating.
  ///
  /// In zh, this message translates to:
  /// **'生成中...'**
  String get generating;

  /// No description provided for @workbench_input_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入内容...'**
  String get workbench_input_hint;

  /// No description provided for @workbench_select_template.
  ///
  /// In zh, this message translates to:
  /// **'选择模板'**
  String get workbench_select_template;

  /// No description provided for @quick_commands.
  ///
  /// In zh, this message translates to:
  /// **'快捷命令'**
  String get quick_commands;

  /// No description provided for @ai_workbench_desc.
  ///
  /// In zh, this message translates to:
  /// **'AI 模板创作工具'**
  String get ai_workbench_desc;

  /// No description provided for @productivity.
  ///
  /// In zh, this message translates to:
  /// **'生产力'**
  String get productivity;

  /// No description provided for @productivity_desc.
  ///
  /// In zh, this message translates to:
  /// **'笔记和待办管理'**
  String get productivity_desc;

  /// No description provided for @agent_replay_desc.
  ///
  /// In zh, this message translates to:
  /// **'查看智能体执行过程'**
  String get agent_replay_desc;

  /// No description provided for @notes.
  ///
  /// In zh, this message translates to:
  /// **'笔记'**
  String get notes;

  /// No description provided for @todos.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get todos;

  /// No description provided for @schedules.
  ///
  /// In zh, this message translates to:
  /// **'日程'**
  String get schedules;

  /// No description provided for @no_notes.
  ///
  /// In zh, this message translates to:
  /// **'暂无笔记'**
  String get no_notes;

  /// No description provided for @no_todos.
  ///
  /// In zh, this message translates to:
  /// **'暂无待办'**
  String get no_todos;

  /// No description provided for @no_schedules.
  ///
  /// In zh, this message translates to:
  /// **'暂无日程'**
  String get no_schedules;

  /// No description provided for @pending.
  ///
  /// In zh, this message translates to:
  /// **'待完成'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get completed;

  /// No description provided for @add_note.
  ///
  /// In zh, this message translates to:
  /// **'添加笔记'**
  String get add_note;

  /// No description provided for @add_todo.
  ///
  /// In zh, this message translates to:
  /// **'添加待办'**
  String get add_todo;

  /// No description provided for @add_schedule.
  ///
  /// In zh, this message translates to:
  /// **'添加日程'**
  String get add_schedule;

  /// No description provided for @title_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入标题...'**
  String get title_hint;

  /// No description provided for @content_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入内容...'**
  String get content_hint;

  /// No description provided for @select_date.
  ///
  /// In zh, this message translates to:
  /// **'选择日期'**
  String get select_date;

  /// No description provided for @select_time.
  ///
  /// In zh, this message translates to:
  /// **'选择时间'**
  String get select_time;

  /// No description provided for @edit_note.
  ///
  /// In zh, this message translates to:
  /// **'编辑笔记'**
  String get edit_note;

  /// No description provided for @reset_commands.
  ///
  /// In zh, this message translates to:
  /// **'重置命令'**
  String get reset_commands;

  /// No description provided for @reset_commands_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置所有快捷命令为默认吗？'**
  String get reset_commands_confirm;

  /// No description provided for @no_quick_commands.
  ///
  /// In zh, this message translates to:
  /// **'暂无快捷命令'**
  String get no_quick_commands;

  /// No description provided for @delete_command.
  ///
  /// In zh, this message translates to:
  /// **'删除命令'**
  String get delete_command;

  /// No description provided for @delete_command_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此快捷命令吗？'**
  String get delete_command_confirm;

  /// No description provided for @category_general.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get category_general;

  /// No description provided for @category_tool.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get category_tool;

  /// No description provided for @category_creative.
  ///
  /// In zh, this message translates to:
  /// **'创意'**
  String get category_creative;

  /// No description provided for @category_work.
  ///
  /// In zh, this message translates to:
  /// **'工作'**
  String get category_work;

  /// No description provided for @edit_command.
  ///
  /// In zh, this message translates to:
  /// **'编辑命令'**
  String get edit_command;

  /// No description provided for @add_command.
  ///
  /// In zh, this message translates to:
  /// **'添加命令'**
  String get add_command;

  /// No description provided for @command_emoji.
  ///
  /// In zh, this message translates to:
  /// **'图标'**
  String get command_emoji;

  /// No description provided for @command_name.
  ///
  /// In zh, this message translates to:
  /// **'命令名称'**
  String get command_name;

  /// No description provided for @command_name_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入命令名称'**
  String get command_name_hint;

  /// No description provided for @command_prompt.
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get command_prompt;

  /// No description provided for @command_prompt_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入提示词模板'**
  String get command_prompt_hint;

  /// No description provided for @command_category.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get command_category;

  /// No description provided for @feedback_recorded.
  ///
  /// In zh, this message translates to:
  /// **'反馈已记录'**
  String get feedback_recorded;

  /// No description provided for @unfavorited.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get unfavorited;

  /// No description provided for @deny.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get deny;

  /// No description provided for @allow.
  ///
  /// In zh, this message translates to:
  /// **'允许'**
  String get allow;

  /// No description provided for @delete_message_pair.
  ///
  /// In zh, this message translates to:
  /// **'删除消息对'**
  String get delete_message_pair;

  /// No description provided for @report_not_helpful.
  ///
  /// In zh, this message translates to:
  /// **'没有帮助'**
  String get report_not_helpful;

  /// No description provided for @my_profile.
  ///
  /// In zh, this message translates to:
  /// **'我的资料'**
  String get my_profile;

  /// No description provided for @report.
  ///
  /// In zh, this message translates to:
  /// **'举报'**
  String get report;

  /// No description provided for @block.
  ///
  /// In zh, this message translates to:
  /// **'拉黑'**
  String get block;

  /// No description provided for @ai_workbench.
  ///
  /// In zh, this message translates to:
  /// **'AI 工作台'**
  String get ai_workbench;

  /// No description provided for @toggle_password.
  ///
  /// In zh, this message translates to:
  /// **'切换密码可见性'**
  String get toggle_password;

  /// No description provided for @switch_to_register.
  ///
  /// In zh, this message translates to:
  /// **'切换到注册'**
  String get switch_to_register;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @matrix_id.
  ///
  /// In zh, this message translates to:
  /// **'Matrix ID'**
  String get matrix_id;

  /// No description provided for @go_back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get go_back;

  /// No description provided for @omnivium_cloud.
  ///
  /// In zh, this message translates to:
  /// **'Omnivium 云端'**
  String get omnivium_cloud;

  /// No description provided for @connected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get connected;

  /// No description provided for @synced.
  ///
  /// In zh, this message translates to:
  /// **'已同步'**
  String get synced;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @reject.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In zh, this message translates to:
  /// **'接受'**
  String get accept;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @rewind.
  ///
  /// In zh, this message translates to:
  /// **'快退'**
  String get rewind;

  /// No description provided for @play.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @forward.
  ///
  /// In zh, this message translates to:
  /// **'快进'**
  String get forward;

  /// No description provided for @toggle_completion.
  ///
  /// In zh, this message translates to:
  /// **'切换完成状态'**
  String get toggle_completion;

  /// No description provided for @close_voice_mode.
  ///
  /// In zh, this message translates to:
  /// **'关闭语音模式'**
  String get close_voice_mode;

  /// No description provided for @stop_listening.
  ///
  /// In zh, this message translates to:
  /// **'停止聆听'**
  String get stop_listening;

  /// No description provided for @start_listening.
  ///
  /// In zh, this message translates to:
  /// **'开始聆听'**
  String get start_listening;

  /// No description provided for @close_conversation.
  ///
  /// In zh, this message translates to:
  /// **'关闭对话'**
  String get close_conversation;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @stop_generating.
  ///
  /// In zh, this message translates to:
  /// **'停止生成'**
  String get stop_generating;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @clear_search_history.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索历史'**
  String get clear_search_history;

  /// No description provided for @user_profile.
  ///
  /// In zh, this message translates to:
  /// **'用户资料'**
  String get user_profile;

  /// No description provided for @close_drawer.
  ///
  /// In zh, this message translates to:
  /// **'关闭侧边栏'**
  String get close_drawer;

  /// No description provided for @cancel_recording.
  ///
  /// In zh, this message translates to:
  /// **'取消录音'**
  String get cancel_recording;

  /// No description provided for @send_recording.
  ///
  /// In zh, this message translates to:
  /// **'发送录音'**
  String get send_recording;

  /// No description provided for @voice_message_record.
  ///
  /// In zh, this message translates to:
  /// **'语音消息，长按录音'**
  String get voice_message_record;

  /// No description provided for @play_video.
  ///
  /// In zh, this message translates to:
  /// **'播放视频'**
  String get play_video;

  /// No description provided for @toggle_thought_chain.
  ///
  /// In zh, this message translates to:
  /// **'切换思维链'**
  String get toggle_thought_chain;

  /// No description provided for @open_link.
  ///
  /// In zh, this message translates to:
  /// **'打开链接'**
  String get open_link;

  /// No description provided for @full_size_image.
  ///
  /// In zh, this message translates to:
  /// **'全尺寸图片'**
  String get full_size_image;

  /// No description provided for @file_thumbnail.
  ///
  /// In zh, this message translates to:
  /// **'文件缩略图'**
  String get file_thumbnail;

  /// No description provided for @article_cover.
  ///
  /// In zh, this message translates to:
  /// **'文章封面'**
  String get article_cover;

  /// No description provided for @author_avatar.
  ///
  /// In zh, this message translates to:
  /// **'作者头像'**
  String get author_avatar;

  /// No description provided for @selected_image.
  ///
  /// In zh, this message translates to:
  /// **'已选图片'**
  String get selected_image;

  /// No description provided for @ai_generated_image.
  ///
  /// In zh, this message translates to:
  /// **'AI生成图片'**
  String get ai_generated_image;

  /// No description provided for @message_hint.
  ///
  /// In zh, this message translates to:
  /// **'消息...'**
  String get message_hint;

  /// No description provided for @template_write.
  ///
  /// In zh, this message translates to:
  /// **'写作'**
  String get template_write;

  /// No description provided for @template_translate.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get template_translate;

  /// No description provided for @template_summarize.
  ///
  /// In zh, this message translates to:
  /// **'总结'**
  String get template_summarize;

  /// No description provided for @template_code.
  ///
  /// In zh, this message translates to:
  /// **'代码'**
  String get template_code;

  /// No description provided for @template_explain.
  ///
  /// In zh, this message translates to:
  /// **'解释'**
  String get template_explain;

  /// No description provided for @template_polish.
  ///
  /// In zh, this message translates to:
  /// **'润色'**
  String get template_polish;

  /// No description provided for @template_email.
  ///
  /// In zh, this message translates to:
  /// **'邮件'**
  String get template_email;

  /// No description provided for @template_brainstorm.
  ///
  /// In zh, this message translates to:
  /// **'头脑风暴'**
  String get template_brainstorm;

  /// No description provided for @faq_a1.
  ///
  /// In zh, this message translates to:
  /// **'Omnivium是一个端到端加密的AI通信平台。'**
  String get faq_a1;

  /// No description provided for @faq_a2.
  ///
  /// In zh, this message translates to:
  /// **'我们使用Matrix协议和Megolm加密来保护您的消息。'**
  String get faq_a2;

  /// No description provided for @faq_a3.
  ///
  /// In zh, this message translates to:
  /// **'前往设置 > AI配置来设置您的AI提供商。'**
  String get faq_a3;

  /// No description provided for @faq_a4.
  ///
  /// In zh, this message translates to:
  /// **'是的，Omnivium支持来自不同提供商的多种AI模型。'**
  String get faq_a4;

  /// No description provided for @faq_a5.
  ///
  /// In zh, this message translates to:
  /// **'语音模式允许使用语音转文字和文字转语音与AI进行免提对话。'**
  String get faq_a5;

  /// No description provided for @faq_a6.
  ///
  /// In zh, this message translates to:
  /// **'前往设置 > 数据与存储来管理您的存储使用。'**
  String get faq_a6;

  /// No description provided for @faq_a7.
  ///
  /// In zh, this message translates to:
  /// **'是的，您可以从设置 > 隐私 > 导出数据中导出数据。'**
  String get faq_a7;

  /// No description provided for @faq_a8.
  ///
  /// In zh, this message translates to:
  /// **'通过应用内或邮件support@omnivium.app联系我们。'**
  String get faq_a8;

  /// No description provided for @faq_a9.
  ///
  /// In zh, this message translates to:
  /// **'检查您的网络连接并尝试重启应用。'**
  String get faq_a9;

  /// No description provided for @faq_a10.
  ///
  /// In zh, this message translates to:
  /// **'前往设置 > 账户 > 修改密码。'**
  String get faq_a10;

  /// No description provided for @pp_data_collection.
  ///
  /// In zh, this message translates to:
  /// **'数据收集'**
  String get pp_data_collection;

  /// No description provided for @pp_data_collection_content.
  ///
  /// In zh, this message translates to:
  /// **'我们仅收集提供服务所必需的最少数据。'**
  String get pp_data_collection_content;

  /// No description provided for @pp_data_usage.
  ///
  /// In zh, this message translates to:
  /// **'数据使用'**
  String get pp_data_usage;

  /// No description provided for @pp_data_usage_content.
  ///
  /// In zh, this message translates to:
  /// **'您的数据仅用于提供和改善我们的服务。'**
  String get pp_data_usage_content;

  /// No description provided for @pp_data_storage.
  ///
  /// In zh, this message translates to:
  /// **'数据存储'**
  String get pp_data_storage;

  /// No description provided for @pp_data_storage_content.
  ///
  /// In zh, this message translates to:
  /// **'数据以加密方式安全存储。'**
  String get pp_data_storage_content;

  /// No description provided for @pp_data_protection.
  ///
  /// In zh, this message translates to:
  /// **'数据保护'**
  String get pp_data_protection;

  /// No description provided for @pp_data_protection_content.
  ///
  /// In zh, this message translates to:
  /// **'我们实施行业标准的安全措施来保护您的数据。'**
  String get pp_data_protection_content;

  /// No description provided for @pp_data_deletion.
  ///
  /// In zh, this message translates to:
  /// **'数据删除'**
  String get pp_data_deletion;

  /// No description provided for @pp_data_deletion_content.
  ///
  /// In zh, this message translates to:
  /// **'您可以随时请求删除您的数据。'**
  String get pp_data_deletion_content;

  /// No description provided for @pp_third_party.
  ///
  /// In zh, this message translates to:
  /// **'第三方'**
  String get pp_third_party;

  /// No description provided for @pp_third_party_content.
  ///
  /// In zh, this message translates to:
  /// **'我们不会将您的数据出售给第三方。'**
  String get pp_third_party_content;

  /// No description provided for @pp_cookie.
  ///
  /// In zh, this message translates to:
  /// **'Cookie'**
  String get pp_cookie;

  /// No description provided for @pp_cookie_content.
  ///
  /// In zh, this message translates to:
  /// **'我们仅出于基本功能使用Cookie。'**
  String get pp_cookie_content;

  /// No description provided for @pp_policy_update.
  ///
  /// In zh, this message translates to:
  /// **'政策更新'**
  String get pp_policy_update;

  /// No description provided for @pp_policy_update_content.
  ///
  /// In zh, this message translates to:
  /// **'如有重大政策变更，我们将通知您。'**
  String get pp_policy_update_content;

  /// No description provided for @pp_contact.
  ///
  /// In zh, this message translates to:
  /// **'联系方式'**
  String get pp_contact;

  /// No description provided for @pp_contact_content.
  ///
  /// In zh, this message translates to:
  /// **'如有关隐私的疑问，请联系privacy@omnivium.app。'**
  String get pp_contact_content;

  /// No description provided for @tos_acceptance.
  ///
  /// In zh, this message translates to:
  /// **'接受条款'**
  String get tos_acceptance;

  /// No description provided for @tos_acceptance_content.
  ///
  /// In zh, this message translates to:
  /// **'使用Omnivium即表示您同意这些服务条款。'**
  String get tos_acceptance_content;

  /// No description provided for @tos_description.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get tos_description;

  /// No description provided for @tos_description_content.
  ///
  /// In zh, this message translates to:
  /// **'这些条款管辖您对Omnivium平台的使用。'**
  String get tos_description_content;

  /// No description provided for @tos_conduct.
  ///
  /// In zh, this message translates to:
  /// **'行为准则'**
  String get tos_conduct;

  /// No description provided for @tos_conduct_content.
  ///
  /// In zh, this message translates to:
  /// **'用户在平台上必须表现得尊重和守法。'**
  String get tos_conduct_content;

  /// No description provided for @tos_ip.
  ///
  /// In zh, this message translates to:
  /// **'知识产权'**
  String get tos_ip;

  /// No description provided for @tos_ip_content.
  ///
  /// In zh, this message translates to:
  /// **'您创建的内容仍属于您的知识产权。'**
  String get tos_ip_content;

  /// No description provided for @tos_disclaimer.
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get tos_disclaimer;

  /// No description provided for @tos_disclaimer_content.
  ///
  /// In zh, this message translates to:
  /// **'本服务按现状提供，不作任何保证。'**
  String get tos_disclaimer_content;

  /// No description provided for @tos_termination.
  ///
  /// In zh, this message translates to:
  /// **'终止'**
  String get tos_termination;

  /// No description provided for @tos_termination_content.
  ///
  /// In zh, this message translates to:
  /// **'我们可能会终止违反这些条款的账户。'**
  String get tos_termination_content;

  /// No description provided for @tos_dispute.
  ///
  /// In zh, this message translates to:
  /// **'争议解决'**
  String get tos_dispute;

  /// No description provided for @tos_dispute_content.
  ///
  /// In zh, this message translates to:
  /// **'争议应通过仲裁解决。'**
  String get tos_dispute_content;

  /// No description provided for @tos_update.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get tos_update;

  /// No description provided for @tos_update_content.
  ///
  /// In zh, this message translates to:
  /// **'我们可能会在事先通知的情况下更新这些条款。'**
  String get tos_update_content;

  /// No description provided for @pause_voice_message.
  ///
  /// In zh, this message translates to:
  /// **'暂停语音消息'**
  String get pause_voice_message;

  /// No description provided for @play_voice_message.
  ///
  /// In zh, this message translates to:
  /// **'播放语音消息'**
  String get play_voice_message;

  /// No description provided for @send_message_semantic.
  ///
  /// In zh, this message translates to:
  /// **'发送消息'**
  String get send_message_semantic;

  /// No description provided for @voice_input_semantic.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get voice_input_semantic;

  /// No description provided for @enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get disabled;

  /// No description provided for @unread.
  ///
  /// In zh, this message translates to:
  /// **'未读'**
  String get unread;

  /// No description provided for @unit_b.
  ///
  /// In zh, this message translates to:
  /// **'B'**
  String get unit_b;

  /// No description provided for @unit_kb.
  ///
  /// In zh, this message translates to:
  /// **'KB'**
  String get unit_kb;

  /// No description provided for @unit_mb.
  ///
  /// In zh, this message translates to:
  /// **'MB'**
  String get unit_mb;

  /// No description provided for @size_zero_mb.
  ///
  /// In zh, this message translates to:
  /// **'0 MB'**
  String get size_zero_mb;

  /// No description provided for @matrix_id_hint.
  ///
  /// In zh, this message translates to:
  /// **'@用户:服务器.com'**
  String get matrix_id_hint;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ja':
      return SJa();
    case 'ko':
      return SKo();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

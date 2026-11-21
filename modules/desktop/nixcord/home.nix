{
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.rhen.nixcord;
  plugins = {
    alwaysTrust = {
      enable = true;
      domain = true;
      file = true;
    };
    betterFolders = {
      enable = false;
      sidebar = true;
      sidebarAnim = true;
      closeAllFolders = false;
      closeAllHomeButton = false;
      closeOthers = false;
      forceOpen = true;
      keepIcons = false;
      showFolderIcon = 1;
    };
    betterSettings = {
      enable = true;
      disableFade = true;
      eagerLoad = true;
      organizeMenu = true;
    };
    clearUrls.enable = true;
    copyEmojiMarkdown.enable = true;
    copyFileContents.enable = true;
    copyStickerLinks.enable = true;
    copyUserUrls.enable = true;
    crashHandler.enable = true;
    customRpc = {
      enable = true;
      type = 2;
      enablePresence = true;
    };
    fakeNitro = {
      enable = true;
      enableEmojiBypass = true;
      emojiSize = 48;
      transformEmojis = true;
      enableStickerBypass = true;
      stickerSize = 160;
      transformStickers = true;
      transformCompoundSentence = false;
      enableStreamQualityBypass = true;
      useHyperLinks = true;
      hyperLinkText = "{{NAME}}";
      disableEmbedPermissionCheck = false;
    };
    fixImagesQuality = {
      enable = true;
      originalImagesInChat = false;
    };
    fullSearchContext.enable = true;
    imageZoom = {
      enable = true;
      size = 280.0;
      zoom = 2.8;
      nearestNeighbour = false;
      square = false;
      invertScroll = true;
      zoomSpeed = 0.5;
      saveZoomValues = true;
    };
    keepCurrentChannel.enable = true;
    memberCount = {
      enable = true;
      toolTip = true;
      memberList = true;
      voiceActivity = true;
    };
    mentionAvatars = {
      enable = true;
      showAtSymbol = true;
    };
    messageLinkEmbeds = {
      enable = true;
      listMode = "blacklist";
      idList = "";
      automodEmbeds = "never";
    };
    messageLogger = {
      enable = true;
      deleteStyle = "text";
      logDeletes = true;
      collapseDeleted = false;
      logEdits = true;
      inlineEdits = true;
      ignoreBots = true;
      ignoreSelf = true;
      ignoreUsers = "";
      ignoreChannels = "";
      ignoreGuilds = "";
      logDeletedAttachments = true;
    };
    moreQuickReactions = {
      enable = true;
      reactionCount = 10;
    };
    mutualGroupDms.enable = true;
    permissionsViewer.enable = true;
    pinDms = {
      enable = true;
      pinOrder = 0;
      canCollapseDmSection = false;
      userBasedCategoryList = {
        "1350456145990647808" = [
          {
            id = "6s4xe7qiwp8";
            name = "Important";
            color = 15277667;
            collapsed = false;
            channels = [
              "1514298982711562390"
              "1497490877914808471"
              "1518353796730982504"
              "1487494558596993035"
            ];
          }
        ];
        "1038665029869912116" = [ ];
      };
    };
    platformIndicators = {
      enable = true;
      list = true;
      badges = true;
      messages = true;
      colorMobileIndicator = true;
    };
    previewMessage.enable = true;
    quickMention.enable = true;
    quickReply = {
      enable = true;
      shouldMention = 2;
      ignoreBlockedAndIgnored = true;
    };
    relationshipNotifier = {
      enable = true;
      notices = false;
      offlineRemovals = true;
      friends = true;
      friendRequestCancels = true;
      servers = true;
      groups = true;
    };
    replyTimestamp.enable = true;
    sendTimestamps = {
      enable = true;
      replaceMessageContents = true;
    };
    serverInfo.enable = true;
    showHiddenChannels = {
      enable = true;
      showMode = 0;
      hideUnreads = true;
      defaultAllowedUsersAndRolesDropdownState = true;
    };
    showHiddenThings = {
      enable = true;
      showTimeouts = true;
      showInvitesPaused = true;
      showModView = true;
    };
    showMeYourName = {
      enable = true;
      mode = "nick-user";
      friendNicknames = "dms";
      displayNames = false;
      inReplies = true;
    };
    silentMessageToggle = {
      enable = true;
      persistState = "channels";
      autoDisable = false;
    };
    startupTimings.enable = true;
    stickerPaste.enable = true;
    streamerModeOnStream.enable = true;
    translate = {
      enable = true;
      service = "google";
      autoTranslate = false;
      showAutoTranslateTooltip = true;
      sentInput = "auto";
      sentOutput = "en";
      receivedInput = "auto";
      receivedOutput = "zh-CN";
      dismissedAutoTranslateAlert = true;
    };
    typingIndicator = {
      enable = true;
      includeMutedChannels = false;
      includeCurrentChannel = true;
      indicatorMode = 3;
    };
    unindent.enable = true;
    unsuppressEmbeds.enable = true;
    userVoiceShow = {
      enable = true;
      showInUserProfileModal = true;
      showInMemberList = true;
      showInMessages = true;
    };
    validReply.enable = true;
    viewRaw = {
      enable = true;
      clickMethod = "Left";
      messageContextMenu = false;
    };
    voiceDownload.enable = true;
    voiceMessages.enable = true;
    webKeybinds = {
      enable = true;
      showNavigationButtons = true;
      overrideCommonKeybinds = true;
    };
    webScreenShareFixes.enable = true;
    whoReacted = {
      enable = true;
      clickableAvatars = true;
    };
    noTrack = {
      enable = true;
      disableAnalytics = true;
    };
    settings = {
      enable = true;
      settingsLocation = "aboveNitro";
      includeVencordInfoWhenCopying = true;
    };
    concatenatedComponentExtractor.enable = true;
    disableDeepLinks.enable = true;
    supportHelper.enable = true;
    webContextMenus.enable = true;
  };
in
{
  imports = [ inputs.nixcord.homeModules.nixcord ];
  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;
      vesktop.settings = {
        discordBranch = "stable";
        minimizeToTray = true;
        arRPC = true;
        splashColor = "rgb(239, 239, 241)";
        splashBackground = "rgb(18, 18, 20)";
      };
      # 不声明 vesktop.state：state.json 由 Vesktop 运行时写入，
      # 交给客户端自行管理，避免 Home Manager 每次激活都做 .backup 备份而冲突。
      config = {
        autoUpdate = true;
        autoUpdateNotification = false;
        useQuickCss = true;
        enabledThemes = [ ];
        plugins = plugins;
      };
      quickCss = ''
        :root {
          --font-primary: "Maple Mono NF CN", "gg sans", sans-serif !important;
          --font-display: "Maple Mono NF CN", "gg sans", sans-serif !important;
          --font-headline: "Maple Mono NF CN", "gg sans", sans-serif !important;
          --font-code: "Maple Mono NF CN", "Consolas", monospace !important;
        }
        * { font-family: "Maple Mono NF CN", "gg sans", sans-serif !important; }
        code, pre, .hljs, [class*="codeBlock"], [class*="markup"] {
          font-family: "Maple Mono NF CN", "Consolas", monospace !important;
        }
      '';
    };
  };
}

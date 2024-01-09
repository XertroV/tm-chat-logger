void Main(){
    startnew(Chat::ChatCoro).WithRunContext(Meta::RunContext::GameLoop);
    MonitoringLoop();
}

void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    Chat::Unload();
}

string currServerName;
string currServerLogin;
string currServerJL;
string currGameMode;
string currMapUid;
string currMapName;
uint serverConnectStart;
string serverConnectStartStr;
bool isTeams;
bool isKO;
bool isCup;
bool isRounds;
bool isTA;

void MonitoringLoop() {
    auto app = GetApp();
    auto net = app.Network;
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    while (true) {
        yield();
        currServerLogin = si.ServerLogin;
        currServerName = si.ServerName;
        currServerJL = si.JoinLink;
        trace("Starting server login watch loop");
        while (si.ServerLogin == currServerLogin) {
            currGameMode = si.ModeName;
            isTeams = currGameMode.StartsWith("TM_Teams");
            isKO = currGameMode.StartsWith("TM_Knockout");
            isCup = currGameMode.StartsWith("TM_Cup");
            isRounds = currGameMode.StartsWith("TM_Rounds");
            isTA = currGameMode.StartsWith("TM_TimeAttack");
            serverConnectStart = Time::Stamp;
            serverConnectStartStr = app.OSLocalDate.Replace("/", "-").Replace(":", "_");
            while (si.ServerLogin == currServerLogin && currGameMode == si.ModeName) {
                UpdateLoopInServer();
                yield();
            }
            yield();
        }
    }
}

string GenerateLogName() {
    return FileNameSafe(serverConnectStartStr + " - " + StripFormatCodes(currServerName));
    //.Replace(":", "").Replace("#", "").Replace("?", "").Replace(",", "").Replace(";", "").Replace("/", "").Replace("\\", "");
}

string FileNameSafe(const string &in filename) {
    return filename.Replace("|", "").Replace(":", "").Replace("#", "").Replace("?", "").Replace("*", "").Replace(":", "").Replace('"', "").Replace("<", "").Replace(">", "").Replace("/", "").Replace("\\", "");
}

string GenerateLogContextStr() {
    string ret = "/------------ CHAT LOG CTX --------------/";
    ret += "\nMap: " + currMapName;
    ret += "\nUID: " + currMapUid;
    ret += "\nServer: " + currServerName;
    ret += "\nServerLogin: " + currServerLogin;
    ret += "\nJoinLink: " + currServerJL;
    ret += "\nGame Mode: " + currGameMode;
    ret += "\nServer Connection Time: " + serverConnectStart;
    ret += "\nTimestamp (Now): " + Time::Stamp;
    ret += "\n";
          ret += "/------------ END CHAT CTX --------------/";
    return ret;
}

void UpdateLoopInServer() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    // early exit if things aren't available
    if (app.RootMap is null || IsLoadingScreenShowing(app)) return;
    auto cmap = app.Network.ClientManiaAppPlayground;
    if (cmap is null) return;
    currMapName = StripFormatCodes(app.RootMap.MapInfo.Name);
    currMapUid = app.RootMap.EdChallengeId;

    UpdateChatLogFileName();
    LogChatContext();

    while (StillInServer(app)) {
        yield();
    }
}

bool IsStartTimeLTEndTime(CGameCtnApp@ app) {
    if (app.CurrentPlayground is null) return false;
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp.Arena is null || cp.Arena.Rules is null) return false;
    return cp.Arena.Rules.RulesStateStartTime < cp.Arena.Rules.RulesStateEndTime;
}

bool StillInServer(CGameCtnApp@ app) {
    return app.RootMap !is null && app.Network.ClientManiaAppPlayground !is null && !IsLoadingScreenShowing(app);
}

bool IsLoadingScreenShowing(CGameCtnApp@ app) {
    return app.LoadProgress.State == NGameLoadProgress::EState::Displayed;
}

bool IsEndRoundOrUiInteraction(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::EndRound || seq == CGamePlaygroundUIConfig::EUISequence::UIInteraction;
}

bool IsPlayingOrFinish(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Playing || seq == CGamePlaygroundUIConfig::EUISequence::Finish;
}

bool IsPodium(CGameManiaAppPlayground@ cmap) {
    if (cmap is null || cmap.UI is null) return false;
    auto seq = cmap.UI.UISequence;
    return seq == CGamePlaygroundUIConfig::EUISequence::Podium;
}

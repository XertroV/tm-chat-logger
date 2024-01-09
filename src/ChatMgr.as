namespace Chat {
    void SendMessage(const string &in msg) {
        auto cp = GetApp().CurrentPlayground;
        if (cp is null || cp.Interface is null) return;
        cp.Interface.ChatEntry = msg;
    }

    void SendGoodMessage(const string &in msg) {
        SendMessage("$o$i$4f4" + msg);
    }

    void SendWarningMessage(const string &in msg) {
        SendMessage("$o$i$f80" + msg);
    }

    NGameScriptChat_SHistory@ hist;
    void ChatCoro() {
        trace('starting check chat coro');
        while (true) {
            yield();
            CheckChat();
        }
    }

    string chatLogFileName;
    void CheckChat() {
        if (hist is null) InitHist();
        // print("" + hist.PendingEvents.Length);
        if (hist.PendingEvents.Length == 0) return;
        // chatLogFileName = serverConnectStartStr + " - ChatLog.txt";
        for (uint i = 0; i < hist.PendingEvents.Length; i++) {
            auto chatEvt = cast<NGameScriptChat_SEvent_NewEntry>(hist.PendingEvents[i]);
            if (chatEvt is null) continue;
            LogMsg(chatEvt);
            // if (!chatEvt.Entry.IsSystemMessage) {
            // }
        }
    }

    void InitHist() {
        auto mgr = GetApp().ChatManagerScriptV2;
        if (mgr is null || mgr.Contextes.Length == 0) return;
        auto ctx = mgr.Contextes[0];
        @hist = ctx.History_Create("t", 50);
    }

    void Unload() {
        if (hist is null) return;
        auto mgr = GetApp().ChatManagerScriptV2;
        if (mgr is null || mgr.Contextes.Length == 0) return;
        auto ctx = mgr.Contextes[0];
        ctx.History_Destroy(hist);
    }

    string currentMsgSenderName;
    string currentMsgSenderLogin;

    void LogMsg(NGameScriptChat_SEvent_NewEntry@ e) {
        auto j = Json::Object();
        j['name'] = string(wstring(e.Entry.SenderDisplayName));
        j['login'] = string(wstring(e.Entry.SenderLogin));
        auto msg = string(wstring(e.Entry.Text)).Trim();
        j['msg'] = msg;
        j['msgClean'] = StripFormatCodes(msg);
        j['teamCol'] = string(wstring(e.Entry.SenderTeamColorText));
        j['ts'] = Time::Stamp;
        j['system'] = e.Entry.IsSystemMessage;
        auto toLog = Json::Write(j);
        // trace('Logging chat msg: ' + toLog);
        WriteToChatLog(toLog);
    }
}

string _chatLogFileName = "uninitialized.txt";
string chatLogFilePath = IO::FromStorageFolder(_chatLogFileName);

void UpdateChatLogFileName() {
    _chatLogFileName = GenerateLogName() + ".txt";
    chatLogFilePath = IO::FromStorageFolder(_chatLogFileName);
}

void LogChatContext() {
    WriteToChatLog(GenerateLogContextStr());
}

void WriteToChatLog(const string &in msg) {
    IO::File f(chatLogFilePath, IO::FileMode::Append);
    f.WriteLine(msg);
    f.Close();
}

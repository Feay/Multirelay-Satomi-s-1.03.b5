integer CMD_MENU = 0;
integer CMD_ACKDEBUG = 49;

default
{
    state_entry()
    {
        llSetMemoryLimit(1024);
        llListen(99, "", llGetOwner(), "");
    }
    
    listen(integer iChan, string sWho, key kWho, string sMsg)
    {
        list lArgs = llParseString2List(sMsg, [" "], []);
        string sCmd = llList2String(lArgs, 0);
        if (sCmd == "relay") llMessageLinked(LINK_THIS, CMD_MENU, "", kWho);
        else if (sCmd == "debug") llMessageLinked(LINK_THIS, CMD_ACKDEBUG, llList2String(lArgs, 1), kWho);
    }

}

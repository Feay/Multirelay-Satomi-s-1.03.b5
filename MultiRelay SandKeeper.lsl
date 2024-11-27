//message map
integer CMD_SWD = 5;
integer CMD_REFRESH = 9;

integer CMD_SENDRLVR = 41;
integer CMD_RECVRLVR = 42;
integer CMD_LISTEN = 45;

// sandkeeper messages (for !x-delay)
integer CMD_DELAY_ADD = 110;
integer CMD_DELAY_CLEAR = 111;
// integer CMD_DELAYED_COMMAND = 112;  <- not needed CMD_RECVRLVR should be used instead
integer CMD_REALDELAY_ADD = 113;
//integer CMD_REALDELAY_CLEAR = 114;
 
list online_event_queue; //scheduled events, online time, time as floats (llGetUnixTime()). Don't try to convert to floats unless you lose awfully lot of precision.
list real_event_queue; //scheduled events, real time, time as integers (llGetTime())

refresh()
{
    start_online_events();
    start_real_events();

    integer has_real = (real_event_queue != []);
    integer has_online = (online_event_queue != []);

    float next_online_event;
    if (has_online) next_online_event = (llList2Float(online_event_queue, 0) - llGetTime());
    else next_online_event = (float)"inf";

    float next_real_event;
    if (has_real) next_real_event = (float) ((llList2Integer(real_event_queue, 0) - llGetUnixTime()));    
    else next_real_event = (float)"inf";
    
//    llOwnerSay("Next online: "+(string) next_online_event);
//    llOwnerSay("Next real: "+(string) next_real_event);
    float next_event;
    if (next_online_event > next_real_event) next_event = next_real_event;
    else next_event = next_online_event;
    
    if (next_event == (float)"inf") llSetTimerEvent(0);
    else if (next_event <= 0)
    { // should not happen... but....
        start_online_events();
        start_real_events();
    }
    else llSetTimerEvent(next_event);
//    llOwnerSay("Next event in "+(string)next_event+" seconds.");
}

schedule_online(string evt, key source)
{
    list args = llParseString2List(evt, [","], []);
    float time = llList2Float(args, 0) + llGetTime();
    integer i = 0;
    integer l = llGetListLength(online_event_queue);
    while (i<l && llList2Float(online_event_queue,i) < time) i+=4;
    online_event_queue = llListInsertList(online_event_queue, [time, source]+llList2List(args,1,2), i);
}

schedule_real(string evt, key source)
{
    list args = llParseString2List(evt, [","], []);
    integer time = llList2Integer(args, 0) + llGetUnixTime();
    integer i = 0;
    integer l = llGetListLength(real_event_queue);
    while (i<l && llList2Integer(real_event_queue,i) < time) i+=4;
    real_event_queue = llListInsertList(real_event_queue, [time, source]+llList2List(args,1,2), i);
}

start_online_events()
{
    while (llGetListLength(online_event_queue)>=4 && llList2Float(online_event_queue,0) <= llGetTime())
    {
        // update queue and timers
        key source = llList2Key(online_event_queue,1);
        string ident = llList2String(online_event_queue,2);
        string command = llList2String(online_event_queue,3);
        online_event_queue = llDeleteSubList(online_event_queue,0,3);
        if (llListFindList(online_event_queue + real_event_queue, [source]) == -1) llMessageLinked(LINK_THIS, CMD_REFRESH, "silent", source);
    
        // handle event
        llMessageLinked(LINK_THIS, CMD_RECVRLVR, ident+","+command, source);
    }
}

start_real_events()
{
    while (llGetListLength(real_event_queue)>=4 && llList2Integer(real_event_queue,0) <= llGetUnixTime())
    {
        // update queue and timers
        key source = llList2Key(real_event_queue,1);
        string ident = llList2String(real_event_queue,2);
        string command = llList2String(real_event_queue,3);
        real_event_queue = llDeleteSubList(real_event_queue,0,3);
        if (llListFindList(online_event_queue + real_event_queue, [source]) == -1) llMessageLinked(LINK_THIS, CMD_REFRESH, "silent", source);
        
        // handle event
        llMessageLinked(LINK_THIS, CMD_RECVRLVR, ident+","+command, source);
    }
}

clear_online(string pattern, key source)
{
    integer i = 0;
    integer total = llGetListLength(online_event_queue);
    while (i < total)
    {
        if ( llList2Key(online_event_queue, i+1) == source && llSubStringIndex(llList2String(online_event_queue, i+2), pattern) != -1 )
        {
            online_event_queue = llDeleteSubList(online_event_queue, i, i+3);
            total -= 4;
        }
        else i += 4;
    }
}

clear_real(string pattern, key source)
{
    integer i = 0;
    integer total = llGetListLength(real_event_queue);
    while (i < total)
    {
        if ( llList2Key(real_event_queue, i+1) == source && llSubStringIndex(llList2String(real_event_queue, i+2), pattern) != -1 )
        {
            real_event_queue = llDeleteSubList(real_event_queue, i, i+3);
            total -= 4;
        }
        else i += 4;
    }
}

default
{
    state_entry()
    {
    }

    link_message(integer link, integer num, string msg, key id)
    {// llOwnerSay("LM in sandkeeper: "+(string) num);
        if (num == CMD_DELAY_ADD)
        {
            schedule_online(msg, id);
            refresh();
        }
        else if (num == CMD_REALDELAY_ADD)
        {
            schedule_real(msg, id);
            refresh();
        }
        else if (num == CMD_DELAY_CLEAR)
        {
            clear_online(msg, id);
            clear_real(msg, id);
            refresh();
        }
        else if (num == CMD_SWD)
        {
            if (id == NULL_KEY) llResetScript();
            else
            {
                clear_online(id, "");
                clear_real(id, "");
                refresh();
            }
        }
        else if (num ==  CMD_SENDRLVR && msg == "ping,ping,ping")
        {
            if (llListFindList(online_event_queue + real_event_queue, [id]) != -1)  llMessageLinked(LINK_THIS, CMD_RECVRLVR, "ping,!pong", id); // <-- cheat gatekeeper!
        }
    }
    
    timer()
    {
        refresh();
    }
}

// RLVR protocol constants
integer RLVR_CHAN = -1812221819;
key WILDCARD = "ffffffff-ffff-ffff-ffff-ffffffffffff";
string protocolstring="ORG encapsulated RLVR protocol";

// internal message map
integer CMD_ADD = 1;
integer CMD_REM = 2;
integer CMD_CLR = 3;
integer CMD_RES = 4;
integer CMD_SWD = 5;
integer CMD_SEND = 6;
integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;
integer CMD_STATUS = 21;
integer CMD_SENDRLVR = 41;
integer CMD_RECVRLVR = 42;
integer CMD_LISTEN = 45;
integer CMD_ACKPOLICY = 46;
integer CMD_ACKDEBUG = 49;

integer CMD_EMAIL_INIT = 50;
integer CMD_NEWKEY = 51;
integer CMD_URL = 55;
integer CMD_FLUSH = 59;

integer EMAIL1 = 70;


integer pollfreq = 10;

integer rlvrlistener;

// known sources attributes
list listeners;
list channels;
list sources;
list buffers;
list quietack;

// temporary sources attributes
list templisteners;
list tempchannels;
list tempsources;
list tempbuffers;
list tempquietack;

list agent_listeners;
list agent_channels;
list agent_sources;
integer agent_waiting = 0;

integer email_sources = 0;
integer email_tempsources = 0;
string address;
integer nonce;
key session;
integer session_date;

//integer email_mode = FALSE;

integer garbage_rate = 180; //garbage collection rate

key cursource;
string curmsg;
integer cursender;

//http-in
//string url;

//string END = "$$";

//partial safewording
integer safewordPending;
key safewordPendingFor;

//debug
integer g_iDebug = FALSE; //output llRegionSayTo acks to llOwnerSay

/*
newurl()
{
    llRequestURL();
}
*/

qemail(key source, string msg)
{
    if (cursource==NULL_KEY) cursource = source;
    if (source != cursource || llStringLength(msg+curmsg)>1500)
    {
        sendmail();
        cursource=source;
    }
    curmsg+="\n"+msg;
}

sendmail()
{
    if (curmsg!="")
    { //llOwnerSay("Sent to email: "+curmsg);
        integer index = llListFindList(sources+tempsources,[cursource]);
        string address = llList2String(channels+tempchannels,index);
        llMessageLinked(LINK_THIS, EMAIL1+cursender, address+curmsg,cursource);
        cursender = (cursender  + 1) % 3;
        cursource=NULL_KEY;
        curmsg="";
    }
}

/*
qhttp(integer index, string msg)
{// llOwnerSay(msg);
    list args = llParseStringKeepNulls(msg,[","],[]);
    if (llList2String(args,2)=="ok" 
        && llList2Integer(llParseString2List(llList2String(args,1),["="],[]),1)>0)
        {
            agent_waiting++;
            //llOwnerSay("one more");
        }
    string buffer = llList2String(buffers+tempbuffers, index);
    //llOwnerSay("Current buffer: "+buffer);
    integer pblen = llGetListLength(buffers);

    buffer += "\n"+msg;
    if (index < pblen) buffers = llListReplaceList(buffers, [buffer], index, index);
    else tempbuffers = llListReplaceList(tempbuffers, [buffer], index - pblen, index - pblen);
        
    if (llGetListLength(args) == 2){agent_waiting--; if (agent_waiting <= 0) sendbuffer = TRUE;
    //            llOwnerSay("one less");

    //llOwnerSay("queued: "+msg+", still waiting: "+(string) agent_waiting);
}
*/

new_listener(integer channel, key id)
{
    integer index = llListFindList(sources, [id]);
    if (index != -1)
    {
        channels = llListReplaceList(channels, [channel],index, index);
        llListenRemove(llList2Integer(channels,index));
        listeners = llListReplaceList(listeners, [llListen(channel, "", id, "")],index, index);
    }
    else
    {
        tempchannels += [channel];
        templisteners += [llListen(channel, "", id, "")];
        llSetTimerEvent(pollfreq);
    }
}

/*
float distancefrom(key id)
{
    vector myPosition = llGetRootPosition();
    list temp = llGetObjectDetails(id, ([OBJECT_POS]));
    vector objPosition = llList2Vector(temp,0);
    if (objPosition == <0, 0, 0>) return 1000.0; //not in sim
    return llVecDist(objPosition, myPosition);
}
*/

integer insim(key id)
{
    list temp = llGetObjectDetails(id, ([OBJECT_POS]));
    vector objPosition = llList2Vector(temp,0);
//    llOwnerSay("InSim: "+(string)(objPosition != <0,0,0>));
    return objPosition != <0, 0, 0>;
}

safeword()
{
    if (safewordPendingFor == NULL_KEY)
    {
        integer i;
        for (i=0; i<llGetListLength(listeners);i++) llListenRemove(llList2Integer(listeners,i));
        channels=[];
        listeners=[];
        sources = [];
        buffers = [];
        quietack = [];
        for (i=0; i<llGetListLength(templisteners);i++) llListenRemove(llList2Integer(templisteners,i));
        tempchannels=[];
        templisteners=[];
        tempsources = [];
        tempbuffers = [];   
        tempquietack = [];
    }
    else
    {
        integer index = llListFindList(sources, [safewordPendingFor]);
        /* TODO remove all data about this source */
    }
    safewordPendingFor = NULL_KEY;
    safewordPending = FALSE;
    llSetTimerEvent(pollfreq);
}



default
{
    state_entry()
    {
        rlvrlistener = llListen(RLVR_CHAN,"",NULL_KEY, "");
        // http-in
//        newurl();
    }

    link_message(integer prim, integer num, string msg, key id)
    {
        if (num == CMD_SENDRLVR)
        {
            //agent_waiting=0;
            integer index = llListFindList(sources+tempsources,[id]);
            if ((msg == "ok" || msg == "ko") && llList2Integer(quietack+tempquietack, index)) return;
            string channel = (string) RLVR_CHAN;
            //llOwnerSay("tosend: "+msg);
            list args = llParseStringKeepNulls(msg,[","],[]);
            if (index != -1) channel = llList2String(channels+tempchannels, index);
            if ((key) channel)
            {
//                qhttp(index, msg);
            }
//            else if (llList2String(args,2) == END) return;  deprecated
            else if ((string)((integer)channel) == channel&&(integer)channel<=-1000)
            {
                string tosend = llList2String(args,0)+","+(string)id+","+llList2String(args,1)+","+llList2String(args,2);
                //llOwnerSay("sending "+tosend+" to: "+(string)id+" on channel " + (string)channel);
                if (g_iDebug) llOwnerSay("Sent by llRegionSayTo to "+(string) id+": "+tosend);
                llRegionSayTo(id, (integer)channel, tosend);
            }
            else
            {
                qemail(id,msg);
            }
        }
        else if (num == CMD_STATUS)
        {
            if (msg=="off") llListenRemove(rlvrlistener);
            else rlvrlistener = llListen(RLVR_CHAN,"",NULL_KEY, "");
        }
        else if (num==CMD_ADDSRC)
        {
            sources += [id];
            integer index = llListFindList(tempsources,[id]);
            if (index != -1)
            {
                channels += [llList2String(tempchannels,index)];
                listeners += [llList2String(templisteners,index)];
                buffers += [llList2String(tempbuffers,index)];
                quietack += [llList2String(quietack,index)];
            }
            else
            {
                channels +=[RLVR_CHAN];
                listeners += [""];
                buffers += [""];
                quietack += ["FALSE"];
            }
        }
        else if (num==CMD_REMSRC)
        {
            integer index = llListFindList(sources, [id]);
            if (index != -1)
            {
                llListenRemove(llList2Integer(listeners, index));
                sources = llDeleteSubList(sources, index, index);
                listeners = llDeleteSubList(listeners, index, index);
                channels = llDeleteSubList(channels, index, index);
                buffers = llDeleteSubList(buffers, index, index);
                quietack = llDeleteSubList(quietack, index, index);
            }
        }
        else if (num==CMD_SWD) 
        {
            safewordPending = TRUE;
            safewordPendingFor = id;
            llSetTimerEvent(3.);
        }
        else if (num==CMD_LISTEN)
        {
            new_listener((integer) msg, id);
        }
        else if (num==CMD_EMAIL_INIT)
        {
            integer index = llListFindList(sources+tempsources,[id]);
            string channel = llList2String(channels+tempchannels,index);
            if (index==-1 || (integer)channel == llList2Integer(channels+tempchannels,index))
            {//email session initiation, only if source not already known with an email
                //email_mode=TRUE;
                llGetNextEmail("","");
                llSetTimerEvent(pollfreq);
                session_date = llGetUnixTime(); 
            }
            else
            {//email address change
                
            }
        }
        else if (num==CMD_SEND)  // a RLV command using a channel is being sent. Listen to this channel.
        {
            list args = llParseString2List(msg,["="],[]);
            integer channel = llList2Integer(args,1);
            if (channel>0 && (string)channel == llList2String(args,1))
            {
                integer index = llListFindList(sources+tempsources,[id]);
                
                if (index!=-1 && (string)llList2Integer(channels+tempchannels,index)!=llList2String(channels+tempchannels,index))
                {//llOwnerSay("new listener");
                if (channel==0) channel = 9999 + (integer) llFrand(9999999);
                    agent_channels+= [channel];
                    agent_listeners += [llListen(channel, "", llGetOwner(), "")];
                    agent_sources += [id];
                    llSetTimerEvent(pollfreq);
                }
            }  
        }
        else if (num==CMD_ACKPOLICY)
        {
                integer quiet = (msg=="quiet");
                integer index = llListFindList(sources,[id]);
                if (index!=-1) quietack = llListReplaceList(quietack, [quiet],index,index);
                index = llListFindList(tempquietack,[id]);
                if (index!=-1) tempquietack = llListReplaceList(tempquietack, [quiet],index,index);
                else
                {
                    tempsources += [id];
                    tempquietack += [quiet];
                    templisteners+= [RLVR_CHAN];
                    tempbuffers += [""];
                } 
        }
        else if (num==CMD_ACKDEBUG) g_iDebug = (integer) msg;
        /* for http-in: send all delayed acks in one message
        else if (num==CMD_FLUSH)
        {
            integer pblen = llGetListLength(buffers);
            integer len = pblen + llGetListLength(tempbuffers);
            integer index;
            for (index = 0; index < len; index++)
            {
                string buffer = llList2String(buffers+tempbuffers, index);
               // llOwnerSay("Response sent: "+buffer);
                llHTTPResponse(llList2Key(channels+tempchannels, index), 200, buffer);
                if (index < pblen) buffers = llListReplaceList(buffers, [""], index, index);
                else tempbuffers = llListReplaceList(tempbuffers, [""], index - pblen, index - pblen);
            }
        }
        */
    }
    
    listen(integer chan, string who, key id, string msg)
    {
        if (id == llGetOwner())
        { //llOwnerSay("Incoming message from agent.");
            //something to do with answers from viewer
            integer index = llListFindList(agent_channels,[chan]);
            key source = llList2Key(agent_sources,index);
            index = llListFindList(sources+tempsources, [source]);
            string source_channel = llList2String(channels+tempchannels, index);
            //llOwnerSay("channel: "+source_channel);
/*            if ((key) source_channel != NULL_KEY)  //this test is wrong, change this when reenabling http
            {//llOwnerSay("Sent to qhttp: "+msg);
                qhttp(llListFindList(sources+tempsources,[source]), (string)chan+","+msg);
            }
            else*/ qemail(source,(string)chan+","+msg);
        }
        else
        {
            list args = llParseStringKeepNulls(msg,[","],[]);
            if (llGetListLength(args)!=3 || (llList2Key(args,1)!=llGetOwner() && llList2Key(args,1)!= WILDCARD)) return;
            if (msg == (string)nonce+","+(string)llGetOwner()+",!x-session-confirm")
            {
                llOwnerSay(llKey2Name(id)+"'s session now uses e-mail. Prepare for a gridwide experience!");
                llRegionSayTo(id, chan,(string)nonce+","+(string)id+",!x-session-confirm,ok");
                llMessageLinked(LINK_THIS, CMD_NEWKEY, session, id);
                integer index = llListFindList(sources,[id]);
                if (index!=-1)
                {
                    sources = llListReplaceList(sources, [session],index,index);
                    channels = llListReplaceList(channels, [address],index,index);
                    llListenRemove(llList2Integer(listeners,index));
                    email_sources ++;
                }
                index = llListFindList(tempsources,[id]);
                if (index!=-1)
                {
                    tempsources = llListReplaceList(tempsources, [session],index,index);
                    tempchannels = llListReplaceList(tempchannels, [address],index,index);
                    llListenRemove(llList2Integer(templisteners,index));
                }
                // dropping the old nonce, preventing replay
                nonce = (integer) llFrand(99999999);
                
                return;
            }
            else llMessageLinked(LINK_THIS, CMD_RECVRLVR, llList2String(args,0)+","+llList2String(args,2),id);
        }
    }
    
    email(string date, string mail_address, string topic, string msg, integer remaining)
    {
        list topicargs = llParseStringKeepNulls(topic,[","],[]);
        if (llGetListLength(topicargs)<3) return;
        key thissession = llList2Key(topicargs,2);
        if (thissession == NULL_KEY) return;
        if (llList2String(topicargs,0)!=protocolstring) return;
        list lines = llParseString2List(msg,["\n"],[]);
        string msg_content = llList2String(lines,3);
        list args = llParseStringKeepNulls(msg_content,[","],[]);
        if (llGetListLength(args)<2) return;
        if (llList2String(args,1)=="!x-session" && (integer) date >= session_date)
        {
            nonce = (integer) llFrand(99999999);
            address = mail_address;
            session = thissession;
            llMessageLinked(LINK_THIS, EMAIL1, address+msg_content+","+(string)nonce,session);
        }
        else if (llGetSubString(llList2String(args,1),0,9)=="!x-channel")
        {
            key objid = llList2Key(llParseString2List(address,["@"],[]),0);
            if (insim(objid))
            {
                qemail(thissession,msg_content+",ok");
                sendmail();
                integer newchannel = llList2Integer(llParseString2List(llList2String(args,1),["/"],[]),1);
                integer index=llListFindList(sources,[thissession]);
                if (index!=-1)
                {
                    sources=llListReplaceList(sources,[objid],index,index);
                    llMessageLinked(LINK_THIS, CMD_NEWKEY, (string)objid, thissession);
                    email_sources--;
                }
                new_listener(newchannel,objid);
                llOwnerSay("Your session with "+llKey2Name(objid)+" is going back to chat mode.");
            } 
            else
            {
                llOwnerSay(llKey2Name(objid)+" tried and failed to ho back to chat mode.");
                qemail(thissession,msg_content+",ko");
            }
        }
        else
        { //standard encapsulated RLVR message
            llMessageLinked(LINK_THIS, CMD_RECVRLVR, msg_content,thissession);
            integer index=llListFindList(sources,[thissession]);
            if (index!=-1) channels=llListReplaceList(channels,[address],index,index);
            else
            {
                tempsources += [thissession];
                tempchannels += [address];
                templisteners += [-1];
                tempbuffers += [];
                tempquietack += [];
                email_tempsources ++;
            }
        }
        
        if (remaining) llGetNextEmail("","");
        
    }
    
    timer()
    {
//        llSetTimerEvent(0);
        integer i;
        for (i=0; i<llGetListLength(templisteners);i++) llListenRemove(llList2Integer(templisteners,i));
        tempchannels=[];
        templisteners=[];
        tempsources = [];
        tempbuffers = [];
        tempquietack = [];
        email_tempsources = 0;
        agent_waiting = 0;
        for (i=0; i<llGetListLength(agent_listeners);i++)
        {
            key source = llList2Key(agent_sources, i);
            integer index = llListFindList(sources+tempsources, [source]);
//            if (llList2Key(channels,index)) qhttp(index,"x,"+END+",x");
            llListenRemove(llList2Integer(agent_listeners,i));
        }
        agent_channels = [];
        agent_listeners = [];
        agent_sources = [];
        
        //if (email_mode)
         llGetNextEmail("","");
        //if (email_sources==0) email_mode = FALSE;
        
        //garbage collection
        for (i=0;i<llGetListLength(sources);i++)
        {
            if ((string)llList2Integer(channels,i)==llList2String(channels,i)) //test if it is an integer
            { // garbage collection for chat sources
                key id = (key) llList2String(sources,i);
                if (!insim(id)) llMessageLinked(LINK_THIS,CMD_CLR,"",id);
            }
        }
        sendmail();
        if (safewordPending) safeword();

    }
    changed(integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
        if (change & (CHANGED_REGION|CHANGED_INVENTORY))
        {
            integer i;
            for (i=0;i<=llGetListLength(sources);i++)
            {
                if ((string)llList2Integer(channels,i)!=llList2String(channels,i))
                {
                    qemail(llList2String(channels,i)+"ping,ping,ping",llList2Key(sources,i));
                }
            }
         
            // http-in
//            newurl();
        }
    }

/*    http_request(key id, string Method, string body) {
        if (Method == URL_REQUEST_GRANTED) {
            url = body+"/RLVR";
            llMessageLinked(LINK_THIS, CMD_URL, url, NULL_KEY);
            llOwnerSay("Http-in enabled on: "+url);
        }
        else if (Method == URL_REQUEST_DENIED)
        {
            llOwnerSay("No URLs free !");
        }
        else //if (Method == "GET")
        {
            key objid = (key) llGetHTTPHeader(id, "x-secondlife-object-key");
            //llOwnerSay(llKey2Name(objid)+" using http.");
            
            if (llGetHTTPHeader(id, "x-path-info")!="/RLVR") //Added a reply so the external server wont wait for timeout
            {
                llHTTPResponse(id, 200, "ERROR: Not reconised");
                return;
            }
            
            string msg_content = llUnescapeURL(llGetHTTPHeader(id, "x-query-string"));
            list args = llParseStringKeepNulls(msg_content, [","], []);
            if (llGetListLength(args)<2) //Added a reply so the external server wont wait for timeout
            {
                llHTTPResponse(id, 200, "ERROR: List too short");
                return;
            }
            ///llOwnerSay("basic tests ok");
            //llOwnerSay(msg_content);
            if (llGetSubString(llList2String(args,1),0,9)=="!x-channel")
            {
                if (insim(objid))
                {
                    llHTTPResponse(id, 200, msg_content+",ok");
                    integer newchannel = llList2Integer(llParseStringKeepNulls(llList2String(args,1),["/"],[]),1);
                    integer index=llListFindList(sources,[objid]);
                    new_listener(newchannel,objid);
                    llOwnerSay("Your session with "+llKey2Name(objid)+" is going back to chat mode.");
                } 
                else
                {
                    llOwnerSay(llKey2Name(objid)+" tried and failed to go back to chat mode.");
                    llHTTPResponse(id, 200, msg_content+",ko");
                }
            }
            else
            { //standard encapsulated RLVR message
                llMessageLinked(LINK_THIS, CMD_RECVRLVR, msg_content, objid);
                integer index=llListFindList(sources,[objid]);
                if (index!=-1) channels=llListReplaceList(channels,[(string) id],index,index);
                else
                {
                    tempsources += [objid];
                    tempchannels += [(string)id];
                    templisteners += [-1];
                    tempbuffers += [""];
                    tempquietack += [FALSE];
                }
            }
        }
    }

    attach(key id)
    {
        if (id) newurl();
        else llReleaseURL(url);
    }
*/
}
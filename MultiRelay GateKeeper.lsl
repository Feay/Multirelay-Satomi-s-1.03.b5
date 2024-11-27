integer MENU_CHANNEL;
integer AUTH_MENU_CHANNEL;
integer LIST_MENU_CHANNEL;
integer LIST_CHANNEL;
integer SIT_CHANNEL;
string PROTOCOL_VERSION = "1100"; //with some additions, but backward compatible, nonetheless
string ORG_VERSIONS = "ORG=0003/who=001/handover=001/email=005/delay=004/vision=001/follow=002/channel=001/ack=002";///http=001
string IMPL_VERSION = "Satomi's Multi-Relay";

integer commandChannel = 99;

string mode="ask";
integer safemode = 1;  // 0: off, 1: evil, 2: unconditional
//integer restraining=TRUE;
integer playful=FALSE;
integer locked=FALSE;   // manual locking
integer outfitkeeper=FALSE;

list sources=[];
list sourceUsers = []; // last !x-who user for each source
//key lastuser=NULL_KEY;
list tempwhitelist=[];
list tempblacklist=[];
list tempuserwhitelist=[];
list tempuserblacklist=[];
list objwhitelist=[];
list objblacklist=[];
list avwhitelist=[];
list avblacklist=[];
list objwhitelistnames=[];
list objblacklistnames=[];
list avwhitelistnames=[];
list avblacklistnames=[];

integer listPrinted=FALSE;
integer listPage=0;

list queue=[];
integer q_estimate = 0; //conservative estimate of queue memory print
integer QSTRIDES=3;
integer listener=0;
integer authlistener=0;
string timertype="";
string listtype;

//message map
integer CMD_MENU = 0;
integer CMD_ADD = 1;
integer CMD_REM = 2;
integer CMD_CLR = 3;
integer CMD_RES = 4;
integer CMD_SWD = 5;
integer CMD_SEND = 6;
integer CMD_LISTOBJ = 7;
integer CMD_HANDOVER = 8;
integer CMD_REFRESH = 9;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;
integer CMD_REMALLSRC = 13;
integer CMD_MANUAL_LOCK = 14;

integer CMD_STATUS = 21;

integer CMD_SENDRLVR = 41;
integer CMD_RECVRLVR = 42;
integer CMD_LISTEN = 45;
integer CMD_ACKPOLICY = 46;

// pigeonkeeper messages (for !x-email)
integer CMD_EMAIL_INIT = 50;
integer CMD_NEWKEY = 51;
integer CMD_URL = 55;

integer CMD_FLUSH = 59;

//integer EMAIL1 = 70;


integer CMD_REQSAFEWORD = 81;
integer CMD_ADD_BLOCKER = 82;
integer CMD_SWDMODE = 83;

integer CMD_SHOW_PENDING = 91;


integer CMD_FOLLOW_SET   = 100;
integer CMD_FOLLOW_CLEAR = 101;


// sandkeeper messages (for !x-delay)
integer CMD_DELAY_ADD = 110;
integer CMD_DELAY_CLEAR = 111;
// integer CMD_DELAYED_COMMAND = 112;  <- not needed CMD_RECVRLVR should be used instead
integer CMD_REALDELAY_ADD = 113;
//integer CMD_REALDELAY_CLEAR = 114;

integer CMD_VISION_SET   = 120;
integer CMD_VISION_CLEAR = 121;


integer CMD_FOLDERMODE=9000;

// dialog buttons
// main dialog
string B_SAFEWORD           = "⚐SAFEWORD⚐";
string B_SAFEWORD_MODE    = "Safeword ☠";
string B_REFRESH            = "♽ Refresh ♽";
string B_RELAY_STATE        = "Grabbed by";
string B_PLAYFUL_ENABLED    = "Playful ☑";
string B_PLAYFUL_DISABLED   = "Playful ☐";
string B_PENDING            = "⁂ Pending ⁂";
string B_ACCESS             = "Access lists";
string B_HELP               = "⁈ Help ⁈";
string B_MODE_OFF           = "Mode: Off";
string B_MODE_RESTR         = "Mode: Restr";
string B_MODE_ASK           = "Mode: Ask";
string B_MODE_AUTO          = "Mode: Auto";
string B_UNLOCKED           = "Locked ☐";
string B_LOCKED             = "Locked ☑";
//string B_DNS_ENABLED = "DNS ☑ (on)";
//string B_DNS_DISABLED = "DNS ☐ (off)";
string B_BUG                = "Report bug!";
string B_OUTFITKEEPER_ON    = "Sm. Strip ☑";
string B_OUTFITKEEPER_OFF   = "Sm. Strip ☐";

//string END = "$$";
//http-in
/*
string url="ko";
integer dns = FALSE;
key reqid;
string DNS="http://witchy-app.appspot.com/relaydb/";
*/

//!x-follow
key isFollowing = NULL_KEY;
//!x-vision
key hasVision = NULL_KEY;

sendrlvr(string ident, key id, string com, string ack)
{
    llMessageLinked(LINK_THIS, CMD_SENDRLVR, ident+","+com+","+ack, id);
}

key getwho(string cmd)
{
    if (llGetSubString(cmd,0,6)=="!x-who/") return (key)llGetSubString(cmd,7,42);
    else return NULL_KEY;
}

integer auth(key object, key user)
{ //llOwnerSay((string)user);
    integer auth=1;
    //object auth
    integer source_index=llListFindList(sources,[object]);
    if (source_index!=-1) {}
    else if (llListFindList(tempblacklist+objblacklist,[object])!=-1) return -1;
    else if (llListFindList(avblacklist,[llGetOwnerKey(object)])!=-1) return -1;
    else if (llListFindList(tempwhitelist+objwhitelist,[object])!=-1) {}
    else if (llListFindList(avwhitelist,[llGetOwnerKey(object)])!=-1) {}
    else if (mode=="auto") {}
    else if (mode=="restricted") return -1;
    else auth=0;
    //user auth
    if (user==NULL_KEY) {}
//    else if (source_index!=-1&&user==(key)llList2String(users,source_index)) {}
//    else if (user==lastuser) {}
    else if (llListFindList(avblacklist+tempuserblacklist,[user])!=-1) return -1;
    else if (llList2Key(sourceUsers, source_index) == user || llListFindList(avwhitelist+tempuserwhitelist,[user])!=-1) {}
    else if (mode=="auto") {}
    else if (mode=="restricted") return -1;
    else return 0;

    return auth;
}

dequeue()
{
    string command = "";
    string curident;
    key curid;
    while (command=="")
    {
        if (queue==[])
        {
            llMessageLinked(LINK_SET,CMD_STATUS,"idle",NULL_KEY);
            timertype="expire";
            llSetTimerEvent(5);
            q_estimate = 0;
            return;
        }
        curident=llList2String(queue,0); //first ident in the queue
        curid=(key)llList2String(queue,1); //first object key
//        llOwnerSay("Next command: "+ llList2String(queue,2));
        command=handlecommand(curident,curid, llList2String(queue,2), FALSE);
// llOwnerSay("in queue before delete: "+(string)llGetListLength(queue));
        queue=(queue=[])+llDeleteSubList(queue,0, QSTRIDES-1);
        q_estimate -= 50 + llStringLength(llList2String(queue,2))+llStringLength(curident);
// llOwnerSay("in queue after delete: "+(string)llGetListLength(queue));

    }
    q_estimate += 50 + llStringLength(command)+llStringLength(curident);
    queue=[curident,curid,command]+queue;
    timertype="authmenu";
    llSetTimerEvent(120);
    AUTH_MENU_CHANNEL=-9999 - llFloor(llFrand(9999999.0));
    list buttons=["Yes","No","Trust Object","Ban Object","Trust Owner","Ban Owner"];
    string owner=llGetDisplayName((llGetOwnerKey(curid)));
    if (owner!="") owner= ", owned by "+owner+",";
    string prompt=llKey2Name(curid)+owner+" wants to control your viewer.";
    if (llGetSubString(command,0,6)=="!x-who/")
    {
        buttons+=["Trust User","Ban User"];
        prompt+="\n"+llGetDisplayName((key)llGetSubString(command,7,42))+" is currently using this device.";
    }
    prompt+="\nDo you want to allow this?";
    authlistener=llListen(AUTH_MENU_CHANNEL,"",llGetOwner(),"");    
    llMessageLinked(LINK_SET,CMD_STATUS,"pending", curid);
    llDialog(llGetOwner(),prompt,buttons,AUTH_MENU_CHANNEL);
}

// handlecommand: handles RLVR command
// ident: ident part of the command (first part)
// key: key of the object sending the command
// com: the command itself ("|"-list)
// auth: has this command already been fully authed?
//   if TRUE: execute everything 
//   if FALSE: execute everything until the first command needing auth
//
// returns the list of commands that are still waiting for auth
string handlecommand(string ident, key id, string com, integer auth)
{
    integer isWho = llGetSubString(com,0,6)=="!x-who/";
    list commands=llParseString2List(com,["|"],[]);
    com = "";
    integer i;
    for (i=0;i<llGetListLength(commands);i++)
    {
        string command=llList2String(commands,i);
        integer wrong=FALSE;
        list subargs=llParseString2List(command,["="],[]);
        list metaargs=llParseStringKeepNulls(command,["/"],[]);
        string val=llList2String(subargs,1);
        string ack="ok";
//        llOwnerSay("subcommand: "+command);
        if (!auth &&
            ( llSubStringIndex(command, "!x-follow") == 0 || llSubStringIndex(command, "!x-vision") == 0
                || (llGetSubString(command,0,0) == "@" && (!playful||val=="n"||val=="add") && (integer) val == 0)
            ))
        { // if no auth, but auth required
            //returns the rest of the commands along with the !x-who data
            if (isWho) return llList2String(commands,0)+"|"+llDumpList2String(llList2List(commands,i,-1),"|");
            else return llDumpList2String(llList2List(commands,i,-1),"|");
        }
        else if (command=="!release") llMessageLinked(LINK_THIS,CMD_SWD,"",id);
        else if (command=="!version") ack=PROTOCOL_VERSION;
        else if (command=="!implversion") ack=IMPL_VERSION;
        else if (command=="!x-orgversions") ack=ORG_VERSIONS;
        else if (llGetSubString(command,0,6)=="!x-who/")
        {
            // lastuser = (key)llGetSubString(command,7,42);
            // TODO
        }
        else if (llGetSubString(command,0,10)=="!x-handover")
        {
            integer index = llListFindList(sources, [id]);
            key target = llList2Key(metaargs, 1);
            if (index==-1 || llGetListLength(metaargs) < 3 || NULL_KEY == target) ack="ko";
            else
            {
                integer keep = llList2Integer(metaargs, 2);
                if (keep)
                {
                    sources = llListReplaceList(sources,[target],index,index);
                    llMessageLinked(LINK_THIS,CMD_HANDOVER,(string)target,id);
                }
                else {llMessageLinked(LINK_THIS,CMD_SWD,"",id); tempwhitelist+=[target];}
            }
            // return "";  <- suspicious 1.03b4
        }
        else if (llGetSubString(command,0,9)=="!x-channel")
        {
            integer channel = llList2Integer(metaargs, 1);
            if (llGetListLength(metaargs) >= 2 && channel <= -1000)
            {
//                    sendrlvr(ident, source, msg, "ok");
                llMessageLinked(LINK_THIS,CMD_LISTEN,(string) channel,id);
            }
            else ack = "ko"; // 1.03b4
//            sendrlvr(ident,source, msg,"ko");    // 1.03b4
//            return "";    <-- suspicious? 1.03b4
        }
        else if (command=="!x-email") llMessageLinked(LINK_THIS, CMD_EMAIL_INIT, "", id);
//        else if (command=="!x-http") ack = url;
        else if (llGetSubString(command,0,6)=="!x-ack/")
        {
            string ackMode = llGetSubString(command,7,-1);
            llMessageLinked(LINK_THIS, CMD_ACKPOLICY, ackMode, id);
        }
        else if (llGetSubString(command,0,8)=="!x-delay/")
        {
            string delayedIdent = ident;
            integer CMD = CMD_DELAY_ADD;
            if (llGetListLength(metaargs) >= 3 && llList2String(metaargs,2) != "") delayedIdent = llList2String(metaargs,2);
            if (llGetListLength(metaargs) >= 4 && llList2String(metaargs,3) == "real") CMD = CMD_REALDELAY_ADD;
            llMessageLinked(LINK_THIS, CMD, llList2String(metaargs,1)+","+delayedIdent+","+llDumpList2String(llDeleteSubList(commands, 0, i),"|"), id);
            sendrlvr(ident,id,command,"ok");
            return "";   // this one is not suspicious: indeed subsequent commands are sent to sandkeeper
        }
        else  if (llGetSubString(command,0,13)=="!x-delay/clear")
        {
            string pattern = "";
            if (llGetListLength(metaargs) >= 2) pattern = llList2String(metaargs,1);
            llMessageLinked(LINK_THIS, CMD_DELAY_CLEAR, pattern, id);
        }
        else if (llGetSubString(command,0,14)=="!x-follow/clear") 
        {
            if ( isFollowing == id ) {
                llMessageLinked(LINK_THIS, CMD_FOLLOW_CLEAR, "", id);
                llMessageLinked(LINK_THIS,CMD_REM,"x-follow",id); // dummy restriction
                isFollowing = NULL_KEY;
            }
        }
        else if (llGetSubString(command,0,8)=="!x-follow") 
        {
            if ( isFollowing != NULL_KEY && isFollowing != id ) ack="ko";
            else
            {
                isFollowing = id;
                llMessageLinked(LINK_THIS, CMD_FOLLOW_SET, command, id);
                llMessageLinked(LINK_THIS,CMD_ADD,"x-follow",id); // dummy restriction
            }
        }
        else if (llGetSubString(command,0,14)=="!x-vision/clear") 
        {
            if ( hasVision == id ) {
                llMessageLinked(LINK_THIS, CMD_VISION_CLEAR, "", id);
                llMessageLinked(LINK_THIS,CMD_REM,"x-vision",id); // dummy restriction
                hasVision = NULL_KEY;
            }
        }
        else if (llSubStringIndex(command, "!x-vision") == 0)
        {
            if ( hasVision != NULL_KEY && hasVision != id ) ack="ko";
            else
            {
                hasVision = id;
                llMessageLinked(LINK_THIS, CMD_VISION_SET,  llGetSubString(command,10,-1), id);
                llMessageLinked(LINK_THIS,CMD_ADD,"x-vision",id); // dummy restriction
            }
        }
        else if (llGetSubString(command,0,0)=="!") ack="ko"; // ko unknown meta-commands
        else if (llGetSubString(command,0,0)!="@") ack=""; // ignore bad commands
/* ???? I wonder why I did this.... that way? Removing it for now (1.03b2)
        {
            if (isWho) return llList2String(commands,0)+"|"+llDumpList2String(llList2List(commands,i,-1),"|");
            else return llDumpList2String(llList2List(commands,i,-1),"|");
        }//probably an ill-formed command, not answering
*/
        else if (command=="@clear") llMessageLinked(LINK_THIS,CMD_CLR,"",id);
        else if ((integer)val>0) llMessageLinked(LINK_THIS,CMD_SEND, llGetSubString(command,1,-1), id);
        else if (llGetListLength(subargs)==2)
        {
            string behav=llGetSubString(llList2String(subargs,0),1,-1);
            if (val=="force")
            {
                llMessageLinked(LINK_THIS,CMD_SEND,behav+"="+val,id);
            }
            else if (val=="n"||val=="add")
            {
                llMessageLinked(LINK_THIS,CMD_ADD,behav,id);
            }
            else if (val=="y"||val=="rem")
            {
                llMessageLinked(LINK_THIS,CMD_REM,behav,id);
            }
            else if (behav == "clear") llMessageLinked(LINK_THIS,CMD_CLR, val, id);
            else ack="ko";
        }
        else ack = ""; // ignore ill-formed commands
/* suspicious (1.03b2)
        {
            if (isWho) return llList2String(commands,0)+"|"+llDumpList2String(llList2List(commands,i,-1),"|");
            else return llDumpList2String(llList2List(commands,i,-1),"|");
        }//probably an ill-formed command, not answering
*/        
        if  (ack) sendrlvr(ident,id,command,ack);
    }
    return "";
}

/*
debug (string msg)
{
    llInstantMessage(llGetOwner(),msg);
}
*/

safeword (key id)
{
    if (id == NULL_KEY)
    {
        llOwnerSay("You have safeworded");
        tempblacklist=[];
        tempwhitelist=[];
        tempuserblacklist=[];
        tempuserwhitelist=[];
        integer i;
        //verboseAcks = [];
        for (i=0;i<llGetListLength(sources);i++)
        {
            sendrlvr("release",llList2Key(sources,i),"!release","ok");
        }
        sources=[];
        hasVision = NULL_KEY;
        isFollowing = NULL_KEY;
    }
    llMessageLinked(LINK_THIS, CMD_STATUS, "off", NULL_KEY);
    timertype="safeword";
    llSetTimerEvent(5.);
}

//----Menu functions section---//
menu()
{
        timertype="menu";
        llSetTimerEvent(120);
        string prompt="";        
        list buttons=[];
        prompt+="\nCurrent mode is: "+mode;
//        if (restraining) prompt+=", restraining";
//        else prompt+=", non-restraining";
        if (mode == "auto") buttons+= [B_MODE_AUTO];
        else if (mode == "ask") buttons+= [B_MODE_ASK];
        else if (mode == "restricted") buttons+= [B_MODE_RESTR];
        else if (mode == "off") buttons += [B_MODE_OFF];
        if (sources == [] && mode != "off")
        {
            buttons += [B_SAFEWORD_MODE];
        }
        else buttons += [" "];
        if (mode == "restricted" || mode == "ask")
        {
            if (playful)
            {
                prompt+=", playful";
                buttons+=[B_PLAYFUL_ENABLED];
            }
            else
            {
                buttons+=[B_PLAYFUL_DISABLED];
                prompt+=", not playful";
            }                
        }
        else buttons += [" "];
        if (sources!=[])
        {
            prompt+="\nYou are currently grabbed by "+(string)llGetListLength(sources)+" object";
            if (llGetListLength(sources)==1) prompt+=".";
            else prompt+="s.";
            buttons+=[B_RELAY_STATE];
            if (safemode) buttons+=[B_SAFEWORD];
            else buttons += [" "];
            buttons+=[B_REFRESH];
        }
        else buttons += [" ", " ", " " ];
        if (mode != "off")
        {
            if (safemode == 1) prompt+=", with evil safeword";
            else if (safemode == 2) prompt+=", with safeword";
            else prompt+=", without safeword";
        }
        prompt += ".";
        if (queue!=[])
        {
            prompt+="\nYou have pending requests.";
            buttons+=[B_PENDING];
        }
        else buttons+= [" "];
        //buttons+=[" "];
        if (outfitkeeper)
        {
            buttons+=[B_OUTFITKEEPER_ON];
            prompt+="\nSmartStrip is on. ";
        }
        else 
        {
            buttons+=[B_OUTFITKEEPER_OFF];
            prompt+="\nSmartStrip is off. ";
        }
/*        if (dns)
        {
            prompt+="\nDNS is enabled";
            buttons += [B_DNS_ENABLED];
        }
        else 
        {
            prompt+="\DNS is disabled";
            buttons += [B_DNS_DISABLED];
        }
*/
//        buttons+=[" "]; //to remove when http is put back
        buttons+=[B_BUG]; //used to be DNS spot... beware when DNS comes backç
        buttons+=[B_HELP];
        if(sources!=[])
        {
            buttons+=[" "];
        }
        else if(locked)
        {
            buttons+=[B_LOCKED];
        }
        else
        {
            buttons+=[B_UNLOCKED];
        }
        
        buttons+=[B_ACCESS];
        prompt+="\n\nMake a choice:";
        listener=llListen(MENU_CHANNEL,"",llGetOwner(),"");
        llDialog(llGetOwner(),prompt,buttons,MENU_CHANNEL);
}

listsmenu()
{
        string prompt="What list do you want to remove items from?";
        list buttons=["Trusted Object","Banned Object","Trusted Avatar","Banned Avatar"];
        prompt+="\n\nMake a choice:";
        listener=llListen(LIST_MENU_CHANNEL,"",llGetOwner(),"");    
        llDialog(llGetOwner(),prompt,buttons,LIST_MENU_CHANNEL);
}

plistmenu(string msg)
{
    list olist;
    list olistnames;
    string prompt;
    if (msg=="Trusted Object")
    {
        olist=objwhitelist;
        olistnames=objwhitelistnames;
        prompt="What object do you want to stop trusting?";
    }
    else if (msg=="Banned Object")
    {
        olist=objblacklist;
        olistnames=objblacklistnames;
        prompt="What object do you want not to ban anymore?";
    }
    else if (msg=="Trusted Avatar")
    {
        olist=avwhitelist;
        olistnames=avwhitelistnames;
        prompt="What avatar do you want to stop trusting?";
    }
    else if (msg=="Banned Avatar")
    {
        olist=avblacklist;
        olistnames=avblacklistnames;
        prompt="What avatar do you want not to ban anymore?";
    }
    else return;
    listtype=msg;

    list buttons=["All"];
    integer numOfEntries=llGetListLength(olist);
    integer numOfButtons=numOfEntries;
    integer startEntry=0;
    if(numOfEntries>11)
    {
        integer pages=(numOfEntries-1)/9;
        if(listPage==-1)
        {
            listPage=pages;
        }
        else if(listPage>pages)
        {
            listPage=0;
        }

        numOfButtons=9;
        if(listPage*9+9>numOfEntries)
        {
            numOfButtons=numOfEntries % 9;
        }
        startEntry=listPage*9;
        buttons=["<<","All",">>"];
    }

    prompt+="\n";
    integer i;
    for (i=0;i<numOfButtons;i++)
    {
        buttons+=(string)(startEntry+i+1);
        prompt+="\n"+(string)(startEntry+i+1)+": "+llList2String(olistnames,i);
    }
    if(!listPrinted)
    {
        for (i=0;i<numOfEntries;i++)
        {
            listPrinted=TRUE;
            llOwnerSay((string)(i+1)+": "+llList2String(olistnames,i)+", "+llList2String(olist,i));
        }
    }
    listener=llListen(LIST_CHANNEL,"",llGetOwner(),"");    
    llDialog(llGetOwner(),llGetSubString(prompt,0,511),buttons,LIST_CHANNEL);
}

remlistitem(string msg)
{
    integer i=((integer) msg) -1;
    if (listtype=="Trusted Object")
    {
        if (msg=="All") {objwhitelist=[];objwhitelistnames=[];return;}
        if  (i<llGetListLength(objwhitelist))
        {
            objwhitelist=llDeleteSubList(objwhitelist,i,i);
            objwhitelistnames=llDeleteSubList(objwhitelistnames,i,i);
        }
    }
    else if (listtype=="Banned Object")
    {
        if (msg=="All") {objblacklist=[];objblacklistnames=[];return;}
        if  (i<llGetListLength(objblacklist))
        {
            objblacklist=llDeleteSubList(objblacklist,i,i);
            objblacklistnames=llDeleteSubList(objblacklistnames,i,i);
        }
    }
    else if (listtype=="Trusted Avatar")
    {
        if (msg=="All") {avwhitelist=[];avwhitelistnames=[];return;}
        if  (i<llGetListLength(avwhitelist)) 
        { 
            avwhitelist=llDeleteSubList(avwhitelist,i,i);
            avwhitelistnames=llDeleteSubList(avwhitelistnames,i,i);
        }
    }
    else if (listtype=="Banned Avatar")
    {
        if (msg=="All") {avblacklist=[];avblacklistnames=[];return;}
        if  (i<llGetListLength(avblacklist))
        { 
            avblacklist=llDeleteSubList(avblacklist,i,i);
            avblacklistnames=llDeleteSubList(avblacklistnames,i,i);
        }
    }
    
}


default
{
    state_entry()
    {
    llOwnerSay((string)llGetFreeMemory());
        MENU_CHANNEL=-9999 - llFloor(llFrand(9999999.0));
        LIST_MENU_CHANNEL=-9999 - llFloor(llFrand(9999999.0));
        LIST_CHANNEL=-9999 - llFloor(llFrand(9999999.0));
        SIT_CHANNEL=9999 + llFloor(llFrand(9999999.0));
        llMessageLinked(LINK_THIS, CMD_STATUS, mode, NULL_KEY);
    }

    listen(integer chan, string who, key id, string msg)
    {
        if (chan==MENU_CHANNEL)
        {
            llListenRemove(listener);
            llSetTimerEvent(0);
            if (msg==B_SAFEWORD) llMessageLinked(LINK_THIS, CMD_REQSAFEWORD, "", NULL_KEY);
            else if (msg==B_OUTFITKEEPER_OFF)
            {
                outfitkeeper=TRUE;
                llMessageLinked(LINK_THIS,CMD_FOLDERMODE,"on",NULL_KEY);
            }
            else if (msg==B_OUTFITKEEPER_ON)
            {
                outfitkeeper=FALSE;
                llMessageLinked(LINK_THIS,CMD_FOLDERMODE,"off",NULL_KEY);
            }
            else if (msg == B_SAFEWORD_MODE)
            {
                if (sources==[]) 
                {
                    safemode = (safemode + 1) % 3;
                    if (safemode == 1) B_SAFEWORD_MODE = "Safeword ☠";
                    else if (safemode == 2) B_SAFEWORD_MODE   = "Safeword ☑";
                    else B_SAFEWORD_MODE = "Safeword ☐";
                    llMessageLinked(LINK_THIS, CMD_SWDMODE, (string) safemode, NULL_KEY);
                }
                else llOwnerSay("Nice try. Unfortunately, it is too late to change that now!");
            }
            else if (msg==B_MODE_AUTO)
            {
                if (sources==[])
                {
                    mode="off";
                    llOwnerSay("Oh come on! No fun! Well, some peace cannot harm. Your relay is now disabled.");
                }
                else
                {
                    mode="restricted";
                    llOwnerSay("Nice try. Unfortunately, the relay is currently locked. The best we can do is switch to Restricted mode.");
                }
            }
            else if (msg==B_MODE_RESTR)
            {
                mode="ask";
                llOwnerSay("Your relay is now working in Ask mode. Your authorization will be asked for unknown RLV sources to control it.");
            }
            else if (msg==B_MODE_ASK)
            {
                mode="auto";
                llOwnerSay("Your relay is now working in Auto mode. All RLV sources can control it, except blacklisted ones.");
            }
            else if (msg==B_MODE_OFF)
            {
                mode="restricted";
                llOwnerSay("Your relay is now working in Restricted mode. Only whitelisted RLV sources and allowed commands can control it.");
            }
//            else if (msg=="+NoRestraint")
//            {
//                if (sources==[])
//                {
//                    restraining=FALSE;
//                }
//                else llOwnerSay("Sorry, you will have to endure those restraints a little longer.");
//            }
//            else if (msg=="-NoRestraint")
//            {
//                restraining=TRUE;
//            }
            else if (msg== B_PLAYFUL_DISABLED)
            {
                playful=TRUE;
                llOwnerSay("Playful option enbled. Non-restricting (force) RLV commands will now control your relay without asking you.");
            }
            else if (msg== B_PLAYFUL_ENABLED)
            {
                playful=FALSE;
                llOwnerSay("Playful option disabled. Non-restricting (force) RLV commands are handled normally.");
            }
            else if (msg== B_RELAY_STATE)
            {
                llMessageLinked(LINK_THIS,CMD_LISTOBJ,"","");
            }
            else if (msg== B_PENDING)
            {
                dequeue();
                return;
            }
            else if (msg== B_REFRESH)
            {
                llMessageLinked(LINK_THIS, CMD_REFRESH, "", NULL_KEY);
            }
            else if (msg== B_ACCESS)
            {
                listsmenu();
                return;
            }
            else if (msg== B_UNLOCKED)
            {
                locked=TRUE;
                llMessageLinked(LINK_THIS,CMD_MANUAL_LOCK,"1",NULL_KEY);
            }
            else if (msg== B_LOCKED)
            {
                locked=FALSE;
                llMessageLinked(LINK_THIS,CMD_MANUAL_LOCK,"0",NULL_KEY);
            }
            else if (msg== B_HELP)
            {
                llGiveInventory(id,"Satomi's MultiRelay - Help");
            }
            else if (msg== B_BUG)
            {
                llLoadURL(id, "Please use this issue tracker to report bugs or make suggestions.", "http://code.google.com/p/multirelay/issues");

            }
/*            else if (msg== B_DNS_ENABLED)
            {
                dns = FALSE;
                llOwnerSay("Unregistering: "+url);
                reqid = llHTTPRequest(DNS+"?type=remove",[],"");
            }
            else if (msg== B_DNS_DISABLED)
            {
                llOwnerSay("Registering: "+url);
                reqid = llHTTPRequest(DNS+"?type=add&url="+llEscapeURL(url),[],"");
                dns = TRUE;
            }
*/            else return;
            llMessageLinked(LINK_THIS,CMD_STATUS,mode,id);
            menu();
        }
        else if (chan==LIST_MENU_CHANNEL)
        {
            listPrinted=FALSE;
            llSetTimerEvent(0);
            llListenRemove(listener);
            plistmenu(msg);
        }
        else if (chan==LIST_CHANNEL)
        {
            llSetTimerEvent(0);
            llListenRemove(listener);
            if(msg=="<<")
            {
                listPage--;
                plistmenu(listtype);
            }
            else if(msg==">>")
            {
                listPage++;
                plistmenu(listtype);
            }
            else
            {
                remlistitem(msg);
            }
        }
        else if (chan==AUTH_MENU_CHANNEL)
        {   // TODO: lot of stuff concerning users
            llListenRemove(authlistener);
            llSetTimerEvent(0);
            authlistener=0;
            key curid=(key)llList2String(queue,1); //first object key
            key user=getwho(llList2String(queue,2));
            if (msg=="Yes")
            {
                tempwhitelist+=[curid];
                if (user) tempuserwhitelist+=[user];
                // TODO: put the user in sourceUsers
            }
            else if (msg=="No")
            {
                if (llListFindList(tempwhitelist+sources, [curid]) == -1) tempblacklist+=[curid];
                if (user) tempuserblacklist+=[user];
            }
            else if (msg=="Trust Object")
            {
                objwhitelist+=[curid];
                objwhitelistnames+=[llKey2Name(curid)];
            }
            else if (msg=="Ban Object")
            {
                objblacklist+=[curid];
                objblacklistnames+=[llKey2Name(curid)];
            }
            else if (msg=="Trust Owner")
            {
                avwhitelist+=[llGetOwnerKey(curid)];
                avwhitelistnames+=[llGetUsername(llGetOwnerKey(curid))];
            }
            else if (msg=="Ban Owner")
            {
                avblacklist+=[llGetOwnerKey(curid)];
                avblacklistnames+=[llGetUsername(llGetOwnerKey(curid))];
            }
            else if (msg=="Trust User")
            {
                avwhitelist+=[user];
                avwhitelistnames+=[llGetUsername(user)];
            }
            else if (msg=="Ban User")
            {
                avblacklist+=[user];
                avblacklistnames+=[llGetUsername(user)];
            }

            //clean newly authed events, while preserving the order of arrival for every device

            // list on_hold=[];       1.03b4: what was that for? on_hold means that auth was neither 1 or -1, why would have it changed at in a future iteration?
            integer i=0;
//llOwnerSay("in queue: "+(string)llGetListLength(queue));
            while (i< llGetListLength(queue))
            {
                string ident=llList2String(queue,0);//first ident
                key object=(key)llList2String(queue,1); //first object key
                string command=llList2String(queue,2); // first command in queue
                key user=getwho(command);
                integer auth=auth(object,user);
/*                if(llListFindList(on_hold,[object])!=-1) i+=QSTRIDES; // skip
                else 
1. 03b4 */
                if(auth==1)
                {
//            llOwnerSay("executing command from "+(string)object);
                  queue=(queue=[])+llDeleteSubList(queue,i,i+QSTRIDES-1);
                  handlecommand(ident,object,command,TRUE);
                }
                else if(auth==-1)
                {
                    queue=(queue=[])+llDeleteSubList(queue,i,i+QSTRIDES-1);
//            llOwnerSay("removing command from "+(string)object);
                    list commands = llParseString2List(command,["|"],[]);
                    integer j;
                    for (j=0;j<llGetListLength(commands);j++)
                    sendrlvr(ident,object,llList2String(commands,j),"ko");
                }
                else
                {
//            llOwnerSay("skipping command from "+(string)object);

                    i+=QSTRIDES;
//                    on_hold+=[object];        1.03b4
                }
            }
            // end of cleaning
//llOwnerSay("in queue: "+(string)llGetListLength(queue));
            dequeue();
            llMessageLinked(LINK_THIS, CMD_FLUSH, "", NULL_KEY);
        }
    }
        
    timer()
    {
        llSetTimerEvent(0);
        if (timertype=="authmenu")
        {
            llListenRemove(authlistener);
            authlistener=0;
            //dequeue();
        }
        else if (timertype=="menu")
        {
            llListenRemove(listener);
        }
        else if (timertype=="safeword")
        {
            llMessageLinked(LINK_THIS, CMD_STATUS, mode, NULL_KEY);
        }
        timertype="";
        tempblacklist=[];
        tempwhitelist=[];
        tempuserblacklist=[];
        tempuserwhitelist=[];
    }
    
    link_message(integer sender_num, integer num, string str, key id )
    {
        if (num==CMD_RECVRLVR)
        {
            if (timertype=="safeword") return;
            if (str=="ping,!pong") return;
            list args=llParseStringKeepNulls(str,[","],[]);
            str = "";  // free up memory in case of large messages
            string ident=llList2String(args,0);
            string command=llToLower(llList2String(args,1));
            args = [];  // free up memory in case of large messages
            //debug(msg);
            integer auth=auth(id,getwho(command));
            if (auth==1)
            {
                handlecommand(ident,id,command,TRUE);
                llMessageLinked(LINK_THIS, CMD_FLUSH, "", NULL_KEY);
            }
            else if (auth!=-1 && q_estimate += 50 + llStringLength(ident)+llStringLength(command) < 6000) //keeps margin for this event + next arriving chat message. was MAXLOAD
            { //debug("queue/ask: "+command);
                queue=(queue=[])+queue+[ident, id, command];
//    llOwnerSay((string)llGetFreeMemory()+"+"+(string)q_estimate);
                if (authlistener==0) dequeue();
            }
            else
            { // reject commands you cannot store (but should we even safeword?)
                list commands = llParseString2List(command,["|"],[]);
                integer j;
                for (j=0;j<llGetListLength(commands);j++)
                sendrlvr(ident,id,llList2String(commands,j),"ko");
//                sendrlvr("release",id,"!release","ok");
//                llMessageLinked(LINK_THIS,CMD_SWD,"",id);  <-- should I?
                if (!auth) llOwnerSay("Out of memory."); // Safewording "+llKey2Name(id));  <-- is it a good idea?
//                timertype = "safeword";
//               llSetTimerEvent(20.);
            }
        }
        if (num==CMD_ADDSRC)
        {
            sources+=[id];
            //verboseAcks+=[TRUE];
//            users+=[lastuser];
            if(safemode != 1) return;
            if(llListFindList(objwhitelist,[id])!=-1 ||
               llListFindList(avwhitelist,[llGetOwnerKey(id)])!=-1
              )
            {
                llMessageLinked(LINK_THIS, CMD_ADD_BLOCKER, "", id);
            }
        }
        else if (num==CMD_REMSRC)
        {
            integer i= llListFindList(sources,[id]);
            if (i!=-1)
            {
                sources=llDeleteSubList(sources,i,i);
                //verboseAcks=llDeleteSubList(verboseAcks,i,i);
//                users=llDeleteSubList(users,i,i);
            }
        }
        else if (num==CMD_REMALLSRC)
        {
            sources = [];
            //verboseAcks = [];
        }
        else if (num==CMD_NEWKEY)
        {
            integer index = llListFindList(sources, [id]);
            if (index!=-1) sources = llListReplaceList(sources,[(key)str],index,index);
            index = llListFindList(tempwhitelist, [id]);
            if (index!=-1) tempwhitelist = llListReplaceList(tempwhitelist,[(key)str],index,index);
        }
        else if (num == CMD_SWD) {if (str=="user safeword") safeword(id);}
        else if (num == CMD_SHOW_PENDING)
        {
            dequeue();
        }
        else if (num == CMD_MENU)
        {
            menu();
        }
/*        else if (num == CMD_URL)
        {
            url = str;
            if (dns)
            {
                reqid = llHTTPRequest(DNS+"?type=add&url="+llEscapeURL(url),[],"");
                llOwnerSay("Updating URL on DNS.");                
            }
        }
*/    }
    
    changed(integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
    }
    
/*    http_response(key req, integer status, list metadata, string body)
    {
        if (req==reqid) llOwnerSay(body);
    }
*/
}

// Handles @thirdview and !x-vision

integer CMD_ADD = 1;
integer CMD_REM = 2;
integer CMD_SWD = 5;
integer CMD_SEND = 6;
integer CMD_ML=31;

integer CMD_VISION_SET   = 120;
integer CMD_VISION_CLEAR = 121;


list sources;

integer enabled = FALSE;

integer visionPrim;

vector vision_color;
float vision_alpha;
key vision_texture;
vector vision_repeats;
vector vision_offsets;
float vision_rot;
vector vision_position;
vector screen_center;

disable()
{
    enabled = FALSE;
    llMessageLinked(LINK_THIS, CMD_REM, "setenv", NULL_KEY); // this should restore environment in RLVa
    llMessageLinked(LINK_THIS, CMD_REM, "setdebug", NULL_KEY);
    llMessageLinked(LINK_THIS, CMD_SEND, "setdebug_renderresolutiondivisor:1=force", NULL_KEY); //env not restored here (could interfere with user settings or other RLV devices)
}

enable()
{
    enabled = TRUE;
    llMessageLinked(LINK_THIS, CMD_ADD, "setenv", NULL_KEY);
    llMessageLinked(LINK_THIS, CMD_ADD, "setdebug", NULL_KEY);
    llMessageLinked(LINK_THIS, CMD_SEND, "setdebug_renderresolutiondivisor:128=force,setenv_scenegamma:0.0=force", NULL_KEY); // send it to bookkeeper in order to preserve order of execution
    llInstantMessage(llGetOwner(),"Now go to mouselook or remain in the dark!");
}

visionclear()
{
    vision_color = <1.0, 1.0, 1.0>;
    vision_alpha = 0.0;
    vision_texture = TEXTURE_BLANK;
    vision_repeats = <1.0, 1.0, 0.0>;
    vision_offsets = ZERO_VECTOR;
    vision_rot = 0.0;
    vision_position = <1.0, 0, 0>;
    visionrefresh();
    llSetLinkPrimitiveParamsFast(visionPrim, [PRIM_SIZE, <0.01, 0.01, 0.01>]);
}
    
visionset(string params)
{
    list lArgs = llParseStringKeepNulls(params, ["/"], []);
    if (llList2String(lArgs,0) != "*") vision_color = (vector) llDumpList2String(llParseString2List(llList2String(lArgs,0),["'"],[]), ",") / 255;
//    llOwnerSay("color: "+(string)vision_color);
    if (llList2String(lArgs,1) != "*") vision_alpha = llList2Float(lArgs,1);
//    llOwnerSay("alpha: "+(string)vision_alpha);
    if (llList2Key(lArgs,2) == "TEXTURE_BLANK") vision_texture = TEXTURE_BLANK;
    else if (llList2Key(lArgs,2) == "TEXTURE_PLYWOOD") vision_texture = TEXTURE_PLYWOOD;    
    else if (llList2String(lArgs,2) != "*") vision_texture = llList2Key(lArgs,2);
    if (llList2String(lArgs,3) != "*") vision_repeats = (vector) llDumpList2String(llParseString2List(llList2String(lArgs,3),["'"],[])+[.0], ",");
    if (llList2String(lArgs,4) != "*") vision_offsets = (vector) llDumpList2String(llParseString2List(llList2String(lArgs,4),["'"],[])+[.0], ",");
    if (llList2String(lArgs,5) != "*") vision_rot = llList2Float(lArgs,5);
    vision_position = screen_center;
    
    llSetLinkPrimitiveParamsFast(visionPrim, [PRIM_SIZE, <1.0, 4.0, 2>]);  // X coordinate: hud depth. 1m = 1 screen height.
    visionrefresh();
}

visionrefresh()
{
    llSetLinkPrimitiveParamsFast(visionPrim, [PRIM_POSITION, vision_position]);
    llSetLinkPrimitiveParamsFast(visionPrim, [PRIM_COLOR, ALL_SIDES, vision_color, vision_alpha]);
    llSetLinkPrimitiveParamsFast(visionPrim, [PRIM_TEXTURE, ALL_SIDES, vision_texture, vision_repeats, vision_offsets, vision_rot]);
}
    
findcenter()
{
        integer attachpt = llGetAttached();
        if (attachpt == ATTACH_HUD_BOTTOM_LEFT) screen_center = <1.0, -1, .5>;
        else if (attachpt == ATTACH_HUD_TOP_LEFT) screen_center = <1.0, -1, -.5>;
        else if (attachpt == ATTACH_HUD_TOP_CENTER) screen_center = <1.0, 0, -.5>;
        else if (attachpt == ATTACH_HUD_TOP_RIGHT) screen_center = <1.0, 1, -.5>;
        else if (attachpt == ATTACH_HUD_BOTTOM_RIGHT) screen_center = <1.0, 1, .5>;
        else if (attachpt == ATTACH_HUD_BOTTOM) screen_center = <1.0, 0, .5>;
        else if (attachpt == ATTACH_HUD_CENTER_1) screen_center = <1.0, 0, 0>;
        else if (attachpt == ATTACH_HUD_CENTER_2) screen_center = <1.0, 0, 0>;

        screen_center -= llGetLocalPos();
}
    
default
{
    state_entry()
    {
        // search !x-vision prim
        integer i;
        for (i = 2; i <= llGetNumberOfPrims(); i++)
        {
            if ((string)llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]) == "~vision") visionPrim =i;
        }
        visionclear();
    }
    
    link_message(integer sender_num, integer num, string str, key id )
    {
        if (num==CMD_ML)
        {
            if (str=="on")
            {
                integer index = llListFindList(sources, [id]);
                if (index == -1) sources += id;
                llSetTimerEvent(1.0);
            }
            else if (str="off")
            {
                integer index = llListFindList(sources, [id]);
                if (index != -1) sources == llDeleteSubList(sources, index, index);
                if (sources == []) { llSetTimerEvent(0); disable();}
            }
        }
        else if (num == CMD_VISION_SET)
        {
            findcenter();
            visionset(str);
        }
        else if (num == CMD_VISION_CLEAR)
        {
            visionclear();
        }
        else if (num==CMD_SWD) {sources = []; llSetTimerEvent(0); disable(); visionclear();}
    }
    
    timer()
    {
        integer toEnable = (0 == (llGetAgentInfo(llGetOwner()) & AGENT_MOUSELOOK));
        if (toEnable && !enabled ) enable();
        else if (!toEnable && enabled) disable();
    }
        
}

integer CMD_MENU = 0;
integer CMD_ADD = 1;
integer CMD_REM = 2;
integer CMD_CLR = 3;
integer CMD_RES = 4;
integer CMD_SWD = 5;
integer CMD_SEND = 6;
integer CMD_LISTOBJ = 7;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;
integer CMD_REMALLSRC = 13;
integer CMD_STATUS = 21;

integer CMD_REQSAFEWORD = 81;

integer CMD_SHOW_PENDING = 91;


integer CMD_SOURCES=200000; // message to timer display

integer trans = FALSE;
integer nsources = 0;

float BASE_ALPHA = 0.7;
float LOCKED_ALPHA = 1.0;
float HIGH_ALPHA = 1.0;
float LOW_ALPHA = 0.3;
float OFF_ALPHA = 0.2;
float alpha = BASE_ALPHA;
string text = "";

string btexture="ab75d5ec-c4fa-eaf8-3746-138002ad8125"; //numbers
string ptexture="62ba548b-0805-2505-7881-6c1f2a813cf3";
integer pendingprim;
integer sourcesprim;

vector textcol=<1.0,0,0>;

string buttondown="ask";
integer buttonlocked=FALSE;

integer sourcesPrim;
integer pendingPrim;
string tex="Numbers";

integer lasttouch;

setPending(integer switch)
{
    if (switch)
    {
         llSetLinkPrimitiveParamsFast(pendingPrim, [PRIM_TEXT, "Request(s) pending.",textcol,1.0]);
         llSetLinkPrimitiveParamsFast(pendingPrim, [PRIM_GLOW,ALL_SIDES,0.15]);
         llSetLinkAlpha(pendingPrim, 1.0,ALL_SIDES);
    }
    else
    {
        llSetLinkPrimitiveParamsFast(pendingPrim, [PRIM_TEXT, "",textcol,1.0]);
        llSetLinkAlpha(pendingPrim, 0,ALL_SIDES);
        llSetLinkPrimitiveParamsFast(pendingPrim, [PRIM_GLOW,ALL_SIDES,0]);
        llSetLinkTexture(pendingPrim, ptexture,ALL_SIDES);
        llSetLinkTextureAnim(pendingPrim, ANIM_ON|PING_PONG  | LOOP, ALL_SIDES,8,1,0, 7,16);
    }
}

texture()
{
    float x=-0.25;
    float y;
    if (nsources>0) x=0.25;
    if (buttondown=="auto") y=0.375;
    else if (buttondown=="ask") y=0.125;
    else if (buttondown=="restricted") y=-0.125;
    else if (buttondown=="off") y=-0.375;
    llOffsetTexture(x,y,ALL_SIDES);
    if (buttondown=="off") llSetAlpha(0.6,ALL_SIDES);
    else llSetAlpha(1.0,ALL_SIDES);
}

displayNb(integer num)
{
    num=num % 100;
    integer digit1=num/10;

    integer row1=digit1/8;
    integer col1=digit1 % 8;

    float xoffset1=-0.4375+col1*0.125;
    float yoffset1=0.25-row1*0.5;

    integer digit2=num % 10;

    integer row2=digit2/8;
    integer col2=digit2 % 8;

    float xoffset2=-0.4375+col2*0.125;
    float yoffset2=0.25-row2*0.5;

    float alpha10=1.0;
    float alpha1=1.0;
    float ypos=0.0;

    if(num<10)
    {
        if(num==0)
            alpha1=0.0;
        alpha10=0.0;
        vector scale = llList2Vector(llGetLinkPrimitiveParams(sourcesPrim, [PRIM_SIZE]), 0);
        ypos=scale.y/4.0;
    }

    vector pos;
//llList2Vector(llGetLinkPrimitiveParams(sourcesPrim, [PRIM_POSITION]), 0);
    pos.x = 0.;
    pos.y = ypos;
    vector rootscale = llGetScale();
    pos.z = rootscale.z * 0.6;

    llSetLinkPrimitiveParamsFast(sourcesPrim,
        [
            PRIM_POSITION,pos,
            PRIM_TEXTURE,3,tex,<0.125,0.48,0.0>,<xoffset1,yoffset1,0.0>,0.0,
            PRIM_TEXTURE,4,tex,<0.125,0.48,0.0>,<xoffset2,yoffset2,0.0>,0.0,
            PRIM_COLOR,3,<1.0,1.0,1.0>,alpha10,
            PRIM_COLOR,4,<1.0,1.0,1.0>,alpha1
        ]
    );
}


default
{
    state_entry()
    {
        // search nbsources prim
        integer i;
        for (i = 2; i <= llGetNumberOfPrims(); i++)
        {
            if ((string)llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]) == "~pending") pendingPrim =i;
            if ((string)llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]) == "~nbsources") sourcesPrim =i;
        }
        llSetTexture(btexture,ALL_SIDES);
        texture();
        
        displayNb(0);
        setPending(FALSE);
    }
        
    link_message(integer sender_num, integer num, string str, key id )
    {    
        if (num==CMD_STATUS)
        {
            if (str == "pending")
            {
                setPending(TRUE);
            }
            else if (str == "idle")
            {
                setPending(FALSE);
            }
            else
            {
                buttondown=str;
                texture();
            }
            
        }
        else if ((num >= CMD_ADDSRC && num <=CMD_REMALLSRC) || num == CMD_SWD)
        {
            if (num==CMD_ADDSRC)
            {
                nsources++;
            }
            else if (num==CMD_REMSRC)
            {
                nsources--;
            }
            else if (num==CMD_REMALLSRC)
            {
                nsources=0;
            }
            else if (num==CMD_SWD) 
            {
                if (id == NULL_KEY) nsources=0;
            }
            
            texture();
            displayNb(nsources);
        }
    }
        
    touch_start(integer num)
    {
        lasttouch = llGetUnixTime();
    }
    
    touch_end(integer num)
    {
        if (llDetectedLinkNumber(0) == sourcesPrim)
        {
            if (llGetUnixTime() > lasttouch + 3.0) llMessageLinked(LINK_THIS, CMD_REQSAFEWORD, "",  NULL_KEY);
            else llMessageLinked(LINK_THIS, CMD_LISTOBJ, "",  llDetectedKey(0));
        }
        else if (llDetectedLinkNumber(0) == pendingPrim)
        {
            llMessageLinked(LINK_SET, CMD_SHOW_PENDING, "", llDetectedKey(0));
        }
        else
        {
            llMessageLinked(LINK_THIS, CMD_MENU, "",  llDetectedKey(0));
        }
    }
        
   
}
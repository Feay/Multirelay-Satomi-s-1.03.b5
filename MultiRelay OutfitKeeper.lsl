//The purpose of this script is to allow a "foldermode" option to make attaching/detaching cleaner. If the user activates foldermode, they can arrange their worn inventory into subfolders of linked items which will be automatically detached when any part of them is detached. So,

//  v#RLV
//   >##restrains
//   >##outfits
//    vCatsuit
//      vBoots
//          Boot l (worn on left foot)
//          Boot r (worn on right foot)
//          Boot upper l (worn on l lower leg)
//          Boot upper r (worn on r lower leg)
//          Boots (worn)
//      vBodysuit
//          Catsuit shirt (worn)
//          Catsuit pants (worn)
//          Catsuit gloves (worn)
//          Catsuit socks (worn)
//      vCatsuit overjacket (worn)
//          Catsuit Jacket (worn)

// @remove:jacket=force will remove just the jacket. @remove:shoes=force will remove shoes and the boot prims. @remove:pants=force or @remove shirt=force will remove the entire catsuit.                            

//send @addoutfit,@remoutfit,@attach,@detach commands which =force as link message with num=CMD_OUTFITCHANGE.

//script queues these commands, and if foldermode is on, will remove anything in the same folder as whatever is currently at the attach point/clothing point, then wait 0.2 seconds before issuing the command.

//folder mode is switched with "on" or "off" link messages on num=CMD_FOLDERMODE.
 
list attachpoints=["left foot","right foot","l upper leg","l lower leg","r upper leg","r lower leg","chest","spine","pelvis","left pec","right pec","left hip","right hip","left hand","right hand", "l forearm","l upper arm","r forearm","r upper arm", "right shoulder", "left shoulder","skull","mouth","chin","nose","left ear","right ear","left eyeball","right eyeball"];
list clothingpoints=["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt"];


list queue;

string currentcmd;
string currentpoint;


integer CMD_FOLDERMODE=9000;
integer CMD_OUTFITCHANGE=9001;

integer foldermode;

integer responsechannel;

handlequeue()
{
    currentcmd=llList2String(queue,0);
    queue=llDeleteSubList(queue,0,0);
    list t=llParseString2List(currentcmd,[":","="],[]);
    currentpoint=llList2String(t,1); 
    process();
    
}

//dequeue removes of points already removed?
    
process()
{
    if (foldermode) 
    {
      integer z=llListFindList(attachpoints,[currentpoint]);
      z+=llListFindList(clothingpoints,[currentpoint]);
      if (z>-1)
      {
          llOwnerSay("@detachthis:"+currentpoint+"=force");
            llSleep(0.2);
        }
    } 
    llOwnerSay("@"+currentcmd);
    if (llGetListLength(queue)>0) handlequeue();
    else llOwnerSay("@"+currentcmd);
}


default
{
    state_entry()
    {
        
    }
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num==CMD_OUTFITCHANGE)
        {
            queue+=str;
            handlequeue();
        }
        else if (num==CMD_FOLDERMODE)
        {
            if (str=="on")
            {
                llOwnerSay("Switching smart strip on. When items are removed that are in your shared folders, everything in the same folder will also come off.");
                foldermode=TRUE;
            }
            else
            {
                llOwnerSay("Switching SmartStrip off");
                foldermode=FALSE;
            }
        }
    }
   
}

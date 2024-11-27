vector NO_LOC = <-1,-1,-1>;
integer CMD_FOLLOW_SET   = 100;
integer CMD_FOLLOW_CLEAR = 101;
integer CMD_SWD = 5;

key controller = NULL_KEY;
key leash_to = NULL_KEY;
integer target_is_av = FALSE;
integer target_id = 0;
vector last_loc;
float leash_length = 2.0;
float leash_tau    = 1.5;

integer is_agent(key prim_or_av){
    if ((llGetAgentSize(prim_or_av) == ZERO_VECTOR)) {
        return 0;
    }
    else  {
        return 1;
    }
}

clear_target() {
   if (target_id) {
        llTargetRemove(target_id);
//        llOwnerSay("removing: "+(string) target_id);
        target_id = 0;
    }
}

unleash() {
    leash_to = NULL_KEY;
    clear_target();
    llStopMoveToTarget();
}

integer handle_link_message(integer sender_num,integer num,string str,key id)
{
    if (num == CMD_SWD)
    {
        if (id == NULL_KEY || id == controller)
        {
            controller = NULL_KEY;
            unleash();
            return 1;
        }
        else return 0;
    }
    else if (num == CMD_FOLLOW_CLEAR)
    {
        if ( controller == id ) {
            controller = NULL_KEY;
            unleash();
            return 1;
        }
        else {
            return 0;
        }
    }
    else  if (num == CMD_FOLLOW_SET)
    {
        list followArgs = llParseStringKeepNulls(str, ["/"], []);
        key target = id;
        if ( (llGetListLength(followArgs) > 1) && (llList2String(followArgs,1)!="") )
        {
            target = (key)llList2String(followArgs,1);
        }
        
        if ( (llGetListLength(followArgs) > 2) && (llList2String(followArgs,2)!="") )
        {
            leash_length = (float)llList2String(followArgs,2);
        }
        else leash_length = 2;
        if ( (llGetListLength(followArgs) > 3) && (llList2String(followArgs,3)!="") )
        {
            leash_tau = (float)llList2String(followArgs,3);
        }
        else leash_tau = 1.5;
        
        if ( (controller != NULL_KEY) && (controller != id) ) return 0;
        controller = id;
        if ( target != leash_to ) {
            leash_to = target;
            target_is_av = is_agent(target);
            fetch_location();
        }
        else {
            update_target();
        }
        
        if ( in_leash_range() ) {
            return 3;
        }
        else if ( last_loc == NO_LOC ) {
            return 2;
        }
        else {
            return 4;
        }
    }
    return 0;
}

update_target() {
    if ( target_id ) {
        llTargetRemove(target_id);
//        llOwnerSay("removing: "+(string) target_id);
    }
    if ( last_loc != NO_LOC ) {
        target_id = llTarget(last_loc, leash_length);
//        llOwnerSay("setting: "+(string) target_id);
    }
}

integer in_leash_range(){
    if ( last_loc == NO_LOC ) {
        return 0;
    }
    if ((llVecDist(llGetRootPosition(),last_loc) <= leash_length)) {
        return 1;
    }
    else  {
        return 0;
    }
}

handle_changed(integer change){
    if (change & CHANGED_OWNER) {
        llResetScript();
    }
}

set_location(vector location) {
    if ( location == last_loc ) {
        return;
    }
    if ( (location != NO_LOC) && (llVecDist(last_loc,location) <= 0.01) ) {
        return;
    }
    last_loc = location;
    if ( last_loc == NO_LOC ) {
        clear_target();
    }
    else {
        update_target();
    }
}


fetch_location() {
    list details = llGetObjectDetails(leash_to, [OBJECT_POS]);
    if ( llGetListLength(details) != -1 ) {
        set_location( llList2Vector(details,0) );
    }
    else {
        set_location( NO_LOC );
    }
}


default {
    state_entry() {
        llSetMemoryLimit(2048);
//        llOwnerSay("default state");
        clear_target();
        llSetTimerEvent(0);
        llStopMoveToTarget();
    }
    link_message(integer sender_num, integer num, string str, key id) {
        integer lm_act = handle_link_message(sender_num,num,str,id);
        if (lm_act == 2)      { state find_target;  }
        else if (lm_act == 3) { state idle;         }
        else if (lm_act == 4) { state out_of_range; }
       }
    changed(integer change) {
        handle_changed(change);
    }
}

state find_target {
    state_entry() {
        llSetMemoryLimit(2048);
//        llOwnerSay("finding target");
        llSetTimerEvent(5.0);
    }
    link_message(integer sender_num, integer num, string str, key id) {
        integer lm_act = handle_link_message(sender_num,num,str,id);
        if (lm_act == 1)      { state default;      }
        else if (lm_act == 3) { state idle;         }
        else if (lm_act == 4) { state out_of_range; }
   }
   timer() {
       fetch_location();
        if ( in_leash_range() ) {
            state idle;
        }
        else {
            state out_of_range;
        }
    }
    changed(integer change) {
        handle_changed(change);
    }
}

state idle {
    state_entry() {
//        llOwnerSay("idling");
        llSetTimerEvent(0.5);
    }
    timer() {
        fetch_location();
        if ( last_loc == NO_LOC ) {
            state find_target;
        }
        else if ( ! in_leash_range() ) {
            state out_of_range;
        }
    }
    not_at_target() {
        state out_of_range;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        integer lm_act = handle_link_message(sender_num,num,str,id);
        if (lm_act == 1)      { state default;      }
        else if (lm_act == 2) { state find_target;  }
        else if (lm_act == 4) { state out_of_range; }
       }
    changed(integer change) {
        handle_changed(change);
    }
                
}

state out_of_range {
    state_entry() {
//        llOwnerSay("not at target");
        llSetTimerEvent(0.3);
        llMoveToTarget(last_loc,leash_tau);
    }
    timer() {
        fetch_location();
        if ( in_leash_range() ) {
            llStopMoveToTarget();
            llReleaseControls();
            state idle;
        }
        else {
            llMoveToTarget(last_loc,leash_tau);
        }
    }
    at_target(integer tnum,vector targetPos,vector ourpos) {
        llStopMoveToTarget();
        state idle;
    }
    link_message(integer sender_num, integer num, string str, key id) {
        integer lm_act = handle_link_message(sender_num,num,str,id);
        if (lm_act == 1)      { llStopMoveToTarget(); state default;      }
        else if (lm_act == 2) { state find_target;  }
        else if (lm_act == 3) { state idle;         }
        else if (lm_act == 4) { llMoveToTarget(last_loc,leash_tau); }
       }
    changed(integer change) {
        handle_changed(change);
    }
}

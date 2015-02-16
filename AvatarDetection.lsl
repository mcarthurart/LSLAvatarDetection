list keys;
list times;
key key_owner;
integer num_avatar;
integer listen_handle;
integer num_channel = 3;
integer say_on = 1;
integer detection_distance = 20;

announceChange(key id, string action) {
    if (say_on == 1) {
        if (llGetDisplayName(id) == "") {
            llOwnerSay("secondlife:///app/agent/" + (string)id + "/about " + action);
        } else {
            llOwnerSay("(" + llGetDisplayName(id) + ") " + llKey2Name(id) + " " + action);
        }
    }
}

float getTime(integer i) {
    float list_time = llList2Float(times, i);
    if (i < 0 || list_time == 0.0) {
        return llGetTime();
    }
    return list_time;
}

default {
    state_entry() {
        keys = [];
        times = [];
        num_avatar = 0;
        key_owner = llGetOwner();
        listen_handle = llListen(num_channel, "", llGetOwner(), "");
        llSetTimerEvent(1.0);
    }
    
    timer() {
        list keys_detected = llGetAgentList(AGENT_LIST_PARCEL, []);
        list keys_filtered;
        list new_keys;
        list new_times;
        key key_avatar;
        vector pos_owner = llGetPos();
        integer num_detected = llGetListLength(keys_detected);
        integer num_filtered;
        integer avatar_index;
        integer i;
        for (i = 0; i < num_detected; ++i) {
            key_avatar = llList2Key(keys_detected, i);
            if ((llVecDist(pos_owner, llList2Vector(llGetObjectDetails(key_avatar, [OBJECT_POS]), 0)) <= detection_distance)
                && (key_avatar != key_owner)) {
                    keys_filtered += key_avatar;
            }
        }
        num_filtered = llGetListLength(keys_filtered);
        if (num_filtered != num_avatar) {
            if (num_filtered > num_avatar) {
                new_keys = keys;
                for (i = 0; i < num_filtered; ++i) {
                    key_avatar = llList2Key(keys_filtered, i);
                    avatar_index = llListFindList(keys, (list)key_avatar);
                    if (avatar_index < 0) {
                        new_keys += key_avatar;
                        announceChange(key_avatar, "entered chat distance");
                    }
                    new_times += getTime(avatar_index);
                }
            } else {
                for (i = 0; i < num_avatar; ++i) {
                    key_avatar = llList2Key(keys, i);
                    if (llListFindList(keys_filtered, (list)key_avatar) < 0) {
                        announceChange(key_avatar, "left chat distance");
                    } else {
                        new_keys += key_avatar;
                    }
                    new_times += getTime(i);
                }
            }
            keys = new_keys;
            times = new_times;
            num_avatar = num_filtered;
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (message == "list") {
            integer i = num_avatar;
            if (i == 0) {
                if (say_on = 1) {
                    llOwnerSay("No avatars nearby.");
                }
            } else {
                if (say_on = 1) {
                    llOwnerSay("Listing nearby avatars:");
                }
                float currentTime = llGetTime();
                for (i = 0; i < num_avatar; ++i) {
                    integer difference = llRound(currentTime - llList2Float(times, i));
                    string hours = (string)llRound(difference / 3600);
                    string minutes = (string)llRound((difference % 3600) / 60);
                    string seconds = (string)llRound((difference % 3600) % 60);
                    string time;
                
                    if (llStringLength(minutes) == 1) {
                        minutes = "0" + minutes;
                    }
                    if (llStringLength(seconds) == 1) {
                        seconds = "0" + seconds;
                    }
                    time = hours + ":" + minutes + ":" + seconds;
                
                    announceChange(llList2Key(keys, i), "seen for " + time);
                }
            }
            return;
        }
        
        if (message == "reset") {
            llResetScript();
        }
        if (message == "off") {
            say_on = 0;
            llOwnerSay("Muted.");
        }
        if (message == "on") {
            say_on = 1;
            llOwnerSay("Unmuted.");
        }
    }
    
    changed(integer change) {
        if (change & CHANGED_REGION) {
            llOwnerSay("Region Changed");
        }
    }
}

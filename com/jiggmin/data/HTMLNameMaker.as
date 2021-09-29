// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.HTMLNameMaker = data.class_145

package com.jiggmin.data
{
    import flash.events.TextEvent;
    import package_4.DiscordVerificationPopup;
    import package_4.PlayerPopup;
    import package_4.PlayerGuestPopup;
    import package_4.GuildPopup;
    import package_4.GuildJoinPopup;
    import package_4.LevelInfoPopup;
    import package_4.ExternalLinkPopup;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;

    public class HTMLNameMaker 
    {

        private var array:Array = new Array(); // var_282

        public function HTMLNameMaker()
        {
        }

        public function makeName(name:String, group:String, dispText:String = ""):String
        {
            var groupColor:String;
            if (group == 1) {
                groupColor = "#047B7B";
            } else if (group == 2) {
                groupColor = "#1C369F";
            } else if (group.indexOf(',') != -1) {
                var mod_vars:Array = group.split(',');
                if (mod_vars[1] == 0) { // temp
                    groupColor = '#006400';
                } else if (mod_vars[1] == 1) { // trial
                    groupColor = '#0092FF';
                } else if (mod_vars[0] == 2) { // handle perma exception
                    groupColor = '#1C369F';
                }
            } else if (group == 3) {
                groupColor = "#870A6F";
            } else {
                groupColor = "#676666";
            }
            if (name.toLowerCase() == 'dev52' && Main.loggedInAs.toLowerCase() == 'dev52') {
                groupColor = '#CC99FF';
            }
            if (name.toLowerCase() == 'wolfie' && Main.loggedInAs.toLowerCase() == 'wolfie') {
                groupColor = '#000000';
            }
            if (name.toLowerCase() == "fred the g. cactus") {
                groupColor = "#83C141";
            }
            if (dispText == "") {
                dispText = name;
            }
            name = Data.cleanHTML(name);
            dispText = Data.cleanHTML(dispText);
            return '<u><font color="' + groupColor + '"><a href="event:user`' + group + "`" + name + '">' + dispText + "</a></font></u>";
        }

        public function makeGuild(name:String, id:int):String
        {
            name = Data.escapeString(name);
            return '<u><font color="#0000FF"><a href="event:guild`' + id + '">' + name + "</a></font></u>";
        }

        public function makeLevel(name:String, id:int):String
        {
            name = Data.escapeString(name);
            return '<u><font color="#0000FF"><a href="event:level`' + id + '">' + name + "</a></font></u>";
        }

        public function makeLink(disp:String, url:String):String
        {
            disp = Data.escapeString(disp);
            url = encodeURI(Data.escapeString(url));
            return '<u><font color="#0000FF"><a href="event:url`' + url + '">' + disp + "</a></font></u>";
        }

        public function listenForLink(textbox:*)
        {
            this.array.push(textbox);
            textbox.addEventListener(TextEvent.LINK, this.clickLink, false, 0, true);
        }

        // _loc2 = arr
        // _loc3 = mode
        // _loc4 = group
        // _loc5 = userName
        // _loc6/_loc7 = guildId
        // method_237 = clickLink
        private function clickLink(e:TextEvent)
        {
            var guildId:int;
            var arr:Array = e.text.split("`");
            var mode:String = arr[0];
            if (mode == "user") {
                var group:String = arr[1];
                var userName:String = arr[2];
                var forcePlayer:Boolean = Boolean(int(arr[3]));
                if (group.indexOf(',') != -1) {
                    var mod_power:* = group.split(',');
                    group = int(mod_power[0]);
                }
                if (group > 0 || forcePlayer) {
                    new PlayerPopup(userName);
                } else {
                    new PlayerGuestPopup(userName);
                }
            } else if (mode == "guild") {
                guildId = arr[1];
                new GuildPopup(guildId);
            } else if (mode == "invite") {
                guildId = arr[1];
                new GuildJoinPopup(guildId);
            } else if (mode == "level") {
                var levelId:int = arr[1];
                new LevelInfoPopup(levelId);
            } else if (mode == "url") {
                var url:String = arr[1];
                new ExternalLinkPopup(url);
            } else if (mode == 'discordverify') {
                var code:String = arr[1];
                new DiscordVerificationPopup(code);
            }
        }

        // _loc1 = i
        // _loc2 = arrayLength
        // _loc3 = link
        public function remove()
        {
            var arrayLength:int = this.array.length;
            var i:int = 0;
            while (i < arrayLength) {
                var link:* = this.array[i];
                if (link != null) {
                    link.removeEventListener(TextEvent.LINK, this.clickLink);
                    link = null;
                }
                i++;
            }
            this.array = null;
        }


    }
}//package com.jiggmin.data


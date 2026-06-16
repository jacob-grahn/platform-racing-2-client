// data.HTMLNameMaker = data.class_145

package com.jiggmin.data
{
    import flash.events.TextEvent;
    import dialogs.DiscordVerificationPopup;
    import dialogs.PlayerPopup;
    import dialogs.PlayerGuestPopup;
    import dialogs.GuildPopup;
    import dialogs.GuildJoinPopup;
    import dialogs.LevelInfoPopup;
    import dialogs.ExternalLinkPopup;
    import flash.net.URLRequest;

    public class HTMLNameMaker 
    {

        private var array:Array = new Array();

        public function HTMLNameMaker()
        {
        }

        // group codes as of v160
        // guest: 0
        // member: 1 and 1,0 = regular | 1,1 = ca
        // mod: 2 = full | 2,0 = temp | 2,1 = trial
        // admin: 3
        // special: any,*
        public function makeName(name:String, group_str:String, dispText:String = ""):String
        {
            var vars:Array = group_str.split(',');
            var group:int = int(vars[0]);
            var group2:String = !vars[1] ? null : vars[1];

            var groupColor:String;
            if (group === 1) { // members
                if (group2 == 1) {
                    groupColor = 'BC9055'; // community ambassador
                } else {
                    groupColor = '047B7B'; // regular member
                }
            } else if (group === 2) { // moderators
                if (group2 == 0) {
                    groupColor = '006400'; // temp
                } else if (group2 == 1) {
                    groupColor = '0092FF'; // trial
                } else {
                    groupColor = '1C369F'; // perma
                }
            } else if (group === 3) {
                groupColor = "870A6F"; // admins and server owners
            } else {
                groupColor = "676666"; // guests
            }
            if (group2 === '*') {
                groupColor = '83C141'; // special users
            }
            /*if (name.toLowerCase() == 'dev52' && Main.loggedInAs.toLowerCase() == 'dev52') {
                groupColor = '#CC99FF';
            }
            if (name.toLowerCase() == 'wolfie' && Main.loggedInAs.toLowerCase() == 'wolfie') {
                groupColor = '#000000';
            }*/
            /*if (name.toLowerCase() == "fred the g. cactus") {
                groupColor = "#83C141";
            }*/
            if (dispText == "") {
                dispText = name;
            }
            name = Data.cleanHTML(name);
            dispText = Data.cleanHTML(dispText);
            return '<u><font color="#' + groupColor + '"><a href="event:user`' + group + "`" + name + '">' + dispText + "</a></font></u>";
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


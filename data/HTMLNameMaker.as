// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.HTMLNameMaker = data.class_145

package data
{
    import flash.events.TextEvent;
    import package_4.PlayerPopup;
    import package_4.PlayerGuestPopup;
    import package_4.GuildPopup;
    import package_4.GuildJoinPopup;

    public class HTMLNameMaker 
    {

        private var array:Array = new Array(); // var_282

        public function HTMLNameMaker()
        {
        }

        public function makeName(name:String, group:int, dispText:String = ""):String
        {
            var groupColor:String;
            switch (group) {
                case 1:
                    groupColor = "#047B7B";
                    break;
                case 2:
                    groupColor = "#1C369F";
                    break;
                case 3:
                    groupColor = "#870A6F";
                    break;
                default:
                    groupColor = "#676666";
                    break;
            }
            if (name.toLowerCase() == 'dev52' && Main.loggedInAs.toLowerCase() == 'dev52') {
                groupColor = '#FF9900';
            }
            if (name.toLowerCase() == 'wolfie' && Main.loggedInAs.toLowerCase() == 'wolfie') {
                groupColor = '#000000';
            }
            /*if (name.toLowerCase() == "fred the g. cactus") { // could be a future addition...
                groupColor = "#83C141";
            }*/
            if (dispText == "") {
                dispText = name;
            }
            name = class_28.escapeString(name);
            dispText = class_28.escapeString(dispText);
            return '<u><font color="' + groupColor + '"><a href="event:user`' + group + "`" + name + '">' + dispText + "</a></font></u>";
        }

        public function makeGuild(name:String, id:int):String
        {
            name = class_28.escapeString(name);
            return '<u><font color="#0000FF"><a href="event:guild`' + id + '">' + name + "</a></font></u>";
        }

        public function listenForLink(e:*)
        {
            this.array.push(e);
            e.addEventListener(TextEvent.LINK, this.clickLink, false, 0, true);
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
                var group:int = arr[1];
                var userName:String = arr[2];
                if (group > 0) {
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
}//package data


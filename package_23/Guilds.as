// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_23.Guilds

package package_23
{
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.events.Event;

    public class Guilds extends PlayersTabListHolder 
    {

        private var m:PlayersTabListGraphic = new PlayersTabListGraphic();
        private var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var sortMode:String = "gpToday"; // var_229

        public function Guilds()
        {
            super(this.m.listHolder);
            this.m.gotoAndStop("guilds");
            addChild(this.m);
            this.m.name_bt.addEventListener(MouseEvent.CLICK, this.clickNameButton, false, 0, true);
            this.m.active_bt.addEventListener(MouseEvent.CLICK, this.clickActiveButton, false, 0, true);
            this.m.gp_bt.addEventListener(MouseEvent.CLICK, this.clickGPButton, false, 0, true);
            this.load();
        }

        // method_276 = clickNameButton
        private function clickNameButton(e:MouseEvent)
        {
            this.sortMode = "guildName";
            this.sortGuildsBy();
        }

        // method_366 = clickActiveButton
        private function clickActiveButton(e:MouseEvent)
        {
            this.sortMode = "activeMembers";
            this.sortGuildsBy();
        }

        // method_408 = clickGPButton
        private function clickGPButton(e:MouseEvent)
        {
            this.sortMode = "gpToday";
            this.sortGuildsBy();
        }

        // method_110 = sortGuildsBy
        private function sortGuildsBy()
        {
            if (this.sortMode == "guildName") {
                super.sortOn(this.sortMode);
            } else {
                super.sortOn(this.sortMode, (Array.NUMERIC | Array.DESCENDING));
            }
        }

        private function load()
        {
            var request:URLRequest = new URLRequest(Main.baseURL + "/guilds_top.php");
            this.superLoader.addEventListener(SuperLoader.d, this.populateList, false, 0, true);
            this.superLoader.addEventListener(SuperLoader.e, hideLoadingGraphic, false, 0, true);
            this.superLoader.load(request);
            this.sortGuildsBy();
        }

        // _loc2 = guild
        // _loc3 = guildListItem
        // method_228 = populateList
        private function populateList(e:Event)
        {
            var guild:Object;
            var guildListItem:PlayersTabGuildListItem;
            for each (guild in this.superLoader.parsedData.guilds) {
                guildListItem = new PlayersTabGuildListItem(guild.guild_name, guild.guild_id, guild.active_count, guild.gp_today);
                method_179(guildListItem);
            }
            hideLoadingGraphic();
        }

        override public function remove()
        {
            this.superLoader.removeEventListener(SuperLoader.d, this.populateList);
            this.m.name_bt.removeEventListener(MouseEvent.CLICK, this.clickNameButton);
            this.m.active_bt.removeEventListener(MouseEvent.CLICK, this.clickActiveButton);
            this.m.gp_bt.removeEventListener(MouseEvent.CLICK, this.clickGPButton);
            super.remove();
        }


    }
}//package package_23


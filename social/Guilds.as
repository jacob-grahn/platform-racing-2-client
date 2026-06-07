// Decompiled by AS3 Sorcerer 5.98


package social
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
        private var sortOrder:String = 'desc';

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
            this.sortGuildsBy('guildName');
        }

        // method_366 = clickActiveButton
        private function clickActiveButton(e:MouseEvent)
        {
            this.sortGuildsBy('activeMembers');
        }

        // method_408 = clickGPButton
        private function clickGPButton(e:MouseEvent)
        {
            this.sortGuildsBy('gpToday');
        }

        // method_110 = sortGuildsBy
        private function sortGuildsBy(newSort:String = null)
        {
            var sort1:String, sort2:String;
            if (newSort != this.sortMode || newSort == null) {
                this.sortMode = newSort != null ? newSort : this.sortMode;
                if (this.sortMode == 'guildName') {
                    this.sortOrder = 'asc';
                    super.sortOn(this.sortMode, Array.CASEINSENSITIVE);
                } else {
                    this.sortOrder = 'desc';
                    sort1 = this.sortMode;
                    sort2 = this.sortMode == 'gpToday' ? 'activeMembers' : 'gpToday';
                    super.numSort([sort1, sort2], this.sortOrder);
                }
            } else if (newSort == this.sortMode) {
                // toggle sort order
                this.sortOrder = this.sortOrder == 'desc' ? 'asc' : 'desc';

                // do the sort
                if (this.sortMode == 'guildName') {
                    var opts:uint = this.sortOrder == 'desc' ? 3 : 1;
                    super.sortOn(this.sortMode, opts);
                } else {
                    sort1 = this.sortMode;
                    sort2 = this.sortMode == 'gpToday' ? 'activeMembers' : 'gpToday';
                    super.numSort([sort1, sort2], this.sortOrder);
                }
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
                addListing(guildListItem);
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
}


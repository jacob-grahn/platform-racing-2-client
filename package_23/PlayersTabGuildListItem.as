// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTabGuildListItem = package_23.class_308

package package_23
{
    import data.class_28;

    public class PlayersTabGuildListItem extends PlayersTabListItem
    {

        public var guildName:String;
        public var activeMembers:int;
        public var gpToday:int;

        public function PlayersTabGuildListItem(name:String, guildId:int, activeCount:int, gpTodayCount:int)
        {
            this.guildName = name;
            this.activeMembers = activeCount;
            this.gpToday = gpTodayCount;
            m.nameBox.htmlText = htmlNameMaker.makeGuild(this.guildName, guildId);
            m.rankBox.text = class_28.formatNumber(this.gpToday);
            m.hatBox.text = this.activeMembers.toString();
        }

    }
}//package package_23


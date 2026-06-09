// Decompiled by AS3 Sorcerer 5.98


package social
{
    import com.jiggmin.data.Data;

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
            m.rankBox.text = Data.formatNumber(this.gpToday);
            m.hatBox.text = this.activeMembers.toString();
        }

    }
}


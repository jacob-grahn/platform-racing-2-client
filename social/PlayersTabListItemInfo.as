// Decompiled by AS3 Sorcerer 5.98


package social
{
    public class PlayersTabListItemInfo extends PlayersTabListItem 
    {

        public var userName:String;
        public var rank:int;
        public var hats:int;

        public function PlayersTabListItemInfo(name:String, group:String, rankNum:int, hatCount:int, server:String)
        {
            var nameLink:String;
            super();
            if (server != "") {
                nameLink = htmlNameMaker.makeName(name, group, name + " (" + server + ")");
            } else {
                nameLink = htmlNameMaker.makeName(name, group);
            }
            m.nameBox.htmlText = nameLink;
            m.rankBox.text = rankNum.toString();
            m.hatBox.text = hatCount.toString();
            this.userName = name;
            this.rank = rankNum;
            this.hats = hatCount;
        }

    }
}

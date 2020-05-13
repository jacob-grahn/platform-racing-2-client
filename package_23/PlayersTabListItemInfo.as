// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_23.PlayersTabListItemInfo = package_23.class_310

package package_23
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

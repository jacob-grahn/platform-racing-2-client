// ArtifactHint = class_147

package page
{
    import com.jiggmin.data.Data;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class ArtifactHint 
    {

        private var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j); // var_123
        private var chatRoom:Chat; // target

        public function ArtifactHint(room:Chat)
        {
            this.chatRoom = room;
            this.superLoader.addEventListener(SuperLoader.d, this.parseHint);
        }

        public function load()
        {
            this.superLoader.load(new URLRequest(Main.baseURL + "/files/artifact_hint.txt"));
        }

        // method_228 = parseHint
        // _loc2 = ret
        private function parseHint(e:Event)
        {
            var ret:Object = this.superLoader.parsedData;
            var hintMsg:String = "Here\'s what I remember: " + ret.hint + ". Maybe I can remember more later!!";
            if (ret.level_id != null) {
                var level:Array = [Data.escapeString(ret.level_title), ret.level_id];
                var user:Array = [Data.escapeString(ret.creator_name), ret.creator_group];
                hintMsg = 'Thanks for helping me find the artifact! It\'s located at ' + this.chatRoom.makeLink('Level', level) + ' by ' + this.chatRoom.makeLink('Name', user) + '.';
            }
            this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", 3, hintMsg], true);
            if (ret.finder_name != "") {
                var foundMsg:String = "The first person to find this artifact was " + Data.escapeString(ret.finder_name) + "!";
                this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", 3, foundMsg], true);
                var bubMsg:String = "";
                if (ret.bubbles_name == "") {
                    bubMsg = "The bubble set will be awarded to the first person to find the artifact that doesn\'t have the set already!";
                } else if (ret.bubbles_name != "" && ret.finder_name != ret.bubbles_name) {
                    bubMsg = "Since they already have the bubble set, the prize was awarded to " + Data.escapeString(ret.bubbles_name) + " instead!";
                }
                if (bubMsg != "") {
                    this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", 3, bubMsg], true);
                }
            }
        }

        public function remove()
        {
            this.superLoader.removeEventListener(SuperLoader.d, this.parseHint);
            this.superLoader.remove();
            this.superLoader = null;
            this.chatRoom = null;
        }


    }
}

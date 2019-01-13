// ArtifactHint = class_147

package page
{
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
            this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", 3, "Here\'s what I remember: " + ret.hint + ". Maybe I can remember more later!!"]);
            if (ret.finder_name != "") {
                this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", 3, "The first person to find this artifact was " + ret.finder_name + "!!"]);
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

// ArtifactHint = class_147

package page
{
    import com.jiggmin.data.Data;
    import flash.net.URLRequest;
    import flash.events.Event;

    public class ArtifactHint 
    {

        private var superLoader:SuperLoader = new SuperLoader(true, SuperLoader.j);
        private var chatRoom:Chat; // target

        public function ArtifactHint(room:Chat)
        {
            this.chatRoom = room;
            this.superLoader.addEventListener(SuperLoader.d, this.parseHint);
        }

        public function load()
        {
            this.superLoader.load(new URLRequest(Main.baseURL + '/files/level_of_the_week.json'));
        }

        private function parseHint(e:Event)
        {
            var ret:Object = this.superLoader.parsedData;
            if (!ret.hasOwnProperty('current')) {
                return;
            }
            var cur:Object = ret.current;
            var level:Array = [cur.level.title, cur.level.id];
            var user:Array = [cur.level.author.name, cur.level.author.group];
            var hintMsg:String = 'The current level of the week is ' + this.chatRoom.makeLink('Level', level) + ' by ' + this.chatRoom.makeLink('Name', user) + '.' + (!cur.hasOwnProperty('first_finder') ? ' See if you can find the hidden artifact!' : '');
            this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", '3,*', hintMsg], true);
            if (cur.hasOwnProperty('first_finder')) {
                var finderName:Array = [cur.first_finder.name, cur.first_finder.group];
                var foundMsg:String = "The first person to find the hidden artifact was " + this.chatRoom.makeLink('Name', finderName) + "!";
                this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", '3,*', foundMsg], true);
                var bubMsg:String = "";
                if (cur.hasOwnProperty('bubbles_winner') && cur.bubbles_winner.group == 0) {
                    bubMsg = "The bubble set will be awarded to the first person to find the artifact that doesn\'t have the set already!";
                } else if (cur.hasOwnProperty('bubbles_winner') && cur.first_finder.name != cur.bubbles_winner.name) {
                    var bubName:Array = [cur.bubbles_winner.name, cur.bubbles_winner.group];
                    bubMsg = "Since they already have the bubble set, the prize was awarded to " + this.chatRoom.makeLink('Name', bubName) + " instead!";
                }
                if (bubMsg != "") {
                    this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", '3,*', bubMsg], true);
                }
            }
            if (ret.hasOwnProperty('scheduled')) {
                var sched:Object = ret.scheduled;
                level = [sched.level.title, sched.level.id];
                user = [sched.level.author.name, sched.level.author.group];
                hintMsg = 'The next level of the week will be ' + this.chatRoom.makeLink('Level', level) + ' by ' + this.chatRoom.makeLink('Name', user) + ', which will take effect on ' + Data.getDateTimeStr(sched.set_time, ['long', 'short']) + '.';
                this.chatRoom.handleMessageFromArray(["Fred the G. Cactus", '3,*', hintMsg], true);
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

// ui.GameSound = ui.class_139

package ui
{
    import fl.controls.ComboBox;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.events.Event;
    import flash.utils.setInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import flash.net.URLRequest;
    import flash.media.SoundLoaderContext;
    import flash.media.Sound;
    import flash.utils.clearInterval;

    public class GameSound extends ComboBox 
    {

        private var soundChannel:SoundChannel; // var_218
        private var inLE:Boolean;
        private var enableMusicInt:uint; // var_531
        //private var var_470:uint;
        private var url:String = Main.baseURL + "/music/56";

        public function GameSound(LE:Boolean = false)
        {
            editable = false;
            this.inLE = LE;
            width = 200;
            rowCount = 4;
            addItem({"id":"0", "label":"None", "file":""});
            if (this.inLE) {
                addItem({"id":"random", "label":"Random", "file":""});
            }
            addItem({"id":"1", "label":"Miniature Fantasy - Dreamscaper", "file":"6698_newgrounds_miniat.mp3"});
            addItem({"id":"2", "label":"Under Fire - AP", "file":"105435_under_fire.mp3"});
            addItem({"id":"3", "label":"Paradise on E - API", "file":"32772_newgrounds_-api-_.mp3"});
            addItem({"id":"4", "label":"Crying Soul - Bounc3", "file":"102483_B0UNC3___Crying_Soul__Frui.mp3"});
            addItem({"id":"5", "label":"My Vision - MrMaestro", "file":"44613_newgrounds_my_vis.mp3"});
            addItem({"id":"6", "label":"Switchblade - SKAzini", "file":"59342_newgrounds_01_swi.mp3"});
            addItem({"id":"7", "label":"The Wires - Cheez-R-Us", "file":"74690_newgrounds_the_wi.mp3"});
            addItem({"id":"8", "label":"Before Mydnite - F-777", "file":"108133_Before_Mydnite.mp3"});
            addItem({"id":"10", "label":"Broked It - SWiTCH", "file":"51265_newgrounds_broked.mp3"});
            addItem({"id":"11", "label":"Hello? - TMM43", "file":"83720_newgrounds_hello.mp3"});
            addItem({"id":"12", "label":"Pyrokinesis - Sean Tucker", "file":"98624_Pyrokinesis.mp3"});
            addItem({"id":"13", "label":"Flowerz 'n' Herbz - Brunzolaitis", "file":"109884_Brunzolaitis___Flowerz_n_H.mp3"});
            addItem({"id":"14", "label":"Instrumental #4 - Reasoner", "file":"128701_Instrumental__4.mp3"});
            addItem({"id":"15", "label":"Prismatic - Lunanova", "file":"Prismatic.mp3"});
            addEventListener(Event.CLOSE, this.focusStage, false, 0, true);
            addEventListener(Event.CHANGE, this.startSong, false, 0, true);
            this.enableMusicInt = setInterval(this.checkSetting, 500);
        }

        private function focusStage(e:Event = null)
        {
            Main.stage.focus = Main.stage;
        }

        // method_629 = gotArtifact
        public function gotArtifact()
        {
            addItem({"id":"16", "label":"We Are Loud - Dynamedion", "file":"we-are-loud.mp3"});
            this.setSong("16");
        }

        // method_759 = checkSetting
        private function checkSetting()
        {
            if (this.musicEnabled()) {
                this.startSong();
            }
        }

        // method_211 = musicEnabled
        private function musicEnabled():Boolean
        {
            if (Main.musicLevel > 0 && MuteButton.muted == false && selectedItem != null && selectedItem.id != 0 && this.soundChannel == null) {
                return true;
            }
            return false;
        }

        /*public function method_851(s:String)
        {
        }*/

        // _loc2 = item
        // _loc3 = i
        public function setSong(s:String)
        {
            if ((s == "random" || s == "") && !this.inLE) {
                selectedIndex = Math.floor(Math.random() * (length - 1)) + 1;
            } else {
                var i:int = 0;
                while (i < length) {
                    var item:Object = getItemAt(i);
                    if (item.id == s) {
                        selectedIndex = i;
                        break;
                    }
                    i++;
                }
            }
            if (s != "0" && s != "random" && s != "") {
                this.startSong();
            }
        }

        // depreciated; using startSong for event listeners instead
        /*private function method_307(e:Event)
        {
            clearTimeout(this.var_470);
            this.var_470 = setTimeout(this.startSong, 25);
        }*/

        // _loc1 = fileUrl
        // _loc2 = request
        // _loc3 = slc
        // _loc4 = song
        // method_89 = startSong
        private function startSong(e:Event = null)
        {
            this.stopSong();
            if (this.musicEnabled()) {
                var fileUrl:String = this.url + "/" + selectedItem.file;
                var request:URLRequest = new URLRequest(fileUrl);
                var slc:SoundLoaderContext = new SoundLoaderContext(3000, false);
                var song:Sound = new Sound(request, slc);
                var st:SoundTransform = new SoundTransform();
                st.volume = Main.musicLevel / 100;
                this.soundChannel = song.play(0, 9999, st);
                this.soundChannel.addEventListener(Event.SOUND_COMPLETE, this.loopSong, false, 0, true);
            }
            Main.stage.focus = Main.stage;
        }

        // method_293 = loopSong
        private function loopSong(e:Event)
        {
            this.soundChannel.removeEventListener(Event.SOUND_COMPLETE, this.loopSong);
            this.startSong();
        }

        // method_461 = stopSong
        private function stopSong()
        {
            if (this.soundChannel != null) {
                this.soundChannel.removeEventListener(Event.SOUND_COMPLETE, this.loopSong);
                this.soundChannel.stop();
                this.soundChannel = null;
            }
        }

        public function remove()
        {
            close();
            clearInterval(this.enableMusicInt);
            removeEventListener(Event.CHANGE, this.startSong);
            this.stopSong();
            //clearTimeout(this.var_470);
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}

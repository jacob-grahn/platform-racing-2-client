// ui.GameSound = ui.class_139

package ui
{
    import com.jiggmin.data.Settings;
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
        private var url:String = Main.baseURL + "/music/new";

        public function GameSound(LE:Boolean = false)
        {
            editable = false;
            this.inLE = LE;
            width = 200;
            rowCount = 4;
            addSong({"id":"0", "label":"None", "file":""});
            if (this.inLE) {
                addSong({"id":"random", "label":"Random", "file":""});
            }
            addSong({"id":"1", "label":"Orbital Trance - Space Planet", "file":"01_orbital-trance.mp3"});
            addSong({"id":"2", "label":"Code - Stefano Maccarelli", "file":"02_code.mp3"});
            addSong({"id":"3", "label":"Paradise on E - API", "file":"03_paradise-on-e_ng32772.mp3"});
            addSong({"id":"4", "label":"Crying Soul (FL Mix) - Pyroific", "file":"04_crying-soul_ng102483.mp3"});
            addSong({"id":"5", "label":"My Vision - David Orr", "file":"05_my-vision_ng44613.mp3"});
            addSong({"id":"6", "label":"Switchblade - Detective Jabsco", "file":"06_switchblade_ng59342.mp3"});
            addSong({"id":"7", "label":"The Wires - Cheez-R-Us", "file":"07_the-wires_ng74690.mp3"});
            addSong({"id":"8", "label":"Before Mydnite - F-777", "file":"08_before-mydnite_ng108133.mp3"});
            // desert rose (REMOVED)
            addSong({"id":"10", "label":"Broked It - SWiTCH", "file":"10_broked-it_ng51265.mp3"});
            addSong({"id":"11", "label":"Hello? - TMM43", "file":"11_hello_ng83720.mp3"});
            addSong({"id":"12", "label":"Pyrokinesis - Sean Tucker", "file":"12_pyrokinesis_ng98624.mp3"});
            addSong({"id":"13", "label":"Flowerz 'n' Herbz - Brunzolaitis", "file":"13_flowerz-n-herbs_ng109884.mp3"});
            addSong({"id":"14", "label":"Instrumental #4 - Reasoner", "file":"14_instrumental-4_ng128701.mp3"});
            addSong({"id":"15", "label":"Prismatic - Lunanova", "file":"15_prismatic.mp3"});
            addSong({"id":"17", "label":"Toodaloo - mustangman", "file":"17_toodaloo.mp3"});
            addSong({"id":"18", "label":"Night Shade - Goliathe", "file":"18_night-shade.mp3"});
            addSong({"id":"19", "label":"Blizzard! - Majicke", "file":"19_blizzard.mp3"});
            addSong({"id":"20", "label":"Pasture (Instrumental) - Dangevin", "file":"20_pasture.mp3"});
            addSong({"id":"21", "label":"Sunset Raiders - AVL", "file":"21_sunset-raiders.mp3"});
            addEventListener(Event.CLOSE, this.focusStage, false, 0, true);
            addEventListener(Event.CHANGE, this.startSong, false, 0, true);
            this.enableMusicInt = setInterval(this.checkSetting, 500);
        }

        private function addSong(song:Object)
        {
            var blacklist:Array = Settings.getValue(Settings.DISABLED_SONGS);
            if (this.inLE == false && song.id != 16 && song.id <= 21 && song.id != 'random' && song.id != 0 && song.id != '') {
                for (var i in blacklist) {
                    if (blacklist[i] == song.id) {
                        return;
                    }
                }
            }
            addItem(song);
        }

        private function focusStage(e:Event = null)
        {
            Main.stage.focus = Main.stage;
        }

        // method_629 = gotArtifact
        public function gotArtifact()
        {
            addSong({"id":"16", "label":"We Are Loud - Dynamedion", "file":"16_we-are-loud.mp3"});
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
            if (Settings.musicLevel > 0 && MuteButton.muted == false && selectedItem != null && selectedItem.id != 0 && this.soundChannel == null) {
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
            var selectId:int = 0;
            if ((s == "random" || s == "") && !this.inLE) {
                selectId = Math.floor(Math.random() * (length - 1)) + 1;
            } else {
                var i:int = 0;
                while (i < length) {
                    var item:Object = getItemAt(i);
                    if (item.id == s) {
                        selectId = i;
                        break;
                    }
                    i++;
                }
            }
            if (s != "0" && selectId == 0) { // if selected song isn't present, go random
                selectId = Math.floor(Math.random() * (length - 1)) + 1;
            }
            if (selectId > 0 && length == 1) { // if selected song isn't present and list length is 1, go none
                selectId = 0;
            }
            selectedIndex = selectId; // set from var
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
            if (this.musicEnabled() && selectedItem.file != '') {
                var fileUrl:String = this.url + '/' + selectedItem.file;
                var request:URLRequest = new URLRequest(fileUrl);
                var slc:SoundLoaderContext = new SoundLoaderContext(3000, false);
                var song:Sound = new Sound(request, slc);
                var st:SoundTransform = new SoundTransform();
                st.volume = Settings.musicLevel / 100;
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

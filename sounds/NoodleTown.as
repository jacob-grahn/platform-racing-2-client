// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// sounds.NoodleTown = package_2.class_11

package sounds
{
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import flash.events.Event;
    import flash.media.SoundTransform;

    public class NoodleTown extends Removable 
    {

        private var song1:Sound = new NoodleTown2();
        private var song2:Sound = new NoodleTown3();
        private var channel1:SoundChannel;
        private var channel2:SoundChannel;
        private var perc1:Number;
        private var perc2:Number;
        private var var_327:Number;
        private var waitTimeout:uint;
        private var var_551:Number = 0.05;
        private var volume:Number = 0;
        private var var_187:Number = 1;

        public function NoodleTown()
        {
        }

        public function startPlaying()
        {
            if (this.channel1 == null) {
                if (Math.random() > 0.5) {
                    this.perc1 = 0;
                    this.perc2 = 1;
                } else {
                    this.perc1 = 1;
                    this.perc2 = 0;
                }
                this.channel1 = this.song1.play(0, 9999);
                this.channel2 = this.song2.play(0, 9999);
                this.setTargetVolume(this.var_187);
                this.applyVolume(this.volume);
                clearTimeout(this.waitTimeout);
                this.scheduleCrossfade();
            }
        }

        private function scheduleCrossfade()
        {
            this.waitTimeout = setTimeout(this.startCrossfade, Math.random() * 80000);
        }

        private function startCrossfade()
        {
            this.var_327 = (Math.random() * 0.004) + 0.002;
            if (this.perc1 > this.perc2) {
                this.var_327 = -this.var_327;
            }
            addEventListener(Event.ENTER_FRAME, this.name_3);
            this.scheduleCrossfade();
        }

        private function name_3(_arg_1:Event)
        {
            this.perc1 = this.perc1 + this.var_327;
            this.perc2 = this.perc2 - this.var_327;
            if (this.perc1 <= 0) {
                this.perc1 = 0;
                this.perc2 = 1;
                removeEventListener(Event.ENTER_FRAME, this.name_3);
            }
            if (this.perc2 <= 0) {
                this.perc1 = 1;
                this.perc2 = 0;
                removeEventListener(Event.ENTER_FRAME, this.name_3);
            }
            this.applyVolume(this.volume);
        }

        // removed _loc2, _loc3 (condensed)
        private function applyVolume(vol:Number)
        {
            this.volume = vol;
            if (this.channel1 != null) {
                this.channel1.soundTransform = new SoundTransform(this.volume * this.perc1);
                this.channel2.soundTransform = new SoundTransform(this.volume * this.perc2);
            }
        }

        public function setTargetVolume(n:Number)
        {
            this.var_187 = n;
            addEventListener(Event.ENTER_FRAME, this.volumeFadeTick);
        }

        private function volumeFadeTick(e:Event)
        {
            if (this.volume < this.var_187) {
                this.volume = this.volume + this.var_551;
                if (this.volume > this.var_187) {
                    this.volume = this.var_187;
                    removeEventListener(Event.ENTER_FRAME, this.volumeFadeTick);
                }
            } else {
                this.volume = this.volume - this.var_551;
                if (this.volume < this.var_187) {
                    this.volume = this.var_187;
                    removeEventListener(Event.ENTER_FRAME, this.volumeFadeTick);
                }
            }
            this.applyVolume(this.volume);
            if (this.volume <= 0 && this.var_187 <= 0) {
                this.stop();
            }
        }

        private function stop()
        {
            if (this.channel1 != null) {
                this.channel1.stop();
                this.channel2.stop();
                this.channel1 = this.channel2 = null;
            }
            removeEventListener(Event.ENTER_FRAME, this.name_3);
            removeEventListener(Event.ENTER_FRAME, this.volumeFadeTick);
            clearTimeout(this.waitTimeout);
        }

        override public function remove()
        {
            this.stop();
            super.remove();
        }


    }
}//package package_2


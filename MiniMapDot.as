// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// MiniMapDot = class_138

package 
{
    import com.jiggmin.data.ColorUtil;
    import flash.display.MovieClip;

    public dynamic class MiniMapDot extends MovieClip 
    {
        private const remote0Color:uint = 0x10B6DE;
        private const remote1Color:uint = 0xCC3333;
        private const remote2Color:uint = 0xFF6633;
        private const remote3Color:uint = 0xCA6EED;
        private const localColor:uint = 0xFFFF00;

        public function MiniMapDot()
        {
            addFrameScript(1, this.frame2);
        }

        public function getColor(tempId:int)
        {
            if (tempId >= 0 && tempId <= 3) {
                return this['remote' + tempId + 'Color'];
            } else {
                return this.localColor;
            }
        }

        internal function frame2():*
        {
            stop();
        }


    }
}//package 


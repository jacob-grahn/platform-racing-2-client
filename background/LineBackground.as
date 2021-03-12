// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.LineBackground
// Is this the LE Grid?

package background
{
    import page.GamePage;

    public class LineBackground extends Background 
    {

        private var segSize:Number = 30;

        public function LineBackground(_arg_1:GamePage)
        {
            super(_arg_1);
            this.method_325(1);
        }

        public function setZoom(_arg_1:Number)
        {
            this.method_325(_arg_1);
        }

        private function method_325(_arg_1:Number)
        {
            var _local_2:Number = ((550 * (1 / _arg_1)) + this.segSize);
            var _local_3:Number = ((400 * (1 / _arg_1)) + this.segSize);
            var _local_4:Number = 0;
            var _local_5:Number = 0;
            graphics.clear();
            graphics.lineStyle(1, 0x777777, 0.25);
            _local_4 = 0;
            while (_local_4 <= _local_2) {
                graphics.moveTo(_local_4, 0);
                graphics.lineTo(_local_4, _local_3);
                _local_4 = (_local_4 + this.segSize);
            }
            _local_5 = 0;
            while (_local_5 <= _local_3) {
                graphics.moveTo(0, _local_5);
                graphics.lineTo(_local_2, _local_5);
                _local_5 = (_local_5 + this.segSize);
            }
        }

        override public function setPos(_arg_1:Number, _arg_2:Number)
        {
            _arg_1 = (_arg_1 % this.segSize);
            _arg_2 = (_arg_2 % this.segSize);
            x = (_arg_1 - (Math.floor(((width / 2) / this.segSize)) * this.segSize));
            y = (_arg_2 - (Math.floor(((height / 2) / this.segSize)) * this.segSize));
        }


    }
}//package background


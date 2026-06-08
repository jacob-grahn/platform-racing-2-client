// background.LineBackground = background.BlockGridLines

package background
{
    import page.GamePage;

    public class BlockGridLines extends Background 
    {

        private var segSize:Number = 30;

        public function BlockGridLines(g:GamePage)
        {
            super(g);
            this.drawGrid(1);
        }

        public function setZoom(z:Number)
        {
            this.drawGrid(z);
        }

        private function drawGrid(zoom:Number)
        {
            var maxSegsX:Number = (550 / zoom) + this.segSize;
            var maxSegsY:Number = (400 / zoom) + this.segSize;
            graphics.clear();
            graphics.lineStyle(1, 0x777777, 0.25);
            for (var curX:Number = 0; curX <= maxSegsX; curX += this.segSize) {
                graphics.moveTo(curX, 0);
                graphics.lineTo(curX, maxSegsY);
            }
            for (var curY:Number = 0; curY <= maxSegsY; curY += this.segSize) {
                graphics.moveTo(0, curY);
                graphics.lineTo(maxSegsX, curY);
            }
        }

        override public function setPos(remX:Number, remY:Number)
        {
            remX %= this.segSize;
            remY %= this.segSize;
            x = remX - Math.floor((width / 2) / this.segSize) * this.segSize;
            y = remY - Math.floor((height / 2) / this.segSize) * this.segSize;
        }


    }
}

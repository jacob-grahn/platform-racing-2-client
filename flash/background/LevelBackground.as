//background.LevelBackground
// actual level background image

package background
{
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import page.GamePage;
    import com.jiggmin.data.Objects;
    import com.jiggmin.data.Settings;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.geom.ColorTransform;

    public class LevelBackground extends Background 
    {

        private var bitmapData:BitmapData = new BitmapData(550, 400, false, 0);
        private var bitmap:Bitmap = new Bitmap(bitmapData);
        private var color:Number;
        private var displayCode:int;

        public function LevelBackground(gamePage:GamePage)
        {
            super(gamePage);
            scale = 0;
            cacheAsBitmap = true;
            mouseEnabled = false;
            mouseChildren = false;
            this.bitmap.x = -275;
            this.bitmap.y = -200;
            addChild(this.bitmap);
        }

        override public function setColor(color:Number)
        {
            this.color = color;
            this.bitmapData.fillRect(this.bitmapData.rect, color);
            this.displayCode = -1;
            super.setColor(color);
        }

        public function setArtBackground(displayCode:int)
        {
            this.displayCode = displayCode;
            var bg:DisplayObject = Objects.getFromCode(displayCode);
            if (displayCode == Objects.BG5Code) {
                this.drawCircleGrid(bg);
            }
            this.bitmapData.draw(bg);
            scale = displayCode == Objects.BG4Code || displayCode == Objects.BG5Code ? 0 : 1;
            applyColorTransform();
        }

        private function drawCircleGrid(bg:DisplayObject)
        {
            var mc:MovieClip = MovieClip(bg);
            var tileSize:int = 50;
            var cols:int = int(550 / tileSize);
            var rows:int = int(400 / tileSize);
            var ct:ColorTransform = new ColorTransform();
            var col:int;
            while (col < cols) {
                var row:int = 0;
                while (row < rows) {
                    ct.color = Math.random() * 0xFFFFFF;
                    var circle:Circle = new Circle();
                    circle.width = circle.height = 25;
                    circle.x = (col * tileSize) + 7.5 + (circle.width / 2);
                    circle.y = (row * tileSize) + 7.5 + (circle.height / 2);
                    circle.transform.colorTransform = ct;
                    mc.addChild(circle);
                    row++;
                }
                col++;
            }
        }

        override public function getSaveString():String
        {
            return this.displayCode.toString();
        }

        override public function setSaveString(s:String, fromLE:Boolean = true)
        {
            // drawbg true; string is not any of these: -1, square, null, and empty (ORIGINAL)
            // drawbg + isLE false; string is either -1, square, null, or empty
            if ((!Settings.getValue(Settings.DRAW_ART, true) && !fromLE) || s == "-1" || s == "Square" || s == null || s == "") {
                return;
            }
            if (s.indexOf("BG") != -1) {
                s = "20" + s.substr(2);
            }
            this.setArtBackground(int(s));
        }

        override public function remove()
        {
            this.bitmapData.dispose();
            this.bitmap.bitmapData = null;
            removeChild(this.bitmap);
            this.bitmap = null;
            this.bitmapData = null;
            super.remove();
        }


    }
}


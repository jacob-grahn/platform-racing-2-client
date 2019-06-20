// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.InfoPopup = package_4.class_203

package package_4
{
    import flash.geom.Rectangle;
    import flash.display.DisplayObject;

    public class InfoPopup extends Removable 
    {

        // _loc2 = stageBounds
        // _loc3 = distToLeft
        // _loc4 = distToTop
        // _loc5 = boxBounds
        // _loc6 = posX
        // _loc7 = posY
        public function InfoPopup(d:DisplayObject)
        {
            super();
            var stageBounds:Rectangle = getBounds(Main.stage);
            var distToLeft:Number = stageBounds.left;
            var distToTop:Number = stageBounds.top;
            var boxBounds:Rectangle = d.getBounds(Main.stage);
            if (boxBounds.left > width) {
                distToLeft = boxBounds.left - width - 7;
            } else {
                distToLeft = boxBounds.right + 7;
            }
            distToTop = boxBounds.top;
            if (distToTop < 0) {
                distToTop = 0;
            }
            if ((distToTop + height) > 400) {
                distToTop = 400 - height;
            }
            var posX:Number = distToLeft - stageBounds.left;
            var posY:Number = distToTop - stageBounds.top;
            x = Math.round(posX);
            y = Math.round(posY);
            Main.stage.addChild(this);
        }

    }
}

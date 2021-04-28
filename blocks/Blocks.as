// class_3 = blocks.Blocks

package blocks
{
    import flash.display.BitmapData;
    import com.jiggmin.data.Objects;

    public class Blocks 
    {

        public static var startBitmap:StartBitmap; // var_420
        public static var basic1Bitmap:Basic1Bitmap;
        public static var basic2Bitmap:Basic2Bitmap;
        public static var basic3Bitmap:Basic3Bitmap;
        public static var basic4Bitmap:Basic4Bitmap;
        public static var brickBitmap:BrickBitmap; // var_391
        public static var basic2Bitmap1:Basic2Bitmap; // var_494
        public static var basic2Bitmap2:Basic2Bitmap; // var_426
        public static var basic2Bitmap3:Basic2Bitmap; // var_485
        public static var basic2Bitmap4:Basic2Bitmap; // var_417
        public static var mineBitmap:MineBitmap; // var_504
        public static var itemBitmap:ItemBitmap; // var_458
        public static var iceBitmap:IceBitmap; // var_110
        public static var finishBitmap:FinishBitmap; // var_461
        public static var crumbleBitmap:CrumbleBitmap; // var_430
        public static var vanishBitmap:VanishBitmap; // var_442
        public static var moveBitmap:MoveBitmap; // var_401
        public static var waterBitmap:WaterBitmap; // var_404
        public static var rotateRightBitmap:RotateRightBitmap; // var_409
        public static var rotateLeftBitmap:RotateLeftBitmap; // var_398
        public static var pushBitmap:PushBitmap; // var_473
        public static var safetyNetBitmap:SafetyNetBitmap; // var_498
        public static var infiniteItemBitmap:InfiniteItemBitmap; // var_462
        public static var happyBitmap:HappyBitmap; // var_408
        public static var sadBitmap:SadBitmap; // var_476
        public static var heartBitmap:HeartBitmap; // var_433
        public static var timeBitmap:TimeBitmap; // var_457
        public static var customStatsBitmap:CustomStatsBitmap;
        public static var teleportBitmap:TeleportBitmap;


        public static function init()
        {
            startBitmap = new StartBitmap(30, 30);
            basic1Bitmap = new Basic1Bitmap(30, 30);
            basic2Bitmap = new Basic2Bitmap(30, 30);
            basic3Bitmap = new Basic3Bitmap(30, 30);
            basic4Bitmap = new Basic4Bitmap(30, 30);
            brickBitmap = new BrickBitmap(30, 30);
            basic2Bitmap1 = new Basic2Bitmap(30, 30);
            basic2Bitmap2 = new Basic2Bitmap(30, 30);
            basic2Bitmap3 = new Basic2Bitmap(30, 30);
            basic2Bitmap4 = new Basic2Bitmap(30, 30);
            mineBitmap = new MineBitmap(30, 30);
            itemBitmap = new ItemBitmap(30, 30);
            iceBitmap = new IceBitmap(30, 30);
            finishBitmap = new FinishBitmap(30, 30);
            crumbleBitmap = new CrumbleBitmap(30, 30);
            vanishBitmap = new VanishBitmap(30, 30);
            moveBitmap = new MoveBitmap(30, 30);
            waterBitmap = new WaterBitmap(30, 30);
            rotateRightBitmap = new RotateRightBitmap(30, 30);
            rotateLeftBitmap = new RotateLeftBitmap(30, 30);
            pushBitmap = new PushBitmap(30, 30);
            safetyNetBitmap = new SafetyNetBitmap(30, 30);
            infiniteItemBitmap = new InfiniteItemBitmap(30, 30);
            happyBitmap = new HappyBitmap(30, 30);
            sadBitmap = new SadBitmap(30, 30);
            heartBitmap = new HeartBitmap(30, 30);
            timeBitmap = new TimeBitmap(30, 30);
            customStatsBitmap = new CustomStatsBitmap(30, 30);
            teleportBitmap = new TeleportBitmap(30, 30);
        }

        // _loc2 = bmpData
        public static function getBlock(blockCode:int):BitmapData
        {
            var bmpData:BitmapData;
            if (blockCode == Objects.BLOCK_BASIC1) {
                bmpData = basic1Bitmap;
            } else if (blockCode == Objects.BLOCK_BASIC2) {
                bmpData = basic2Bitmap;
            } else if (blockCode == Objects.BLOCK_BASIC3) {
                bmpData = basic3Bitmap;
            } else if (blockCode == Objects.BLOCK_BASIC4) {
                bmpData = basic4Bitmap;
            } else if (blockCode == Objects.BLOCK_BRICK) {
                bmpData = brickBitmap;
            } else if (blockCode == Objects.BLOCK_CRUMBLE) {
                bmpData = crumbleBitmap;
            } else if (blockCode == Objects.BLOCK_FINISH) {
                bmpData = finishBitmap;
            } else if (blockCode == Objects.BLOCK_HAPPY) {
                bmpData = happyBitmap;
            } else if (blockCode == Objects.BLOCK_ICE) {
                bmpData = iceBitmap;
            } else if (blockCode == Objects.BLOCK_ITEM_INF) {
                bmpData = infiniteItemBitmap;
            } else if (blockCode == Objects.BLOCK_ITEM) {
                bmpData = itemBitmap;
            } else if (blockCode == Objects.BLOCK_MINE) {
                bmpData = mineBitmap;
            } else if (blockCode == Objects.BLOCK_MOVE) {
                bmpData = moveBitmap;
            } else if (blockCode == Objects.BLOCK_PUSH) {
                bmpData = pushBitmap;
            } else if (blockCode == Objects.BLOCK_ROTATE_LEFT) {
                bmpData = rotateLeftBitmap;
            } else if (blockCode == Objects.BLOCK_ROTATE_RIGHT) {
                bmpData = rotateRightBitmap;
            } else if (blockCode == Objects.BLOCK_SAD) {
                bmpData = sadBitmap;
            } else if (blockCode == Objects.BLOCK_SAFETY) {
                bmpData = safetyNetBitmap;
            } else if (blockCode == Objects.BLOCK_VANISH) {
                bmpData = vanishBitmap;
            } else if (blockCode == Objects.BLOCK_WATER) {
                bmpData = waterBitmap;
            } else if (blockCode == Objects.BLOCK_ARROW_DOWN) {
                bmpData = basic2Bitmap1;
            } else if (blockCode == Objects.BLOCK_ARROW_LEFT) {
                bmpData = basic2Bitmap3;
            } else if (blockCode == Objects.BLOCK_ARROW_RIGHT) {
                bmpData = basic2Bitmap4;
            } else if (blockCode == Objects.BLOCK_ARROW_UP) {
                bmpData = basic2Bitmap2;
            } else if (blockCode == Objects.BLOCK_HEART) {
                bmpData = heartBitmap;
            } else if (blockCode == Objects.BLOCK_START1 || blockCode == Objects.BLOCK_START2 || blockCode == Objects.BLOCK_START3 || blockCode == Objects.BLOCK_START4) {
                bmpData = startBitmap;
            } else if (blockCode == Objects.BLOCK_TIME) {
                bmpData = timeBitmap;
            } else if (blockCode == Objects.BLOCK_CUSTOM_STATS) {
                bmpData = customStatsBitmap;
            } else if (blockCode == Objects.BLOCK_TELEPORT) {
                bmpData = teleportBitmap;
            }
            return bmpData;
        }


    }
}

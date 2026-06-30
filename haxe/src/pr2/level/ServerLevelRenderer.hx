package pr2.level;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.effects.BlockPiece;
import pr2.effects.MineExplosion;
import pr2.runtime.PR2MovieClip;

/**
	Renders the decoded server block layer in original PR2 pixel units.

	Server levels are stored around large editor coordinates (~10000 px). This
	renderer keeps the 30 px block scale and translates the world so a chosen
	focus point, usually the first start block, appears at a stable stage point.
**/
class ServerLevelRenderer extends Sprite {
	public static inline var TILE_SIZE:Int = 30;
	// Edge length of the transparent square that stroke art is rasterized onto,
	// mirroring DrawableBackground.rasterTileSize. Kept well under the WebGL
	// MAX_TEXTURE_SIZE (8192 on many GPUs, 4096 on some) so a single tile never
	// fails to upload. See rasterizeBrushInto.
	public static inline var ART_RASTER_TILE_SIZE:Int = 1024;
	public static inline var DEFAULT_FOCUS_X:Float = 180;
	public static inline var DEFAULT_FOCUS_Y:Float = 280;
	public static inline var DEFAULT_BLOCKS_PER_FRAME:Int = 50;
	// View-window culling (mirrors Flash background.Background.updateViewWindow):
	// only blocks within VIEW_MARGIN_SEGMENTS of the visible stage are attached to
	// blockLayer. Without this the whole level (18k+ blocks on big maps) stays on
	// the display list, giving one WebGL draw call per block and ~3fps; Flash keeps
	// just the on-screen window attached and recycles blocks as the camera scrolls.
	public static inline var VIEW_MARGIN_SEGMENTS:Int = 2;
	// Only rebuild the window once the camera has scrolled this many segments, so a
	// slow pan does not churn addChild/removeChild every frame (Flash uses 5).
	public static inline var VIEW_REBUILD_THRESHOLD:Int = 3;

	private final level:ServerLevel;
	private var offsetX:Float;
	private var offsetY:Float;
	// Unrounded camera offset, kept so the parallax layers can re-derive their
	// rounded per-plane offset whenever the committed rotation changes.
	private var rawOffsetX:Float;
	private var rawOffsetY:Float;
	// Pivot (in block-layer local/level-pixel coords) that the committed rotation
	// turns about. The controller swaps the player's coordinates about the fixture
	// origin (originTile*TILE_SIZE), so the blocks must turn about that same point
	// or they land hundreds of pixels off-screen and culling drops them all.
	private var rotationPivotX:Float = 0;
	private var rotationPivotY:Float = 0;
	// Holds the parallax art layers and the block layer — everything that spins
	// when a rotate block fires. Mirrors Flash, which rotates the whole Course
	// during the tween (worldContainer here) and bakes the committed 90-degree
	// step into blockBackground/bg* (blockLayer + art layer rotation here). The
	// solid background and themed art-background bitmap stay direct children of
	// `this` so they remain upright, like Flash's counter-rotated `bg`.
	private final worldContainer:Sprite = new Sprite();
	// Committed course rotation (a multiple of 90), baked about the block layer's
	// own origin. `tweenRotation` is the in-progress smooth spin applied to the
	// whole world about the screen centre while a rotate block animates.
	private var courseRotation:Int = 0;
	private var tweenRotation:Float = 0;
	private final blockLayer:Sprite = new Sprite();
	private final artLayerContainers:Array<Sprite> = [];
	private final blockDisplays:Map<String, Sprite> = new Map();
	// Block sprites keyed by segment (column -> row -> sprite), mirroring Flash's
	// blockArray[segX][segY]. Used to attach/detach only the on-screen window
	// without scanning every block. Every block lives here whether attached or not.
	private final blockGrid:Map<Int, Map<Int, Sprite>> = new Map();
	private var viewColMin:Int = 0;
	private var viewColMax:Int = 0;
	private var viewRowMin:Int = 0;
	private var viewRowMax:Int = 0;
	private var viewInitialized:Bool = false;
	private final arrowDisplays:Map<String, PR2MovieClip> = new Map();
	private final arrowCompletionHandlers:Map<String, Event->Void> = new Map();
	private final waterRippleFrames:Map<String, Int> = new Map();
	private final artDrawCursors:Array<ArtDrawCursor> = [];
	private var nextBlockToDraw:Int = 0;
	private var nextArtLayerToDraw:Int = 0;
	private var drawnArtItems:Int = 0;
	private var totalArtItems:Int = 0;
	private var incrementalBlocks:Bool = false;
	private var blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME;

	public function new(level:ServerLevel, ?focusBlock:DecodedBlock, focusScreenX:Float = DEFAULT_FOCUS_X, focusScreenY:Float = DEFAULT_FOCUS_Y,
			incrementalBlocks:Bool = false, blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME) {
		super();
		this.level = level;
		this.incrementalBlocks = incrementalBlocks;
		this.blocksPerFrame = blocksPerFrame <= 0 ? DEFAULT_BLOCKS_PER_FRAME : blocksPerFrame;

		var focus = focusBlock == null ? firstRenderableBlock(level) : focusBlock;
		if (focus == null) {
			offsetX = 0;
			offsetY = 0;
		} else {
			offsetX = focusScreenX - focus.x;
			offsetY = focusScreenY - focus.y;
		}
		rawOffsetX = offsetX;
		rawOffsetY = offsetY;

		drawBackground();
		drawArtBackground();
		// The block and parallax art layers live inside the rotating world
		// container; the solid background and art-background bitmap above stay on
		// `this` so they remain upright when the course spins.
		addChild(worldContainer);
		// Course.attachBackgrounds places bg3/bg2/bg1 behind the map and bg4/bg5
		// in front. Preserve that authored depth order instead of flattening all
		// five drawing planes behind the blocks.
		drawArtLayer(2);
		drawArtLayer(1);
		drawArtLayer(0);
		drawBlocks();
		drawArtLayer(3);
		drawArtLayer(4);
		if (incrementalBlocks && totalArtItems > 0) {
			addEventListener(Event.ENTER_FRAME, drawArtBatch);
		}
	}

	public function isBlockDrawingComplete():Bool {
		return nextBlockToDraw >= level.blocks.length;
	}

	public function isDrawingComplete():Bool {
		return isBlockDrawingComplete() && drawnArtItems >= totalArtItems;
	}

	public function drawnBlockCount():Int {
		return nextBlockToDraw;
	}

	public function drawnArtItemCount():Int {
		return drawnArtItems;
	}

	// World points handed in here (player, eggs, mines) are already expressed in
	// the current rotated frame, so they only need the camera translation plus
	// the in-progress tween spin about the screen centre. The committed course
	// rotation is baked into the block layer, which stores its blocks in the
	// original frame, so it must not be applied again here.
	public function worldToScreen(x:Float, y:Float):Point {
		var point = new Point(x + offsetX, y + offsetY);
		return tweenRotation == 0 ? point : worldContainer.transform.matrix.transformPoint(point);
	}

	public function screenToWorld(x:Float, y:Float):Point {
		var point = new Point(x, y);
		if (tweenRotation != 0) {
			var inverse = worldContainer.transform.matrix.clone();
			inverse.invert();
			point = inverse.transformPoint(point);
		}
		return new Point(point.x - offsetX, point.y - offsetY);
	}

	public function cameraOffset():Point {
		return new Point(offsetX, offsetY);
	}

	/**
		Applies the rotate-block course rotation. `courseRotation` is the committed
		multiple of 90 degrees, baked into the block and parallax layers about their
		own origin (Flash `blockBackground.rotation`/`bg*.rotation`). `tweenRotation`
		is the in-progress smooth spin applied to the whole world about the screen
		centre while the block animates (Flash rotating the Course during the tween).
	**/
	public function setCourseRotation(courseRotation:Int, tweenRotation:Float):Void {
		if (this.courseRotation != courseRotation) {
			this.courseRotation = courseRotation;
			applyLayerTransforms();
			updateViewWindow(true);
		}
		if (this.tweenRotation != tweenRotation) {
			this.tweenRotation = tweenRotation;
			applyTweenRotation();
		}
	}

	/**
		Sets the point the committed course rotation turns about, in block-layer
		local (level-pixel) coordinates. Course passes the fixture origin so the
		blocks turn about the same pivot the controller uses when it swaps the
		player's coordinates on each rotate step.
	**/
	public function setRotationPivot(x:Float, y:Float):Void {
		if (rotationPivotX == x && rotationPivotY == y) {
			return;
		}
		rotationPivotX = x;
		rotationPivotY = y;
		if (courseRotation != 0) {
			applyLayerTransforms();
			updateViewWindow(true);
		}
	}

	// Builds the block/art layer matrix: turn the original-frame content about the
	// committed rotation pivot, then apply the (per-plane) camera translation.
	private function layerMatrix(translateX:Float, translateY:Float):Matrix {
		var matrix = new Matrix();
		if (courseRotation != 0) {
			matrix.translate(-rotationPivotX, -rotationPivotY);
			matrix.rotate(courseRotation * Math.PI / 180);
			matrix.translate(rotationPivotX, rotationPivotY);
		}
		matrix.translate(translateX, translateY);
		return matrix;
	}

	private function applyLayerTransforms():Void {
		blockLayer.transform.matrix = layerMatrix(offsetX, offsetY);
		for (i in 0...artLayerContainers.length) {
			if (artLayerContainers[i] == null) {
				continue;
			}
			var layer = level.artLayers[i];
			artLayerContainers[i].transform.matrix = layerMatrix(parallaxOffset(rawOffsetX, layer.scale), parallaxOffset(rawOffsetY, layer.scale));
		}
	}

	private function applyTweenRotation():Void {
		if (tweenRotation == 0) {
			worldContainer.transform.matrix = new Matrix();
			return;
		}
		var pivotX = Constants.STAGE_WIDTH / 2;
		var pivotY = Constants.STAGE_HEIGHT / 2;
		var matrix = new Matrix();
		matrix.translate(-pivotX, -pivotY);
		matrix.rotate(tweenRotation * Math.PI / 180);
		matrix.translate(pivotX, pivotY);
		worldContainer.transform.matrix = matrix;
	}

	/** Applies Course.setPos camera translation to world and parallax layers. */
	public function setCameraOffset(x:Float, y:Float):Void {
		rawOffsetX = x;
		rawOffsetY = y;
		offsetX = Math.round(x);
		offsetY = Math.round(y);
		applyLayerTransforms();
		updateViewWindow(false);
	}

	public function setBlockAlpha(worldX:Int, worldY:Int, alpha:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.alpha = alpha;
		}
	}

	public function setBlockColorMultiplier(worldX:Int, worldY:Int, multiplier:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.transform.colorTransform = new ColorTransform(multiplier, multiplier, multiplier);
		}
	}

	public function animateArrow(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var arrow = arrowDisplays.get(key);
		if (arrow == null) {
			return;
		}
		if (arrow.currentFrame < 5) {
			arrow.gotoAndPlay(arrow.currentFrame + 1);
		} else if (arrow.currentFrame > 5) {
			arrow.gotoAndPlay(arrow.currentFrame - 1);
		}
		if (!arrowCompletionHandlers.exists(key)) {
			var onFrame:Event->Void = null;
			onFrame = function(_:Event):Void {
				if (arrow.currentFrame != 1) {
					return;
				}
				arrow.removeEventListener(Event.ENTER_FRAME, onFrame);
				arrowCompletionHandlers.remove(key);
				arrowDisplays.remove(key);
				var pivot = arrow.parent;
				if (pivot != null && pivot.parent != null) {
					pivot.parent.removeChild(pivot);
				}
				arrow.dispose();
			};
			arrowCompletionHandlers.set(key, onFrame);
			arrow.addEventListener(Event.ENTER_FRAME, onFrame);
		}
	}

	public function arrowFrameAt(worldX:Int, worldY:Int):Null<Int> {
		var arrow = arrowDisplays.get(blockKey(worldX, worldY));
		return arrow == null ? null : arrow.currentFrame;
	}

	public function activateVanish(worldX:Int, worldY:Int):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display != null) {
			display.alpha = 0;
		}
	}

	public function triggerWaterRipple(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return;
		}
		display.alpha -= 0.1;
		if (display.alpha < 0.5) {
			display.alpha = 0.5;
		}
		waterRippleFrames.set(key, 1);
		addEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
	}

	public function blockAlphaAt(worldX:Int, worldY:Int):Null<Float> {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		return display == null ? null : display.alpha;
	}

	public function showMineExplosion(worldX:Float, worldY:Float, playSound:Bool = true):MineExplosion {
		var effect = new MineExplosion(worldX, worldY, offsetX, offsetY, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function showBlockPieces(linkage:String, worldX:Float, worldY:Float, count:Int, spreadX:Float, spreadY:Float,
			spreadRot:Float, ?random:Void->Float):Array<BlockPiece> {
		var nextRandom = random == null ? Math.random : random;
		var pieces:Array<BlockPiece> = [];
		for (_ in 0...count) {
			var piece = new BlockPiece(linkage, worldX + nextRandom() * TILE_SIZE, worldY + nextRandom() * TILE_SIZE, spreadX, spreadY, spreadRot,
				BlockPiece.GRAVITY, BlockPiece.FRICTION, BlockPiece.FADE_RATE, nextRandom);
			blockLayer.addChild(piece);
			pieces.push(piece);
		}
		return pieces;
	}

	private static inline function parallaxOffset(screenOffset:Float, scale:Float):Float {
		return Math.round(screenOffset * scale);
	}

	public static function blockAssetPath(code:Int):String {
		return switch (code) {
			case ObjectCodes.BLOCK_BASIC1: "assets/blocks/basic1.png";
			case ObjectCodes.BLOCK_BASIC2: "assets/blocks/basic2.png";
			case ObjectCodes.BLOCK_BASIC3: "assets/blocks/basic3.png";
			case ObjectCodes.BLOCK_BASIC4: "assets/blocks/basic4.png";
			case ObjectCodes.BLOCK_BRICK: "assets/blocks/brick.png";
			case ObjectCodes.BLOCK_MINE: "assets/blocks/mine_block.png";
			case ObjectCodes.BLOCK_ITEM: "assets/blocks/item.png";
			case ObjectCodes.BLOCK_START1 | ObjectCodes.BLOCK_START2 | ObjectCodes.BLOCK_START3 | ObjectCodes.BLOCK_START4: "assets/blocks/start.png";
			case ObjectCodes.BLOCK_ICE: "assets/blocks/ice.png";
			case ObjectCodes.BLOCK_FINISH: "assets/blocks/finish.png";
			case ObjectCodes.BLOCK_CRUMBLE: "assets/blocks/crumble.png";
			case ObjectCodes.BLOCK_VANISH: "assets/blocks/vanish.png";
			case ObjectCodes.BLOCK_MOVE: "assets/blocks/move.png";
			case ObjectCodes.BLOCK_WATER: "assets/blocks/water.png";
			case ObjectCodes.BLOCK_ROTATE_RIGHT: "assets/blocks/rotate_right.png";
			case ObjectCodes.BLOCK_ROTATE_LEFT: "assets/blocks/rotate_left.png";
			case ObjectCodes.BLOCK_PUSH: "assets/blocks/push.png";
			case ObjectCodes.BLOCK_SAFETY: "assets/blocks/safety_net.png";
			case ObjectCodes.BLOCK_ITEM_INF: "assets/blocks/infinite_item.png";
			case ObjectCodes.BLOCK_HAPPY: "assets/blocks/happy.png";
			case ObjectCodes.BLOCK_SAD: "assets/blocks/sad.png";
			case ObjectCodes.BLOCK_HEART: "assets/blocks/heart.png";
			case ObjectCodes.BLOCK_TIME: "assets/blocks/time.png";
			case ObjectCodes.BLOCK_CUSTOM_STATS: "assets/blocks/custom_stats.png";
			case ObjectCodes.BLOCK_TELEPORT: "assets/blocks/teleport_block.png";
			// ArrowBlock uses a basic2 tile as its base (Blocks.getBlock) and adds
			// the rotated arrow overlay on top; see arrowOverlayAssetPath.
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT:
				"assets/blocks/basic2.png";
			default: "";
		}
	}

	/** The committed raster export retained for asset-inventory compatibility. */
	public static inline function arrowOverlayAssetPath():String {
		return "assets/blocks/arrow_overlay@4x.png";
	}

	/**
		Arrow overlay rotation in degrees, matching ArrowUp/Down/Left/RightBlock's
		`rot` argument to ArrowBlock. Null for non-arrow blocks.
	**/
	public static function arrowOverlayRotation(code:Int):Null<Float> {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_UP: 0;
			case ObjectCodes.BLOCK_ARROW_DOWN: 180;
			case ObjectCodes.BLOCK_ARROW_LEFT: -90;
			case ObjectCodes.BLOCK_ARROW_RIGHT: 90;
			default: null;
		}
	}

	public static function artBackgroundAssetPath(code:Int):String {
		return switch (code) {
			case 201: "assets/backgrounds/bg1@4x.png";
			case 202: "assets/backgrounds/bg2@4x.png";
			case 203: "assets/backgrounds/bg3@4x.png";
			case 204: "assets/backgrounds/bg4@4x.png";
			case 205: "assets/backgrounds/bg5@4x.png";
			case 206: "assets/backgrounds/bg6@4x.png";
			case 207: "assets/backgrounds/bg7@4x.png";
			default: "";
		}
	}

	public static function stampAssetPath(code:Int):String {
		return switch (code) {
			case 0: "assets/stamps/tree1@4x.png";
			case 1: "assets/stamps/tree2@4x.png";
			case 2: "assets/stamps/tree3@4x.png";
			case 3: "assets/stamps/petrified_tree@4x.png";
			case 5: "assets/stamps/rock1@4x.png";
			case 6: "assets/stamps/rock2@4x.png";
			case 7: "assets/stamps/spire1@4x.png";
			case 8: "assets/stamps/spire2@4x.png";
			default: "";
		}
	}

	private function drawBackground():Void {
		var background = new Shape();
		background.graphics.beginFill(level.bgColor);
		background.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		background.graphics.endFill();
		addChild(background);
	}

	private function drawBlocks():Void {
		blockLayer.x = offsetX;
		blockLayer.y = offsetY;
		worldContainer.addChild(blockLayer);
		// Establish the initial window from the start-focus offset so blocks that
		// fall on screen are attached as they are created, and the rest stay off
		// the display list until the camera scrolls to them.
		updateViewWindow(true);
		if (incrementalBlocks) {
			addEventListener(Event.ENTER_FRAME, drawBlockBatch);
			return;
		}
		drawNextBlocks(level.blocks.length);
	}

	private function drawBlockBatch(event:Event):Void {
		drawNextBlocks(blocksPerFrame);
		if (isBlockDrawingComplete()) {
			removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		}
	}

	private function drawArtBatch(event:Event):Void {
		drawNextArtItems(blocksPerFrame);
		if (drawnArtItems >= totalArtItems) {
			removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		}
	}

	private function onWaterRippleFrame(event:Event):Void {
		for (key in [for (k in waterRippleFrames.keys()) k]) {
			var display = blockDisplays.get(key);
			if (display == null) {
				waterRippleFrames.remove(key);
				continue;
			}
			display.alpha += 0.03;
			if (display.alpha >= 1) {
				display.alpha = 1;
				waterRippleFrames.remove(key);
			}
		}
		if (!waterRippleFrames.keys().hasNext()) {
			removeEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
		}
	}

	private function drawNextBlocks(limit:Int):Void {
		var end = Std.int(Math.min(level.blocks.length, nextBlockToDraw + limit));
		while (nextBlockToDraw < end) {
			var block = level.blocks[nextBlockToDraw++];
			addBlockDisplay(block);
		}
	}

	private function addBlockDisplay(block:DecodedBlock):Void {
		var display = createBlockDisplay(block);
		blockDisplays.set(blockKey(block.x, block.y), display);
		var segX = segmentOf(block.x);
		var segY = segmentOf(block.y);
		var col = blockGrid.get(segX);
		if (col == null) {
			col = new Map();
			blockGrid.set(segX, col);
		}
		col.set(segY, display);
		// Attach only if the block currently falls inside the view window; otherwise
		// it stays in the grid and is attached later when the camera scrolls to it.
		if (isInView(segX, segY)) {
			blockLayer.addChild(display);
		}
	}

	private static inline function segmentOf(coord:Int):Int {
		return Math.round(coord / TILE_SIZE);
	}

	private inline function isInView(segX:Int, segY:Int):Bool {
		return viewInitialized && segX >= viewColMin && segX <= viewColMax && segY >= viewRowMin && segY <= viewRowMax;
	}

	private function setBlockAttached(segX:Int, segY:Int, attach:Bool):Void {
		var col = blockGrid.get(segX);
		if (col == null) {
			return;
		}
		var display = col.get(segY);
		if (display == null) {
			return;
		}
		if (attach) {
			if (display.parent != blockLayer) {
				blockLayer.addChild(display);
			}
		} else if (display.parent == blockLayer) {
			blockLayer.removeChild(display);
		}
	}

	/**
		Attaches the on-screen block window and detaches what scrolled out, mirroring
		Flash `background.Background.updateViewWindow`. Only the window perimeter is
		walked (a few hundred segment cells), never the full block list.
	**/
	private function updateViewWindow(force:Bool):Void {
		// Map the visible stage rectangle into the block layer's local (original,
		// pre-rotation) frame so culling stays correct when a rotate block spins the
		// course. Mirrors Flash background.Background.updateViewWindow, which rotates
		// the camera window into the block layer's frame before picking the column/
		// row range. The combined matrix folds in both the committed block rotation
		// and the in-progress tween, so the bounding box covers the rotated window.
		var toLocal = blockLayer.transform.matrix.clone();
		toLocal.concat(worldContainer.transform.matrix);
		toLocal.invert();
		var minX = Math.POSITIVE_INFINITY;
		var minY = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;
		var maxY = Math.NEGATIVE_INFINITY;
		for (corner in [new Point(0, 0), new Point(Constants.STAGE_WIDTH, 0), new Point(0, Constants.STAGE_HEIGHT),
			new Point(Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT)]) {
			var local = toLocal.transformPoint(corner);
			if (local.x < minX) minX = local.x;
			if (local.x > maxX) maxX = local.x;
			if (local.y < minY) minY = local.y;
			if (local.y > maxY) maxY = local.y;
		}
		var colMin = Math.floor(minX / TILE_SIZE) - VIEW_MARGIN_SEGMENTS;
		var colMax = Math.ceil(maxX / TILE_SIZE) + VIEW_MARGIN_SEGMENTS;
		var rowMin = Math.floor(minY / TILE_SIZE) - VIEW_MARGIN_SEGMENTS;
		var rowMax = Math.ceil(maxY / TILE_SIZE) + VIEW_MARGIN_SEGMENTS;
		if (!force
			&& viewInitialized
			&& intAbs(colMin - viewColMin) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(colMax - viewColMax) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(rowMin - viewRowMin) <= VIEW_REBUILD_THRESHOLD
			&& intAbs(rowMax - viewRowMax) <= VIEW_REBUILD_THRESHOLD) {
			return;
		}
		// Detach cells leaving the window.
		if (viewInitialized) {
			for (segX in viewColMin...viewColMax + 1) {
				for (segY in viewRowMin...viewRowMax + 1) {
					if (segX < colMin || segX > colMax || segY < rowMin || segY > rowMax) {
						setBlockAttached(segX, segY, false);
					}
				}
			}
		}
		// Attach cells entering the window (skip those already inside the old one).
		for (segX in colMin...colMax + 1) {
			for (segY in rowMin...rowMax + 1) {
				if (!viewInitialized || segX < viewColMin || segX > viewColMax || segY < viewRowMin || segY > viewRowMax) {
					setBlockAttached(segX, segY, true);
				}
			}
		}
		viewColMin = colMin;
		viewColMax = colMax;
		viewRowMin = rowMin;
		viewRowMax = rowMax;
		viewInitialized = true;
	}

	private static inline function intAbs(value:Int):Int {
		return value < 0 ? -value : value;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		removeEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
		waterRippleFrames.clear();
		// Dispose every arrow movie clip, including off-screen ones that culling left
		// detached from blockLayer so the tree walk below would not reach them.
		for (key in arrowDisplays.keys()) {
			var arrow = arrowDisplays.get(key);
			var handler = arrowCompletionHandlers.get(key);
			if (handler != null) {
				arrow.removeEventListener(Event.ENTER_FRAME, handler);
			}
			arrow.dispose();
		}
		arrowDisplays.clear();
		arrowCompletionHandlers.clear();
		disposeAnimatedChildren(this);
		if (parent != null) {
			parent.removeChild(this);
		}
	}

	private function disposeAnimatedChildren(container:Sprite):Void {
		var i = container.numChildren - 1;
		while (i >= 0) {
			var child = container.getChildAt(i);
			var mineExplosion = Std.downcast(child, MineExplosion);
			if (mineExplosion != null) {
				mineExplosion.remove();
				i--;
				continue;
			}
			var blockPiece = Std.downcast(child, BlockPiece);
			if (blockPiece != null) {
				blockPiece.remove();
				i--;
				continue;
			}
			var clip = Std.downcast(child, PR2MovieClip);
			if (clip != null) {
				clip.dispose();
			}
			var childContainer = Std.downcast(child, Sprite);
			if (childContainer != null) {
				disposeAnimatedChildren(childContainer);
			}
			i--;
		}
	}

	private static inline function blockKey(x:Int, y:Int):String {
		return x + "," + y;
	}

	private function drawArtBackground():Void {
		if (level.artBackgroundCode == null) {
			return;
		}
		var assetPath = artBackgroundAssetPath(level.artBackgroundCode);
		if (assetPath == "" || !Assets.exists(assetPath, AssetType.IMAGE)) {
			return;
		}

		var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
		bitmap.smoothing = true;
		bitmap.width = Constants.STAGE_WIDTH;
		bitmap.height = Constants.STAGE_HEIGHT;
		addChild(bitmap);
	}

	private function drawArtLayer(index:Int):Void {
		if (index >= level.artLayers.length) return;
		var layer = level.artLayers[index];
		var container = new Sprite();
		container.name = 'artLayer${index + 1}';
		// Background.setPos rounds camera movement after applying the plane's
		// parallax scale. DrawableBackground applies that scale to placed objects
		// and text individually rather than scaling its stroke canvas.
		container.x = parallaxOffset(offsetX, layer.scale);
		container.y = parallaxOffset(offsetY, layer.scale);
		artLayerContainers[index] = container;
		// Brush strokes are rasterized onto this canvas, which sits beneath the
		// placed objects and text — the rasterCanvas/objCanvas split from
		// DrawableBackground. Drawing the strokes straight into the container's
		// vector graphics instead would make OpenFL's HTML5 backend rasterize the
		// whole (potentially level-spanning) layer into one offscreen texture.
		var rasterCanvas = new Sprite();
		container.addChild(rasterCanvas);
		if (incrementalBlocks) {
			totalArtItems += layer.drawActions.length + layer.objects.length + layer.texts.length;
			artDrawCursors[index] = new ArtDrawCursor(container, rasterCanvas, layer);
		} else {
			var brushCanvas = new Sprite();
			drawLayerStrokes(brushCanvas, layer.drawActions);
			rasterizeBrushInto(rasterCanvas, brushCanvas);
			drawLayerObjects(container, layer.objects, layer.scale);
			drawLayerTexts(container, layer.texts, layer.scale);
		}
		worldContainer.addChild(container);
	}

	private function drawNextArtItems(limit:Int):Void {
		var remaining = limit;
		while (remaining > 0 && drawnArtItems < totalArtItems) {
			while (nextArtLayerToDraw < artDrawCursors.length && artDrawCursors[nextArtLayerToDraw] == null) {
				nextArtLayerToDraw++;
			}
			if (nextArtLayerToDraw >= artDrawCursors.length) {
				return;
			}
			var cursor = artDrawCursors[nextArtLayerToDraw];
			if (cursor.drawNext()) {
				drawnArtItems++;
				remaining--;
			}
			if (cursor.isComplete()) {
				nextArtLayerToDraw++;
			}
		}
	}

	private function drawLayerStrokes(brushCanvas:Sprite, actions:Array<DecodedDrawAction>):Void {
		var color = 0x000000;
		var size = 10.0;
		var mode = "draw";
		var drawing = false;
		brushCanvas.graphics.lineStyle(size, color);

		for (action in actions) {
			var state = drawStrokeAction(brushCanvas, color, size, mode, action);
			color = state.color;
			size = state.size;
			mode = state.mode;
			if (action.kind == "d" && mode != "erase" && action.values.length >= 2) {
				drawing = true;
			}
		}
		if (!drawing) {
			brushCanvas.graphics.clear();
		}
	}

	/**
		Rasterizes the accumulated brush strokes onto transparent square tiles and
		attaches them to `rasterCanvas`, mirroring DrawableBackground.rasterizeTile
		(`new BitmapData(rasterTileSize + 1, rasterTileSize + 1, true, 0)`).

		The original tiles the brush canvas so no single bitmap is huge. The port
		needs the same split for a different but related reason: OpenFL's HTML5
		renderer rasterizes each display object's vector graphics into one offscreen
		texture sized to its bounds. Server art can span the whole level (>8192 px),
		exceeding the GPU's MAX_TEXTURE_SIZE; the upload then fails and the layer
		paints as an opaque black quad (the same failure documented for the login
		background's bg_front). Tiling keeps every texture under the limit, and the
		transparent fill (`true, 0`) lets the level show through between strokes.
	**/
	public static function rasterizeBrushInto(rasterCanvas:Sprite, brushCanvas:Sprite):Void {
		var bounds = brushCanvas.getBounds(brushCanvas);
		if (bounds.width <= 0 || bounds.height <= 0) {
			return;
		}
		var tile = ART_RASTER_TILE_SIZE;
		var tileY = Math.floor(bounds.y / tile) * tile;
		var endX = bounds.x + bounds.width;
		var endY = bounds.y + bounds.height;
		while (tileY < endY) {
			var tileX = Math.floor(bounds.x / tile) * tile;
			while (tileX < endX) {
				// +1 overlap between neighbouring tiles hides the seam, as in the original.
				var data = new BitmapData(tile + 1, tile + 1, true, 0);
				var matrix = new Matrix();
				matrix.translate(-tileX, -tileY);
				data.draw(brushCanvas, matrix, null, null, null, true);
				if (data.getColorBoundsRect(0xFF000000, 0x00000000, false).width == 0) {
					// No strokes landed on this tile; keep memory proportional to drawn art.
					data.dispose();
				} else {
					var bitmap = new Bitmap(data);
					bitmap.smoothing = true;
					bitmap.x = tileX;
					bitmap.y = tileY;
					rasterCanvas.addChild(bitmap);
				}
				tileX += tile;
			}
			tileY += tile;
		}
	}

	public static function drawStrokeAction(container:Sprite, color:Int, size:Float, mode:String, action:DecodedDrawAction):ArtStrokeState {
		switch (action.kind) {
			case "c":
				color = Std.int(action.values[0]);
				container.graphics.lineStyle(size, color);
			case "t":
				size = action.values[0];
				container.graphics.lineStyle(size, color);
			case "m":
				mode = action.text;
			case "d":
				if (mode != "erase" && action.values.length >= 2) {
					var x = action.values[0];
					var y = action.values[1];
					container.graphics.moveTo(x, y);
					container.graphics.lineTo(x - 0.15, y);
					container.graphics.moveTo(x, y);
					var i = 2;
					while (i + 1 < action.values.length) {
						x += action.values[i];
						y += action.values[i + 1];
						container.graphics.lineTo(x, y);
						i += 2;
					}
				}
			default:
		}
		return {color: color, size: size, mode: mode};
	}

	private function drawLayerObjects(container:Sprite, objects:Array<DecodedArtObject>, layerScale:Float):Void {
		for (object in objects) {
			addLayerObject(container, object, layerScale);
		}
	}

	private function drawLayerTexts(container:Sprite, texts:Array<DecodedTextObject>, layerScale:Float):Void {
		for (text in texts) {
			addLayerText(container, text, layerScale);
		}
	}

	public static function addLayerObject(container:Sprite, object:DecodedArtObject, layerScale:Float):Void {
		var assetPath = stampAssetPath(object.code);
		if (assetPath == "" || !Assets.exists(assetPath, AssetType.IMAGE)) {
			return;
		}
		var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
		bitmap.smoothing = true;
		bitmap.scaleX = object.scaleX * layerScale / 4;
		bitmap.scaleY = object.scaleY * layerScale / 4;
		bitmap.x = object.x * layerScale;
		bitmap.y = object.y * layerScale;
		container.addChild(bitmap);
	}

	public static function addLayerText(container:Sprite, text:DecodedTextObject, layerScale:Float):Void {
		var field = new TextField();
		field.selectable = false;
		field.wordWrap = false;
		field.multiline = true;
		field.autoSize = TextFieldAutoSize.LEFT;
		field.textColor = text.color;
		field.text = parseTextObjectText(text.text);
		field.scaleX = text.scaleX * layerScale;
		field.scaleY = text.scaleY * layerScale;
		field.height = 24;
		field.x = text.x * layerScale;
		field.y = text.y * layerScale;
		container.addChild(field);
	}

	private function createBlockDisplay(block:DecodedBlock):Sprite {
		var container = new Sprite();
		container.x = block.x;
		container.y = block.y;

		var assetPath = blockAssetPath(block.code);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = TILE_SIZE;
			bitmap.height = TILE_SIZE;
			container.addChild(bitmap);
		} else {
			drawFallbackBlock(container, block.code);
		}

		var arrowRotation = arrowOverlayRotation(block.code);
		if (arrowRotation != null) {
			var arrow = addArrowOverlay(container, arrowRotation);
			if (arrow != null) {
				arrowDisplays.set(blockKey(block.x, block.y), arrow);
			}
		}

		return container;
	}

	/**
		Adds the rotated arrow graphic over an arrow block, matching ArrowBlock,
		which places the ArrowBlockGraphic at the tile centre (15,15) and rotates
		it about that point.
	**/
	private static function addArrowOverlay(container:Sprite, rotation:Float):Null<PR2MovieClip> {
		var pivot = new Sprite();
		var arrow = PR2MovieClip.fromLinkage("ArrowBlockGraphic", {maxNestedDepth: 2});
		// ArrowBlockGraphic's generated AS3 class stops on frame 1. Reinstall that
		// class script here so gotoAndPlay runs the authored brighten/fade cycle
		// once and stops after wrapping back to the first frame.
		arrow.stop();
		arrow.setFrameScript(0, arrow.stop);
		arrow.gotoAndStop(1);
		pivot.addChild(arrow);
		pivot.x = TILE_SIZE / 2;
		pivot.y = TILE_SIZE / 2;
		pivot.rotation = rotation;
		container.addChild(pivot);
		return arrow;
	}

	private static function drawFallbackBlock(container:Sprite, code:Int):Void {
		var shape = new Shape();
		shape.graphics.beginFill(fallbackFill(code), 0.9);
		shape.graphics.drawRect(0, 0, TILE_SIZE, TILE_SIZE);
		shape.graphics.endFill();
		shape.graphics.lineStyle(1, 0x111111, 0.55);
		shape.graphics.drawRect(0.5, 0.5, TILE_SIZE - 1, TILE_SIZE - 1);
		container.addChild(shape);
	}

	private static function fallbackFill(code:Int):Int {
		return switch (code) {
			case ObjectCodes.BLOCK_ARROW_DOWN | ObjectCodes.BLOCK_ARROW_UP | ObjectCodes.BLOCK_ARROW_LEFT | ObjectCodes.BLOCK_ARROW_RIGHT: 0xD0D0D0;
			default: 0x888888;
		}
	}

	private static function firstRenderableBlock(level:ServerLevel):Null<DecodedBlock> {
		return level.blocks.length == 0 ? null : level.blocks[0];
	}

	private static function parseTextObjectText(value:String):String {
		return StringTools.replace(StringTools.replace(value, "|", ","), "<br>", "\n");
	}
}

typedef ArtStrokeState = {
	var color:Int;
	var size:Float;
	var mode:String;
}

private class ArtDrawCursor {
	public final container:Sprite;
	public final rasterCanvas:Sprite;
	public final brushCanvas:Sprite;
	public final layer:DecodedArtLayer;
	public var color:Int = 0x000000;
	public var size:Float = 10.0;
	public var mode:String = "draw";
	private var actionIndex:Int = 0;
	private var objectIndex:Int = 0;
	private var textIndex:Int = 0;
	private var rasterized:Bool = false;

	public function new(container:Sprite, rasterCanvas:Sprite, layer:DecodedArtLayer) {
		this.container = container;
		this.rasterCanvas = rasterCanvas;
		this.brushCanvas = new Sprite();
		this.layer = layer;
		brushCanvas.graphics.lineStyle(size, color);
	}

	public function drawNext():Bool {
		if (actionIndex < layer.drawActions.length) {
			var state = ServerLevelRenderer.drawStrokeAction(brushCanvas, color, size, mode, layer.drawActions[actionIndex++]);
			color = state.color;
			size = state.size;
			mode = state.mode;
			return true;
		}
		if (!rasterized) {
			// All strokes are in; bake them onto transparent tiles once the layer's
			// brush canvas is complete, before the objects/text layer on top of it.
			ServerLevelRenderer.rasterizeBrushInto(rasterCanvas, brushCanvas);
			rasterized = true;
		}
		if (objectIndex < layer.objects.length) {
			ServerLevelRenderer.addLayerObject(container, layer.objects[objectIndex++], layer.scale);
			return true;
		}
		if (textIndex < layer.texts.length) {
			ServerLevelRenderer.addLayerText(container, layer.texts[textIndex++], layer.scale);
			return true;
		}
		return false;
	}

	public function isComplete():Bool {
		return actionIndex >= layer.drawActions.length && objectIndex >= layer.objects.length && textIndex >= layer.texts.length;
	}
}

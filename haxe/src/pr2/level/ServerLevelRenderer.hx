package pr2.level;

import com.jiggmin.data.Objects;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import pr2.Constants;
import pr2.gameplay.PrizePopup;
import pr2.lobby.account.Settings;
import pr2.lobby.dialogs.MessagePopup;
import pr2.lobby.dialogs.Popup;
import pr2.level.ServerLevel.DecodedArtLayer;
import pr2.level.ServerLevel.DecodedArtObject;
import pr2.level.ServerLevel.DecodedBlock;
import pr2.level.ServerLevel.DecodedDrawAction;
import pr2.level.ServerLevel.DecodedTextObject;
import pr2.effects.BlockPiece;
import pr2.effects.MineAppear;
import pr2.effects.MineExplosion;
import pr2.effects.TeleportPop;
import pr2.runtime.PR2MovieClip;

typedef ArtRenderOptions = {
	@:optional var onArtWarning:String->Void;
	@:optional var suppressArtWarningPopup:Bool;
	@:optional var artDrawFaultInjector:Int->Void;
	@:optional var rasterTileLimit:Int;
	@:optional var editorWarning:Bool;
}

/**
	Renders the decoded server block layer in original PR2 pixel units.

	Server levels are stored around large editor coordinates (~10000 px). This
	renderer keeps the 30 px block scale and translates the world so a chosen
	focus point, usually the first start block, appears at a stable stage point.
**/
class ServerLevelRenderer extends Sprite {
	public static inline var TILE_SIZE:Int = 30;
	private static inline var TELEPORT_DEFAULT_COLOR:Int = 0xFF7F50;
	// Edge length of the transparent square that stroke art is rasterized onto,
	// mirroring DrawableBackground.rasterTileSize. Kept well under the WebGL
	// MAX_TEXTURE_SIZE (8192 on many GPUs, 4096 on some) so a single tile never
	// fails to upload. See rasterizeBrushInto.
	public static inline var ART_RASTER_TILE_SIZE:Int = 512;
	public static inline var DEFAULT_ART_RASTER_TILE_LIMIT:Int = 750;
	public static inline var DEFAULT_ART_BRUSH_SIZE:Float = 4.0;
	private static inline var ART_DRAW_ACTION_BATCH_LIMIT:Int = 8;
	public static inline var ART_DRAW_BATCH_MAX_TILE_COUNT:Int = 24;
	public static inline var ART_DRAW_BATCH_MAX_TILE_SPAN:Int = 2;
	private static inline var ART_DRAW_FRAME_BUDGET_SECONDS:Float = 0.008;
	private static inline var ART_DRAW_SLOW_PROFILE_MS:Float = 50.0;
	private static inline var RENDER_FRAME_ESCAPE_SECONDS:Float = 0.1;
	public static inline var ART_RASTER_VIEW_MARGIN_TILES:Int = 1;
	public static inline var ART_RASTER_VIEW_REBUILD_THRESHOLD:Int = 1;
	public static inline var ART_RASTER_ATTACH_TILES_PER_FRAME:Int = 1;
	public static inline var DEFAULT_FOCUS_X:Float = 180;
	public static inline var DEFAULT_FOCUS_Y:Float = 280;
	public static inline var DEFAULT_BLOCKS_PER_FRAME:Int = 50;
	public static inline var BG5_CODE:Int = 205;
	public static inline var ART_LOAD_WARNING_GAME:String = "Error: Some art didn't load correctly. Don't worry! You can still play the level.\n\nIf this persists, please contact a member of the PR2 staff team.";
	public static inline var ART_LOAD_WARNING_EDITOR:String = "Error: Some art didn't load correctly. This could be because there's too much art on your level. Saving the level now may cause permanent damage to its playability. Try undoing your recent changes until you don't get this error, and then saving your work.\n\nIf this persists, please contact a member of the PR2 staff team.";
	public static inline var ART_RASTER_STOP_WARNING:String = "Error: Some art didn't load correctly. Don't worry! You can still play the level.\n\nYou can prevent this in the future by enabling lossless art quality in the options menu.";
	private static inline var ICE_OVERLAY_NAME:String = "iceOverlay";
	private static inline var ART_RASTER_CANVAS_NAME:String = "artRasterCanvas";
	// View-window culling (mirrors Flash background.Background.updateViewWindow):
	// only blocks within VIEW_MARGIN_SEGMENTS of the visible stage are attached to
	// blockLayer. Without this the whole level (18k+ blocks on big maps) stays on
	// the display list, giving one WebGL draw call per block and ~3fps; Flash keeps
	// just the on-screen window attached and recycles blocks as the camera scrolls.
	public static inline var VIEW_MARGIN_SEGMENTS:Int = 2;
	// Only rebuild the window once the camera has scrolled this many segments, so a
	// slow pan does not churn addChild/removeChild every frame. Keep this no larger
	// than the margin, otherwise blocks can enter the visible stage before the
	// window refreshes and visibly pop in at the edge.
	public static inline var VIEW_REBUILD_THRESHOLD:Int = VIEW_MARGIN_SEGMENTS;

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
	private final artRasterTileLayers:Array<ArtRasterTiles> = [];
	private var solidBackground:Null<Shape>;
	private var currentBackgroundColor:Int;
	private var artBackgroundTintScale:Float = 1;
	private final artBackgroundChildren:Array<DisplayObject> = [];
	private var artCachingEnabled:Bool = true;
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
	private final moveArrowDisplays:Map<String, PR2MovieClip> = new Map();
	private final waterRippleFrames:Map<String, Int> = new Map();
	private final blockBounceVelocities:Map<String, Point> = new Map();
	private final artDrawCursors:Array<ArtDrawCursor> = [];
	private var nextBlockToDraw:Int = 0;
	private var nextArtLayerToDraw:Int = 0;
	private var drawnArtItems:Int = 0;
	private var totalArtItems:Int = 0;
	private var incrementalBlocks:Bool = false;
	private var blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME;
	private final drawArtEnabled:Bool;
	private final artOptions:Null<ArtRenderOptions>;
	private final artRasterBudget:ArtRasterBudget;
	private var attemptedArtItems:Int = 0;
	private var artLoadWarningShown:Bool = false;
	private var rasterStopNotified:Bool = false;
	private var artRasterAttachActive:Bool = false;
	public var artWarningMessage(default, null):Null<String>;
	public var stoppedRasterizing(default, null):Bool = false;
	public var artProfileLastMs(default, null):Float = 0;
	public var artProfileLastLayer(default, null):Int = -1;
	public var artProfileLastAction(default, null):Int = -1;
	public var artProfileLastKind(default, null):String = "";
	public var artProfileLastPath(default, null):String = "";
	public var artProfileLastMode(default, null):String = "";
	public var artProfileLastItems(default, null):Int = 0;
	public var artProfileLastValues(default, null):Int = 0;
	public var artProfileLastTiles(default, null):Int = 0;
	public var artProfileLastSpanX(default, null):Int = 0;
	public var artProfileLastSpanY(default, null):Int = 0;
	public var artProfileSlowCount(default, null):Int = 0;
	public var artProfileMaxMs(default, null):Float = 0;
	public var artProfileMaxLayer(default, null):Int = -1;
	public var artProfileMaxAction(default, null):Int = -1;
	public var artProfileMaxKind(default, null):String = "";
	public var artProfileMaxPath(default, null):String = "";
	public var artProfileMaxMode(default, null):String = "";
	public var artProfileMaxItems(default, null):Int = 0;
	public var artProfileMaxValues(default, null):Int = 0;
	public var artProfileMaxTiles(default, null):Int = 0;
	public var artProfileMaxSpanX(default, null):Int = 0;
	public var artProfileMaxSpanY(default, null):Int = 0;

	public function new(level:ServerLevel, ?focusBlock:DecodedBlock, focusScreenX:Float = DEFAULT_FOCUS_X, focusScreenY:Float = DEFAULT_FOCUS_Y,
			incrementalBlocks:Bool = false, blocksPerFrame:Int = DEFAULT_BLOCKS_PER_FRAME, ?artOptions:ArtRenderOptions) {
		super();
		this.level = level;
		this.incrementalBlocks = incrementalBlocks;
		this.blocksPerFrame = blocksPerFrame <= 0 ? DEFAULT_BLOCKS_PER_FRAME : blocksPerFrame;
		this.drawArtEnabled = Settings.getValue(Settings.DRAW_ART, true) != false;
		this.artOptions = artOptions;
		this.artRasterBudget = new ArtRasterBudget(artOptions != null && artOptions.rasterTileLimit != null ? artOptions.rasterTileLimit
			: DEFAULT_ART_RASTER_TILE_LIMIT, notifyRasterStopped);
		this.currentBackgroundColor = level.bgColor;

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
		applyBackgroundColorTransforms();
		setArtCaching(true);
		if (incrementalBlocks && totalArtItems > 0) {
			addEventListener(Event.ENTER_FRAME, drawArtBatch);
		}
	}

	public function isBlockDrawingComplete():Bool {
		return nextBlockToDraw >= level.blocks.length;
	}

	public static inline function isArtDrawBatchWithinLimits(tileCount:Int, tileSpanX:Int, tileSpanY:Int):Bool {
		return tileCount <= ART_DRAW_BATCH_MAX_TILE_COUNT && tileSpanX <= ART_DRAW_BATCH_MAX_TILE_SPAN && tileSpanY <= ART_DRAW_BATCH_MAX_TILE_SPAN;
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

	public function artProfileDebugState():String {
		if (artProfileLastAction < 0 && artProfileMaxAction < 0) {
			return "";
		}
		return ';artLastMs=${round1(artProfileLastMs)}'
			+ ';artLastLayer=$artProfileLastLayer'
			+ ';artLastAction=$artProfileLastAction'
			+ ';artLastKind=$artProfileLastKind'
			+ ';artLastPath=$artProfileLastPath'
			+ ';artLastMode=$artProfileLastMode'
			+ ';artLastItems=$artProfileLastItems'
			+ ';artLastValues=$artProfileLastValues'
			+ ';artLastTiles=$artProfileLastTiles'
			+ ';artLastSpan=${artProfileLastSpanX}x${artProfileLastSpanY}'
			+ ';artSlow=$artProfileSlowCount'
			+ ';artMaxMs=${round1(artProfileMaxMs)}'
			+ ';artMaxLayer=$artProfileMaxLayer'
			+ ';artMaxAction=$artProfileMaxAction'
			+ ';artMaxKind=$artProfileMaxKind'
			+ ';artMaxPath=$artProfileMaxPath'
			+ ';artMaxMode=$artProfileMaxMode'
			+ ';artMaxItems=$artProfileMaxItems'
			+ ';artMaxValues=$artProfileMaxValues'
			+ ';artMaxTiles=$artProfileMaxTiles'
			+ ';artMaxSpan=${artProfileMaxSpanX}x${artProfileMaxSpanY}';
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

	public function worldToCharacterLayer(x:Float, y:Float):Point {
		return new Point(x + offsetX, y + offsetY);
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
			updateArtViewWindows(true);
		}
		if (this.tweenRotation != tweenRotation) {
			this.tweenRotation = tweenRotation;
			applyTweenRotation();
			updateViewWindow(false);
			updateArtViewWindows(false);
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
			updateArtViewWindows(true);
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
		updateArtViewWindows(false);
	}

	/** Applies Flash `Course.setColor`/`Background.applyColorTransform` to rendered planes. */
	public function setBackgroundColor(color:Int):Void {
		currentBackgroundColor = color;
		redrawSolidBackground();
		applyBackgroundColorTransforms();
	}

	public function setArtCaching(enabled:Bool):Void {
		artCachingEnabled = enabled;
		for (container in artLayerContainers) {
			if (container == null) {
				continue;
			}
			for (i in 0...container.numChildren) {
				var child = container.getChildAt(i);
				if (child.name == ART_RASTER_CANVAS_NAME) {
					child.cacheAsBitmap = false;
				} else {
					child.cacheAsBitmap = enabled;
				}
			}
		}
	}

	public function debugArtCachingEnabled():Bool {
		return artCachingEnabled;
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

	public function setBlockIceOverlayAlpha(worldX:Int, worldY:Int, alpha:Float):Void {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		if (display == null) {
			return;
		}
		var overlay = display.getChildByName(ICE_OVERLAY_NAME);
		if (alpha <= 0) {
			if (overlay != null) {
				display.removeChild(overlay);
			}
			return;
		}
		if (overlay == null) {
			overlay = createIceOverlay();
			display.addChild(overlay);
		}
		overlay.alpha = alpha;
	}

	public function blockIceOverlayAlphaAt(worldX:Int, worldY:Int):Float {
		var display = blockDisplays.get(blockKey(worldX, worldY));
		var overlay = display == null ? null : display.getChildByName(ICE_OVERLAY_NAME);
		return overlay == null ? 0 : overlay.alpha;
	}

	public function blockIsBouncingAt(worldX:Int, worldY:Int):Bool {
		return blockBounceVelocities.exists(blockKey(worldX, worldY));
	}

	public function attachBackCharacterLayer(layer:Sprite):Void {
		if (layer.parent == worldContainer) {
			return;
		}
		// Flash keeps a swimming character in `backBackground`, the plane sitting
		// between the rear parallax art (bg1/bg2/bg3) and the block map. Insert the
		// back character layer just below the block layer inside the rotating world
		// so a character in water renders behind the blocks but still in front of
		// the background art. Placing it below `worldContainer` (as before) buried
		// it behind every background art layer, so it vanished in water on any
		// level with a drawn background (e.g. Underwater World).
		worldContainer.addChildAt(layer, worldContainer.getChildIndex(blockLayer));
	}

	// Test seam: depth of `child` within the rotating world container, or -1 when
	// it is not a direct child of it. Lets the shell test assert the back
	// character layer sits below the blocks (and thus above the background art).
	@:allow(pr2.gameplay.GameShellMountTest)
	private function worldChildDepth(child:openfl.display.DisplayObject):Int {
		return child.parent == worldContainer ? worldContainer.getChildIndex(child) : -1;
	}

	@:allow(pr2.gameplay.GameShellMountTest)
	private function blockLayerDepth():Int {
		return worldContainer.getChildIndex(blockLayer);
	}

	public function attachFrontCharacterLayer(layer:Sprite):Void {
		if (layer.parent == worldContainer) {
			return;
		}
		worldContainer.addChild(layer);
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

	public function animateBlockBump(worldX:Int, worldY:Int, hitX:Float = 0, hitY:Float = -15):Void {
		var key = blockKey(worldX, worldY);
		if (!blockDisplays.exists(key)) {
			return;
		}
		blockBounceVelocities.set(key, new Point(hitX, hitY));
		addEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
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

	public function removeBlockDisplay(worldX:Int, worldY:Int):Bool {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return false;
		}
		blockDisplays.remove(key);
		removeFromBlockGrid(worldX, worldY);
		arrowDisplays.remove(key);
		moveArrowDisplays.remove(key);
		blockBounceVelocities.remove(key);
		disposeAnimatedChildren(display);
		if (display.parent != null) {
			display.parent.removeChild(display);
		}
		return true;
	}

	public function moveBlockDisplay(fromWorldX:Int, fromWorldY:Int, toWorldX:Int, toWorldY:Int):Void {
		if (fromWorldX == toWorldX && fromWorldY == toWorldY) {
			return;
		}
		var fromKey = blockKey(fromWorldX, fromWorldY);
		var display = blockDisplays.get(fromKey);
		if (display == null) {
			return;
		}

		blockDisplays.remove(fromKey);
		removeFromBlockGrid(fromWorldX, fromWorldY);

		display.x = toWorldX;
		display.y = toWorldY;
		var toKey = blockKey(toWorldX, toWorldY);
		blockDisplays.set(toKey, display);
		var bounceVelocity = blockBounceVelocities.get(fromKey);
		if (bounceVelocity != null) {
			blockBounceVelocities.remove(fromKey);
			blockBounceVelocities.set(toKey, bounceVelocity);
		}
		var moveArrow = moveArrowDisplays.get(fromKey);
		if (moveArrow != null) {
			moveArrowDisplays.remove(fromKey);
			moveArrowDisplays.set(toKey, moveArrow);
		}
		addToBlockGrid(toWorldX, toWorldY, display);

		if (isInView(segmentOf(toWorldX), segmentOf(toWorldY))) {
			if (display.parent != blockLayer) {
				blockLayer.addChild(display);
			}
		} else if (display.parent == blockLayer) {
			blockLayer.removeChild(display);
		}
	}

	public function showMoveBlockArrow(worldX:Int, worldY:Int, direction:Int):Void {
		var key = blockKey(worldX, worldY);
		var display = blockDisplays.get(key);
		if (display == null) {
			return;
		}
		var arrow = moveArrowDisplays.get(key);
		if (arrow == null) {
			arrow = PR2MovieClip.fromLinkage("MoveArrow", {maxNestedDepth: 2});
			arrow.x = TILE_SIZE / 2;
			arrow.y = TILE_SIZE / 2;
			display.addChild(arrow);
			moveArrowDisplays.set(key, arrow);
		}
		arrow.rotation = moveBlockArrowRotation(direction);
	}

	public function hideMoveBlockArrow(worldX:Int, worldY:Int):Void {
		var key = blockKey(worldX, worldY);
		var arrow = moveArrowDisplays.get(key);
		if (arrow == null) {
			return;
		}
		if (arrow.parent != null) {
			arrow.parent.removeChild(arrow);
		}
		moveArrowDisplays.remove(key);
	}

	public function moveBlockArrowRotationAt(worldX:Int, worldY:Int):Null<Float> {
		var arrow = moveArrowDisplays.get(blockKey(worldX, worldY));
		return arrow == null ? null : arrow.rotation;
	}

	public function showMineExplosion(worldX:Float, worldY:Float, playSound:Bool = true):MineExplosion {
		var effect = new MineExplosion(worldX, worldY, offsetX, offsetY, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function showMineAppear(worldX:Float, worldY:Float, tileWorldX:Int, tileWorldY:Int, rotationDegrees:Float = 0, playSound:Bool = true):MineAppear {
		var effect = new MineAppear(worldX, worldY, rotationDegrees, offsetX, offsetY, function():Void {
			if (!blockDisplays.exists(blockKey(tileWorldX, tileWorldY))) {
				addBlockDisplay(new DecodedBlock(ObjectCodes.BLOCK_MINE, tileWorldX, tileWorldY));
			}
		}, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function showTeleportPop(worldX:Float, worldY:Float, playSound:Bool = true):TeleportPop {
		var effect = new TeleportPop(worldX, worldY, offsetX, offsetY, playSound);
		blockLayer.addChild(effect);
		return effect;
	}

	public function worldEffectLayer():DisplayObjectContainer {
		return blockLayer;
	}

	public function resetRuntimeState():Void {
		clearRuntimeEffects();
		setCourseRotation(0, 0);
		updateViewWindow(true);
	}

	public function teleportPopCountForTests():Int {
		var count = 0;
		for (i in 0...blockLayer.numChildren) {
			if (Std.isOfType(blockLayer.getChildAt(i), TeleportPop)) {
				count++;
			}
		}
		return count;
	}

	private function clearRuntimeEffects():Void {
		var i = blockLayer.numChildren - 1;
		while (i >= 0) {
			var child = blockLayer.getChildAt(i);
			if (Std.isOfType(child, TeleportPop)) {
				(cast child : TeleportPop).remove();
			} else if (Std.isOfType(child, MineExplosion)) {
				(cast child : MineExplosion).remove();
			} else if (Std.isOfType(child, MineAppear)) {
				(cast child : MineAppear).remove(false);
			} else if (Std.isOfType(child, BlockPiece)) {
				(cast child : BlockPiece).remove();
			}
			i--;
		}
	}

	public function showBlockPieces(linkage:String, worldX:Float, worldY:Float, count:Int, spreadX:Float, spreadY:Float,
			spreadRot:Float, gravity:Float = BlockPiece.GRAVITY, friction:Float = BlockPiece.FRICTION, fadeRate:Float = BlockPiece.FADE_RATE,
			?random:Void->Float):Array<BlockPiece> {
		var nextRandom = random == null ? Math.random : random;
		var pieces:Array<BlockPiece> = [];
		for (_ in 0...count) {
			var piece = new BlockPiece(linkage, gravity, friction, fadeRate, spreadX, spreadY, spreadRot, worldX + nextRandom() * TILE_SIZE,
				worldY + nextRandom() * TILE_SIZE, nextRandom);
			blockLayer.addChild(piece);
			pieces.push(piece);
		}
		return pieces;
	}

	private static inline function parallaxOffset(screenOffset:Float, scale:Float):Float {
		return Math.round(screenOffset * scale);
	}

	public static inline function isStartBlockCode(code:Int):Bool {
		return code >= ObjectCodes.BLOCK_START1 && code <= ObjectCodes.BLOCK_START4;
	}

	public static inline function isSpawnMarkerBlockCode(code:Int):Bool {
		return isStartBlockCode(code) || code == ObjectCodes.BLOCK_MINION_EGG;
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
		solidBackground = new Shape();
		redrawSolidBackground();
		addChild(solidBackground);
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
		drawNextBlocks(blocksPerFrame, Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS);
		if (isBlockDrawingComplete()) {
			removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		}
	}

	private function drawArtBatch(event:Event):Void {
		var deadline = Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS;
		try {
			drawNextArtItemsForFrame(deadline);
			if (Timer.stamp() < deadline) {
				attachArtRasterTiles(ART_RASTER_ATTACH_TILES_PER_FRAME, deadline);
			}
		} catch (error:Dynamic) {
			handleArtDrawFailure(error);
		}
		if (drawnArtItems >= totalArtItems) {
			removeEventListener(Event.ENTER_FRAME, drawArtBatch);
			finishArtRasterAttaching();
		}
	}

	private function drawNextArtItemsForFrame(escapeDeadline:Float):Void {
		var deadline = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME
			? Math.min(Timer.stamp() + ART_DRAW_FRAME_BUDGET_SECONDS, escapeDeadline)
			: escapeDeadline;
		var drawnThisFrame = 0;
		var actionBatchLimit = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME ? ART_DRAW_ACTION_BATCH_LIMIT : 1;
		var maxItemsThisFrame = blocksPerFrame == DEFAULT_BLOCKS_PER_FRAME ? 1000000 : blocksPerFrame;
		while (drawnArtItems < totalArtItems && drawnThisFrame < maxItemsThisFrame && (drawnThisFrame == 0 || Timer.stamp() < deadline)) {
			var before = drawnArtItems;
			drawNextArtItems(actionBatchLimit, deadline);
			if (drawnArtItems == before) {
				return;
			}
			drawnThisFrame += drawnArtItems - before;
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

	private function onBlockBounceFrame(event:Event):Void {
		for (key in [for (k in blockBounceVelocities.keys()) k]) {
			var display = blockDisplays.get(key);
			if (display == null) {
				blockBounceVelocities.remove(key);
				continue;
			}
			var velocity = blockBounceVelocities.get(key);
			velocity.x *= 0.5;
			velocity.y *= 0.5;
			var origin = blockOrigin(key);
			display.x += velocity.x;
			display.x += (origin.x - display.x) * 0.35;
			display.y += velocity.y;
			display.y += (origin.y - display.y) * 0.35;
			if (Math.abs(origin.y - display.y) < 0.25 && Math.abs(origin.y - display.x) < 0.25) {
				display.x = origin.x;
				display.y = origin.y;
				blockBounceVelocities.remove(key);
			}
		}
		if (!blockBounceVelocities.keys().hasNext()) {
			removeEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
		}
	}

	private function drawNextBlocks(limit:Int, ?deadline:Null<Float>):Void {
		var end = Std.int(Math.min(level.blocks.length, nextBlockToDraw + limit));
		var drawn = 0;
		while (nextBlockToDraw < end) {
			if (deadline != null && drawn > 0 && Timer.stamp() >= deadline) {
				break;
			}
			var block = level.blocks[nextBlockToDraw++];
			addBlockDisplay(block);
			drawn++;
		}
	}

	private function addBlockDisplay(block:DecodedBlock):Void {
		// Start and minion-egg blocks are spawn markers, not scenery. Flash's
		// gameplay Map records their positions and never adds them to the block
		// display list.
		if (isSpawnMarkerBlockCode(block.code)) {
			return;
		}
		var display = createBlockDisplay(block);
		blockDisplays.set(blockKey(block.x, block.y), display);
		addToBlockGrid(block.x, block.y, display);
		var segX = segmentOf(block.x);
		var segY = segmentOf(block.y);
		// Attach only if the block currently falls inside the view window; otherwise
		// it stays in the grid and is attached later when the camera scrolls to it.
		if (isInView(segX, segY)) {
			blockLayer.addChild(display);
		}
	}

	private function addToBlockGrid(worldX:Int, worldY:Int, display:Sprite):Void {
		var segX = segmentOf(worldX);
		var segY = segmentOf(worldY);
		var col = blockGrid.get(segX);
		if (col == null) {
			col = new Map();
			blockGrid.set(segX, col);
		}
		col.set(segY, display);
	}

	private function removeFromBlockGrid(worldX:Int, worldY:Int):Void {
		var segX = segmentOf(worldX);
		var segY = segmentOf(worldY);
		var col = blockGrid.get(segX);
		if (col == null) {
			return;
		}
		col.remove(segY);
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

	private function updateArtViewWindows(force:Bool):Void {
		for (tiles in artRasterTileLayers) {
			if (tiles != null) {
				updateArtViewWindow(tiles, force);
			}
		}
		if (drawnArtItems >= totalArtItems) {
			finishArtRasterAttaching();
		}
	}

	private function updateArtViewWindow(tiles:ArtRasterTiles, force:Bool):Void {
		var rasterCanvas = tiles.rasterCanvas;
		if (rasterCanvas.parent == null) {
			return;
		}
		var toLocal = rasterCanvas.transform.matrix.clone();
		toLocal.concat(rasterCanvas.parent.transform.matrix);
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
		var tile = ART_RASTER_TILE_SIZE;
		var margin = ART_RASTER_VIEW_MARGIN_TILES * tile;
		tiles.setVisibleTileWindow(
			artTileOrigin(Std.int(Math.floor(minX))) - margin,
			artTileOrigin(Std.int(Math.floor(maxX))) + margin,
			artTileOrigin(Std.int(Math.floor(minY))) - margin,
			artTileOrigin(Std.int(Math.floor(maxY))) + margin,
			force
		);
	}

	private static inline function intAbs(value:Int):Int {
		return value < 0 ? -value : value;
	}

	private static inline function round1(value:Float):Float {
		return Math.round(value * 10) / 10;
	}

	private static inline function artTileOrigin(pixel:Int):Int {
		var tile = ART_RASTER_TILE_SIZE;
		return Std.int(Math.floor(pixel / tile)) * tile;
	}

	public function remove():Void {
		removeEventListener(Event.ENTER_FRAME, drawBlockBatch);
		removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		removeEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		removeEventListener(Event.ENTER_FRAME, onWaterRippleFrame);
		removeEventListener(Event.ENTER_FRAME, onBlockBounceFrame);
		artRasterAttachActive = false;
		waterRippleFrames.clear();
		blockBounceVelocities.clear();
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
			var mineAppear = Std.downcast(child, MineAppear);
			if (mineAppear != null) {
				mineAppear.remove();
				i--;
				continue;
			}
			var blockPiece = Std.downcast(child, BlockPiece);
			if (blockPiece != null) {
				blockPiece.remove();
				i--;
				continue;
			}
			var arrowEffect = Std.downcast(child, pr2.effects.ArrowEffect);
			if (arrowEffect != null) {
				arrowEffect.remove();
				i--;
				continue;
			}
			var starEffect = Std.downcast(child, pr2.effects.StarEffect);
			if (starEffect != null) {
				starEffect.remove();
				i--;
				continue;
			}
			var physicsParticle = Std.downcast(child, pr2.character.PhysicsParticle);
			if (physicsParticle != null) {
				physicsParticle.remove();
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

	private static function blockOrigin(key:String):Point {
		var comma = key.indexOf(",");
		return new Point(Std.parseInt(key.substring(0, comma)), Std.parseInt(key.substring(comma + 1)));
	}

	private function drawArtBackground():Void {
		if (!drawArtEnabled) {
			return;
		}
		if (level.artBackgroundCode == null) {
			return;
		}
		var assetPath = artBackgroundAssetPath(level.artBackgroundCode);
		if (assetPath == "" || !Assets.exists(assetPath, AssetType.IMAGE)) {
			if (level.artBackgroundCode == BG5_CODE) {
				artBackgroundTintScale = 0;
				var grid = createBg5CircleGrid();
				addChild(grid);
				artBackgroundChildren.push(grid);
			}
			return;
		}

		var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
		bitmap.smoothing = true;
		bitmap.width = Constants.STAGE_WIDTH;
		bitmap.height = Constants.STAGE_HEIGHT;
		addChild(bitmap);
		artBackgroundChildren.push(bitmap);
		artBackgroundTintScale = level.artBackgroundCode == 204 || level.artBackgroundCode == BG5_CODE ? 0 : 1;
		if (level.artBackgroundCode == BG5_CODE) {
			var grid = createBg5CircleGrid();
			addChild(grid);
			artBackgroundChildren.push(grid);
		}
	}

	private function drawArtLayer(index:Int):Void {
		if (!drawArtEnabled) return;
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
		rasterCanvas.name = ART_RASTER_CANVAS_NAME;
		container.addChild(rasterCanvas);
		var strokeTiles = new ArtRasterTiles(rasterCanvas, artRasterBudget);
		artRasterTileLayers[index] = strokeTiles;
		if (incrementalBlocks) {
			totalArtItems += layer.drawActions.length + layer.objects.length + layer.texts.length;
			artDrawCursors[index] = new ArtDrawCursor(container, strokeTiles, layer);
		} else {
			try {
				strokeTiles.applyAll(layer.drawActions);
				drawLayerObjects(container, layer.objects, layer.scale);
				drawLayerTexts(container, layer.texts, layer.scale);
			} catch (error:Dynamic) {
				handleArtDrawFailure(error);
			}
		}
		worldContainer.addChild(container);
		updateArtViewWindow(strokeTiles, true);
		if (!incrementalBlocks) {
			strokeTiles.attachQueuedTiles(1000000);
		}
	}

	private function redrawSolidBackground():Void {
		if (solidBackground == null) {
			return;
		}
		solidBackground.graphics.clear();
		solidBackground.graphics.beginFill(currentBackgroundColor);
		solidBackground.graphics.drawRect(0, 0, Constants.STAGE_WIDTH, Constants.STAGE_HEIGHT);
		solidBackground.graphics.endFill();
	}

	private function applyBackgroundColorTransforms():Void {
		for (child in artBackgroundChildren) {
			child.transform.colorTransform = backgroundColorTransform(artBackgroundTintScale);
		}
		blockLayer.transform.colorTransform = backgroundColorTransform(1);
		for (i in 0...artLayerContainers.length) {
			var container = artLayerContainers[i];
			if (container != null && i < level.artLayers.length) {
				container.transform.colorTransform = backgroundColorTransform(level.artLayers[i].scale);
			}
		}
	}

	private function backgroundColorTransform(layerScale:Float):ColorTransform {
		var amount = ((1 - layerScale) * 0.4) + 0.1;
		var red = (currentBackgroundColor >> 16) & 0xFF;
		var green = (currentBackgroundColor >> 8) & 0xFF;
		var blue = currentBackgroundColor & 0xFF;
		return new ColorTransform(1 - amount, 1 - amount, 1 - amount, 1, red * amount, green * amount, blue * amount, 0);
	}

	public static function createBg5CircleGrid(?random:Void->Float):Sprite {
		var nextRandom = random == null ? Math.random : random;
		var grid = new Sprite();
		grid.name = "bg5CircleGrid";
		grid.mouseEnabled = false;
		grid.mouseChildren = false;
		var tileSize = 50;
		var cols = Std.int(Constants.STAGE_WIDTH / tileSize);
		var rows = Std.int(Constants.STAGE_HEIGHT / tileSize);
		for (col in 0...cols) {
			for (row in 0...rows) {
				var circle = new Shape();
				circle.graphics.beginFill(Std.int(nextRandom() * 0xFFFFFF));
				circle.graphics.drawCircle(0, 0, 12.5);
				circle.graphics.endFill();
				circle.x = col * tileSize + 20;
				circle.y = row * tileSize + 20;
				grid.addChild(circle);
			}
		}
		return grid;
	}

	private function drawNextArtItems(limit:Int, ?deadline:Null<Float>):Void {
		var remaining = limit;
		while (remaining > 0 && drawnArtItems < totalArtItems) {
			while (nextArtLayerToDraw < artDrawCursors.length && artDrawCursors[nextArtLayerToDraw] == null) {
				nextArtLayerToDraw++;
			}
			if (nextArtLayerToDraw >= artDrawCursors.length) {
				return;
			}
			var cursor = artDrawCursors[nextArtLayerToDraw];
			if (artOptions != null && artOptions.artDrawFaultInjector != null) {
				artOptions.artDrawFaultInjector(attemptedArtItems);
			}
			var started = Timer.stamp();
			var drawn = cursor.drawNext(artOptions != null && artOptions.artDrawFaultInjector != null ? 1 : remaining, deadline);
			recordArtDrawProfile(cursor, nextArtLayerToDraw, drawn, (Timer.stamp() - started) * 1000);
			if (drawn > 0) {
				attemptedArtItems += drawn;
				drawnArtItems += drawn;
				remaining -= drawn;
			}
			if (cursor.isComplete()) {
				nextArtLayerToDraw++;
			}
			if (deadline != null && Timer.stamp() >= deadline) {
				return;
			}
		}
	}

	private function recordArtDrawProfile(cursor:ArtDrawCursor, layerIndex:Int, drawn:Int, elapsedMs:Float):Void {
		artProfileLastMs = cursor.lastProfileMs > 0 ? cursor.lastProfileMs : elapsedMs;
		artProfileLastLayer = layerIndex;
		artProfileLastAction = cursor.lastProfileActionIndex;
		artProfileLastKind = cursor.lastProfileKind;
		artProfileLastPath = cursor.lastProfilePath;
		artProfileLastMode = cursor.lastProfileMode;
		artProfileLastItems = drawn;
		artProfileLastValues = cursor.lastProfileValueCount;
		artProfileLastTiles = cursor.lastProfileTileCount;
		artProfileLastSpanX = cursor.lastProfileTileSpanX;
		artProfileLastSpanY = cursor.lastProfileTileSpanY;
		if (elapsedMs >= ART_DRAW_SLOW_PROFILE_MS) {
			artProfileSlowCount++;
		}
		if (elapsedMs > artProfileMaxMs) {
			artProfileMaxMs = elapsedMs;
			artProfileMaxLayer = artProfileLastLayer;
			artProfileMaxAction = artProfileLastAction;
			artProfileMaxKind = artProfileLastKind;
			artProfileMaxPath = artProfileLastPath;
			artProfileMaxMode = artProfileLastMode;
			artProfileMaxItems = artProfileLastItems;
			artProfileMaxValues = artProfileLastValues;
			artProfileMaxTiles = artProfileLastTiles;
			artProfileMaxSpanX = artProfileLastSpanX;
			artProfileMaxSpanY = artProfileLastSpanY;
		}
	}

	private function handleArtDrawFailure(error:Dynamic):Void {
		if (!artLoadWarningShown) {
			artLoadWarningShown = true;
			emitArtWarning(artOptions != null && artOptions.editorWarning == true ? ART_LOAD_WARNING_EDITOR : ART_LOAD_WARNING_GAME, true);
		}
		finishArtDrawingAfterFailure();
	}

	private function finishArtDrawingAfterFailure():Void {
		drawnArtItems = totalArtItems;
		nextArtLayerToDraw = artDrawCursors.length;
		removeEventListener(Event.ENTER_FRAME, drawArtBatch);
		finishArtRasterAttaching();
	}

	private function finishArtRasterAttaching():Void {
		if (hasQueuedVisibleArtRasterTiles() && !artRasterAttachActive) {
			artRasterAttachActive = true;
			addEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		}
	}

	private function onArtRasterAttachFrame(event:Event):Void {
		attachArtRasterTiles(ART_RASTER_ATTACH_TILES_PER_FRAME, Timer.stamp() + RENDER_FRAME_ESCAPE_SECONDS);
		if (!hasQueuedVisibleArtRasterTiles()) {
			artRasterAttachActive = false;
			removeEventListener(Event.ENTER_FRAME, onArtRasterAttachFrame);
		}
	}

	private function attachArtRasterTiles(limit:Int, ?deadline:Null<Float>):Int {
		var remaining = limit;
		for (tiles in artRasterTileLayers) {
			if (remaining <= 0) {
				break;
			}
			if (deadline != null && remaining < limit && Timer.stamp() >= deadline) {
				break;
			}
			if (tiles != null) {
				remaining -= tiles.attachQueuedTiles(remaining);
			}
		}
		return limit - remaining;
	}

	private function hasQueuedVisibleArtRasterTiles():Bool {
		for (tiles in artRasterTileLayers) {
			if (tiles != null && tiles.hasQueuedVisibleTiles()) {
				return true;
			}
		}
		return false;
	}

	private function notifyRasterStopped():Void {
		stoppedRasterizing = true;
		if (!rasterStopNotified) {
			rasterStopNotified = true;
			emitArtWarning(ART_RASTER_STOP_WARNING, false);
		}
	}

	private function emitArtWarning(message:String, gatePopup:Bool):Void {
		artWarningMessage = message;
		if (artOptions != null && artOptions.onArtWarning != null) {
			artOptions.onArtWarning(message);
			return;
		}
		if (artOptions != null && artOptions.suppressArtWarningPopup == true) {
			return;
		}
		if (!gatePopup || canOpenArtWarningPopup()) {
			new MessagePopup(message);
		}
	}

	private static function canOpenArtWarningPopup():Bool {
		var open = Popup.getOpen();
		return open.length == 0 || (open.length == 1 && Std.isOfType(open[0], PrizePopup));
	}

	public static function drawLayerStrokes(brushCanvas:Sprite, actions:Array<DecodedDrawAction>):Void {
		var color = 0x000000;
		var size = DEFAULT_ART_BRUSH_SIZE;
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

	public static function renderLayerStrokes(rasterCanvas:Sprite, actions:Array<DecodedDrawAction>, ?budget:ArtRasterBudget):Void {
		var tiles = new ArtRasterTiles(rasterCanvas, budget);
		tiles.applyAll(actions);
		tiles.attachQueuedTiles(1000000);
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
		var display = Objects.getFromCode(object.code);
		if (display == null) {
			return;
		}
		display.scaleX = object.scaleX * layerScale;
		display.scaleY = object.scaleY * layerScale;
		display.x = object.x * layerScale;
		display.y = object.y * layerScale;
		container.addChild(display);
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

		if (block.code == ObjectCodes.BLOCK_TELEPORT) {
			var background = new Shape();
			background.graphics.beginFill(teleportBlockColor(block.opts));
			background.graphics.drawRect(0, 0, TILE_SIZE, TILE_SIZE);
			background.graphics.endFill();
			container.addChild(background);
		}

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

	private static function teleportBlockColor(options:String):Int {
		var parsed = Std.parseInt(options);
		return parsed == null ? TELEPORT_DEFAULT_COLOR : parsed;
	}

	private function createIceOverlay():Sprite {
		var overlay = new Sprite();
		overlay.name = ICE_OVERLAY_NAME;
		var assetPath = blockAssetPath(ObjectCodes.BLOCK_ICE);
		if (assetPath != "" && Assets.exists(assetPath, AssetType.IMAGE)) {
			var bitmap = new Bitmap(Assets.getBitmapData(assetPath));
			bitmap.smoothing = false;
			bitmap.width = TILE_SIZE;
			bitmap.height = TILE_SIZE;
			overlay.addChild(bitmap);
		} else {
			drawFallbackBlock(overlay, ObjectCodes.BLOCK_ICE);
		}
		return overlay;
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

	private static function moveBlockArrowRotation(direction:Int):Float {
		return switch (direction) {
			case 3: 270;
			case 2: 90;
			case 1: 0;
			case 0: 180;
			default: 0;
		}
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
	public final layer:DecodedArtLayer;
	public var lastProfileActionIndex(default, null):Int = -1;
	public var lastProfileKind(default, null):String = "";
	public var lastProfilePath(default, null):String = "";
	public var lastProfileMode(default, null):String = "";
	public var lastProfileValueCount(default, null):Int = 0;
	public var lastProfileTileCount(default, null):Int = 0;
	public var lastProfileTileSpanX(default, null):Int = 0;
	public var lastProfileTileSpanY(default, null):Int = 0;
	public var lastProfileMs(default, null):Float = 0;
	private final strokeTiles:ArtRasterTiles;
	private var actionIndex:Int = 0;
	private var objectIndex:Int = 0;
	private var textIndex:Int = 0;

	public function new(container:Sprite, strokeTiles:ArtRasterTiles, layer:DecodedArtLayer) {
		this.container = container;
		this.rasterCanvas = strokeTiles.rasterCanvas;
		this.layer = layer;
		this.strokeTiles = strokeTiles;
	}

	public function drawNext(maxActions:Int = 1, ?deadline:Null<Float>):Int {
		lastProfileMs = 0;
		if (actionIndex < layer.drawActions.length) {
			var drawn = 0;
			var batchDrawStrokes = maxActions > 1;
			while (drawn < maxActions && actionIndex < layer.drawActions.length) {
				var currentActionIndex = actionIndex;
				var action = layer.drawActions[actionIndex];
				var actionStarted = Timer.stamp();
				var complete = true;
				complete = strokeTiles.apply(action, batchDrawStrokes, deadline);
				var actionMs = (Timer.stamp() - actionStarted) * 1000;
				if (actionMs >= lastProfileMs) {
					copyStrokeProfile(action, currentActionIndex, actionMs);
				}
				if (!complete) {
					break;
				}
				actionIndex++;
				drawn++;
				if (deadline != null && drawn > 0 && Timer.stamp() >= deadline) {
					break;
				}
			}
			if (batchDrawStrokes && !strokeTiles.hasPendingRasterWork()) {
				var flushStarted = Timer.stamp();
				strokeTiles.flush();
				var flushMs = (Timer.stamp() - flushStarted) * 1000;
				if (flushMs > lastProfileMs) {
					copyFlushProfile(actionIndex - 1, flushMs);
				}
			}
			return drawn;
		}
		var flushStarted = Timer.stamp();
		strokeTiles.flush();
		var flushMs = (Timer.stamp() - flushStarted) * 1000;
		if (flushMs > lastProfileMs) {
			copyFlushProfile(actionIndex - 1, flushMs);
		}
		if (objectIndex < layer.objects.length) {
			var objectStarted = Timer.stamp();
			ServerLevelRenderer.addLayerObject(container, layer.objects[objectIndex++], layer.scale);
			lastProfileMs = (Timer.stamp() - objectStarted) * 1000;
			lastProfileActionIndex = objectIndex - 1;
			lastProfileKind = "object";
			lastProfilePath = "object";
			lastProfileMode = "";
			lastProfileValueCount = 0;
			lastProfileTileCount = 0;
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return 1;
		}
		if (textIndex < layer.texts.length) {
			var textStarted = Timer.stamp();
			ServerLevelRenderer.addLayerText(container, layer.texts[textIndex++], layer.scale);
			lastProfileMs = (Timer.stamp() - textStarted) * 1000;
			lastProfileActionIndex = textIndex - 1;
			lastProfileKind = "text";
			lastProfilePath = "text";
			lastProfileMode = "";
			lastProfileValueCount = 0;
			lastProfileTileCount = 0;
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return 1;
		}
		return 0;
	}

	private function copyStrokeProfile(action:DecodedDrawAction, actionIndex:Int, elapsedMs:Float):Void {
		lastProfileMs = elapsedMs;
		lastProfileActionIndex = actionIndex;
		lastProfileKind = action.kind;
		lastProfilePath = strokeTiles.lastProfilePath;
		lastProfileMode = strokeTiles.lastProfileMode;
		lastProfileValueCount = action.values.length;
		lastProfileTileCount = strokeTiles.lastProfileTileCount;
		lastProfileTileSpanX = strokeTiles.lastProfileTileSpanX;
		lastProfileTileSpanY = strokeTiles.lastProfileTileSpanY;
	}

	private function copyFlushProfile(actionIndex:Int, elapsedMs:Float):Void {
		lastProfileMs = elapsedMs;
		lastProfileActionIndex = actionIndex;
		lastProfileKind = "flush";
		lastProfilePath = strokeTiles.lastProfilePath;
		lastProfileMode = strokeTiles.lastProfileMode;
		lastProfileValueCount = 0;
		lastProfileTileCount = strokeTiles.lastProfileTileCount;
		lastProfileTileSpanX = strokeTiles.lastProfileTileSpanX;
		lastProfileTileSpanY = strokeTiles.lastProfileTileSpanY;
	}

	public function isComplete():Bool {
		return actionIndex >= layer.drawActions.length && objectIndex >= layer.objects.length && textIndex >= layer.texts.length;
	}
}

private class ArtStrokeTileSet {
	public final keys:Array<String> = [];
	public final tileXs:Array<Int> = [];
	public final tileYs:Array<Int> = [];
	public final seen:Map<String, Bool> = new Map();
	public var minTileX:Int = 0;
	public var maxTileX:Int = 0;
	public var minTileY:Int = 0;
	public var maxTileY:Int = 0;

	public function new() {}

	public function add(key:String, tileX:Int, tileY:Int):Void {
		if (seen.exists(key)) {
			return;
		}
		seen.set(key, true);
		keys.push(key);
		tileXs.push(tileX);
		tileYs.push(tileY);
		if (keys.length == 1) {
			minTileX = maxTileX = tileX;
			minTileY = maxTileY = tileY;
			return;
		}
		if (tileX < minTileX) minTileX = tileX;
		if (tileX > maxTileX) maxTileX = tileX;
		if (tileY < minTileY) minTileY = tileY;
		if (tileY > maxTileY) maxTileY = tileY;
	}

	public function tileSpanX():Int {
		if (keys.length == 0) {
			return 0;
		}
		return Std.int((maxTileX - minTileX) / ServerLevelRenderer.ART_RASTER_TILE_SIZE) + 1;
	}

	public function tileSpanY():Int {
		if (keys.length == 0) {
			return 0;
		}
		return Std.int((maxTileY - minTileY) / ServerLevelRenderer.ART_RASTER_TILE_SIZE) + 1;
	}
}

class ArtRasterBudget {
	public final limit:Int;
	public var tileCount(default, null):Int = 0;
	public var stopped(default, null):Bool = false;
	private final onStopped:Void->Void;

	public function new(limit:Int, onStopped:Void->Void) {
		this.limit = limit;
		this.onStopped = onStopped;
	}

	public function reserveTile():Bool {
		if (limit < 0) {
			tileCount++;
			return true;
		}
		if (tileCount >= limit) {
			if (!stopped) {
				stopped = true;
				onStopped();
			}
			return false;
		}
		tileCount++;
		return true;
	}
}

private class LargeStrokeRasterOperation {
	public final shape:Shape;
	public final strokeTiles:ArtStrokeTileSet;
	public final bounds:Rectangle;
	public final erase:Bool;
	public final profilePath:String;
	public final profileMode:String;
	public var tileIndex:Int = 0;

	public function new(shape:Shape, strokeTiles:ArtStrokeTileSet, bounds:Rectangle, erase:Bool, profilePath:String, profileMode:String) {
		this.shape = shape;
		this.strokeTiles = strokeTiles;
		this.bounds = bounds;
		this.erase = erase;
		this.profilePath = profilePath;
		this.profileMode = profileMode;
	}
}

private class ArtRasterTiles {
	public final rasterCanvas:Sprite;
	public var lastProfilePath(default, null):String = "";
	public var lastProfileMode(default, null):String = "";
	public var lastProfileTileCount(default, null):Int = 0;
	public var lastProfileTileSpanX(default, null):Int = 0;
	public var lastProfileTileSpanY(default, null):Int = 0;
	private final budget:Null<ArtRasterBudget>;
	private final tiles:Map<String, Bitmap> = new Map();
	private var attachQueue:Array<String> = [];
	private var attachQueueSeen:Map<String, Bool> = new Map();
	private var pendingShape:Null<Shape>;
	private var pendingErase:Bool = false;
	private var pendingBounds:Null<Rectangle>;
	private var pendingTileKeys:Array<String> = [];
	private var pendingTileKeySeen:Map<String, Bool> = new Map();
	private var pendingTileXs:Array<Int> = [];
	private var pendingTileYs:Array<Int> = [];
	private var pendingMinTileX:Int = 0;
	private var pendingMaxTileX:Int = 0;
	private var pendingMinTileY:Int = 0;
	private var pendingMaxTileY:Int = 0;
	private var pendingLargeStroke:Null<LargeStrokeRasterOperation>;
	private var viewInitialized:Bool = false;
	private var viewMinTileX:Int = 0;
	private var viewMaxTileX:Int = 0;
	private var viewMinTileY:Int = 0;
	private var viewMaxTileY:Int = 0;
	private var color:Int = 0x000000;
	private var size:Float = ServerLevelRenderer.DEFAULT_ART_BRUSH_SIZE;
	private var mode:String = "draw";

	public function new(rasterCanvas:Sprite, ?budget:ArtRasterBudget) {
		this.rasterCanvas = rasterCanvas;
		this.budget = budget;
	}

	public function applyAll(actions:Array<DecodedDrawAction>):Void {
		for (action in actions) {
			while (!apply(action, true)) {}
		}
		flush();
	}

	public function apply(action:DecodedDrawAction, batch:Bool = false, ?deadline:Null<Float>):Bool {
		if (pendingLargeStroke != null) {
			return continueLargeStroke(deadline);
		}
		switch (action.kind) {
			case "c":
				color = Std.int(action.values[0]);
				setControlProfile("color");
			case "t":
				size = action.values[0];
				setControlProfile("size");
			case "m":
				if (batch && mode != action.text) {
					flush();
				}
				mode = action.text;
				setControlProfile("mode");
			case "d":
				if (action.values.length >= 2) {
					var complete = mode == "erase" ? addEraseStrokeToBatch(action, deadline) : addDrawStrokeToBatch(action, deadline);
					if (!batch && complete && !hasPendingRasterWork()) {
						flush();
					}
					return complete;
				}
			default:
				setControlProfile("unknown");
		}
		return true;
	}

	public function flush():Void {
		if (pendingShape == null) {
			setControlProfile("flush");
			return;
		}
		setPendingFlushProfile(pendingErase ? "eraseFlush" : "flush");
		var shape = pendingShape;
		var matrix = new Matrix();
		if (pendingErase) {
			flushEraseShape(shape, matrix);
		} else {
			for (i in 0...pendingTileKeys.length) {
				var bitmap = getOrCreateTile(pendingTileXs[i], pendingTileYs[i]);
				if (bitmap == null) {
					continue;
				}
				matrix.identity();
				matrix.translate(-pendingTileXs[i], -pendingTileYs[i]);
				bitmap.bitmapData.draw(shape, matrix, null, null, null, true);
				queueTileAttach(pendingTileKeys[i]);
			}
		}
		resetPendingBatch();
	}

	private function flushEraseShape(shape:Shape, matrix:Matrix):Void {
		if (pendingBounds == null) {
			return;
		}
		var tileSize = ServerLevelRenderer.ART_RASTER_TILE_SIZE + 1;
		for (i in 0...pendingTileKeys.length) {
			var bitmap = tiles.get(pendingTileKeys[i]);
			if (bitmap == null) {
				continue;
			}
			var tileX = pendingTileXs[i];
			var tileY = pendingTileYs[i];
			var rectX = Std.int(Math.max(0, Math.floor(pendingBounds.x - tileX)));
			var rectY = Std.int(Math.max(0, Math.floor(pendingBounds.y - tileY)));
			var rectRight = Std.int(Math.min(tileSize, Math.ceil(pendingBounds.right - tileX)));
			var rectBottom = Std.int(Math.min(tileSize, Math.ceil(pendingBounds.bottom - tileY)));
			if (rectRight <= rectX || rectBottom <= rectY) {
				continue;
			}
			var targetRect = new Rectangle(rectX, rectY, rectRight - rectX, rectBottom - rectY);
			var mask = new BitmapData(Std.int(targetRect.width), Std.int(targetRect.height), true, 0);
			matrix.identity();
			matrix.translate(-(tileX + rectX), -(tileY + rectY));
			mask.draw(shape, matrix, null, null, null, true);
			clearMaskedPixels(bitmap.bitmapData, targetRect, mask);
			mask.dispose();
			queueTileAttach(pendingTileKeys[i]);
		}
	}

	private function resetPendingBatch():Void {
		pendingShape = null;
		pendingErase = false;
		pendingBounds = null;
		pendingTileKeys = [];
		pendingTileKeySeen = new Map();
		pendingTileXs = [];
		pendingTileYs = [];
		pendingMinTileX = pendingMaxTileX = pendingMinTileY = pendingMaxTileY = 0;
	}

	public function setVisibleTileWindow(minTileX:Int, maxTileX:Int, minTileY:Int, maxTileY:Int, force:Bool):Void {
		var threshold = ServerLevelRenderer.ART_RASTER_VIEW_REBUILD_THRESHOLD * ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		if (!force
			&& viewInitialized
			&& intAbs(minTileX - viewMinTileX) <= threshold
			&& intAbs(maxTileX - viewMaxTileX) <= threshold
			&& intAbs(minTileY - viewMinTileY) <= threshold
			&& intAbs(maxTileY - viewMaxTileY) <= threshold) {
			return;
		}
		viewMinTileX = minTileX;
		viewMaxTileX = maxTileX;
		viewMinTileY = minTileY;
		viewMaxTileY = maxTileY;
		viewInitialized = true;
		for (key in tiles.keys()) {
			var bitmap = tiles.get(key);
			if (bitmap == null) {
				continue;
			}
			if (isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				queueTileAttach(key);
			} else {
				setTileAttached(bitmap, false);
			}
		}
	}

	public function attachQueuedTiles(limit:Int):Int {
		if (limit <= 0 || attachQueue.length == 0) {
			return 0;
		}
		var attached = 0;
		var remainingKeys:Array<String> = [];
		var remainingSeen:Map<String, Bool> = new Map();
		for (key in attachQueue) {
			var bitmap = tiles.get(key);
			if (bitmap == null) {
				continue;
			}
			if (!isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				setTileAttached(bitmap, false);
				continue;
			}
			if (bitmap.parent == rasterCanvas) {
				continue;
			}
			if (attached < limit) {
				setTileAttached(bitmap, true);
				attached++;
			} else if (!remainingSeen.exists(key)) {
				remainingSeen.set(key, true);
				remainingKeys.push(key);
			}
		}
		attachQueue = remainingKeys;
		attachQueueSeen = remainingSeen;
		return attached;
	}

	public function hasQueuedVisibleTiles():Bool {
		for (key in attachQueue) {
			var bitmap = tiles.get(key);
			if (bitmap != null && bitmap.parent != rasterCanvas && isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
				return true;
			}
		}
		return false;
	}

	public function hasPendingRasterWork():Bool {
		return pendingLargeStroke != null;
	}

	private function getOrCreateTile(tileX:Int, tileY:Int):Null<Bitmap> {
		var key = tileKey(tileX, tileY);
		var bitmap = tiles.get(key);
		if (bitmap != null) {
			return bitmap;
		}
		if (budget != null && !budget.reserveTile()) {
			return null;
		}
		bitmap = new Bitmap(new BitmapData(ServerLevelRenderer.ART_RASTER_TILE_SIZE + 1, ServerLevelRenderer.ART_RASTER_TILE_SIZE + 1, true, 0));
		bitmap.smoothing = true;
		bitmap.x = tileX;
		bitmap.y = tileY;
		tiles.set(key, bitmap);
		queueTileAttach(key);
		return bitmap;
	}

	private function isTileVisible(tileX:Int, tileY:Int):Bool {
		return !viewInitialized || (tileX >= viewMinTileX && tileX <= viewMaxTileX && tileY >= viewMinTileY && tileY <= viewMaxTileY);
	}

	private function setTileAttached(bitmap:Bitmap, attach:Bool):Void {
		if (attach) {
			if (bitmap.parent != rasterCanvas) {
				rasterCanvas.addChild(bitmap);
			}
		} else if (bitmap.parent == rasterCanvas) {
			rasterCanvas.removeChild(bitmap);
		}
	}

	private function queueTileAttach(key:String):Void {
		if (attachQueueSeen.exists(key)) {
			return;
		}
		var bitmap = tiles.get(key);
		if (bitmap == null || bitmap.parent == rasterCanvas || !isTileVisible(Std.int(bitmap.x), Std.int(bitmap.y))) {
			return;
		}
		attachQueueSeen.set(key, true);
		attachQueue.push(key);
	}

	private static inline function intAbs(value:Int):Int {
		return value < 0 ? -value : value;
	}

	private function startLargeStroke(action:DecodedDrawAction, erase:Bool, profilePath:String, ?deadline:Null<Float>):Bool {
		flush();
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTilesForErase(action, radius);
		if (strokeTiles.keys.length == 0) {
			setEstimatedStrokeProfile(action, profilePath);
			return true;
		}
		var shape = strokeShape(action, erase ? 0xFFFFFF : color);
		var bounds = strokeBounds(action, radius);
		pendingLargeStroke = new LargeStrokeRasterOperation(shape, strokeTiles, bounds, erase, profilePath, mode);
		return continueLargeStroke(deadline);
	}

	private function continueLargeStroke(?deadline:Null<Float>):Bool {
		var op = pendingLargeStroke;
		if (op == null) {
			return true;
		}
		setLargeStrokeProfile(op);
		var matrix = new Matrix();
		var processed = 0;
		while (op.tileIndex < op.strokeTiles.keys.length && (processed == 0 || deadline == null || Timer.stamp() < deadline)) {
			if (op.erase) {
				eraseLargeStrokeTile(op, matrix);
			} else {
				drawLargeStrokeTile(op, matrix);
			}
			op.tileIndex++;
			processed++;
		}
		if (op.tileIndex >= op.strokeTiles.keys.length) {
			pendingLargeStroke = null;
			return true;
		}
		return false;
	}

	private function drawLargeStrokeTile(op:LargeStrokeRasterOperation, matrix:Matrix):Void {
		var tileX = op.strokeTiles.tileXs[op.tileIndex];
		var tileY = op.strokeTiles.tileYs[op.tileIndex];
		var bitmap = getOrCreateTile(tileX, tileY);
		if (bitmap == null) {
			return;
		}
		matrix.identity();
		matrix.translate(-tileX, -tileY);
		bitmap.bitmapData.draw(op.shape, matrix, null, null, null, true);
		queueTileAttach(op.strokeTiles.keys[op.tileIndex]);
	}

	private function eraseLargeStrokeTile(op:LargeStrokeRasterOperation, matrix:Matrix):Void {
		var key = op.strokeTiles.keys[op.tileIndex];
		var bitmap = tiles.get(key);
		if (bitmap == null) {
			return;
		}
		var tileX = op.strokeTiles.tileXs[op.tileIndex];
		var tileY = op.strokeTiles.tileYs[op.tileIndex];
		var tileSize = ServerLevelRenderer.ART_RASTER_TILE_SIZE + 1;
		var rectX = Std.int(Math.max(0, Math.floor(op.bounds.x - tileX)));
		var rectY = Std.int(Math.max(0, Math.floor(op.bounds.y - tileY)));
		var rectRight = Std.int(Math.min(tileSize, Math.ceil(op.bounds.right - tileX)));
		var rectBottom = Std.int(Math.min(tileSize, Math.ceil(op.bounds.bottom - tileY)));
		if (rectRight <= rectX || rectBottom <= rectY) {
			return;
		}
		var targetRect = new Rectangle(rectX, rectY, rectRight - rectX, rectBottom - rectY);
		var mask = new BitmapData(Std.int(targetRect.width), Std.int(targetRect.height), true, 0);
		matrix.identity();
		matrix.translate(-(tileX + rectX), -(tileY + rectY));
		mask.draw(op.shape, matrix, null, null, null, true);
		clearMaskedPixels(bitmap.bitmapData, targetRect, mask);
		mask.dispose();
		queueTileAttach(key);
	}

	private function clearMaskedPixels(target:BitmapData, targetRect:Rectangle, mask:BitmapData):Void {
		var maskPixels = mask.getPixels(mask.rect);
		if (maskPixels == null) {
			return;
		}
		var width = Std.int(targetRect.width);
		var height = Std.int(targetRect.height);
		var targetX = Std.int(targetRect.x);
		var targetY = Std.int(targetRect.y);
		maskPixels.position = 0;
		target.lock();
		for (y in 0...height) {
			for (x in 0...width) {
				if (maskPixels.readUnsignedInt() != 0) {
					target.setPixel32(targetX + x, targetY + y, 0);
				}
			}
		}
		target.unlock(targetRect);
	}

	private function strokeShape(action:DecodedDrawAction, strokeColor:Int):Shape {
		var shape = new Shape();
		var graphics = shape.graphics;
		graphics.lineStyle(size, strokeColor);
		var x = action.values[0];
		var y = action.values[1];
		graphics.moveTo(x, y);
		graphics.lineTo(x - 0.15, y);
		graphics.moveTo(x, y);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			graphics.lineTo(nextX, nextY);
			x = nextX;
			y = nextY;
			i += 2;
		}
		return shape;
	}

	private function strokeBounds(action:DecodedDrawAction, radius:Float):Rectangle {
		var x = action.values[0];
		var y = action.values[1];
		var minX = x - radius - 1;
		var minY = y - radius - 1;
		var maxX = x + radius + 1;
		var maxY = y + radius + 1;
		var i = 2;
		while (i + 1 < action.values.length) {
			x += action.values[i];
			y += action.values[i + 1];
			minX = Math.min(minX, x - radius - 1);
			minY = Math.min(minY, y - radius - 1);
			maxX = Math.max(maxX, x + radius + 1);
			maxY = Math.max(maxY, y + radius + 1);
			i += 2;
		}
		return new Rectangle(minX, minY, maxX - minX, maxY - minY);
	}

	private function addDrawStrokeToBatch(action:DecodedDrawAction, ?deadline:Null<Float>):Bool {
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTiles(action, radius);
		if (strokeTiles == null) {
			flush();
			return startLargeStroke(action, false, "tileFallback", deadline);
		}
		if (pendingShape != null && pendingErase) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			return startLargeStroke(action, false, "tileFallback", deadline);
		}
		setStrokeTileProfile(strokeTiles, "batch");
		if (pendingShape == null) {
			pendingShape = new Shape();
			pendingErase = false;
		}
		var graphics = pendingShape.graphics;
		graphics.lineStyle(size, color);
		appendStrokeToGraphics(graphics, action);
		addPendingStrokeTiles(strokeTiles);
		return true;
	}

	private function addEraseStrokeToBatch(action:DecodedDrawAction, ?deadline:Null<Float>):Bool {
		var radius = Math.max(0.5, size / 2);
		var strokeTiles = collectStrokeTiles(action, radius);
		if (strokeTiles == null) {
			flush();
			return startLargeStroke(action, true, "eraseTileFallback", deadline);
		}
		if (pendingShape != null && !pendingErase) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			flush();
		}
		if (!canAddStrokeTilesToBatch(strokeTiles)) {
			return startLargeStroke(action, true, "eraseTileFallback", deadline);
		}
		setStrokeTileProfile(strokeTiles, "eraseBatch");
		if (pendingShape == null) {
			pendingShape = new Shape();
			pendingErase = true;
		}
		var graphics = pendingShape.graphics;
		graphics.lineStyle(size, 0xFFFFFF);
		appendStrokeToGraphics(graphics, action);
		addPendingStrokeTiles(strokeTiles);
		addPendingBounds(strokeBounds(action, radius));
		return true;
	}

	private function appendStrokeToGraphics(graphics:openfl.display.Graphics, action:DecodedDrawAction):Void {
		var x = action.values[0];
		var y = action.values[1];
		graphics.moveTo(x, y);
		graphics.lineTo(x - 0.15, y);
		graphics.moveTo(x, y);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			graphics.lineTo(nextX, nextY);
			x = nextX;
			y = nextY;
			i += 2;
		}
	}

	private function collectStrokeTiles(action:DecodedDrawAction, radius:Float):Null<ArtStrokeTileSet> {
		var tiles = new ArtStrokeTileSet();
		var x = action.values[0];
		var y = action.values[1];
		addTilesForBounds(tiles, x - radius - 1, y - radius - 1, x + radius + 1, y + radius + 1);
		if (!isStrokeTileSetBatchable(tiles)) {
			return null;
		}
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			addTilesForBounds(tiles,
				Math.min(x, nextX) - radius - 1,
				Math.min(y, nextY) - radius - 1,
				Math.max(x, nextX) + radius + 1,
				Math.max(y, nextY) + radius + 1
			);
			if (!isStrokeTileSetBatchable(tiles)) {
				return null;
			}
			x = nextX;
			y = nextY;
			i += 2;
		}
		return tiles;
	}

	private function collectStrokeTilesForErase(action:DecodedDrawAction, radius:Float):ArtStrokeTileSet {
		var tiles = new ArtStrokeTileSet();
		var x = action.values[0];
		var y = action.values[1];
		addTilesForBounds(tiles, x - radius - 1, y - radius - 1, x + radius + 1, y + radius + 1);
		var i = 2;
		while (i + 1 < action.values.length) {
			var nextX = x + action.values[i];
			var nextY = y + action.values[i + 1];
			addTilesForBounds(tiles,
				Math.min(x, nextX) - radius - 1,
				Math.min(y, nextY) - radius - 1,
				Math.max(x, nextX) + radius + 1,
				Math.max(y, nextY) + radius + 1
			);
			x = nextX;
			y = nextY;
			i += 2;
		}
		return tiles;
	}

	private function addTilesForBounds(tiles:ArtStrokeTileSet, minX:Float, minY:Float, maxX:Float, maxY:Float):Void {
		var tile = ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		var tileY = tileOrigin(Std.int(Math.floor(minY)));
		var endY = tileOrigin(Std.int(Math.floor(maxY)));
		while (tileY <= endY) {
			var tileX = tileOrigin(Std.int(Math.floor(minX)));
			var endX = tileOrigin(Std.int(Math.floor(maxX)));
			while (tileX <= endX) {
				var key = tileKey(tileX, tileY);
				tiles.add(key, tileX, tileY);
				tileX += tile;
			}
			tileY += tile;
		}
	}

	private function isStrokeTileSetBatchable(tiles:ArtStrokeTileSet):Bool {
		return ServerLevelRenderer.isArtDrawBatchWithinLimits(tiles.keys.length, tiles.tileSpanX(), tiles.tileSpanY());
	}

	private function canAddStrokeTilesToBatch(strokeTiles:ArtStrokeTileSet):Bool {
		var count = pendingTileKeys.length;
		var minTileX = pendingMinTileX;
		var maxTileX = pendingMaxTileX;
		var minTileY = pendingMinTileY;
		var maxTileY = pendingMaxTileY;
		if (pendingShape == null) {
			count = 0;
			minTileX = strokeTiles.minTileX;
			maxTileX = strokeTiles.maxTileX;
			minTileY = strokeTiles.minTileY;
			maxTileY = strokeTiles.maxTileY;
		}
		for (i in 0...strokeTiles.keys.length) {
			var key = strokeTiles.keys[i];
			var tileX = strokeTiles.tileXs[i];
			var tileY = strokeTiles.tileYs[i];
			if (!pendingTileKeySeen.exists(key)) {
				count++;
			}
			if (tileX < minTileX) minTileX = tileX;
			if (tileX > maxTileX) maxTileX = tileX;
			if (tileY < minTileY) minTileY = tileY;
			if (tileY > maxTileY) maxTileY = tileY;
		}
		var tile = ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		return ServerLevelRenderer.isArtDrawBatchWithinLimits(
			count,
			Std.int((maxTileX - minTileX) / tile) + 1,
			Std.int((maxTileY - minTileY) / tile) + 1
		);
	}

	private function addPendingStrokeTiles(strokeTiles:ArtStrokeTileSet):Void {
		for (i in 0...strokeTiles.keys.length) {
			var key = strokeTiles.keys[i];
			if (!pendingTileKeySeen.exists(key)) {
				var tileX = strokeTiles.tileXs[i];
				var tileY = strokeTiles.tileYs[i];
				pendingTileKeySeen.set(key, true);
				pendingTileKeys.push(key);
				pendingTileXs.push(tileX);
				pendingTileYs.push(tileY);
				if (pendingTileKeys.length == 1) {
					pendingMinTileX = pendingMaxTileX = tileX;
					pendingMinTileY = pendingMaxTileY = tileY;
				} else {
					if (tileX < pendingMinTileX) pendingMinTileX = tileX;
					if (tileX > pendingMaxTileX) pendingMaxTileX = tileX;
					if (tileY < pendingMinTileY) pendingMinTileY = tileY;
					if (tileY > pendingMaxTileY) pendingMaxTileY = tileY;
				}
			}
		}
	}

	private function addPendingBounds(bounds:Rectangle):Void {
		if (pendingBounds == null) {
			pendingBounds = bounds;
			return;
		}
		var minX = Math.min(pendingBounds.x, bounds.x);
		var minY = Math.min(pendingBounds.y, bounds.y);
		var maxX = Math.max(pendingBounds.right, bounds.right);
		var maxY = Math.max(pendingBounds.bottom, bounds.bottom);
		pendingBounds.setTo(minX, minY, maxX - minX, maxY - minY);
	}

	private function setControlProfile(path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = 0;
		lastProfileTileSpanX = 0;
		lastProfileTileSpanY = 0;
	}

	private function setStrokeTileProfile(strokeTiles:ArtStrokeTileSet, path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = strokeTiles.keys.length;
		lastProfileTileSpanX = strokeTiles.tileSpanX();
		lastProfileTileSpanY = strokeTiles.tileSpanY();
	}

	private function setEstimatedStrokeProfile(action:DecodedDrawAction, path:String):Void {
		var bounds = strokeBounds(action, Math.max(0.5, size / 2));
		var minTileX = tileOrigin(Std.int(Math.floor(bounds.x)));
		var maxTileX = tileOrigin(Std.int(Math.floor(bounds.right)));
		var minTileY = tileOrigin(Std.int(Math.floor(bounds.y)));
		var maxTileY = tileOrigin(Std.int(Math.floor(bounds.bottom)));
		var tile = ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileSpanX = Std.int((maxTileX - minTileX) / tile) + 1;
		lastProfileTileSpanY = Std.int((maxTileY - minTileY) / tile) + 1;
		lastProfileTileCount = lastProfileTileSpanX * lastProfileTileSpanY;
	}

	private function setLargeStrokeProfile(op:LargeStrokeRasterOperation):Void {
		lastProfilePath = op.profilePath;
		lastProfileMode = op.profileMode;
		lastProfileTileCount = op.strokeTiles.keys.length;
		lastProfileTileSpanX = op.strokeTiles.tileSpanX();
		lastProfileTileSpanY = op.strokeTiles.tileSpanY();
	}

	private function setPendingFlushProfile(path:String):Void {
		lastProfilePath = path;
		lastProfileMode = mode;
		lastProfileTileCount = pendingTileKeys.length;
		if (pendingTileKeys.length == 0) {
			lastProfileTileSpanX = 0;
			lastProfileTileSpanY = 0;
			return;
		}
		var tile = ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		lastProfileTileSpanX = Std.int((pendingMaxTileX - pendingMinTileX) / tile) + 1;
		lastProfileTileSpanY = Std.int((pendingMaxTileY - pendingMinTileY) / tile) + 1;
	}

	private static inline function tileOrigin(pixel:Int):Int {
		var tile = ServerLevelRenderer.ART_RASTER_TILE_SIZE;
		return Std.int(Math.floor(pixel / tile)) * tile;
	}

	private static inline function tileKey(tileX:Int, tileY:Int):String {
		return tileX + "," + tileY;
	}
}

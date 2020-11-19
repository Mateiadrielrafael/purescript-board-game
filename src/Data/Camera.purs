-- | Implementation of a virtual camera used for zooming and panning.
module Camera where

import Prelude
import Data.Lens (Lens', over, view)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Newtype (class Newtype)
import Data.Symbol (SProxy(..))
import Data.Typelevel.Num (D2, d0, d1)
import Data.Vec (Vec, (!!))
import Halogen.HTML (IProp)
import Halogen.Svg.Attributes as SA
import Math (floor)

type Vec2
  = Vec D2

newtype Camera
  = Camera
  { position :: Vec2 Number
  , zoom :: Number
  }

derive instance newtypeCamera :: Newtype Camera _

defaultCamera :: Camera
defaultCamera =
  Camera
    { position: zero
    , zoom: 1.0
    }

toWorldCoordinates :: Camera -> Vec2 Number -> Vec2 Number
toWorldCoordinates (Camera { position, zoom }) vec = position + ((_ / zoom) <$> vec)

origin :: Camera -> Vec2 Number
origin = view _CameraPosition

-- Zoom on the origin of the __screen__ view 
zoomOrigin :: Number -> Camera -> Camera
zoomOrigin = over _CameraZoom <<< (*)

-- Translate the camera using a vector in world coordinates
pan :: Vec2 Number -> Camera -> Camera
pan = over _CameraPosition <<< flip (-)

-- Translate the camera using a vector in screen coordinates
screenPan :: Vec2 Number -> Camera -> Camera
screenPan vector camera = pan worldCoordinates camera
  where
  worldCoordinates = toWorldCoordinates camera vector - origin camera

-- Zooms relative to a poin in screen coorinates
zoomOn :: Vec2 Number -> Number -> Camera -> Camera
zoomOn point amount = screenPan (-point) >>> zoomOrigin amount >>> screenPan point

-- Generate a svg viewbox from a Camera
toViewBox :: forall r i. Vec2 Number -> Camera -> IProp ( viewBox ∷ String | r ) i
toViewBox scale (Camera { position, zoom }) =
  SA.viewBox (floor $ position !! d0)
    (floor $ position !! d1)
    (floor $ scale !! d0 / zoom)
    (floor $ scale !! d1 / zoom)

-- Lenses
_CameraPosition :: Lens' Camera (Vec2 Number)
_CameraPosition = _Newtype <<< prop (SProxy :: _ "position")

_CameraZoom :: Lens' Camera Number
_CameraZoom = _Newtype <<< prop (SProxy :: _ "zoom")

{-# LANGUAGE CPP #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module HarfBuzz.Internal
  ( HbBufferRaw
  , HbFontRaw
  , HbBufferPtr
  , HbFontPtr
  , HbLanguageRaw
  , HbScriptRaw
  , HbDirectionRaw
  , RawGlyphInfo (..)
  , RawGlyphPosition (..)
  , hbDirectionInvalid
  , hbDirectionLtr
  , hbDirectionRtl
  , hbDirectionTtb
  , hbDirectionBtt
  , hbBufferCreate
  , hbBufferDestroy
  , hbBufferAddUtf8
  , hbBufferSetDirection
  , hbBufferSetScript
  , hbBufferSetLanguage
  , hbBufferGetGlyphInfos
  , hbBufferGetGlyphPositions
  , hbFontDestroy
  , hbShape
  , hbScriptFromString
  , hbLanguageFromString
  , hbwBuildProbe
#if defined(HB_WITH_FREETYPE)
  , hbFtFontCreateReferenced
#endif
  ) where

import Data.Int
import Data.Word
import Foreign.C.String
import Foreign.C.Types
import Foreign.Ptr
import Foreign.Storable
#if defined(HB_WITH_FREETYPE)
import FreeType.Core.Base (FT_Face)
#endif

#include "hb.h"
#if defined(HB_WITH_FREETYPE)
#include "hb-ft.h"
#endif

data HbBufferRaw
data HbFontRaw
data HbFeatureRaw
data HbLanguageImpl

type HbBufferPtr = Ptr HbBufferRaw
type HbFontPtr = Ptr HbFontRaw
type HbLanguageRaw = Ptr HbLanguageImpl
type HbScriptRaw = #{type hb_script_t}
type HbDirectionRaw = #{type hb_direction_t}

data RawGlyphInfo = RawGlyphInfo
  { rawGlyphInfoCodepoint :: Word32
  , rawGlyphInfoCluster   :: Word32
  } deriving (Eq, Show)

instance Storable RawGlyphInfo where
  sizeOf _ = #{size hb_glyph_info_t}
  alignment _ = #{alignment hb_glyph_info_t}

  peek ptr =
    RawGlyphInfo
      <$> #{peek hb_glyph_info_t, codepoint} ptr
      <*> #{peek hb_glyph_info_t, cluster} ptr

  poke _ _ =
    error "RawGlyphInfo.poke is not implemented"

data RawGlyphPosition = RawGlyphPosition
  { rawGlyphPositionXAdvance :: Int32
  , rawGlyphPositionYAdvance :: Int32
  , rawGlyphPositionXOffset  :: Int32
  , rawGlyphPositionYOffset  :: Int32
  } deriving (Eq, Show)

instance Storable RawGlyphPosition where
  sizeOf _ = #{size hb_glyph_position_t}
  alignment _ = #{alignment hb_glyph_position_t}

  peek ptr =
    RawGlyphPosition
      <$> #{peek hb_glyph_position_t, x_advance} ptr
      <*> #{peek hb_glyph_position_t, y_advance} ptr
      <*> #{peek hb_glyph_position_t, x_offset} ptr
      <*> #{peek hb_glyph_position_t, y_offset} ptr

  poke _ _ =
    error "RawGlyphPosition.poke is not implemented"

hbDirectionInvalid :: HbDirectionRaw
hbDirectionInvalid = #{const HB_DIRECTION_INVALID}

hbDirectionLtr :: HbDirectionRaw
hbDirectionLtr = #{const HB_DIRECTION_LTR}

hbDirectionRtl :: HbDirectionRaw
hbDirectionRtl = #{const HB_DIRECTION_RTL}

hbDirectionTtb :: HbDirectionRaw
hbDirectionTtb = #{const HB_DIRECTION_TTB}

hbDirectionBtt :: HbDirectionRaw
hbDirectionBtt = #{const HB_DIRECTION_BTT}

foreign import ccall unsafe "hb_buffer_create"
  hbBufferCreate :: IO HbBufferPtr

foreign import ccall unsafe "hb_buffer_destroy"
  hbBufferDestroy :: HbBufferPtr -> IO ()

foreign import ccall unsafe "hb_buffer_add_utf8"
  hbBufferAddUtf8
    :: HbBufferPtr
    -> CString
    -> CInt
    -> CUInt
    -> CInt
    -> IO ()

foreign import ccall unsafe "hb_buffer_set_direction"
  hbBufferSetDirection :: HbBufferPtr -> HbDirectionRaw -> IO ()

foreign import ccall unsafe "hb_buffer_set_script"
  hbBufferSetScript :: HbBufferPtr -> HbScriptRaw -> IO ()

foreign import ccall unsafe "hb_buffer_set_language"
  hbBufferSetLanguage :: HbBufferPtr -> HbLanguageRaw -> IO ()

foreign import ccall unsafe "hb_buffer_get_glyph_infos"
  hbBufferGetGlyphInfos :: HbBufferPtr -> Ptr CUInt -> IO (Ptr RawGlyphInfo)

foreign import ccall unsafe "hb_buffer_get_glyph_positions"
  hbBufferGetGlyphPositions :: HbBufferPtr -> Ptr CUInt -> IO (Ptr RawGlyphPosition)

foreign import ccall unsafe "hb_font_destroy"
  hbFontDestroy :: HbFontPtr -> IO ()

foreign import ccall unsafe "hb_shape"
  hbShape :: HbFontPtr -> HbBufferPtr -> Ptr HbFeatureRaw -> CUInt -> IO ()

foreign import ccall unsafe "hb_script_from_string"
  hbScriptFromString :: CString -> CInt -> IO HbScriptRaw

foreign import ccall unsafe "hb_language_from_string"
  hbLanguageFromString :: CString -> CInt -> IO HbLanguageRaw

#if defined(HB_WITH_FREETYPE)
foreign import ccall unsafe "hb_ft_font_create_referenced"
  hbFtFontCreateReferenced :: FT_Face -> IO HbFontPtr
#endif

foreign import ccall unsafe "hbw_build_probe"
  hbwBuildProbe :: IO CUInt

{-# LANGUAGE CPP #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module HarfBuzz
  ( HbBuffer
  , HbFont
  , HbLanguage
  , Script
  , Direction (..)
  , directionInvalid
  , directionLTR
  , directionRTL
  , directionTTB
  , directionBTT
  , GlyphInfo (..)
  , GlyphPosition (..)
  , bufferCreate
  , bufferDestroy
  , bufferAddUtf8
  , bufferSetDirection
  , bufferSetScript
  , bufferSetLanguage
#if defined(HB_WITH_FREETYPE)
  , ftFontCreateReferenced
#endif
  , fontDestroy
  , shape
  , bufferGetGlyphInfos
  , bufferGetGlyphPositions
  , scriptFromString
  , languageFromString
  ) where

import HarfBuzz.Internal

import Data.ByteString (ByteString)
import qualified Data.ByteString.Unsafe as BS
import Data.Word
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Ptr
import Foreign.Storable
#if defined(HB_WITH_FREETYPE)
import FreeType.Core.Base (FT_Face)
#endif

newtype HbBuffer = HbBuffer HbBufferPtr

newtype HbFont = HbFont HbFontPtr

newtype HbLanguage = HbLanguage HbLanguageRaw
  deriving (Eq)

newtype Script = Script HbScriptRaw
  deriving (Eq)

newtype Direction = Direction HbDirectionRaw
  deriving (Eq, Show)

directionInvalid :: Direction
directionInvalid = Direction hbDirectionInvalid

directionLTR :: Direction
directionLTR = Direction hbDirectionLtr

directionRTL :: Direction
directionRTL = Direction hbDirectionRtl

directionTTB :: Direction
directionTTB = Direction hbDirectionTtb

directionBTT :: Direction
directionBTT = Direction hbDirectionBtt

data GlyphInfo = GlyphInfo
  { glyphInfoCodepoint :: Word32
  , glyphInfoCluster   :: Word32
  } deriving (Eq, Show)

data GlyphPosition = GlyphPosition
  { glyphPositionXAdvance :: Int
  , glyphPositionYAdvance :: Int
  , glyphPositionXOffset  :: Int
  , glyphPositionYOffset  :: Int
  } deriving (Eq, Show)

checkNotNull :: String -> Ptr a -> IO (Ptr a)
checkNotNull name ptr
  | ptr == nullPtr = ioError (userError (name ++ " returned null"))
  | otherwise = pure ptr

bufferCreate :: IO HbBuffer
bufferCreate = HbBuffer <$> (hbBufferCreate >>= checkNotNull "hb_buffer_create")

bufferDestroy :: HbBuffer -> IO ()
bufferDestroy (HbBuffer buffer) = hbBufferDestroy buffer

bufferAddUtf8 :: HbBuffer -> ByteString -> IO ()
bufferAddUtf8 (HbBuffer buffer) bytes =
  BS.unsafeUseAsCStringLen bytes $ \(ptr, len) ->
    hbBufferAddUtf8 buffer ptr (fromIntegral len) 0 (fromIntegral len)

bufferSetDirection :: HbBuffer -> Direction -> IO ()
bufferSetDirection (HbBuffer buffer) (Direction direction) =
  hbBufferSetDirection buffer direction

bufferSetScript :: HbBuffer -> Script -> IO ()
bufferSetScript (HbBuffer buffer) (Script script) =
  hbBufferSetScript buffer script

bufferSetLanguage :: HbBuffer -> HbLanguage -> IO ()
bufferSetLanguage (HbBuffer buffer) (HbLanguage language) =
  hbBufferSetLanguage buffer language

#if defined(HB_WITH_FREETYPE)
ftFontCreateReferenced :: FT_Face -> IO HbFont
ftFontCreateReferenced face =
  HbFont <$> (hbFtFontCreateReferenced face >>= checkNotNull "hb_ft_font_create_referenced")
#endif

fontDestroy :: HbFont -> IO ()
fontDestroy (HbFont font) = hbFontDestroy font

shape :: HbFont -> HbBuffer -> IO ()
shape (HbFont font) (HbBuffer buffer) =
  hbShape font buffer nullPtr 0

bufferGetGlyphInfos :: HbBuffer -> IO [GlyphInfo]
bufferGetGlyphInfos (HbBuffer buffer) =
  alloca $ \lenPtr -> do
    rawPtr <- hbBufferGetGlyphInfos buffer lenPtr
    len <- fromIntegral <$> peek lenPtr
    if rawPtr == nullPtr || len == 0
      then pure []
      else fmap toGlyphInfo <$> peekArray len rawPtr

bufferGetGlyphPositions :: HbBuffer -> IO [GlyphPosition]
bufferGetGlyphPositions (HbBuffer buffer) =
  alloca $ \lenPtr -> do
    rawPtr <- hbBufferGetGlyphPositions buffer lenPtr
    len <- fromIntegral <$> peek lenPtr
    if rawPtr == nullPtr || len == 0
      then pure []
      else fmap toGlyphPosition <$> peekArray len rawPtr

scriptFromString :: ByteString -> IO Script
scriptFromString bytes =
  BS.unsafeUseAsCStringLen bytes $ \(ptr, len) ->
    Script <$> hbScriptFromString ptr (fromIntegral len)

languageFromString :: ByteString -> IO HbLanguage
languageFromString bytes =
  BS.unsafeUseAsCStringLen bytes $ \(ptr, len) ->
    HbLanguage <$> hbLanguageFromString ptr (fromIntegral len)

toGlyphInfo :: RawGlyphInfo -> GlyphInfo
toGlyphInfo raw =
  GlyphInfo
    { glyphInfoCodepoint = rawGlyphInfoCodepoint raw
    , glyphInfoCluster = rawGlyphInfoCluster raw
    }

toGlyphPosition :: RawGlyphPosition -> GlyphPosition
toGlyphPosition raw =
  GlyphPosition
    { glyphPositionXAdvance = fromIntegral (rawGlyphPositionXAdvance raw)
    , glyphPositionYAdvance = fromIntegral (rawGlyphPositionYAdvance raw)
    , glyphPositionXOffset = fromIntegral (rawGlyphPositionXOffset raw)
    , glyphPositionYOffset = fromIntegral (rawGlyphPositionYOffset raw)
    }

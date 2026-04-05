{-# LANGUAGE CPP #-}

module Main where

import Control.Exception (bracket)
import Control.Monad (unless)
import qualified Data.ByteString.Char8 as BS8
import System.Exit (die)

import HarfBuzz
import HarfBuzz.Internal (hbwBuildProbe)

#if defined(HB_WITH_FREETYPE)
import FreeType.Core.Base
#endif

main :: IO ()
main = do
  probe <- hbwBuildProbe
  unless (probe > 0) $
    die "native HarfBuzz build probe failed"

#if defined(HB_WITH_FREETYPE)
  ft_With_FreeType $ \library ->
    ft_With_Face library "test/fonts/Roboto-Regular.ttf" 0 $ \face -> do
      ft_Set_Char_Size face 0 (16 * 64) 0 0
      font <- ftFontCreateReferenced face
      bracket (pure font) fontDestroy $ \hbFont ->
        bracket bufferCreate bufferDestroy $ \buffer -> do
          script <- scriptFromString (BS8.pack "Latn")
          language <- languageFromString (BS8.pack "en")

          bufferAddUtf8 buffer (BS8.pack "office")
          bufferSetDirection buffer directionLTR
          bufferSetScript buffer script
          bufferSetLanguage buffer language
          shape hbFont buffer

          infos <- bufferGetGlyphInfos buffer
          positions <- bufferGetGlyphPositions buffer

          unless (not (null infos)) $
            die "shape produced no glyph infos"

          unless (length infos == length positions) $
            die "glyph info/position lengths differ"
#else
  pure ()
#endif

{-# language OverloadedStrings #-}

module Main where

import Control.Exception
import Control.Monad
import qualified Data.Text as T
import System.Environment
import System.Exit
import Turtle hiding (die)


fixOverwrites inFileName numStr1 numStr2 outFileName
  = procs "donttouch\\FixOverwrites.exe" [inFileName,numStr1,numStr2,outFileName] (return "")

smmod inFileName cfgFileName outFileName
  = procs "donttouch\\SMModAutoNew.exe" [inFileName,cfgFileName,outFileName] (return "")

ppcinject inFileName outFileName patches
   = procs "donttouch\\PPCInject.exe" (inFileName:outFileName:patches) (return "")

main = do
  args <- getArgs
  progName <- getProgName
  when (length args /= 3) $
    die $ "Usage: " ++ progName ++ " [in file] [config] [out file]"
  let [inFileName,cfgFileName,outFileName] = map T.pack args

  let 
    doTheMario = do
      echo "Preparing REL for code insert..."
      fixOverwrites inFileName "0x80314ef0" "0x80314f30" ".mkb2.main_loop_temp_1.rel"
      fixOverwrites ".mkb2.main_loop_temp_1.rel" "0x803153c0" "0x803153f4" ".mkb2.main_loop_temp_2.rel"
      echo "Inserting code..."
      ppcinject ".mkb2.main_loop_temp_2.rel" ".mkb2.main_loop_temp_3.rel" ["donttouch\\newStoryModeEntries.asm"] 
      echo "Adding story mode entries..."
      smmod ".mkb2.main_loop_temp_3.rel" cfgFileName outFileName
      rm ".mkb2.main_loop_temp_1.rel"
      rm ".mkb2.main_loop_temp_2.rel"
      rm ".mkb2.main_loop_temp_3.rel"
    handleException :: ProcFailed -> IO ()
    handleException pf = do
      putStrLn "The smmod script has failed"
  
  catch doTheMario handleException


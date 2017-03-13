-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Number.ES.Rules
  ( rules ) where

import qualified Data.HashMap.Strict as HashMap
import Data.Maybe
import qualified Data.Text as Text
import Prelude
import Data.String

import Duckling.Dimensions.Types
import Duckling.Number.Helpers
import Duckling.Number.Types (NumberData (..))
import qualified Duckling.Number.Types as TNumber
import Duckling.Regex.Types
import Duckling.Types

ruleNumbersPrefixWithNegativeOrMinus :: Rule
ruleNumbersPrefixWithNegativeOrMinus = Rule
  { name = "numbers prefix with -, negative or minus"
  , pattern =
    [ regex "-|menos"
    , dimension DNumber
    ]
  , prod = \tokens -> case tokens of
      (_:Token DNumber (NumberData {TNumber.value = v}):_) -> double $ v * (- 1)
      _ -> Nothing
  }

ruleIntegerNumeric :: Rule
ruleIntegerNumeric = Rule
  { name = "integer (numeric)"
  , pattern =
    [ regex "(\\d{1,18})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) -> do
        v <- parseInt match
        integer $ toInteger v
      _ -> Nothing
  }

ruleDecimalWithThousandsSeparator :: Rule
ruleDecimalWithThousandsSeparator = Rule
  { name = "decimal with thousands separator"
  , pattern =
    [ regex "(\\d+(\\.\\d\\d\\d)+,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):
       _) -> let dot = Text.singleton '.'
                 comma = Text.singleton ','
                 fmt = Text.replace comma dot $ Text.replace dot Text.empty match
        in parseDouble fmt >>= double
      _ -> Nothing
  }

ruleDecimalNumber :: Rule
ruleDecimalNumber = Rule
  { name = "decimal number"
  , pattern =
    [ regex "(\\d*,\\d+)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        parseDecimal False match
      _ -> Nothing
  }

byTensMap :: HashMap.HashMap Text.Text Integer
byTensMap = HashMap.fromList
  [ ( "veinte" , 20 )
  , ( "treinta" , 30 )
  , ( "cuarenta" , 40 )
  , ( "cincuenta" , 50 )
  , ( "sesenta" , 60 )
  , ( "setenta" , 70 )
  , ( "ochenta" , 80 )
  , ( "noventa" , 90 )
  ]

ruleNumber2 :: Rule
ruleNumber2 = Rule
  { name = "number (20..90)"
  , pattern =
    [ regex "(veinte|treinta|cuarenta|cincuenta|sesenta|setenta|ochenta|noventa)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) byTensMap >>= integer
      _ -> Nothing
  }

zeroToFifteenMap :: HashMap.HashMap Text.Text Integer
zeroToFifteenMap = HashMap.fromList
  [ ( "zero" , 0 )
  , ( "cero" , 0 )
  , ( "un" , 1 )
  , ( "una" , 1 )
  , ( "uno" , 1 )
  , ( "dos" , 2 )
  , ( "tr\x00e9s" , 3 )
  , ( "tres" , 3 )
  , ( "cuatro" , 4 )
  , ( "cinco" , 5 )
  , ( "seis" , 6 )
  , ( "s\x00e9is" , 6 )
  , ( "siete" , 7 )
  , ( "ocho" , 8 )
  , ( "nueve" , 9 )
  , ( "diez" , 10 )
  , ( "dies" , 10 )
  , ( "once" , 11 )
  , ( "doce" , 12 )
  , ( "trece" , 13 )
  , ( "catorce" , 14 )
  , ( "quince" , 15 )
  ]

ruleNumber :: Rule
ruleNumber = Rule
  { name = "number (0..15)"
  , pattern =
    [ regex "((c|z)ero|un(o|a)?|dos|tr(\x00e9|e)s|cuatro|cinco|s(e|\x00e9)is|siete|ocho|nueve|die(z|s)|once|doce|trece|catorce|quince)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) zeroToFifteenMap >>= integer
      _ -> Nothing
  }

sixteenToTwentyNineMap :: HashMap.HashMap Text.Text Integer
sixteenToTwentyNineMap = HashMap.fromList
  [ ( "dieciseis" , 16 )
  , ( "diesis\x00e9is" , 16 )
  , ( "diesiseis" , 16 )
  , ( "diecis\x00e9is" , 16 )
  , ( "diecisiete" , 17 )
  , ( "dieciocho" , 18 )
  , ( "diecinueve" , 19 )
  , ( "veintiuno" , 21 )
  , ( "veintiuna" , 21 )
  , ( "veintidos" , 22 )
  , ( "veintitr\x00e9s" , 23 )
  , ( "veintitres" , 23 )
  , ( "veinticuatro" , 24 )
  , ( "veinticinco" , 25 )
  , ( "veintis\x00e9is" , 26 )
  , ( "veintiseis" , 26 )
  , ( "veintisiete" , 27 )
  , ( "veintiocho" , 28 )
  , ( "veintinueve" , 29 )
  ]

ruleNumber5 :: Rule
ruleNumber5 = Rule
  { name = "number (16..19 21..29)"
  , pattern =
    [ regex "(die(c|s)is(\x00e9|e)is|diecisiete|dieciocho|diecinueve|veintiun(o|a)|veintidos|veintitr(\x00e9|e)s|veinticuatro|veinticinco|veintis(\x00e9|e)is|veintisiete|veintiocho|veintinueve)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) sixteenToTwentyNineMap >>= integer
      _ -> Nothing
  }

ruleNumber3 :: Rule
ruleNumber3 = Rule
  { name = "number (16..19)"
  , pattern =
    [ numberWith TNumber.value (== 10)
    , regex "y"
    , numberBetween 6 10
    ]
  , prod = \tokens -> case tokens of
      (_:_:Token DNumber (NumberData {TNumber.value = v}):_) -> double $ 10 + v
      _ -> Nothing
  }

ruleNumbersSuffixesKMG :: Rule
ruleNumbersSuffixesKMG = Rule
  { name = "numbers suffixes (K, M, G)"
  , pattern =
    [ dimension DNumber
    , regex "([kmg])(?=[\\W\\$\x20ac]|$)"
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v}):
       Token RegexMatch (GroupMatch (match:_)):
       _) -> case Text.toLower match of
          "k" -> double $ v * 1e3
          "m" -> double $ v * 1e6
          "g" -> double $ v * 1e9
          _ -> Nothing
      _ -> Nothing
  }

oneHundredToThousandMap :: HashMap.HashMap Text.Text Integer
oneHundredToThousandMap = HashMap.fromList
  [ ( "cien" , 100 )
  , ( "cientos" , 100 )
  , ( "ciento" , 100 )
  , ( "doscientos" , 200 )
  , ( "trescientos" , 300 )
  , ( "cuatrocientos" , 400 )
  , ( "quinientos" , 500 )
  , ( "seiscientos" , 600 )
  , ( "setecientos" , 700 )
  , ( "ochocientos" , 800 )
  , ( "novecientos" , 900 )
  , ( "mil" , 1000 )
  ]


ruleNumber6 :: Rule
ruleNumber6 = Rule
  { name = "number 100..1000 "
  , pattern =
    [ regex "(cien(to)?s?|doscientos|trescientos|cuatrocientos|quinientos|seiscientos|setecientos|ochocientos|novecientos|mil)"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        HashMap.lookup (Text.toLower match) oneHundredToThousandMap >>= integer
      _ -> Nothing
  }

ruleNumber4 :: Rule
ruleNumber4 = Rule
  { name = "number (21..29 31..39 41..49 51..59 61..69 71..79 81..89 91..99)"
  , pattern =
    [ oneOf [70, 20, 60, 50, 40, 90, 30, 80]
    , regex "y"
    , numberBetween 1 10
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v1}):_:Token DNumber (NumberData {TNumber.value = v2}):_) ->
        double $ v1 + v2
      _ -> Nothing
  }

ruleNumbers :: Rule
ruleNumbers = Rule
  { name = "numbers 200..999"
  , pattern =
    [ numberBetween 2 10
    , numberWith TNumber.value (== 100)
    , numberBetween 0 100
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v1}):
       _:
       Token DNumber (NumberData {TNumber.value = v2}):
       _) -> double $ 100 * v1 + v2
      _ -> Nothing
  }

ruleNumberDotNumber :: Rule
ruleNumberDotNumber = Rule
  { name = "number dot number"
  , pattern =
    [ dimension DNumber
    , regex "punto"
    , numberWith TNumber.grain isNothing
    ]
  , prod = \tokens -> case tokens of
      (Token DNumber (NumberData {TNumber.value = v1}):
       _:
       Token DNumber (NumberData {TNumber.value = v2}):
       _) -> double $ v1 + decimalsToDouble v2
      _ -> Nothing
  }

ruleIntegerWithThousandsSeparator :: Rule
ruleIntegerWithThousandsSeparator = Rule
  { name = "integer with thousands separator ."
  , pattern =
    [ regex "(\\d{1,3}(\\.\\d\\d\\d){1,5})"
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (match:_)):_) ->
        parseDouble (Text.replace (Text.singleton '.') Text.empty match) >>= double
      _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleDecimalNumber
  , ruleDecimalWithThousandsSeparator
  , ruleIntegerNumeric
  , ruleIntegerWithThousandsSeparator
  , ruleNumber
  , ruleNumber2
  , ruleNumber3
  , ruleNumber4
  , ruleNumber5
  , ruleNumber6
  , ruleNumberDotNumber
  , ruleNumbers
  , ruleNumbersPrefixWithNegativeOrMinus
  , ruleNumbersSuffixesKMG
  ]
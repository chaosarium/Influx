module Colours exposing (..)

import Css
import Html
import Html.Attributes



-- UTILITIES


colorHtml : String -> Html.Attribute msg
colorHtml colourStr =
    Html.Attributes.style "color" colourStr


colorCss : String -> Css.Style
colorCss colourStr =
    Css.property "color" colourStr


bgHtml : String -> Html.Attribute msg
bgHtml colourStr =
    Html.Attributes.style "background-color" colourStr


bgCss : String -> Css.Style
bgCss colourStr =
    Css.property "background-color" colourStr


borderHtml : String -> Html.Attribute msg
borderHtml colourStr =
    Html.Attributes.style "border-color" colourStr


borderCss : String -> Css.Style
borderCss colourStr =
    Css.property "border-color" colourStr



-- BLACK AND WHITE


white =
    "var(--white)"


black =
    "var(--black)"



-- PALETTE


amber1 =
    "var(--amber-1)"


amber2 =
    "var(--amber-2)"


amber3 =
    "var(--amber-3)"


amber4 =
    "var(--amber-4)"


amber5 =
    "var(--amber-5)"


amber6 =
    "var(--amber-6)"


amber7 =
    "var(--amber-7)"


amber8 =
    "var(--amber-8)"


amber9 =
    "var(--amber-9)"


amber10 =
    "var(--amber-10)"


amber11 =
    "var(--amber-11)"


amber12 =
    "var(--amber-12)"


amberA1 =
    "var(--amber-a1)"


amberA2 =
    "var(--amber-a2)"


amberA3 =
    "var(--amber-a3)"


amberA4 =
    "var(--amber-a4)"


amberA5 =
    "var(--amber-a5)"


amberA6 =
    "var(--amber-a6)"


amberA7 =
    "var(--amber-a7)"


amberA8 =
    "var(--amber-a8)"


amberA9 =
    "var(--amber-a9)"


amberA10 =
    "var(--amber-a10)"


amberA11 =
    "var(--amber-a11)"


amberA12 =
    "var(--amber-a12)"


blackA1 =
    "var(--black-a1)"


blackA2 =
    "var(--black-a2)"


blackA3 =
    "var(--black-a3)"


blackA4 =
    "var(--black-a4)"


blackA5 =
    "var(--black-a5)"


blackA6 =
    "var(--black-a6)"


blackA7 =
    "var(--black-a7)"


blackA8 =
    "var(--black-a8)"


blackA9 =
    "var(--black-a9)"


blackA10 =
    "var(--black-a10)"


blackA11 =
    "var(--black-a11)"


blackA12 =
    "var(--black-a12)"


blue1 =
    "var(--blue-1)"


blue2 =
    "var(--blue-2)"


blue3 =
    "var(--blue-3)"


blue4 =
    "var(--blue-4)"


blue5 =
    "var(--blue-5)"


blue6 =
    "var(--blue-6)"


blue7 =
    "var(--blue-7)"


blue8 =
    "var(--blue-8)"


blue9 =
    "var(--blue-9)"


blue10 =
    "var(--blue-10)"


blue11 =
    "var(--blue-11)"


blue12 =
    "var(--blue-12)"


blueA1 =
    "var(--blue-a1)"


blueA2 =
    "var(--blue-a2)"


blueA3 =
    "var(--blue-a3)"


blueA4 =
    "var(--blue-a4)"


blueA5 =
    "var(--blue-a5)"


blueA6 =
    "var(--blue-a6)"


blueA7 =
    "var(--blue-a7)"


blueA8 =
    "var(--blue-a8)"


blueA9 =
    "var(--blue-a9)"


blueA10 =
    "var(--blue-a10)"


blueA11 =
    "var(--blue-a11)"


blueA12 =
    "var(--blue-a12)"


bronze1 =
    "var(--bronze-1)"


bronze2 =
    "var(--bronze-2)"


bronze3 =
    "var(--bronze-3)"


bronze4 =
    "var(--bronze-4)"


bronze5 =
    "var(--bronze-5)"


bronze6 =
    "var(--bronze-6)"


bronze7 =
    "var(--bronze-7)"


bronze8 =
    "var(--bronze-8)"


bronze9 =
    "var(--bronze-9)"


bronze10 =
    "var(--bronze-10)"


bronze11 =
    "var(--bronze-11)"


bronze12 =
    "var(--bronze-12)"


bronzeA1 =
    "var(--bronze-a1)"


bronzeA2 =
    "var(--bronze-a2)"


bronzeA3 =
    "var(--bronze-a3)"


bronzeA4 =
    "var(--bronze-a4)"


bronzeA5 =
    "var(--bronze-a5)"


bronzeA6 =
    "var(--bronze-a6)"


bronzeA7 =
    "var(--bronze-a7)"


bronzeA8 =
    "var(--bronze-a8)"


bronzeA9 =
    "var(--bronze-a9)"


bronzeA10 =
    "var(--bronze-a10)"


bronzeA11 =
    "var(--bronze-a11)"


bronzeA12 =
    "var(--bronze-a12)"


brown1 =
    "var(--brown-1)"


brown2 =
    "var(--brown-2)"


brown3 =
    "var(--brown-3)"


brown4 =
    "var(--brown-4)"


brown5 =
    "var(--brown-5)"


brown6 =
    "var(--brown-6)"


brown7 =
    "var(--brown-7)"


brown8 =
    "var(--brown-8)"


brown9 =
    "var(--brown-9)"


brown10 =
    "var(--brown-10)"


brown11 =
    "var(--brown-11)"


brown12 =
    "var(--brown-12)"


brownA1 =
    "var(--brown-a1)"


brownA2 =
    "var(--brown-a2)"


brownA3 =
    "var(--brown-a3)"


brownA4 =
    "var(--brown-a4)"


brownA5 =
    "var(--brown-a5)"


brownA6 =
    "var(--brown-a6)"


brownA7 =
    "var(--brown-a7)"


brownA8 =
    "var(--brown-a8)"


brownA9 =
    "var(--brown-a9)"


brownA10 =
    "var(--brown-a10)"


brownA11 =
    "var(--brown-a11)"


brownA12 =
    "var(--brown-a12)"


crimson1 =
    "var(--crimson-1)"


crimson2 =
    "var(--crimson-2)"


crimson3 =
    "var(--crimson-3)"


crimson4 =
    "var(--crimson-4)"


crimson5 =
    "var(--crimson-5)"


crimson6 =
    "var(--crimson-6)"


crimson7 =
    "var(--crimson-7)"


crimson8 =
    "var(--crimson-8)"


crimson9 =
    "var(--crimson-9)"


crimson10 =
    "var(--crimson-10)"


crimson11 =
    "var(--crimson-11)"


crimson12 =
    "var(--crimson-12)"


crimsonA1 =
    "var(--crimson-a1)"


crimsonA2 =
    "var(--crimson-a2)"


crimsonA3 =
    "var(--crimson-a3)"


crimsonA4 =
    "var(--crimson-a4)"


crimsonA5 =
    "var(--crimson-a5)"


crimsonA6 =
    "var(--crimson-a6)"


crimsonA7 =
    "var(--crimson-a7)"


crimsonA8 =
    "var(--crimson-a8)"


crimsonA9 =
    "var(--crimson-a9)"


crimsonA10 =
    "var(--crimson-a10)"


crimsonA11 =
    "var(--crimson-a11)"


crimsonA12 =
    "var(--crimson-a12)"


cyan1 =
    "var(--cyan-1)"


cyan2 =
    "var(--cyan-2)"


cyan3 =
    "var(--cyan-3)"


cyan4 =
    "var(--cyan-4)"


cyan5 =
    "var(--cyan-5)"


cyan6 =
    "var(--cyan-6)"


cyan7 =
    "var(--cyan-7)"


cyan8 =
    "var(--cyan-8)"


cyan9 =
    "var(--cyan-9)"


cyan10 =
    "var(--cyan-10)"


cyan11 =
    "var(--cyan-11)"


cyan12 =
    "var(--cyan-12)"


cyanA1 =
    "var(--cyan-a1)"


cyanA2 =
    "var(--cyan-a2)"


cyanA3 =
    "var(--cyan-a3)"


cyanA4 =
    "var(--cyan-a4)"


cyanA5 =
    "var(--cyan-a5)"


cyanA6 =
    "var(--cyan-a6)"


cyanA7 =
    "var(--cyan-a7)"


cyanA8 =
    "var(--cyan-a8)"


cyanA9 =
    "var(--cyan-a9)"


cyanA10 =
    "var(--cyan-a10)"


cyanA11 =
    "var(--cyan-a11)"


cyanA12 =
    "var(--cyan-a12)"


gold1 =
    "var(--gold-1)"


gold2 =
    "var(--gold-2)"


gold3 =
    "var(--gold-3)"


gold4 =
    "var(--gold-4)"


gold5 =
    "var(--gold-5)"


gold6 =
    "var(--gold-6)"


gold7 =
    "var(--gold-7)"


gold8 =
    "var(--gold-8)"


gold9 =
    "var(--gold-9)"


gold10 =
    "var(--gold-10)"


gold11 =
    "var(--gold-11)"


gold12 =
    "var(--gold-12)"


goldA1 =
    "var(--gold-a1)"


goldA2 =
    "var(--gold-a2)"


goldA3 =
    "var(--gold-a3)"


goldA4 =
    "var(--gold-a4)"


goldA5 =
    "var(--gold-a5)"


goldA6 =
    "var(--gold-a6)"


goldA7 =
    "var(--gold-a7)"


goldA8 =
    "var(--gold-a8)"


goldA9 =
    "var(--gold-a9)"


goldA10 =
    "var(--gold-a10)"


goldA11 =
    "var(--gold-a11)"


goldA12 =
    "var(--gold-a12)"


grass1 =
    "var(--grass-1)"


grass2 =
    "var(--grass-2)"


grass3 =
    "var(--grass-3)"


grass4 =
    "var(--grass-4)"


grass5 =
    "var(--grass-5)"


grass6 =
    "var(--grass-6)"


grass7 =
    "var(--grass-7)"


grass8 =
    "var(--grass-8)"


grass9 =
    "var(--grass-9)"


grass10 =
    "var(--grass-10)"


grass11 =
    "var(--grass-11)"


grass12 =
    "var(--grass-12)"


grassA1 =
    "var(--grass-a1)"


grassA2 =
    "var(--grass-a2)"


grassA3 =
    "var(--grass-a3)"


grassA4 =
    "var(--grass-a4)"


grassA5 =
    "var(--grass-a5)"


grassA6 =
    "var(--grass-a6)"


grassA7 =
    "var(--grass-a7)"


grassA8 =
    "var(--grass-a8)"


grassA9 =
    "var(--grass-a9)"


grassA10 =
    "var(--grass-a10)"


grassA11 =
    "var(--grass-a11)"


grassA12 =
    "var(--grass-a12)"


gray1 =
    "var(--gray-1)"


gray2 =
    "var(--gray-2)"


gray3 =
    "var(--gray-3)"


gray4 =
    "var(--gray-4)"


gray5 =
    "var(--gray-5)"


gray6 =
    "var(--gray-6)"


gray7 =
    "var(--gray-7)"


gray8 =
    "var(--gray-8)"


gray9 =
    "var(--gray-9)"


gray10 =
    "var(--gray-10)"


gray11 =
    "var(--gray-11)"


gray12 =
    "var(--gray-12)"


grayA1 =
    "var(--gray-a1)"


grayA2 =
    "var(--gray-a2)"


grayA3 =
    "var(--gray-a3)"


grayA4 =
    "var(--gray-a4)"


grayA5 =
    "var(--gray-a5)"


grayA6 =
    "var(--gray-a6)"


grayA7 =
    "var(--gray-a7)"


grayA8 =
    "var(--gray-a8)"


grayA9 =
    "var(--gray-a9)"


grayA10 =
    "var(--gray-a10)"


grayA11 =
    "var(--gray-a11)"


grayA12 =
    "var(--gray-a12)"


green1 =
    "var(--green-1)"


green2 =
    "var(--green-2)"


green3 =
    "var(--green-3)"


green4 =
    "var(--green-4)"


green5 =
    "var(--green-5)"


green6 =
    "var(--green-6)"


green7 =
    "var(--green-7)"


green8 =
    "var(--green-8)"


green9 =
    "var(--green-9)"


green10 =
    "var(--green-10)"


green11 =
    "var(--green-11)"


green12 =
    "var(--green-12)"


greenA1 =
    "var(--green-a1)"


greenA2 =
    "var(--green-a2)"


greenA3 =
    "var(--green-a3)"


greenA4 =
    "var(--green-a4)"


greenA5 =
    "var(--green-a5)"


greenA6 =
    "var(--green-a6)"


greenA7 =
    "var(--green-a7)"


greenA8 =
    "var(--green-a8)"


greenA9 =
    "var(--green-a9)"


greenA10 =
    "var(--green-a10)"


greenA11 =
    "var(--green-a11)"


greenA12 =
    "var(--green-a12)"


indigo1 =
    "var(--indigo-1)"


indigo2 =
    "var(--indigo-2)"


indigo3 =
    "var(--indigo-3)"


indigo4 =
    "var(--indigo-4)"


indigo5 =
    "var(--indigo-5)"


indigo6 =
    "var(--indigo-6)"


indigo7 =
    "var(--indigo-7)"


indigo8 =
    "var(--indigo-8)"


indigo9 =
    "var(--indigo-9)"


indigo10 =
    "var(--indigo-10)"


indigo11 =
    "var(--indigo-11)"


indigo12 =
    "var(--indigo-12)"


indigoA1 =
    "var(--indigo-a1)"


indigoA2 =
    "var(--indigo-a2)"


indigoA3 =
    "var(--indigo-a3)"


indigoA4 =
    "var(--indigo-a4)"


indigoA5 =
    "var(--indigo-a5)"


indigoA6 =
    "var(--indigo-a6)"


indigoA7 =
    "var(--indigo-a7)"


indigoA8 =
    "var(--indigo-a8)"


indigoA9 =
    "var(--indigo-a9)"


indigoA10 =
    "var(--indigo-a10)"


indigoA11 =
    "var(--indigo-a11)"


indigoA12 =
    "var(--indigo-a12)"


iris1 =
    "var(--iris-1)"


iris2 =
    "var(--iris-2)"


iris3 =
    "var(--iris-3)"


iris4 =
    "var(--iris-4)"


iris5 =
    "var(--iris-5)"


iris6 =
    "var(--iris-6)"


iris7 =
    "var(--iris-7)"


iris8 =
    "var(--iris-8)"


iris9 =
    "var(--iris-9)"


iris10 =
    "var(--iris-10)"


iris11 =
    "var(--iris-11)"


iris12 =
    "var(--iris-12)"


irisA1 =
    "var(--iris-a1)"


irisA2 =
    "var(--iris-a2)"


irisA3 =
    "var(--iris-a3)"


irisA4 =
    "var(--iris-a4)"


irisA5 =
    "var(--iris-a5)"


irisA6 =
    "var(--iris-a6)"


irisA7 =
    "var(--iris-a7)"


irisA8 =
    "var(--iris-a8)"


irisA9 =
    "var(--iris-a9)"


irisA10 =
    "var(--iris-a10)"


irisA11 =
    "var(--iris-a11)"


irisA12 =
    "var(--iris-a12)"


jade1 =
    "var(--jade-1)"


jade2 =
    "var(--jade-2)"


jade3 =
    "var(--jade-3)"


jade4 =
    "var(--jade-4)"


jade5 =
    "var(--jade-5)"


jade6 =
    "var(--jade-6)"


jade7 =
    "var(--jade-7)"


jade8 =
    "var(--jade-8)"


jade9 =
    "var(--jade-9)"


jade10 =
    "var(--jade-10)"


jade11 =
    "var(--jade-11)"


jade12 =
    "var(--jade-12)"


jadeA1 =
    "var(--jade-a1)"


jadeA2 =
    "var(--jade-a2)"


jadeA3 =
    "var(--jade-a3)"


jadeA4 =
    "var(--jade-a4)"


jadeA5 =
    "var(--jade-a5)"


jadeA6 =
    "var(--jade-a6)"


jadeA7 =
    "var(--jade-a7)"


jadeA8 =
    "var(--jade-a8)"


jadeA9 =
    "var(--jade-a9)"


jadeA10 =
    "var(--jade-a10)"


jadeA11 =
    "var(--jade-a11)"


jadeA12 =
    "var(--jade-a12)"


lime1 =
    "var(--lime-1)"


lime2 =
    "var(--lime-2)"


lime3 =
    "var(--lime-3)"


lime4 =
    "var(--lime-4)"


lime5 =
    "var(--lime-5)"


lime6 =
    "var(--lime-6)"


lime7 =
    "var(--lime-7)"


lime8 =
    "var(--lime-8)"


lime9 =
    "var(--lime-9)"


lime10 =
    "var(--lime-10)"


lime11 =
    "var(--lime-11)"


lime12 =
    "var(--lime-12)"


limeA1 =
    "var(--lime-a1)"


limeA2 =
    "var(--lime-a2)"


limeA3 =
    "var(--lime-a3)"


limeA4 =
    "var(--lime-a4)"


limeA5 =
    "var(--lime-a5)"


limeA6 =
    "var(--lime-a6)"


limeA7 =
    "var(--lime-a7)"


limeA8 =
    "var(--lime-a8)"


limeA9 =
    "var(--lime-a9)"


limeA10 =
    "var(--lime-a10)"


limeA11 =
    "var(--lime-a11)"


limeA12 =
    "var(--lime-a12)"


mauve1 =
    "var(--mauve-1)"


mauve2 =
    "var(--mauve-2)"


mauve3 =
    "var(--mauve-3)"


mauve4 =
    "var(--mauve-4)"


mauve5 =
    "var(--mauve-5)"


mauve6 =
    "var(--mauve-6)"


mauve7 =
    "var(--mauve-7)"


mauve8 =
    "var(--mauve-8)"


mauve9 =
    "var(--mauve-9)"


mauve10 =
    "var(--mauve-10)"


mauve11 =
    "var(--mauve-11)"


mauve12 =
    "var(--mauve-12)"


mauveA1 =
    "var(--mauve-a1)"


mauveA2 =
    "var(--mauve-a2)"


mauveA3 =
    "var(--mauve-a3)"


mauveA4 =
    "var(--mauve-a4)"


mauveA5 =
    "var(--mauve-a5)"


mauveA6 =
    "var(--mauve-a6)"


mauveA7 =
    "var(--mauve-a7)"


mauveA8 =
    "var(--mauve-a8)"


mauveA9 =
    "var(--mauve-a9)"


mauveA10 =
    "var(--mauve-a10)"


mauveA11 =
    "var(--mauve-a11)"


mauveA12 =
    "var(--mauve-a12)"


mint1 =
    "var(--mint-1)"


mint2 =
    "var(--mint-2)"


mint3 =
    "var(--mint-3)"


mint4 =
    "var(--mint-4)"


mint5 =
    "var(--mint-5)"


mint6 =
    "var(--mint-6)"


mint7 =
    "var(--mint-7)"


mint8 =
    "var(--mint-8)"


mint9 =
    "var(--mint-9)"


mint10 =
    "var(--mint-10)"


mint11 =
    "var(--mint-11)"


mint12 =
    "var(--mint-12)"


mintA1 =
    "var(--mint-a1)"


mintA2 =
    "var(--mint-a2)"


mintA3 =
    "var(--mint-a3)"


mintA4 =
    "var(--mint-a4)"


mintA5 =
    "var(--mint-a5)"


mintA6 =
    "var(--mint-a6)"


mintA7 =
    "var(--mint-a7)"


mintA8 =
    "var(--mint-a8)"


mintA9 =
    "var(--mint-a9)"


mintA10 =
    "var(--mint-a10)"


mintA11 =
    "var(--mint-a11)"


mintA12 =
    "var(--mint-a12)"


olive1 =
    "var(--olive-1)"


olive2 =
    "var(--olive-2)"


olive3 =
    "var(--olive-3)"


olive4 =
    "var(--olive-4)"


olive5 =
    "var(--olive-5)"


olive6 =
    "var(--olive-6)"


olive7 =
    "var(--olive-7)"


olive8 =
    "var(--olive-8)"


olive9 =
    "var(--olive-9)"


olive10 =
    "var(--olive-10)"


olive11 =
    "var(--olive-11)"


olive12 =
    "var(--olive-12)"


oliveA1 =
    "var(--olive-a1)"


oliveA2 =
    "var(--olive-a2)"


oliveA3 =
    "var(--olive-a3)"


oliveA4 =
    "var(--olive-a4)"


oliveA5 =
    "var(--olive-a5)"


oliveA6 =
    "var(--olive-a6)"


oliveA7 =
    "var(--olive-a7)"


oliveA8 =
    "var(--olive-a8)"


oliveA9 =
    "var(--olive-a9)"


oliveA10 =
    "var(--olive-a10)"


oliveA11 =
    "var(--olive-a11)"


oliveA12 =
    "var(--olive-a12)"


orange1 =
    "var(--orange-1)"


orange2 =
    "var(--orange-2)"


orange3 =
    "var(--orange-3)"


orange4 =
    "var(--orange-4)"


orange5 =
    "var(--orange-5)"


orange6 =
    "var(--orange-6)"


orange7 =
    "var(--orange-7)"


orange8 =
    "var(--orange-8)"


orange9 =
    "var(--orange-9)"


orange10 =
    "var(--orange-10)"


orange11 =
    "var(--orange-11)"


orange12 =
    "var(--orange-12)"


orangeA1 =
    "var(--orange-a1)"


orangeA2 =
    "var(--orange-a2)"


orangeA3 =
    "var(--orange-a3)"


orangeA4 =
    "var(--orange-a4)"


orangeA5 =
    "var(--orange-a5)"


orangeA6 =
    "var(--orange-a6)"


orangeA7 =
    "var(--orange-a7)"


orangeA8 =
    "var(--orange-a8)"


orangeA9 =
    "var(--orange-a9)"


orangeA10 =
    "var(--orange-a10)"


orangeA11 =
    "var(--orange-a11)"


orangeA12 =
    "var(--orange-a12)"


pink1 =
    "var(--pink-1)"


pink2 =
    "var(--pink-2)"


pink3 =
    "var(--pink-3)"


pink4 =
    "var(--pink-4)"


pink5 =
    "var(--pink-5)"


pink6 =
    "var(--pink-6)"


pink7 =
    "var(--pink-7)"


pink8 =
    "var(--pink-8)"


pink9 =
    "var(--pink-9)"


pink10 =
    "var(--pink-10)"


pink11 =
    "var(--pink-11)"


pink12 =
    "var(--pink-12)"


pinkA1 =
    "var(--pink-a1)"


pinkA2 =
    "var(--pink-a2)"


pinkA3 =
    "var(--pink-a3)"


pinkA4 =
    "var(--pink-a4)"


pinkA5 =
    "var(--pink-a5)"


pinkA6 =
    "var(--pink-a6)"


pinkA7 =
    "var(--pink-a7)"


pinkA8 =
    "var(--pink-a8)"


pinkA9 =
    "var(--pink-a9)"


pinkA10 =
    "var(--pink-a10)"


pinkA11 =
    "var(--pink-a11)"


pinkA12 =
    "var(--pink-a12)"


plum1 =
    "var(--plum-1)"


plum2 =
    "var(--plum-2)"


plum3 =
    "var(--plum-3)"


plum4 =
    "var(--plum-4)"


plum5 =
    "var(--plum-5)"


plum6 =
    "var(--plum-6)"


plum7 =
    "var(--plum-7)"


plum8 =
    "var(--plum-8)"


plum9 =
    "var(--plum-9)"


plum10 =
    "var(--plum-10)"


plum11 =
    "var(--plum-11)"


plum12 =
    "var(--plum-12)"


plumA1 =
    "var(--plum-a1)"


plumA2 =
    "var(--plum-a2)"


plumA3 =
    "var(--plum-a3)"


plumA4 =
    "var(--plum-a4)"


plumA5 =
    "var(--plum-a5)"


plumA6 =
    "var(--plum-a6)"


plumA7 =
    "var(--plum-a7)"


plumA8 =
    "var(--plum-a8)"


plumA9 =
    "var(--plum-a9)"


plumA10 =
    "var(--plum-a10)"


plumA11 =
    "var(--plum-a11)"


plumA12 =
    "var(--plum-a12)"


purple1 =
    "var(--purple-1)"


purple2 =
    "var(--purple-2)"


purple3 =
    "var(--purple-3)"


purple4 =
    "var(--purple-4)"


purple5 =
    "var(--purple-5)"


purple6 =
    "var(--purple-6)"


purple7 =
    "var(--purple-7)"


purple8 =
    "var(--purple-8)"


purple9 =
    "var(--purple-9)"


purple10 =
    "var(--purple-10)"


purple11 =
    "var(--purple-11)"


purple12 =
    "var(--purple-12)"


purpleA1 =
    "var(--purple-a1)"


purpleA2 =
    "var(--purple-a2)"


purpleA3 =
    "var(--purple-a3)"


purpleA4 =
    "var(--purple-a4)"


purpleA5 =
    "var(--purple-a5)"


purpleA6 =
    "var(--purple-a6)"


purpleA7 =
    "var(--purple-a7)"


purpleA8 =
    "var(--purple-a8)"


purpleA9 =
    "var(--purple-a9)"


purpleA10 =
    "var(--purple-a10)"


purpleA11 =
    "var(--purple-a11)"


purpleA12 =
    "var(--purple-a12)"


red1 =
    "var(--red-1)"


red2 =
    "var(--red-2)"


red3 =
    "var(--red-3)"


red4 =
    "var(--red-4)"


red5 =
    "var(--red-5)"


red6 =
    "var(--red-6)"


red7 =
    "var(--red-7)"


red8 =
    "var(--red-8)"


red9 =
    "var(--red-9)"


red10 =
    "var(--red-10)"


red11 =
    "var(--red-11)"


red12 =
    "var(--red-12)"


redA1 =
    "var(--red-a1)"


redA2 =
    "var(--red-a2)"


redA3 =
    "var(--red-a3)"


redA4 =
    "var(--red-a4)"


redA5 =
    "var(--red-a5)"


redA6 =
    "var(--red-a6)"


redA7 =
    "var(--red-a7)"


redA8 =
    "var(--red-a8)"


redA9 =
    "var(--red-a9)"


redA10 =
    "var(--red-a10)"


redA11 =
    "var(--red-a11)"


redA12 =
    "var(--red-a12)"


ruby1 =
    "var(--ruby-1)"


ruby2 =
    "var(--ruby-2)"


ruby3 =
    "var(--ruby-3)"


ruby4 =
    "var(--ruby-4)"


ruby5 =
    "var(--ruby-5)"


ruby6 =
    "var(--ruby-6)"


ruby7 =
    "var(--ruby-7)"


ruby8 =
    "var(--ruby-8)"


ruby9 =
    "var(--ruby-9)"


ruby10 =
    "var(--ruby-10)"


ruby11 =
    "var(--ruby-11)"


ruby12 =
    "var(--ruby-12)"


rubyA1 =
    "var(--ruby-a1)"


rubyA2 =
    "var(--ruby-a2)"


rubyA3 =
    "var(--ruby-a3)"


rubyA4 =
    "var(--ruby-a4)"


rubyA5 =
    "var(--ruby-a5)"


rubyA6 =
    "var(--ruby-a6)"


rubyA7 =
    "var(--ruby-a7)"


rubyA8 =
    "var(--ruby-a8)"


rubyA9 =
    "var(--ruby-a9)"


rubyA10 =
    "var(--ruby-a10)"


rubyA11 =
    "var(--ruby-a11)"


rubyA12 =
    "var(--ruby-a12)"


sage1 =
    "var(--sage-1)"


sage2 =
    "var(--sage-2)"


sage3 =
    "var(--sage-3)"


sage4 =
    "var(--sage-4)"


sage5 =
    "var(--sage-5)"


sage6 =
    "var(--sage-6)"


sage7 =
    "var(--sage-7)"


sage8 =
    "var(--sage-8)"


sage9 =
    "var(--sage-9)"


sage10 =
    "var(--sage-10)"


sage11 =
    "var(--sage-11)"


sage12 =
    "var(--sage-12)"


sageA1 =
    "var(--sage-a1)"


sageA2 =
    "var(--sage-a2)"


sageA3 =
    "var(--sage-a3)"


sageA4 =
    "var(--sage-a4)"


sageA5 =
    "var(--sage-a5)"


sageA6 =
    "var(--sage-a6)"


sageA7 =
    "var(--sage-a7)"


sageA8 =
    "var(--sage-a8)"


sageA9 =
    "var(--sage-a9)"


sageA10 =
    "var(--sage-a10)"


sageA11 =
    "var(--sage-a11)"


sageA12 =
    "var(--sage-a12)"


sand1 =
    "var(--sand-1)"


sand2 =
    "var(--sand-2)"


sand3 =
    "var(--sand-3)"


sand4 =
    "var(--sand-4)"


sand5 =
    "var(--sand-5)"


sand6 =
    "var(--sand-6)"


sand7 =
    "var(--sand-7)"


sand8 =
    "var(--sand-8)"


sand9 =
    "var(--sand-9)"


sand10 =
    "var(--sand-10)"


sand11 =
    "var(--sand-11)"


sand12 =
    "var(--sand-12)"


sandA1 =
    "var(--sand-a1)"


sandA2 =
    "var(--sand-a2)"


sandA3 =
    "var(--sand-a3)"


sandA4 =
    "var(--sand-a4)"


sandA5 =
    "var(--sand-a5)"


sandA6 =
    "var(--sand-a6)"


sandA7 =
    "var(--sand-a7)"


sandA8 =
    "var(--sand-a8)"


sandA9 =
    "var(--sand-a9)"


sandA10 =
    "var(--sand-a10)"


sandA11 =
    "var(--sand-a11)"


sandA12 =
    "var(--sand-a12)"


sky1 =
    "var(--sky-1)"


sky2 =
    "var(--sky-2)"


sky3 =
    "var(--sky-3)"


sky4 =
    "var(--sky-4)"


sky5 =
    "var(--sky-5)"


sky6 =
    "var(--sky-6)"


sky7 =
    "var(--sky-7)"


sky8 =
    "var(--sky-8)"


sky9 =
    "var(--sky-9)"


sky10 =
    "var(--sky-10)"


sky11 =
    "var(--sky-11)"


sky12 =
    "var(--sky-12)"


skyA1 =
    "var(--sky-a1)"


skyA2 =
    "var(--sky-a2)"


skyA3 =
    "var(--sky-a3)"


skyA4 =
    "var(--sky-a4)"


skyA5 =
    "var(--sky-a5)"


skyA6 =
    "var(--sky-a6)"


skyA7 =
    "var(--sky-a7)"


skyA8 =
    "var(--sky-a8)"


skyA9 =
    "var(--sky-a9)"


skyA10 =
    "var(--sky-a10)"


skyA11 =
    "var(--sky-a11)"


skyA12 =
    "var(--sky-a12)"


slate1 =
    "var(--slate-1)"


slate2 =
    "var(--slate-2)"


slate3 =
    "var(--slate-3)"


slate4 =
    "var(--slate-4)"


slate5 =
    "var(--slate-5)"


slate6 =
    "var(--slate-6)"


slate7 =
    "var(--slate-7)"


slate8 =
    "var(--slate-8)"


slate9 =
    "var(--slate-9)"


slate10 =
    "var(--slate-10)"


slate11 =
    "var(--slate-11)"


slate12 =
    "var(--slate-12)"


slateA1 =
    "var(--slate-a1)"


slateA2 =
    "var(--slate-a2)"


slateA3 =
    "var(--slate-a3)"


slateA4 =
    "var(--slate-a4)"


slateA5 =
    "var(--slate-a5)"


slateA6 =
    "var(--slate-a6)"


slateA7 =
    "var(--slate-a7)"


slateA8 =
    "var(--slate-a8)"


slateA9 =
    "var(--slate-a9)"


slateA10 =
    "var(--slate-a10)"


slateA11 =
    "var(--slate-a11)"


slateA12 =
    "var(--slate-a12)"


teal1 =
    "var(--teal-1)"


teal2 =
    "var(--teal-2)"


teal3 =
    "var(--teal-3)"


teal4 =
    "var(--teal-4)"


teal5 =
    "var(--teal-5)"


teal6 =
    "var(--teal-6)"


teal7 =
    "var(--teal-7)"


teal8 =
    "var(--teal-8)"


teal9 =
    "var(--teal-9)"


teal10 =
    "var(--teal-10)"


teal11 =
    "var(--teal-11)"


teal12 =
    "var(--teal-12)"


tealA1 =
    "var(--teal-a1)"


tealA2 =
    "var(--teal-a2)"


tealA3 =
    "var(--teal-a3)"


tealA4 =
    "var(--teal-a4)"


tealA5 =
    "var(--teal-a5)"


tealA6 =
    "var(--teal-a6)"


tealA7 =
    "var(--teal-a7)"


tealA8 =
    "var(--teal-a8)"


tealA9 =
    "var(--teal-a9)"


tealA10 =
    "var(--teal-a10)"


tealA11 =
    "var(--teal-a11)"


tealA12 =
    "var(--teal-a12)"


tomato1 =
    "var(--tomato-1)"


tomato2 =
    "var(--tomato-2)"


tomato3 =
    "var(--tomato-3)"


tomato4 =
    "var(--tomato-4)"


tomato5 =
    "var(--tomato-5)"


tomato6 =
    "var(--tomato-6)"


tomato7 =
    "var(--tomato-7)"


tomato8 =
    "var(--tomato-8)"


tomato9 =
    "var(--tomato-9)"


tomato10 =
    "var(--tomato-10)"


tomato11 =
    "var(--tomato-11)"


tomato12 =
    "var(--tomato-12)"


tomatoA1 =
    "var(--tomato-a1)"


tomatoA2 =
    "var(--tomato-a2)"


tomatoA3 =
    "var(--tomato-a3)"


tomatoA4 =
    "var(--tomato-a4)"


tomatoA5 =
    "var(--tomato-a5)"


tomatoA6 =
    "var(--tomato-a6)"


tomatoA7 =
    "var(--tomato-a7)"


tomatoA8 =
    "var(--tomato-a8)"


tomatoA9 =
    "var(--tomato-a9)"


tomatoA10 =
    "var(--tomato-a10)"


tomatoA11 =
    "var(--tomato-a11)"


tomatoA12 =
    "var(--tomato-a12)"


violet1 =
    "var(--violet-1)"


violet2 =
    "var(--violet-2)"


violet3 =
    "var(--violet-3)"


violet4 =
    "var(--violet-4)"


violet5 =
    "var(--violet-5)"


violet6 =
    "var(--violet-6)"


violet7 =
    "var(--violet-7)"


violet8 =
    "var(--violet-8)"


violet9 =
    "var(--violet-9)"


violet10 =
    "var(--violet-10)"


violet11 =
    "var(--violet-11)"


violet12 =
    "var(--violet-12)"


violetA1 =
    "var(--violet-a1)"


violetA2 =
    "var(--violet-a2)"


violetA3 =
    "var(--violet-a3)"


violetA4 =
    "var(--violet-a4)"


violetA5 =
    "var(--violet-a5)"


violetA6 =
    "var(--violet-a6)"


violetA7 =
    "var(--violet-a7)"


violetA8 =
    "var(--violet-a8)"


violetA9 =
    "var(--violet-a9)"


violetA10 =
    "var(--violet-a10)"


violetA11 =
    "var(--violet-a11)"


violetA12 =
    "var(--violet-a12)"


whiteA1 =
    "var(--white-a1)"


whiteA2 =
    "var(--white-a2)"


whiteA3 =
    "var(--white-a3)"


whiteA4 =
    "var(--white-a4)"


whiteA5 =
    "var(--white-a5)"


whiteA6 =
    "var(--white-a6)"


whiteA7 =
    "var(--white-a7)"


whiteA8 =
    "var(--white-a8)"


whiteA9 =
    "var(--white-a9)"


whiteA10 =
    "var(--white-a10)"


whiteA11 =
    "var(--white-a11)"


whiteA12 =
    "var(--white-a12)"


yellow1 =
    "var(--yellow-1)"


yellow2 =
    "var(--yellow-2)"


yellow3 =
    "var(--yellow-3)"


yellow4 =
    "var(--yellow-4)"


yellow5 =
    "var(--yellow-5)"


yellow6 =
    "var(--yellow-6)"


yellow7 =
    "var(--yellow-7)"


yellow8 =
    "var(--yellow-8)"


yellow9 =
    "var(--yellow-9)"


yellow10 =
    "var(--yellow-10)"


yellow11 =
    "var(--yellow-11)"


yellow12 =
    "var(--yellow-12)"


yellowA1 =
    "var(--yellow-a1)"


yellowA2 =
    "var(--yellow-a2)"


yellowA3 =
    "var(--yellow-a3)"


yellowA4 =
    "var(--yellow-a4)"


yellowA5 =
    "var(--yellow-a5)"


yellowA6 =
    "var(--yellow-a6)"


yellowA7 =
    "var(--yellow-a7)"


yellowA8 =
    "var(--yellow-a8)"


yellowA9 =
    "var(--yellow-a9)"


yellowA10 =
    "var(--yellow-a10)"


yellowA11 =
    "var(--yellow-a11)"


yellowA12 =
    "var(--yellow-a12)"

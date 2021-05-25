#!/bin/bash
export GRASS_RENDER_IMMEDIATE=cairo
export GRASS_RENDER_WIDTH=1500
export GRASS_RENDER_HEIGHT=1183
export GRASS_RENDER_FILE_READ=TRUE
export GRASS_FONT=/usr/share/fonts/truetype/freefont/FreeSansBold.ttf

g.region raster=elevation_1997 res=2 -a

# create dashed line
D=50
DD=$(($D + $D))
S=0
rm seg_tmp.txt
for I in `seq 0 $DD 10500`
do
   D_TMP=$(($D))
   echo "L 1 1 $S $(($S + $D))" >> seg_tmp.txt
   S=$(($S + $DD))
done
v.segment --o input=shoreline_2018 output=shoreline_2018_seg rules=seg_tmp.txt

rm *.png
rm *.gif
#for E in elevation_1997 #`g.list type=raster mapset=elevation_timeseries exc="*ground"`
#for E in `g.list type=raster mapset=elevation_timeseries exc="*ground"`
#for E in `g.list type=raster pattern="coast*"` `g.list type=raster mapset=elevation_timeseries exc="*_*_*"`
for E in `g.list type=raster pattern="coast*"` elevation_1997 elevation_1998 elevation_1999 elevation_2000 elevation_2001 elevation_2004 elevation_2005  elevation_2010_ground elevation_2014_ground elevation_2016_ground elevation_2017_ground elevation_2018_ground


do
    r.mapcalc "new = if($E > 0.01, 1, 0)" --o --q
    r.colors new --q rules=- <<EOF
0 130:220:235
1 239:198:42
EOF
    T=`r.timestamp map=$E`
    T="`python -c """print '$T'.split()[2] if len('$T'.split()) < 7 else '$T'.split()[2] + ' - ' + '$T'.split()[6]"""`"
    ST="`python -c """print '$T'.replace(' - ', '_') if '-' in '$T' else '$T'"""`"
    d.rast new
    d.vect map=shoreline_${ST} color=98:85:36 width=3 --q
    d.vect map=shoreline_2018_seg color=98:85:36 width=3 --q
    d.vect map=transportation@PERMANENT where="highway = 'path'" width=2 color=50:50:50 --q
    d.vect map=transportation@PERMANENT where="highway <> 'path'" color=94:94:94 width=1 --q
    d.vect map=buildings color=none fill_color=77:77:77 width=1 --q
    d.barscale -f style=solid at=0,5 bgcolor=none fontsize=30 color=50:50:50 --q
    d.text text="$T" at=60,3 color=50:50:50 --q
    mv map.png $E.png
    pngnq $E.png
    optipng -o5 $E-nq8.png
    mv $E-nq8.png $E.png
done
convert -delay 1x1  `ls coast* elevation* -tr` -coalesce -layers OptimizeTransparency animation.gif
convert animation.gif \( +clone -set delay 500 \) +swap +delete  animation_with_pause.gif

for I in `ls *.png -tr`
do
    echo \<section data-background="img/island/$I" data-background-size="100%"\>\<\/section\>
done


#!/bin/bash
export GRASS_RENDER_IMMEDIATE=cairo
export GRASS_RENDER_WIDTH=1000
export GRASS_RENDER_HEIGHT=640
#export GRASS_RENDER_HEIGHT=884
export GRASS_RENDER_FILE_READ=TRUE
export GRASS_FONT=/usr/share/fonts/truetype/freefont/FreeSansBold.ttf

g.region n=11670 s=10625 e=706108 w=704476 res=1 -a
#g.region n=11670 s=10226 e=706108 w=704476 res=1 -a

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
v.segment --o input=shoreline_2014_cat output=shoreline_2014_seg rules=seg_tmp.txt

rm *.png
rm *.gif
#for E in elevation_1997 #`g.list type=raster mapset=elevation_timeseries exc="*ground"`
#for E in `g.list type=raster mapset=elevation_timeseries exc="*ground"`
for E in `g.list type=raster mapset=elevation_timeseries exc="*_*_*"`

do
    T=`r.timestamp map=$E`
    T="`python -c """print '$T'.split()[2] if len('$T'.split()) < 7 else '$T'.split()[2] + ' - ' + '$T'.split()[6]"""`"
    ST="`python -c """print '$T'.replace(' - ', '_') if '-' in '$T' else '$T'"""`"
    d.rast $E
    #d.vect map=shoreline_${ST} color=98:85:36 width=3 --q
    #d.vect map=shoreline_2014_seg color=98:85:36 width=3 --q
    d.vect map=transportation@PERMANENT where="highway = 'path'" width=2 color=50:50:50 --q
    d.vect map=transportation@PERMANENT where="highway <> 'path'" color=94:94:94 width=1 --q
    d.vect map=buildings width=1 --q
    d.barscale -f style=solid at=1,6 bgcolor=none fontsize=25 color=50:50:50 --q
    d.text text="$T" at=55,3 color=50:50:50 --q
    d.legend raster=elev_feet labelnum=6 at=10,40,3.5,8 range=0,50 fontsize=20 color=50:50:50
    d.text at=3.5,45 color=50:50:50 --q size=3 << EOF
Elevation
in feet
EOF
    
    mv map.png ${E}_cape.png
    pngnq ${E}_cape.png
    optipng -o5 ${E}_cape-nq8.png
    mv ${E}_cape-nq8.png ${E}_cape.png
done
convert -delay 1x1  `ls coast* elevation* -tr` -coalesce -layers OptimizeTransparency animation.gif
convert animation.gif \( +clone -set delay 500 \) +swap +delete  animation_with_pause.gif

for I in `ls *.png -tr`
do
    echo \<section data-background="img/cape/$I" data-background-size="100%"\>\<\/section\>
done


#!/bin/sh

########################################################################################################################
mkdir ./temp/
mkdir ./temp/.libs/
mkdir ./out/
########################################################################################################################

cd ./temp/
INCLUDE=`pwd`

########################################################################################################################
#Script used to convert cmf to wave
########################################################################################################################
echo LD_LIBRARY_PATH=./.libs/ ./gamemus -w \"\$2\" \"\$1\" > cmf2wav.sh
chmod +x ./cmf2wav.sh

########################################################################################################################
#Script used to fix the GFX
echo "echo -en \"\x46\x4f\x52\x4d\x00\x00\x9d\xd2\x49\x4c\x42\x4d\x42\x4d\x48\x44\"" > gfx-fix.sh
echo "tail -c +17" >> gfx-fix.sh
chmod +x ./gfx-fix.sh

echo "FILE=\`echo \"\$1\" | rev | cut -d/ -f 1 | rev | cut -d. -f1\`" > gfx-process.sh
echo "cat \"\$1\" | ../temp/gfx-fix.sh | ilbmtoppm -verbose | ppmtobmp -bpp 24 > ../out/gfx_\$FILE.bmp" >> gfx-process.sh 
chmod +x ./gfx-process.sh

########################################################################################################################
# Download the libgame. This is used to convert the Creative Music File to wav
########################################################################################################################
wget https://github.com/Malvineous/libgamecommon/releases/download/v1.2/libgamecommon-1.2.tar.bz2 -O libgamecommon-1.2.tar.bz2
wget https://github.com/Malvineous/libgamemusic/releases/download/v1.2/libgamemusic-1.2.tar.bz2 -O libgamemusic-1.2.tar.bz2

tar jxf ./libgamecommon-1.2.tar.bz2
cd ./libgamecommon-1.2
./configure
make

#Prepare the libs and exports to compile the libgamemusic
export libgamecommon_LIBS=`pwd`/src/.libs/libgamecommon.so
export libgamecommon_CFLAGS=-I`pwd`/include
cp `pwd`/src/.libs/libgamecommon.so* ../.libs/
cd ../

#Compile the lib game music
tar jxf ./libgamemusic-1.2.tar.bz2
cd ./libgamemusic-1.2
./configure
make
cp `pwd`/src/.libs/libgamemusic.so* ../.libs/
mv ./examples/.libs/gamemus ../.libs/
mv ./examples/gamemus ../
cd ../

########################################################################################################################
# Download and compile the "ripper" - library used to extract SFX and MUSIC from the game files
########################################################################################################################
wget https://github.com/Malvineous/ripper6/releases/download/v0.1/ripper6-0.1.tar.bz2 -O ripper6.tar.bz2
tar jxf ./ripper6.tar.bz2 
cd ./ripper6-0.1/
./configure
make
mv ./src/ripper6 ../
cd ../

########################################################################################################################
# Extract and conver teh SFX and MUSIC
########################################################################################################################
find ../game/ -iname digi.dat | xargs -n1 -I% ../temp/ripper6 %
find ../game/ -iname music.dat | xargs -n1 -I% ../temp/ripper6 %
#
ls -1 *.voc | cut -d . -f 1 | xargs -n1 -I% ffmpeg -i %.voc -acodec pcm_s16le -ac 1 -ar 48000 ../out/digi_%.wav
ls -1 *.cmf | cut -d . -f 1 | xargs -n1 -I% ./cmf2wav.sh ./%.cmf ../out/mus_%.wav

########################################################################################################################
# Fix and convert the GFX
########################################################################################################################
find ../game/ -iname *.img | xargs -n1 -I% ../temp/gfx-process.sh %

cd ../

rm -fr ./temp/
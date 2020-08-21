# #!/bin/sh
# Exist on first fail
set -e
# Run this after fonts have been generated

# Go the sources directory to run commands
SOURCE="${BASH_SOURCE[0]}"
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd $DIR
echo $(pwd)

echo "Generating VFs"
mkdir -p ../fonts/variable
fontmake -m MerriweatherSans.designspace -o variable --output-path ../fonts/variable/MerriweatherSans[wght].ttf
fontmake -m MerriweatherSans-Italic.designspace -o variable --output-path ../fonts/variable/MerriweatherSans-Italic[wght].ttf

rm -rf master_ufo/ instance_ufo/ instance_ufos/*

vfs=$(ls ../fonts/variable/*\[wght\].ttf)

echo "Post processing VFs"
for vf in $vfs
do
	gftools fix-dsig -f $vf;
	gftools fix-nonhinting $vf $vf.fix
	mv $vf.fix $vf
	# python3 -m ttfautohint --stem-width-mode nnn $vf "$vf.fix";
	# mv "$vf.fix" $vf;
done
rm ../fonts/variable/*gasp.ttf

gftools fix-vf-meta $vfs
for vf in $vfs
do
	mv $vf.fix $vf
done

echo "Dropping MVAR"
for vf in $vfs
do
	# mv "$vf.fix" $vf;
	ttx -f -x "MVAR" $vf; # Drop MVAR. Table has issue in DW
	rtrip=$(basename -s .ttf $vf)
	new_file=../fonts/variable/$rtrip.ttx;
	rm $vf;
	ttx $new_file
	rm $new_file
done


echo "Generating Static fonts"
mkdir -p ../fonts
fontmake -m MerriweatherSans.designspace -i -o ttf --output-dir ../fonts/ttf/
fontmake -m MerriweatherSans.designspace -i -o otf --output-dir ../fonts/otf/
fontmake -m MerriweatherSans-Italic.designspace -i -o ttf --output-dir ../fonts/ttf/
fontmake -m MerriweatherSans-Italic.designspace -i -o otf --output-dir ../fonts/otf/

echo "Post processing"
ttf=$(ls ../fonts/ttf/*.ttf)
for ttf in $ttf
do
	gftools fix-dsig -f $ttf;
	python3 -m ttfautohint -l 6 -r 50 -G 0 -x 11 -H 220 -D latn -f none -a qqq -X "" $ttf "$ttf.fix";
	mv "$ttf.fix" $ttf;
done

for ttf in $ttf
do
  gftools fix-hinting $ttf;
  mv "$ttf.fix" $ttf;
done

echo "Fix DSIG in OTFs"
otfs=$(ls ../fonts/otf/*.otf)
for otf in $otfs
do
	gftools fix-dsig -f $otf;
done

rm -rf master_ufo/ instance_ufo/ instance_ufos/*

echo done

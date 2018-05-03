#!/bin/bash

source conf.sh

data_origin=0x01000000

if [ -z "$2" ]; then
    output=.
else
    output=$2
fi

# dump all segments
${MIPS32_GCC_PATH}/bin/${MIPS32_GCC_PREFIX}-readelf -l $1 | tail -n 2 > segments_dump

# remove leading white spaces
sed "s/^[ \t]*//" -i segments_dump

# remove segment numbers
cut -d " " -f 2- segments_dump > segments

# remove leading white spaces
sed "s/^[ \t]*//" -i segments

# save sections of text segment
head -n 1 segments > text_sections

# save sections of data segment
tail -n 1 segments > data_sections

# process text segment

if [ -a text ]; then
    rm text
fi

touch text

for i in $(head -n 1 text_sections); do
    # dump all text sections into one file
    ${MIPS32_GCC_PATH}/bin/${MIPS32_GCC_PREFIX}-readelf -x $i $1 | cut -c3-48 | tail -n +3 | head -n -1 >> text
done

awk '{printf "%s ",$1;
printf "%s%s%s%s ",substr($2,7,2),substr($2,5,2),substr($2,3,2),substr($2,1,2);
printf "%s%s%s%s ",substr($3,7,2),substr($3,5,2),substr($3,3,2),substr($3,1,2);
printf "%s%s%s%s ",substr($4,7,2),substr($4,5,2),substr($4,3,2),substr($4,1,2);
printf "%s%s%s%s\n",substr($5,7,2),substr($5,5,2),substr($5,3,2),substr($5,1,2)};' text > tmp && mv tmp text

# update addresses (word addresses vs byte addresses)
awk --non-decimal-data '{$1/=4}1' text > tmp && mv tmp text

# header for modelsim
echo "// instance=/tb_packet_processor_top/inst_write_instr/bram
// format=mti addressradix=d dataradix=h version=1.0 wordsperline=4" > $output/instr.mem

# add : for modelsim
awk '{$1=$1":"}1' text >> $output/instr.mem

# process data segment

if [ -a data ]; then
    rm data
fi

touch data

for i in $(head -n 1 data_sections); do
    # dump all text sections into one file
    ${MIPS32_GCC_PATH}/bin/${MIPS32_GCC_PREFIX}-readelf -x $i $1 | cut -c3-48 | tail -n +3 | head -n -1 >> data
done

awk '{printf "%s ",$1;
printf "%s%s%s%s ",substr($2,7,2),substr($2,5,2),substr($2,3,2),substr($2,1,2);
printf "%s%s%s%s ",substr($3,7,2),substr($3,5,2),substr($3,3,2),substr($3,1,2);
printf "%s%s%s%s ",substr($4,7,2),substr($4,5,2),substr($4,3,2),substr($4,1,2);
printf "%s%s%s%s\n",substr($5,7,2),substr($5,5,2),substr($5,3,2),substr($5,1,2)};' data > tmp && mv tmp data

# update addresses (word addresses vs byte addresses)
awk --non-decimal-data "{\$1=(\$1-$data_origin)/4}1" data > tmp && mv tmp data

# header for modelsim
echo "// instance=/tb_packet_processor_top/inst_write_data/bram
// format=mti addressradix=d dataradix=h version=1.0 wordsperline=4" > $output/data.mem

# add : for modelsim
awk '{$1=$1":"}1' data >> $output/data.mem

# clean up
rm segments_dump segments text_sections data_sections text data

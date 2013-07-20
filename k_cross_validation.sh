#!/bin/bash
# Input Format: sh k_cross_validation.sh datafile numpartitions [vwarguments]
# example input: sh k_cross_validation.sh 0001.dat 10 '-l 0.01 --passes 10 -c'
# result will be dafault to stdout
partition=$2
filename=$1
vwargs=$3

#the number of lines in our data
linesize=`wc -l < $1`

#get the number of lines for each splited file
splitsize=`expr '(' $linesize + $2 - 1 ')' / $2`

#splitting up the data file...
`split -l $splitsize $1 tempcrossv`

#Make a temporary folder and move the files into the folder
#Warning: Should not have files in the orignial folder that has prefix tempcrossv
#Warning: Should not already has folder called tempcross, all the files in this folder will get deleted in the end
mkdir tempcross
mv tempcrossv* tempcross
cd tempcross

############################################
# core logic:
# A,rename one file to test.dat and combine all other files to train
# B,use the trained model to do prediction on the test data set
# C,rename the test dataset back to its orgnial name
# D,repeat this for number of partition times
############################################
totalloss=0
for file in tempcross*
do
   fn=$(basename "$file")
   mv $fn test.dat
   cat tempcrossv* >> train.dat
   vw train.dat $vwargs -f train.model --quiet
   loss=`vw -p ../predict -t test.dat -i train.model 2>&1 | grep "average loss" | cut -c 16-`
   loss=`printf '%f' $loss`
   totalloss=`echo "$loss + $totalloss" | bc`
   echo predicting on $fn, resulting average loss $loss 
   rm train.model train.dat 
   mv test.dat $fn
done



cd ..

#calculate average loss...
avgloss=`echo "$totalloss / $2" | bc -l`
echo average loss on $2 partitions is $avgloss

#cleaning up....
rm -rf tempcross
rm predict

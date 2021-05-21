#!/bin/bash
# author:菜鸟教程
# url:www.runoob.com
filename=run.sh
# method 1
:'
while read line
do
echo $line
done < $filename
'
# method 2
:'
cat $filename | while read line
do
echo $line
done
'
# method 3
for line in `cat $filename`
do
echo $line
done
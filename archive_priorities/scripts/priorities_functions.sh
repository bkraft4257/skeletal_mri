secret1_dcm_scan() {

    for ii in $(cat data.list); do

	echo "================================================================================"
	echo $ii
	echo

	cd $ii
	dcm_scan 20*

    done

}

secret1_dcm_parse() {

  outFile=$( dirname ${1})/dcmConvert_secret2.cfg

  echo
  echo ">>>>>>>>>> Selecting T1 axial images of the thigh "
  echo $1
  echo

  grep  'T1AXDBLEFTTHIGH\[TE36\]' $1 > ${1}.tmp1
  sed   -i -e 's/:thigh36//g' ${1}.tmp1
  sed   -i -e 's/T1AXDBLEFTTHIGH/t1/g' ${1}.tmp1
  sed   -i -e 's#\[TE36\]#_36ms#g'         ${1}.tmp1 
  sed   -i -e 's#\[TE66\]#_62ms#g'         ${1}.tmp1 

  dcm_add_rs ${1}.tmp1 > ${1}.tmp2
  
  mv -f ${1}.tmp2 $outFile

  rm -f ${1}.tmp[12] 

  cat $outFile
 
  echo
}


secret2_dcm_parse() {

  outFile=$( dirname ${1})/dcmConvert_secret2.cfg

  echo
  echo ">>>>>>>>>> Selecting T1 axial images of the thigh "
  echo $1
  echo

  grep  'T1AXDBLEFTTHIGH\[TE36\]' $1 > ${1}.tmp1
  sed   -i -e 's/:thigh36//g' ${1}.tmp1
  sed   -i -e 's/T1AXDBLEFTTHIGH/t1/g' ${1}.tmp1
  sed   -i -e 's#\[TE36\]#_36ms#g'         ${1}.tmp1 
  sed   -i -e 's#\[TE66\]#_62ms#g'         ${1}.tmp1 

  dcm_add_rs ${1}.tmp1 > ${1}.tmp2
  
  mv -f ${1}.tmp2 $outFile

  rm -f ${1}.tmp[12] 

  cat $outFile
 
  echo
}

#!/bin/bash

inSubjectDir=${1-$PWD}
inSubjectDir=$(readlink -f $inSubjectDir)

m0=m0_To_mask.muscle.nii.gz    # M0 image
maskM0=mask.m0_To_mask.muscle.nii.gz
pwi=pwi_To_mask.muscle.nii.gz

maskMuscle=mask.muscle.nii.gz

t2w=t2w.nii.gz
maskT2w=mask.t2w.nii.gz
labelsT2w=labels.t2w.nii.gz
labelsMuscle=labels.muscle.nii.gz

frequencyBackgroundMask=frequencyBackground.${maskT2w}
phaseBackgroundMask=phaseBackground.${maskT2w}

translationM0ExistFlag=true
translationMaskM0ExistFlag=true
translationPwiExistFlag=true

synM0ExistFlag=true
synMaskM0ExistFlag=true
synPwiExistFlag=true

maskMuscleExistFlag=true
frequencyBackgroundMaskExistFlag=true
phaseBackgroundMaskExistFlag=true

t2wExistFlag=true
maskT2wExistFlag=true
labelsT2wExistFlag=true
labelsMuscleExistFlag=true

[ -f translation.$m0 ]                || translationM0ExistFlag=false;
[ -f translation.$maskM0 ]            || translationMaskM0ExistFlag=false;
[ -f translation.$pwi             ]   || translationPwiExistFlag=false;

[ -f syn.$m0 ]                || synM0ExistFlag=false;
[ -f syn.$maskM0 ]            || synMaskM0ExistFlag=false;
[ -f syn.$pwi             ]   || synPwiExistFlag=false;

[ -f $maskMuscle ]                 || maskMuscleExistFlag=false;
[ -f $frequencyBackgroundMask  ]   || frequencyBackgroundMaskExistFlag=false;
[ -f $phaseBackgroundMask      ]   || phaseBackgroundMaskExistFlag=false;

[ -f $t2w             ]   || t2wExistFlag=false;
[ -f $maskT2w         ]   || maskT2wExistFlag=false;
[ -f $labelsT2w         ]   || labelsT2wExistFlag=false;
[ -f $labelsMuscle         ]   || labelsMuscleExistFlag=false;

echo "IW>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo $0
echo
echo "date, " $(date)
echo "user, " $(whoami)
echo "pwd,  "$(pwd)
echo
echo "inSubjectDir, "         $inSubjectDir
echo "inReorientDir, "        $inReorientDir
echo


printf "translation.m0, %s, %s \n"         "translation.$m0"      "$translationM0ExistFlag"
printf "translation.maskM0, %s, %s \n"     "translation.$maskM0"  "$translationMaskM0ExistFlag"
printf "translation.pwi, %s, %s \n\n"      "translation.$pwi"     "$translationPwiExistFlag"

printf "syn.m0, %s, %s \n"         "syn.$m0"      "$synM0ExistFlag"
printf "syn.maskM0, %s, %s \n"     "syn.$maskM0"  "$synMaskM0ExistFlag"
printf "syn.pwi, %s, %s \n\n"      "syn.$pwi"     "$synPwiExistFlag"

printf "maskMuscle, %s, %s \n" "$maskMuscle" "$maskMuscleExistFlag"
printf "frequencyBackgroudnMask, %s, %s \n" "frequencyBackground.${maskT2w}" "$frequencyBackgroundMaskExistFlag"
printf "phaseBackgroundMask,     %s, %s \n" "phaseBackground.${maskT2w}" "$phaseBackgroundMaskExistFlag"

printf "t2w, %s, %s \n" "$t2w" "$t2wExistFlag"
printf "maskT2w, %s, %s \n" "$maskT2w" "$maskT2wExistFlag"
printf "labelsT2w, %s, %s \n" "$labelsT2w" "$labelsT2wExistFlag"
printf "labelsMuscle, %s, %s \n" "$labelsMuscle" "$labelsMuscleExistFlag"

echo
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< <<<IW "
echo


if  $t2wExistFlag         && $labelsMuscleExistFlag     &&  \
    $synMaskM0ExistFlag   && $translationMaskM0ExistFlag && \
    $frequencyBackgroundMaskExistFlag    &&    $phaseBackgroundMaskExistFlag;  then

    cmd="freeview $t2w                          \
                   ${labelsMuscle}:colormap=lut:opacity=0.5 \
                   translation.${maskM0}:visible=0:colorscale=0.1,1:opacity=0.4 \
                   syn.${maskM0}:colormap=jet:colorscale=0.1,1:opacity=0.4 \
                   ${frequencyBackgroundMask}:colormap=jet:opacity=0.4  \
                   ${phaseBackgroundMask}:colormap=jet:opacity=0.4 "

    echo $cmd
    echo
    $cmd  2> /dev/null  &
    

else
    printf "\n\n\n!!!! Unable to display Figure 1 ------------------------------------- \n\n" ""

      printf "\t t2w, %s, %s \n" "$t2w" "$t2wExistFlag"
      printf "\t labelsMuscle, %s, %s \n" "$labelsMuscle" "$labelsMuscleExistFlag"

      printf "\t translation.maskM0, %s, %s \n"     "translation.$maskM0"  "$translationMaskM0ExistFlag"
      printf "\t syn.maskM0, %s, %s \n"             "syn.$maskM0"           "$synMaskM0ExistFlag"

      printf "\t frequencyBackgroudnMask, %s, %s \n" "frequencyBackground.${maskT2w}" "$frequencyBackgroundMaskExistFlag"
      printf "\t phaseBackgroundMask,     %s, %s \n" "phaseBackground.${maskT2w}" "$phaseBackgroundMaskExistFlag"

fi

if true; then 

if  $t2wExistFlag            		 &&   $labelsMuscleExistFlag    && \
    $translationM0ExistFlag  		 &&   $translationPwiExistFlag  &&  $translationMaskM0ExistFlag  && \
    $synM0ExistFlag          		 &&   $synPwiExistFlag          &&  $synMaskM0ExistFlag  &&         \
    $frequencyBackgroundMaskExistFlag    &&    $phaseBackgroundMaskExistFlag;  then

    cmd="freeview $t2w  \
                  ${labelsMuscle}:colormap=lut \
                  translation.$m0:visible=0 \
                  translation.${pwi}:visible=0:colormap=heat  \
                  translation.${maskM0}:visible=0:colorscale=0.1,1:opacity=0.4 \
                  syn.$m0:visible=0 \
                  syn.${pwi}:visible=0:colormap=heat \
                  syn.${maskM0}:colormap=jet:colorscale=0,300:opacity=0.4 \
                  ${frequencyBackgroundMask}:colormap=jet:opacity=0.4  \
                  ${phaseBackgroundMask}:colormap=jet:opacity=0.4 "

    echo $cmd
    echo
    $cmd  2> /dev/null &
    

else

printf "\n\n\n!!!! Second QA test failed %s ------------------------------------- \n\n" "!"


      printf "\t t2w, %s, %s \n" "$t2w" "$t2wExistFlag"
      printf "\t labelsMuscle, %s, %s \n\n" "$labelsMuscle" "$labelsMuscleExistFlag"

      printf "\t translation.m0, %s, %s \n"         "translation.$m0"      "$translationM0ExistFlag"
      printf "\t translation.maskM0, %s, %s \n"     "translation.$maskM0"  "$translationMaskM0ExistFlag"
      printf "\t translation.pwi, %s, %s \n\n"      "translation.$pwi"     "$translationPwiExistFlag"

      printf "\t syn.m0, %s, %s \n"         "syn.$m0"      "$synM0ExistFlag"
      printf "\t syn.maskM0, %s, %s \n"     "syn.$maskM0"  "$synMaskM0ExistFlag"
      printf "\t syn.pwi, %s, %s \n\n"      "syn.$pwi"     "$synPwiExistFlag"


      printf "\t frequencyBackgroudnMask, %s, %s \n" "frequencyBackground.${maskT2w}" "$frequencyBackgroundMaskExistFlag"
      printf "\t phaseBackgroundMask,     %s, %s \n" "phaseBackground.${maskT2w}" "$phaseBackgroundMaskExistFlag"

fi

fi
printf "\n\n"


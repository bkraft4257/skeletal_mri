
###
## MSK Project
##
#

alias  repri='source ${PRIORITIES_PATH}/priorities_alias.sh'
alias  cdp='cd $PRIORITIES_MRI_DATA/;echo;ls;echo'

alias cdpp='cd $PRIORITIES_PATH/;echo;ls;echo'
alias cdpm='cd $PRIORITIES_MATLAB/;echo;ls;echo'
alias cdps='cd $PRIORITIES_SCRIPTS/;echo;ls;echo'


function priid() {

    subjectID=$(pwd | grep -o 'pri[0-9][0-9]_[a-z][a-z][a-z][a-z][a-z]\/[1-3]')
    echo $subjectID
}


function priname() {

    subjectID=$(pwd | grep -o 'pri[0-9][0-9]_[a-z][a-z][a-z][a-z][a-z]')
    echo $subjectID
}

function privisit() {

    subjectID=$(pwd | grep -o 'pri[0-9][0-9]_[a-z][a-z][a-z][a-z][a-z]\/[1-3]')
    visit=${subjectID: -1}
    echo $visit
}




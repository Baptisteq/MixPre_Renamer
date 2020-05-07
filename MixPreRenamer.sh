#!/bin/bash
# set -x

#----usage----#
usage(){
echo "$0, $INPUTDIR must be a valid dir which leads to BWF.WAV files generated by MixPre-3 MkII sound device's equipment"
local ERROR=$1
echo "ERROR:$ERROR"
exit
}

#--Generate log file---#
LOG=Log.txt
[ -f $LOG ] && echo "==New Batch == $(Date)">>$LOG|| echo "Original file name ==> New filename ==> Date">$LOG

#----InputParameter

INPUTDIR=$1

#----Input Validation
[ -d $INPUTDIR ] && echo "input dir:$INPUTDIR is a valid folder" || usage "input dir:$INPUTDIR is not a valid dir"

#----List all .WAV files contained in INPUTDIR (! not recursively)----#
LISTOFWAV=$(find $INPUTDIR -maxdepth 1 | grep ".*\.WAV")
# if no found file => exit
[[ "$LISTOFWAV" == "" ]] && usage "No WAV files have been found in this dir:$INPUTDIR" || echo "$LISTOFWAV"

for WAV in $LISTOFWAV
do
  # path windows compatible
  WAVDISKNAME=$(echo "$WAV" | sed "s/\/cygdrive\/\([a-z]\)\/.*/\1/" | tr "[:lower:]" "[:upper:]")
  WAVDISKNAME="$WAVDISKNAME"":"
  WAVWINPATH=$(echo "$WAV" | sed "s/\/cygdrive\/[a-z]/$WAVDISKNAME/" )
  echo "wavwinpath:$WAVWINPATH"
  #Get Original FileName (the one gernate by the MixPre)
  ORIGINALFILENAME=$(ffprobe -loglevel -8 -show_entries "format_tags" "$WAVWINPATH" | grep "sFILENAME=" | tr -d "\r" )
  ORIGINALFILENAME=${ORIGINALFILENAME:10:(-4)}
  echo "original filename:$ORIGINALFILENAME"
  #Get Original TakeNumber
  ORIGINALTAKENUMBER=$(echo "$ORIGINALFILENAME" | sed "s/.*-\([0-9]*\)$/\1/")
  echo "original take number:$ORIGINALTAKENUMBER"
  # new  base file name based on sNOTE (snote must not over reach 84 characrters max)
  NEWFILENAME=$(ffprobe -loglevel -8 -show_entries "format_tags" "$WAVWINPATH" | grep "sNOTE=" | tr -d "\r" | sed "s/[^a-zA-Z0-9]/_/g" | tr " " "_" | tr "[:upper:]" "[:lower:]" | sed "s/_*$//" )
  NEWFILENAME=${NEWFILENAME:6}
  
  # Define if newfile name is applied or original filename is preserved  
  if [[ $NEWFILENAME == "" ]]; then
    NEWFILENAME="$ORIGINALFILENAME"
    else
    # get Format value (stereo mono), Bitdepth value, samplerate value
    FORMATVALUE=$(ffprobe -loglevel -8 -show_entries "format_tags" "$WAVWINPATH" | grep "TAG:coding_history=" | tr -d "\r" | sed "s/.*,M=\([^,]*\),.*/\1/" )
      case $FORMATVALUE in
        "mono")FORMATSTR="M";;
      "stereo")FORMATSTR="ST";;
             *)FORMATSTR="X"  
      esac
    BITDEPTHVALUE=$(ffprobe -loglevel -8 -show_entries "format_tags" "$WAVWINPATH" | grep "TAG:coding_history=" | tr -d "\r" | sed "s/.*,W=\([0-9][0-9]\),.*/\1/" )
    SAMPLERATEVALUE=$(ffprobe -loglevel -8 -show_entries "format_tags" "$WAVWINPATH" | grep "TAG:coding_history=" | tr -d "\r" | sed "s/.*,F=\([0-9]*\),.*/\1/" | tr -d "0" )
    # new file name is applied concatenante sNOTE + OriginalTakeNumber + BitDepthSR
    NEWFILENAME="$NEWFILENAME""_T""$ORIGINALTAKENUMBER""_""$FORMATSTR""$BITDEPTHVALUE""$SAMPLERATEVALUE"
  echo "NewFIleName:$NEWFILENAME"
  fi
    
  # concatenate input dir
  OUTPUTFILENAME="$INPUTDIR""/""$NEWFILENAME"".WAV"
  echo "output path:$OUTPUTFILENAME"
 
  #rename
  mv $WAV $OUTPUTFILENAME
  #log#
  echo -e "$ORIGINALFILENAME"" ==> ""$NEWFILENAME"" ==> ""$(date)\r" >>$LOG
done

exit

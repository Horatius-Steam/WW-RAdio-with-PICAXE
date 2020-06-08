init:
;set I/O
input C.2,C.3,C.4,B.2,B.3
output B.1,B.4,B.5

;Outputs
;RADIO
Symbol INTERNAL_LED	= B.1			;heartbeat to show that system is still alive
Symbol POWER_LED		= B.5			;LED to inteact with user eg. show that year has changed
Symbol TX			= B.4			;com port to MP3 player

;Inputs
;Radio
Symbol YEAR			= B.2			;ADC to read poti for year selection
Symbol VOLUME	      = B.3			;ADC to read poti for volume
Symbol ONOFF      	= C.4			;button to pause broadcast
;MP3
Symbol RX 			= C.3			;receives messages from MP3 player
Symbol BUSY_PIN 		= pinC.2		;busy pin from MP3 player, indicates that a sond is still playing

;constant values
;MP3
Symbol BAUD_FREQ 		= M8
Symbol BAUD 		= T9600_8

;Variables
;Radio
Symbol HelpVar		= b0			;universal helper variable for diverse purposes
Symbol BufferYear		= b1			;buffer for year selectiom
Symbol StorageYear	= b2			;storages for actula year
Symbol BufferVolume	= b4			;buffer for volume
Symbol StorageVolume	= b5			;storages for actual volume
Symbol DirOnMP3		= b8			;storages for DIR on SD card corralting to choosen year
Symbol RadioCounter	= b9			;counter for music pieces (10 music pieces per year)

;MP3
Symbol arg 			= w3 ; b7:b6	;word variable to controll MP3 player
Symbol arg.lsb 		= b6			;the corresponding LSB
Symbol arg.msb 		= b7			;the corresponding MSB

;init variables
HelpVar			= 0
BufferYear			= 0
StorageYear			= 0
BufferVolume		= 0
StorageVolume		= 0
DirOnMp3			= 0
RadioCounter		= 0

;initials all pins
Low INTERNAL_LED
High TX
High POWER_LED

;init MP3							;choose to use only SD card and wayt for enumbering all files on card
SerTxd("Select microSD Card", CR, LF )
HelpVar = $09 : arg = $0002 : Gosub Send
Pause 4000
gosub flashpower						;flash power LED to show that SD MP3 player is ready

main:
  ;debug
  gosub selectyear
  gosub setvolume
  gosub heartbeat 
  if BUSY_PIN = 1	then					;if no actual music is played and year has changed
    gosub flashpower					;show that now MP3 is played
    if RadioCounter = 10 then				;maximal 10 tracks
      Radiocounter = 1
    else
      INC RadioCounter					;inc for next track
    endif
    SerTxd("play from folder: ",StorageYear," Folder: ",DirOnMP3, CR, LF )
    arg.msb = DirOnMP3					;numbor of folder
    arg.lsb = RadioCounter				;number of track
    HelpVar = $0F						;command for folder play
    Gosub Send						;send command to MP3 player	
  endif
goto main

selectyear:
  HelpVar = 0						;clear universal variable HelpVar
  readadc YEAR,HelpVar					;read value from poti to variable HelpVar
   select HelpVar
  if helpVar > 240 then					;special feature, early radio
    BufferYear = 30
    DirOnMp3 = 01
  endif
  if HelpVar <= 230 and b0 >= 155 then		;assign poti range to buffer variable BufferYea
    BufferYear = 39
    DirOnMP3 = 02
  endif
  if HelpVar <= 200 and b0 >= 185 then
    BufferYear = 40
    DirOnMP3 = 03
  endif
  if HelpVar <= 170 and b0 >= 155 then
	BufferYear = 41
	DirOnMP3 = 04
  endif
  if HelpVar <= 140 and b0 >= 125 then
	BufferYear = 42
	DirOnMP3 = 05
  endif
  if HelpVar <= 110 and b0 >= 95 then
	BufferYear = 43
	DirOnMP3 = 06
  endif
  if HelpVar <= 80 and b0 >= 65 then
	BufferYear = 44
	DirOnMP3 = 07
  endif
  if HelpVar <= 50 and b0 >= 15 then
	BufferYear = 45
	DirOnMP3 = 08
  endif
  if HelpVar < 16 then					;special feature moon landing ;-)
	BufferYear = 50
	DirOnMP3 = 09
  endif
  if BufferYear <> StorageYear then			;if poti changed range, store year to storage varable
    StorageYear = BufferYear
    SerTxd("Stop", CR, LF )				;stop playing
    HelpVar = $16 : Gosub Send
    RadioCounter = 0					;Reset counter
    Pause 100
  endif
return

setvolume:
  HelpVar = 0						;reset HelpVar
  readadc VOLUME,HelpVar				;read value from poti to universal help variable
  BufferVolume = HelpVar / 8				;calculate range for MP3 player values are 0 - 30
  if BufferVolume > 30 then				; 255 / 8 = 31 so set value to 30
    BufferVolume = 30
  endif
  if StorageVolume <> BufferVolume then		;if poti has changed
    StorageVolume = BufferVolume			;store the value
    SerTxd("Set volume: ", #StorageVolume, CR, LF )
    HelpVar = $06 : arg = StorageVolume		;set volume on MP3 player
    Gosub Send
    Pause 100						
  endif
return

heartbeat:							;flash internal LED to show that system is alive
  high INTERNAL_LED
  pause 200
  low INTERNAL_LED
  pause 200
return

flashpower:							;flash power LED to show some activies
  low POWER_LED
  pause 500
  high POWER_LED
return

Send:								;universal subroutine to send commands to MP3 player
  SetFreq BAUD_FREQ
  Pause 10
  SerOut TX, BAUD, ( $7E, $FF, $06, HelpVar, $00, arg.msb, arg.lsb, $EF )
  SetFreq MDEFAULT
return



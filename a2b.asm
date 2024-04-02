a2b			START 		0
										. setup: copies input to src
			CLEAR	    A
			STA		    srcIdx
			STA		    ruleIdx
			STA		    segmentLen
			STA		    count
			JSUB		cpyInputToStr	. copies input to src
compSrcLen	LDA			srcIdx			. loads srcIdx to register A					| while (srcIdx < srcLen && ruleIdx < ruleLen) {
			LDS			srcLen			. loads srcLen to register S
			COMPR		A, S			. compare srcIdx with srcLen
			JLT			compRuleLen		. if srcIdx < srcLen, jumps to compRuleLen
										. for next comparison
			J			terminate		. otherwise, jumps to terminate
compRuleLen	LDA			ruleIdx			. loads ruleIdx to register A
			LDS			ruleLen			. loads ruleLen to register S
			COMPR		A, S			. compare ruleIdx with ruleLen
			JLT			loopInner		. if ruleIdx < ruleLen, jumps to loopInner
			J 			terminate		. otherwise, jumps to terminate
loopInner	JSUB		isSameChar		. compare src[srcIdx] and rule[ruleIdx]
			JEQ			increaseIdx		. if src[srcIdx] == rule[ruleIdx], 				|	 if (src[srcIdx] == rule[ruleIdx]) {
										. then jumps to increaseIdx
			J		    skipRule		. otherwise, skips current rule by jumping to
										. skipRule
increaseIdx LDA			srcIdx			. loads srcIdx to register A					|		 srcIdx++;
			ADD			#1				. adds 1 to register A
			STA			srcIdx			. stores register A to srcIdx
			LDA			segmentLen		. loads segmentLen to register A				|		 segmentLen++;
			ADD			#1				. adds 1 to register A
			STA			segmentLen		. stores register A to segmentLen
			LDA			ruleIdx			. loads ruleIdx to register A					|		 ruleIdx++;
			ADD			#1				. adds 1 to register A
			STA			ruleIdx			. stores register A to ruleIdx
			LDX			ruleIdx			. loads ruleIdx to register X					|		 if (rule[ruleIdx] == '=') {
			LDCH		rule, X			. loads rule[ruleIdx] to register A
			LDS			equal			. loads '=' to register S
			COMPR		A, S			. compares rule[ruleIdx] with '='
			JEQ			applyRule		. if rule[ruleIdx] == '=',
										. then apply the replacement to original pattern
			J			applyRuleEnd	. otherwise, keep matching rule and jumps to
										. next checking iteration
applyRule	CLEAR		A				. clears register A to 0						|			 int count = 0;
			STA			count			. sets count to 0
										. we have to skip '=' here
			LDA			ruleIdx			. loads ruleIdx									|			 ruleIdx++;
			ADD			#1				. adds 1 to register A
			STA			ruleIdx			. stores register A to ruleIdx
			LDA			srcIdx			. loads srcIdx to register A					|			 srcIdx -= segmentLen;
			SUB			segmentLen		. subtracts srcIdx with segmentLen
			STA			srcIdx			. stores register A to srcIdx
replaceStart							.												|			 while (count < segmentLen) {
			LDA			count			. loads count to register A
			LDS			segmentLen		. loads segmentLen to register S
			COMPR		A, S			. compares count with segmentLen
			JEQ			replaceEnd		. if count == segmentLen,
										. then jumps to replaceEnd
			LDX			ruleIdx			. loads ruleIdx to register X					|				 src[srcIdx] = rule[ruleIdx];
			LDCH		rule, X			. loads rule[ruleIdx] to register A
			LDX			srcIdx			. loads srcIdx to register X
			STCH		src, X			. stores rule[ruleIdx] to src[srcIdx]
			LDA			count			. loads count to register A						|				 count++;
			ADD			#1				. adds 1 to register A
			STA			count			. stores register A to count
			LDA			srcIdx			. loads srcIdx to register A					|				 srcIdx++;
			ADD			#1				. adds 1 to register A
			STA			srcIdx			. stores register A to srcIdx
			LDA			ruleIdx			. loads ruleIdx to register A					|				 ruleIdx++;
			ADD			#1				. adds 1 to register A
			STA			ruleIdx			. stores register A to ruleIdx
			J 			replaceStart 	. jumps back to replaceStart for next iteration
replaceEnd								.												|			}
			CLEAR		A				. clears register A to 0						|		 srcIdx = 0;  
			STA			srcIdx			. stores register A to srcIdx
			CLEAR		A				. clears register A to 0						|		 ruleIdx = 0;  
			STA			ruleIdx			. stores register A to ruleIdx
			CLEAR		A				. clears register A to 0						|		 segmentLen = 0;  
			STA			segmentLen		. stores register A to segmentLen
applyRuleEnd                            .                                               |        }
			J			loopEnd			. jumps to loop's end
skipRule								.												| 	  } else {
			LDA			srcIdx			. loads srcIdx to register A					|		 srcIdx -= segmentLen;
			SUB			segmentLen		. subtracts srcIdx with segmentLen
			STA			srcIdx			. stores subtraction result back to register A
			CLEAR		A				. clears register A to 0						|		 segmentLen = 0;
			STA			segmentLen		. stores 0 to segmentLen
skipUntilSemicolon						.												|		 while (ruleIdx < ruleLen && rule[ruleIdx] != ';') {
			LDA			ruleIdx			. loads ruleIdx to register A
			LDS			ruleLen			. loads ruleLen to register S
			COMPR		A, S			. compares ruleIdx with ruleLen
			JEQ			skipUntilSemicolonEnd
										. if ruleIdx >= ruleLen, jumps to 
										. skipUntilSemicolonEnd
			LDX			ruleIdx			. loads ruleIdx to register X
			LDCH		rule, X			. loads rule[ruleIdx] to register A
			LDS			semicolon		. loads ';' to register S
			COMPR		A, S			. compares rule[ruleIdx] with ';'
			JEQ			skipUntilSemicolonEnd
										. if rule[ruleIdx] == ';', jumps to
										. skipUntilSemicolonEnd
skipUntilSemicolonInc
			LDA			ruleIdx			. loads ruleIdx									|			 ruleIdx++;
			ADD			#1				. adds 1 to register A
			STA			ruleIdx			. stores register A to ruleIdx
			J			skipUntilSemicolon
										.												|		 }
										. jumps back to skipUntilSemicolon for next
										. iteration
skipUntilSemicolonEnd
										. after skipping process, we'll have to skip
										. additional 1 character (';')
			LDA			ruleIdx			. loads ruleIdx									|		 ruleIdx++;
			ADD			#1				. adds 1 to register A
			STA			ruleIdx			. stores register A to ruleIdx
			LDA			ruleIdx			. loads ruleIdx to register A					|		 if (ruleIdx >= ruleLen) {
			LDS			ruleLen			. loads ruleLen to register S
			COMPR		A, S			. compares ruleIdx with ruleLen
			JLT			skipRuleEnd		. if ruleIdx < ruleLen, more rules have to be
										. checked, thus, no need to increment srcIdx
										. and set ruleIdx back to 0
			LDA			srcIdx			. loads srcIdx to register A					|			 srcIdx++;
			ADD			#1				. adds 1 to register A
			STA			srcIdx			. stores register A to srcIdx
			CLEAR		A				. clears register A to 0						|			 ruleIdx = 0;
			STA			ruleIdx			. stores register A to ruleIdx
										.												|		 }
skipRuleEnd J			loopEnd			. jumps to loop's end							|	 }
loopEnd		J			compSrcLen		. jumps back to compSrcLen for next iteration	| }

. Phase wrapUp: prints output to device stdout and terminates program
terminate 	CLEAR		X
printStr	LDCH		src, X			. loads src[X] to register A
			JSUB		writeChar		. print out character at src[X]
			TIX			srcLen			. increase register X by 1 and compares with srcLen
			JLT			printStr		. if register X < srcLen, then jumps back to
										. printStr to print remaining characters
			LDA			newline			. loads new line character '\n'
			JSUB		writeChar		. print out character '\n'
			J	   	exit

. Function writeChar: Writes character from register A out to stdout
writeChar	TD			stdout			. tests if device stdout is ready
			JEQ			writeChar		. if device stdout is not ready, then jump 
										. to writeChar and continue waiting
			WD			stdout			. otherwise, write character from register A
										. to device stdout
			RSUB						. returns to parent process

. Function isSameChar: Compares src[srcIdx] and rule[ruleIdx],
. then stores comparison result (0 or 1) to register A
isSameChar	LDX			srcIdx			. loads srcIdx to register X
			LDCH		src, X			. loads src[srcIdx] to register A
			RMO			A, S			. moves value from register A to register S
			LDX			ruleIdx			. loads ruleIdx to register X
			LDCH		rule, X			. loads rule[ruleIdx] to register X
			COMPR		A, S			. compares src[srcIdx] and rule[ruleIdx]
			JEQ			isSameCharL0	. if comparison is 0, jumps to isSameCharL0
			LDA			#0				. otherwise, then loads 1 to register A
			RSUB						. returns to parent process
isSameCharL0
			LDA			#1				. loads 1 to register A
			RSUB						. returns to parent process
. end of Function isSameChar

. Function cpyInputToStr: Copies input string to src
cpyInputToStr
			LDT		 #3
			CLEAR		X				. clear register X to 0
cpyMov		LDCH		input, X		. loads input[X] to register A
			STCH		src, X			. stores register A to src[X]
			TIXR		T				. increase register X by 1 and compares with srcLen
			JLT			cpyMov
			RSUB						. returns to parent process

. constants	
stdout	    BYTE	  	X'01'
newline	    WORD	  	10
equal	    WORD		61
semicolon   WORD		59

. variables
srcIdx	 	RESW	  	1				. variable src's character index
ruleIdx	    RESW		1				. variable rule's character index
segmentLen	RESW		1				. used for matching a pattern
count		RESW		1				. used for copying
input		BYTE		C'CBA'
src	   	    RESB		3
srcLen		WORD		3
rule		BYTE		C'CB=BC;CA=AC;BA=AB'
ruleLen		WORD		17

exit		END		 a2b

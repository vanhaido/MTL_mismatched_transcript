#!/usr/bin/env python
import sys
import os
import re
import codecs
import sys, getopt

# This program reads hungarian text and converts it to IPA characters.
# It first reads through the text and tries to find English Words
# If English words are found, uses a pre-made dictionary to map the
# English word to IPA pronunciation syllables
# Any non-English word is then converted to IPA characters using a second
# Dictionary provided by Mark

#Define a file path

# dont check english dict
# cheat the system by using VN dictionary as the english dict
engPronuncToIpa =  os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/data" + "/temp"
engToPronunciation = os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/" + "data/temp2"
#hungWordsToPronunciation = os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/" + "data/dict.txt"
#hungWordsToPronunciation = os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/" + "data/lexicon_BABEL_norm_notone_IPA.txt"
hungWordsToPronunciation = "/home/hai/Dropbox/ADSC/Dict/Vietnamese/wenda/lexicon_norm_notone_IPA.txt"
hungPronunciationToIpa = os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/data" + "/g2p_dict.txt"
hungarianToIpa = os.environ["SBS_DATADIR"] + "/" +  "tkekona/" + "vietnamese/" + "data/g2p_dict.txt"
Hnum = 0
Enum = 0
Znum = 0
total = 0
def main(argv):

	#The current hardcoded locations are for test purposes. These values are overwritten by the
	#input parameters below
	htextlist = os.environ["SBS_DATADIR"] + "/" + "lists/vietnamese/train.txt"
	hungarianFileFolder = os.environ["SBS_DATADIR"] + "/" + "transcripts/matched/vietnamese/"

	try:
		opts, args = getopt.getopt(argv,"hg:u:t:",["g2p=","utts=","transdir="])
	except getopt.GetoptError:
		print 'sbs_create_phntrans_HG.py -g <grammerToPhone> -u <utterances> -t <transcriptDirectory>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'sbs_create_phntrans_HG.py -g <grammerToPhone> -u <utterances> -t <transcriptDirectory>'
			sys.exit()
		elif opt in ("-g", "--g2p"): #hungarian to IPA dictionary
			NOWIAMHARDCODINGTHIS = arg
		elif opt in ("-u", "--utts"): #.txt file list
			htextlist = arg
		elif opt in ("-t", "--transdir"): #actual location 
			hungarianFileFolder = arg

	#Make an Hungarian words to pronunciation dictionary
	HPDict = makeDictionary(hungWordsToPronunciation, '\t', True)
	#Make a Hungarian pronunciation to Ipa dictionary
	HPIDict = makeDictionary(hungPronunciationToIpa, '\t', True)
	#Chain HPDict and PIDict to make a HWIDict
	#HWIDict = chainDictionaries(HPDict, HPIDict)
	HWIDict = HPDict		

	#Make an English to Pronuncition of English word dictionary
	EPDict = makeDictionary(engToPronunciation, '\t', True)
	#Make an English Pronunciation to Ipa dictionary
	EPIDict = makeDictionary(engPronuncToIpa, '\t', True)
	#Map English words to Ipa Pronunciation by chaining EPDict and EPIDict
	#EWIDict = chainDictionaries(EPDict, EPIDict)
	EWIDict = EPDict
	#Make an Hungarian words/transcript not found in any dictionary to Ipa dictionary
	HIDict = makeDictionary(hungarianToIpa, '\t', True)
	
	#htextlist contains a list of all the hungarian transcript file names appended with .wav
	with open(htextlist) as list:
		#Iterate through the htext file names and change text to IPA form
		first = True
		for line in list:
#			I used to have a list of all the .wave files but it is now the list of .txt files
#			line = line[:-4]
#			toIpa(hungarianFileFolder + line + "txt", HEIDict, HIDict, line)
			toIpa(hungarianFileFolder + "/" + line.strip() + ".txt", HWIDict, EWIDict, HIDict, line)
	output = open("HungPriorityCorrectOrthMemory.txt", 'a')
	output.write("Vietnamese Words found using Viet Dict: " + str(Hnum) + "\n")
	output.write("English Words found using English (temp) Dict: " + str(Enum) + "\n")
	output.write("Other Words found using g2p: " + str(Znum) + "\n")
	output.write("Total num words in documents: " + str(total) + "\n")
			
def chainDictionaries(LPDict, PIDict):
	#New dictionary mapping from Language words to the IPA pronunciation of the word
	newdict = {}
	
	#For every key, value pair in dict1, convert value to Ipa and map dict1 key to Ipa of value
	for key, value in LPDict.iteritems():
		newValue = pronunciationToIpa(value, PIDict)
		newdict[key] = newValue
		
	return newdict

#value is the string of pronunciation symbols
def pronunciationToIpa(value, PIDict):
	#Result string to return
	result = ""
	
	#Split the original string by whitespace
	#vanhai	
	#phonemes = re.split('\W+', value.strip(), flags=re.UNICODE)
	#phonemes = re.split(' ', value.strip(), flags=re.UNICODE)
	phonemes = re.split(' ', value.strip())
	
	#Convert each phone to Ipa. If it doesn't exist, replace with a # and print an error message
	for phone in phonemes:
		if phone in PIDict:
			result += PIDict[phone].strip() + " "
		else:
			print "#" + phone + "#"
			print "#" + phone + "#" + " was not found in PIDict"
	
	return result.strip()
	
		
def makeDictionary(dictFile, parser, unicode):
	content = ""
	if unicode:
		#Open the hangarian to API character dictionary
		file = codecs.open(dictFile, 'r', 'utf-8')
		content = file.readlines()
		
	else:
		#We know these files are in English
		file = open(dictFile)
		content = file.readlines()
	
	#Dictionary to return
	dict = {}
	
	#If hangarian character is found, return API form of character
	for line in content:
		line = line.strip()
		#vanhai
		#line = line.lower()
		if not line.startswith("#") and not line.startswith(";;;"):
			pair =  re.split(parser, line)
			if len(pair) == 2:
				dict[pair[0].strip()] = pair[1].strip()
				
	return dict
	
def toIpa(hungarianFile, Hdict, Edict, dict, line):	
	#Open file with hungarian text and read it as unicode
	hf = codecs.open(hungarianFile, 'r', 'utf-8')
	hwords = hf.read()
	
	#Build string to write to output file
	ipa = ""
	
	#Makes a list of the individual words by parsing spaces
	#vanhai
	#words = re.findall(r"[\w']+|[!.?,\"\'$;:#%^&*@-]", hwords)

	


	#words = hwords.decode("utf-8").split()

	words = re.split('\W+', hwords, flags=re.UNICODE)

	#words = re.findall(r'\w+', hwords)
	#words = hwords
	memory = ""
	
	for word in words:
		#word = word.lower()
		global total
		total = total + 1
		#ipa += word
		if word in Hdict:
			ipa += Hdict[word] + " " 
	#		ipa += "<" + word + ">" + Hdict[word] + "  =="
			global Hnum
			Hnum = Hnum + 1
		elif word in Edict:
			#ipa += Edict[word] + "++"
			global Enum
			Enum = Enum + 1
		else:
			global Znum
			Znum = Znum + 1			
	#Iterate through each character in hwords and change hangarian characters to API
			#print word
			for char in word:
				#char = char.lower()
				if char == "." or char == "!" or char == "?":
					#ipa += clear(memory, dict)
					memory = ""
					#ipa += "sil "
				elif len(memory) == 3:
					if memory in dict:
						#ipa = ipa + dict[memory] + " "
						memory = ""
					elif memory[0:2] in dict:
						#ipa = ipa + dict[memory[0:2]] + " "
						memory = memory[2:3]
					elif memory[0:1] in dict:
						#ipa = ipa + dict[memory[0:1]] + " "
						memory = memory[1:3]
					else:
						memory = memory[1:3]
					memory = memory + char
				else:
					memory = memory + char
		#vanhai #ipa += clear(memory, dict)
		memory = ""
	#vanhai				
	print ipa.encode('utf-8').strip()
	#print ipa.encode('ascii').strip()
	
def clear(s, dict):
	if len(s) == 3:
		if s in dict:
			return dict[s] + " "
		else:
			return clear(s[0:2], dict) + clear(s[2:3], dict)
	elif len(s) == 2:
		if s in dict:
			return dict[s] + " "
		else:
			return clear(s[0:1], dict) + clear(s[1:2], dict)
	else:
		if s in dict:
			return dict[s] + " "
		else:
			return ""
	
main(sys.argv[1:])

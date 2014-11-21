proc getChoreList {} {
	return {"daily: clean dirty dishes" "on need: take trash to bins" "daily: put clean dishes away" "daily: clean Francis" "daily: feed Francis" "weekly: take trash bins to curb" "weekly: clean toilet" "biweekly: vacuum house" "biweekly: mop kitchen floor" "weekly: clean stove top" "biweekly: clean bathtub" "weekly: clean bathroom sink/mirror" "weekly: clean bathroom floor" "weekly: change bed sheets" "2/week: water garden" "weekly: pull weeds" "weekly: maintain compost" "biweekly: dust house" "weekly: tidying" "on need: buy lizard food"}
}

proc getParticipantList {} {
	return {adrian alisa}
}

proc getParticipantRanking {choreList participant} {
	array set ret {}
	puts "For participant $participant:"
	foreach chore $choreList {
    puts "Score for chore '$chore'?"
		set data [gets stdin]
		scan $data "%d" myint
    set ret($chore) $myint
	}
	return [array get ret]
}

proc getRankingMap {choreList participantList} {
	return {
		alisa {{on need: buy lizard food} 5 {weekly: clean bathroom sink/mirror} 1 {biweekly: dust house} 4 {biweekly: mop kitchen floor} 7 {2/week: water garden} 1 {daily: clean Francis} 2 {weekly: pull weeds} 4 {weekly: change bed sheets} 1 {biweekly: clean bathtub} 3 {weekly: maintain compost} 1 {on need: take trash to bins} 1 {weekly: clean stove top} 4 {weekly: tidying} 1 {daily: put clean dishes away} 1 {biweekly: vacuum house} 1 {weekly: clean bathroom floor} 7 {daily: clean dirty dishes} 7 {weekly: take trash bins to curb} 2 {daily: feed Francis} 2 {weekly: clean toilet} 6}
		adrian {{on need: buy lizard food} 3 {weekly: clean bathroom sink/mirror} 1 {biweekly: dust house} 4 {biweekly: mop kitchen floor} 4 {2/week: water garden} 4 {daily: clean Francis} 3 {weekly: pull weeds} 4 {weekly: change bed sheets} 1 {biweekly: clean bathtub} 2 {weekly: maintain compost} 1 {on need: take trash to bins} 3 {weekly: clean stove top} 3 {weekly: tidying} 4 {daily: put clean dishes away} 4 {biweekly: vacuum house} 4 {weekly: clean bathroom floor} 2 {daily: clean dirty dishes} 6 {weekly: take trash bins to curb} 1 {daily: feed Francis} 6 {weekly: clean toilet} 2}
		}
	array set ret {}
	foreach participant $participantList {
		set ret($participant) [getParticipantRanking $choreList $participant]
	}
	puts "return {[array get ret]}"
	gets stdin
	return [array get ret]
}

proc getParticipantListFromRankingMap {rankingMap} {
	set ret {}
	foreach {participant ranking} $rankingMap {
    lappend ret $participant
	}
	return $ret
}

proc getChoreListFromRankingMap {rankingMap} {
	set ret {}
	foreach {participant ranking} $rankingMap {
		foreach {chore rank} $ranking {
			if {[lsearch $ret $chore] == -1} {
				lappend ret $chore
			}
		}
	}
	return $ret
}

proc getWeightedRanking {ranking} {
	array set ret {}
	set totalWeight 0
  foreach {chore rank} $ranking {
		set totalWeight [expr $totalWeight + $rank]
	}
	foreach {chore rank} $ranking {
		set ret($chore) [expr $rank / ($totalWeight+0.0)]
	}
	return [array get ret]
}

proc getWeightedRankingMap {rankingMap} {
	array set weightedRankingMap {}
	foreach {participant ranking} $rankingMap {
    set weightedRankingMap($participant) [getWeightedRanking $ranking]
	}
  return [array get weightedRankingMap]
}

proc getTotalWeightsPerParticipantForAllocation {allocation rankingMap} {
  #make sure it is in weighted ranking form, as well as initialize the totalWeight map to 0 for each participant
	array set weightedRankingMap [getWeightedRankingMap $rankingMap]
	array set totalWeight {}
	foreach {participant ranking} $rankingMap {
	  set totalWeight($participant) 0.0
	}
  #sum up the total weight for this allocation
	foreach {chore participant} $allocation {
		array set curRanking $weightedRankingMap($participant)
		set curChoreWeight $curRanking($chore)
    set totalWeight($participant) [expr $totalWeight($participant) + $curChoreWeight]
	}
  return [array get totalWeight]
}

#allocation is map from chore->participantName
#rankingMap is map from participantName->getParticipantRanking
proc getAllocationScore {allocation rankingMap} {
  #make sure it is in weighted ranking form, as well as initialize the totalWeight map to 0 for each participant
	array set weightedRankingMap [getWeightedRankingMap $rankingMap]
	array set totalWeight {}
	foreach {participant ranking} $rankingMap {
	  set totalWeight($participant) 0.0
	}
  #sum up the total weight for this allocation
	foreach {chore participant} $allocation {
		array set curRanking $weightedRankingMap($participant)
		set curChoreWeight $curRanking($chore)
    set totalWeight($participant) [expr $totalWeight($participant) + $curChoreWeight]
	}
  #check constraints
  set participants [getParticipantListFromRankingMap $rankingMap]
	set maxWeightEach [expr 1.0 / [llength $participants]]
	set totalScore 0.0
	foreach participant $participants {
		set weight $totalWeight($participant)
		if {$weight > $maxWeightEach} {
      return -1
		} else {
      #score is euclidian distance
			set totalScore [expr $totalScore + ($weight * $weight)]
		}
	}
  #maximum weight each person could take on is 1/n, where n is the number of participants. Assuming that each person takes the max weight, then the euclidian sum will be n * (1/n)^2, or 1/n, which is just the maxWeightEach
	return [expr $maxWeightEach - $totalScore]
}

proc getAllAllocations {choreList participantList} {
	#if we have no chores, we are DONE
	if {[llength $choreList] == 0} {
		return ""
	}
	#get the first chore
	set firstChore [lindex $choreList 0]
	set choreList [lreplace $choreList 0 0]
  #get the remaining chores
	set remainingAllocations [getAllAllocations $choreList $participantList]
	set ret {}
  #add the first chore
	foreach participant $participantList {
	  if {[llength $remainingAllocations] == 0} {
			set newAllocation ""
		  lappend newAllocation $firstChore
			lappend newAllocation $participant
		  lappend ret $newAllocation
	  }
	  foreach allocation $remainingAllocations {
			set newAllocation $allocation
			lappend newAllocation $firstChore
			lappend newAllocation $participant
			lappend ret $newAllocation
		}
	}
	return $ret
}

#keep track of the top 10 allocations
set topAllocations {}
proc register_found_allocation {allocation rankingMap} {
	global topAllocations
  set oldTopAllocations $topAllocations
  set score [getAllocationScore $allocation $rankingMap]
	set allocated [invertArray $allocation]
  lappend topAllocations [list $score $allocated]
	set topAllocations [lsort -real -index 0 -decreasing $topAllocations]
  #trim off all but 10 items
	if {[llength $topAllocations] > 10} {
	  set topAllocations [lreplace $topAllocations 10 10]
	}
	if {$topAllocations != $oldTopAllocations} {
		puts "NEW ALLOCATION!"
	  foreach element $topAllocations {
		  foreach {score allocation} $element {
		    puts "Score = $score"
		    foreach {participant choreList} $allocation {
				  puts "$participant = $choreList"
			  }
		  }
	  }
	}
}

#rankingMap MUST be normalized!
proc findAllValidAllocationsCombined {_rankingMap participantList choreList {_curParticipantCost {}} {curAllocation {}}} {
  #we have no more chores left, return the currentAllocation
  if {[llength $choreList] == 0} {
		register_found_allocation $curAllocation ${_rankingMap}
		#return [list $curAllocation]
		return
	}
	array set rankingMap ${_rankingMap}
	array set curParticipantCost ${_curParticipantCost}
	#if curParticipantCost is empty for a given participant, initialize it to 0
	foreach participant $participantList {
		if {![info exists curParticipantCost($participant)]} {
			set curParticipantCost($participant) 0.0
		}
	}
	#pop the first chore off the front of the list
	set firstChore [lindex $choreList 0]
	set choreList [lreplace $choreList 0 0]
	#try to allocate the firstChore to each participant, seeing if it is still valid
	set maxWeightEach [expr 1.0 / [llength $participantList]]
	#set ret {}
	foreach participant $participantList {
    array set curRanking $rankingMap($participant)
		set curChoreWeight $curRanking($firstChore)
    set curWeight [expr $curParticipantCost($participant) + $curChoreWeight]
		if {$curWeight <= $maxWeightEach} {
			#this is a valid assignment, so continue chasing
			array set newCost ${_curParticipantCost}
			set newCost($participant) $curWeight
			set newAllocation $curAllocation
			lappend newAllocation $firstChore
			lappend newAllocation $participant
      #get all of the valid allocations, given our current allocations, and add them to our return list
			set allocations [findAllValidAllocationsCombined ${_rankingMap} $participantList $choreList [array get newCost] $newAllocation]
      #foreach allocation $allocations {
			#	lappend ret $allocation
			#}
		}
	}
  #return $ret
}

proc findAllValidAllocations {rankingMap} {
	set ret {}
	set choreList [getChoreListFromRankingMap $rankingMap]
	set participantList [getParticipantListFromRankingMap $rankingMap]
	set allAllocations [getAllAllocations $choreList $participantList]
	foreach allocation $allAllocations {
    set score [getAllocationScore $allocation $rankingMap]
		if {$score >= 0.0} {
			lappend ret $allocation
		}
	}
	return $ret
}

proc invertArray {mapping} {
	array set ret {}
	foreach {key value} $mapping {
		lappend ret($value) $key
	}
	return [array get ret]
}

proc main {} {
  set choreList [getChoreList]
	set participantList [getParticipantList]
  set rankingMap [getRankingMap $choreList $participantList]
  findAllValidAllocationsCombined [getWeightedRankingMap $rankingMap] $participantList $choreList
	puts "FINAL:"
	global topAllocations
	foreach element $topAllocations {
		foreach {score allocation} $element {
		  puts "Score = $score"
		  foreach {participant choreList} $allocation {
				puts "$participant = $choreList"
			}
		}
	}
}

if {0} {
proc main {} {
	set choreList [getChoreList]
	set participantList [getParticipantList]
  set rankingMap [getRankingMap $choreList $participantList]
	#set validAllocations [findAllValidAllocations $rankingMap]
	set validAllocations [findAllValidAllocationsCombined [getWeightedRankingMap $rankingMap] $participantList $choreList]
	set unsortedList {}
	foreach allocation $validAllocations {
		set score [getAllocationScore $allocation $rankingMap]
		set allocated [invertArray $allocation]
    lappend unsortedList [list $score $allocated]
	}
	set sortedList [lsort -real -index 0 $unsortedList]
	foreach element $sortedList {
		foreach {score allocation} $element {
		  puts "Score = $score"
		  foreach {participant choreList} $allocation {
				puts "$participant = $choreList"
			}
		}
	}
}
}

#!/bin/bash
#
# Copyright (c) Arnd Bergmann
# Copyright (c) 2026 Krzysztof Kozlowski <krzk@kernel.org>

# Start with our standard set of branches
TOPLEVEL="soc/arm soc/dt soc/drivers soc/defconfig soc/late arm/fixes"

BASE=v6.19-rc5
#BASE=mainline/master

# Append any custom ones. Figuring out dependency order is tricky, so we don't
# even try.
for b in $(git log --oneline --first-parent ${BASE}..for-next |
	sed "s/.*Merge branch '//g" | sed "s/' into .*//g" | grep / | sort -u) ; do
	if ! fgrep -q ${b} <<< "${TOPLEVEL}" ; then
		TOPLEVEL="${TOPLEVEL} ${b}"
	fi
done

# Main loop. Iterate over all toplevel branches
#
for b in ${TOPLEVEL} ; do
	echo ${b}
	# Branch doesn't exist (yet)? Skip it.
	if [ -z "$(git ls-remote . refs/heads/${b})" ] ; then
		echo ""
		continue
	fi
	# This will cause weird stuff to happen if mainline/master is behind
	# the topic branch, so make sure it's always updated.
#       BASE=$(git merge-base mainline/master ${b} 2>/dev/null)
	SHAS=$(git log --reverse --oneline --first-parent ${BASE}..${b} | sed "s/ .*//g")
	# We keep track of whether the last printed entry was a patch or a branch
	# to avoid re-printing "patch" when several are applied.
	LP=0
	for s in ${SHAS} ; do
		if git show --format=short ${s} | egrep -q "^Merge:" ; then
			# Actual branch merge. SHA is the top commit of the topic branch
			SHA=$(git log --oneline -1 --abbrev=12 --pretty=%H ${s}^2)
			# Try to figure out if we have a local head for it, if not use <no branch>
			BRANCH=$(git ls-remote . refs/heads/* |fgrep ${SHA} | sed s@.*refs/heads/@@g)
			: ${BRANCH:="<no branch> (${SHA})"}
			# Print out the branch and the tag or branch that was merged.
			echo "	${BRANCH}"
			echo -n "		"
			git log -1 --pretty=%s ${s} |
				sed "s/Merge tag '\(.*\)' of \(.*\) into.*/\2 tags\/\1/g" |
				sed "s/Merge branch '\(.*\)' of \(.*\) into.*/\2 \1/g"
			# Try to be clever and see if there are any included branches
			# here so we can express dependencies. Exclude any topic that
			# is already in our category branch.
			for b in $(git branch --merged ${SHA} |
				fgrep -v "${BRANCH}" |
				fgrep -v master) ; do
				if ! git branch --merged ${s}^1 | fgrep -q ${b} ; then
					echo "		contains ${b}"
				fi
			done
			LP=0
		else
			# This is a patch, not a branch, so just print the subject
			if [ ${LP} != 1 ] ; then
				echo "	patch"
			fi
			echo -n "		"
			git log -1 --pretty=%s ${s} | tac
			LP=1
		fi
	done
	echo ""
done

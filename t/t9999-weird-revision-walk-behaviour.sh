#!/bin/sh

test_description='Weird revision walk behaviour'

. ./test-lib.sh

# Create the following history, i.e. where both parents of merge 'M1'
# are in 'master':
#
#   B---M2   master
#  / \ /
# A   X
#  \ / \
#   C---M1   b2
#
# and modify 'file' in commits 'A' and 'B', so one of 'M1's parents
# ('B') is TREESAME wrt. 'file'.
test_expect_success 'setup' '
	test_commit initial file &&	# A
	test_commit modified file &&	# B
	git checkout -b b1 master^ &&
	test_commit other-file &&	# C
	git checkout -b b2 master &&
	git merge --no-ff b1 &&		# M1
	git checkout master &&
	git merge --no-ff b1		# M2
'

test_expect_success 'debug' '
	git log --oneline --graph --all
'

test_expect_failure "\"Merge branch 'b1' into b2\" should not be shown" '
	git log master..b2 -- file >actual &&
	test_must_be_empty actual
'

test_done

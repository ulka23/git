#!/bin/sh

test_description='racy edit todo reread problem'

. ./test-lib.sh

test_expect_success 'setup' '
	test_commit first_ &&
	test_commit second &&
	test_commit third_ &&
	test_commit fourth &&
	test_commit fifth_ &&
	test_commit sixth_ &&

	write_script sequence-editor <<-\EOS &&
		todo=.git/rebase-merge/git-rebase-todo &&
		cat >"$todo" <<-EOF
			reword $(git rev-parse second^0) second
			reword $(git rev-parse third_^0) third_
			reword $(git rev-parse fourth^0) fourth
		EOF
	EOS

	write_script commit-editor <<-\EOS &&
		read first_line <"$1" &&
		echo "$first_line - edited" >"$1" &&

		todo=.git/rebase-merge/git-rebase-todo &&

		if test "$first_line" = second
		then
			stat --format=%i "$todo" >expected-ino
		elif test "$first_line" = third_
		then
			ino=$(cat expected-ino) &&
			file=$(find . -inum $ino) &&
			if test -n "$file"
			then
				echo &&
				echo "Trying to free inode $ino by moving \"$file\" out of the way" &&
				cp -av "$file" "$file".tmp &&
				rm -fv "$file"
			fi &&

			cat >"$todo".tmp <<-EOF &&
			reword $(git rev-parse fifth_^0) fifth_
			reword $(git rev-parse sixth_^0) sixth_
			EOF
			mv -v "$todo".tmp "$todo" &&

			if test "$ino" -eq $(stat --format=%i "$todo")
			then
				echo "Yay! The todo list did get inode $ino, just what the sequencer is expecting!"
			fi &&

			if test -n "$file"
			then
				mv -v "$file".tmp "$file"
			fi
		fi
	EOS

	cat >expect <<-\EOF
	sixth_ - edited
	fifth_ - edited
	third_ - edited
	second - edited
	first_
	EOF
'

for trial in 0 1 2 3 4
do
	test_expect_success "demonstrate racy todo re-read problem #$trial" '
		git reset --hard fourth &&
		>expected-ino && # placeholder

		GIT_SEQUENCE_EDITOR=./sequence-editor \
		GIT_EDITOR=./commit-editor \
		git rebase -i HEAD^^^ &&

		git log --format=%s >actual &&
		test_cmp expect actual
	'
done

test_done

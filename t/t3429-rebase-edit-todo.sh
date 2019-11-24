#!/bin/sh

test_description='rebase should reread the todo file if an exec modifies it'

. ./test-lib.sh
. "$TEST_DIRECTORY"/lib-rebase.sh

test_expect_success 'setup' '
	test_commit first file &&
	test_commit second file &&
	test_commit third file
'

test_expect_success 'rebase exec modifies rebase-todo' '
	todo=.git/rebase-merge/git-rebase-todo &&
	git rebase HEAD -x "echo exec touch F >>$todo" &&
	test -e F
'

test_expect_success SHA1 'loose object cache vs re-reading todo list' '
	GIT_REBASE_TODO=.git/rebase-merge/git-rebase-todo &&
	export GIT_REBASE_TODO &&
	write_script append-todo.sh <<-\EOS &&
	# For values 5 and 6, this yields SHA-1s with the same first two digits
	echo "pick $(git rev-parse --short \
		$(printf "%s\\n" \
			"tree $EMPTY_TREE" \
			"author A U Thor <author@example.org> $1 +0000" \
			"committer A U Thor <author@example.org> $1 +0000" \
			"" \
			"$1" |
		  git hash-object -t commit -w --stdin))" >>$GIT_REBASE_TODO

	shift
	test -z "$*" ||
	echo "exec $0 $*" >>$GIT_REBASE_TODO
	EOS

	git rebase HEAD -x "./append-todo.sh 5 6"
'

test_expect_success 'todo is re-read after reword and squash' '
	write_script reword-editor.sh <<-\EOS &&
	GIT_SEQUENCE_EDITOR="echo \"exec echo $(cat file) >>actual\" >>" \
		git rebase --edit-todo
	EOS

	test_write_lines first third >expected &&
	set_fake_editor &&
	GIT_SEQUENCE_EDITOR="$EDITOR" FAKE_LINES="reword 1 squash 2 fixup 3" \
		GIT_EDITOR=./reword-editor.sh git rebase -i --root third &&
	test_cmp expected actual
'

test_expect_success 'setup for racy tests' '
	write_script sequence-editor <<-EOS &&
		cat >.git/rebase-merge/git-rebase-todo <<-\EOF
			r $(git rev-parse second^0) second
			r $(git rev-parse third^0) third
		EOF
	EOS

	write_script commit-editor <<-\EOS &&
		read first_line <"$1" &&
		echo "$first_line - edited" >"$1" &&

		todo=.git/rebase-merge/git-rebase-todo &&

		if test "$first_line" = second
		then
			old_size=$(wc -c <"$todo") &&
			# Replace the "reword <full-oid> third" line with
			# a different instruction of the same line length.
			# Overwrite the file in-place, so the inode stays
			# the same as well.
			cat >"$todo" <<-EOF &&
				exec echo 0123456789012345678901234 >exec-cmd-was-run
			EOF
			new_size=$(wc -c <"$todo") &&

			if test $old_size -ne $new_size
			then
				echo >&2 "error: bug in the test script: the size of the todo list must not change"
				exit 1
			fi
		fi
	EOS

	cat >expect <<-\EOF
	second - edited
	first
	EOF
'

# This test can give false success if your machine is sufficiently
# slow or all trials happened to happen on second boundaries.

for trial in 0 1 2 3 4
do
	test_expect_success "racy todo re-read #$trial" '
		git reset --hard third &&
		rm -rf exec-cmd-was-run &&

		GIT_SEQUENCE_EDITOR=./sequence-editor \
		GIT_EDITOR=./commit-editor \
		git rebase -i HEAD^^ &&

		test_path_is_file exec-cmd-was-run &&
		git log --format=%s >actual &&
		test_cmp expect actual
	'
done

test_done

#!/bin/sh

test_description='require_clean_work_tree'

. ./test-lib.sh

sh_setup_path="$(git --exec-path)"/git-sh-setup

run_require_clean_work_tree () {
	(
		. "$sh_setup_path" &&
		require_clean_work_tree "do-something"
	)
}

test_expect_success 'setup' '
	test_commit initial file
'

test_expect_success 'success on clean index and worktree' '
	run_require_clean_work_tree
'

test_expect_success 'error on dirty worktree' '
	echo "Cannot do-something: You have unstaged changes." >expect &&
	test_when_finished "git reset --hard" &&
	echo dirty >file &&
	test_must_fail run_require_clean_work_tree 2>err &&
	test_cmp expect err
'

test_expect_success 'error on dirty index' '
	echo "Cannot do-something: Your index contains uncommitted changes." >expect &&
	test_when_finished "git reset --hard" &&
	echo dirty >file &&
	git add file &&
	test_must_fail run_require_clean_work_tree 2>err &&
	test_cmp expect err
'

test_expect_success 'error on dirty index and worktree' '
	cat >expect <<-EOF &&
	Cannot do-something: You have unstaged changes.
	Additionally, your index contains uncommitted changes.
	EOF
	test_when_finished "git reset --hard" &&
	echo dirty >file &&
	git add file &&
	echo dirtier >file &&
	test_must_fail run_require_clean_work_tree 2>err &&
	test_cmp expect err
'

test_expect_success 'error on clean index and worktree while on orphan branch' '
	test_when_finished "git checkout master" &&
	git checkout --orphan orphan &&
	git reset --hard &&
	run_require_clean_work_tree
'

test_expect_success 'error on dirty index while on orphan branch' '
	echo "Cannot do-something: Your index contains uncommitted changes." >expect &&
	test_when_finished "git checkout master" &&
	git checkout --orphan orphan &&
	test_must_fail run_require_clean_work_tree 2>err &&
	test_cmp expect err
'

test_expect_success 'error on dirty index and work tree while on orphan branch' '
	cat >expect <<-EOF &&
	Cannot do-something: You have unstaged changes.
	Additionally, your index contains uncommitted changes.
	EOF
	test_when_finished "git checkout master" &&
	git checkout --orphan orphan &&
	echo dirty >file &&
	test_must_fail run_require_clean_work_tree 2>err &&
	test_cmp expect err
'

test_done
